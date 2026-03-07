"""
    nsga2(model::Model; kwargs...)

Runs the NSGA-II evolutionary algorithm on the given optimization model.

# Arguments
- `model::Model`: JuMP optimization model.

# Keyword Arguments
- Various user options (e.g., population size, generations, penalty type, etc.).

# Returns
- `(pareto_front::Vector{SolutionNSGA}, report)`: Final Pareto front and performance report.
"""
function nsga2(model::Model; kwargs...)
    @warn("Still not ready")
    user_options = Dict(kwargs) 
    options = nsga2_options(user_options, model)

    pop_size       = options[:pop_size]
    generations    = options[:generations]
    crossover_rate = options[:crossover_rate]
    mutation_rate  = options[:mutation_rate]
    penalty        = options[:penalty]
    rho            = options[:rho]

    dvars = decision_vars(model)
    obj_exprs = model_objectives(model)
    obj_coefs, obj_consts = compile_affine_objectives(obj_exprs, dvars)
    cons_coefs, cons_rhs, cons_sense = extract_linear_constraints(model, dvars)

    population = initialize_population(dvars, options[:num_objectives], pop_size; default_range=options[:default_range])

    # ===== Initial log =====
    start_time = time()
    println_if_necessary("Initializing NSGA-II with $(options[:num_objectives]) objectives.", options)
    println_if_necessary("Population size: $pop_size", options)
    println_if_necessary("Generations: $generations", options)
    println_if_necessary("Penalty type: $penalty", options)
    println_if_necessary("Objective sense: $(options[:objective_sense_set])", options)

    println_if_necessary("-"^76, options)
    printf_if_necessary(options, "%-12s | %15s | %23s", "Generation", "Time (s)", "Best fitness[1]")
    println_if_necessary("-"^76, options)

    # Initial evaluation
    evaluate_population_with_penalty!(population, dvars, obj_coefs, obj_consts,
                                      cons_coefs, cons_rhs, cons_sense;
                                      penalty_type=penalty, ρ=rho, generation=0, maxgen=generations,
                                      sense_vec=options[:objective_sense_set])

    # Evolutionary loop
    for gen in 1:generations
        fronts = fast_non_dominated_sort(population, options[:objective_sense_set])
        for front in fronts
            calculate_crowding_distance!(front)
        end
        mating_pool = selection(population, pop_size, options[:objective_sense_set])
        offspring = variation(mating_pool, crossover_rate, mutation_rate)

        for ind in offspring
            for (j,var) in enumerate(dvars)
                nm = Symbol(name(var))
                val = ind.variables[nm]
                lb = has_lower_bound(var) ? lower_bound(var) : -Inf
                ub = has_upper_bound(var) ? upper_bound(var) : Inf
                ind.variables[nm] = clamp(val, lb, ub)
            end
        end

        evaluate_population_with_penalty!(offspring, dvars, obj_coefs, obj_consts,
                                          cons_coefs, cons_rhs, cons_sense;
                                          penalty_type=penalty, ρ=rho, generation=gen, maxgen=generations,
                                          sense_vec=options[:objective_sense_set])

        population = environmental_selection(vcat(population, offspring), pop_size, options[:objective_sense_set])

        # ===== Log per generation =====
        elapsed = round(time() - start_time, digits=4)
        best_fit = minimum([ind.fitness[1] for ind in population])
        printf_if_necessary(options, "%-12d | %15.4f | %23.4f", gen, elapsed, best_fit)
    end

    total_time = time() - start_time
    println_if_necessary("Total execution time: $total_time seconds", options)
    println_if_necessary("-"^76, options)
    println_if_necessary("Execution completed\n", options)

    fronts = fast_non_dominated_sort(population, options[:objective_sense_set])
    pareto_front = fronts[1]

    # Generate final report
    report = nsga2_report(pareto_front, total_time, options)

    return pareto_front, report
end


###############################
###############################
###############################

"""
    compute_penalty(v::Vector{Float64}; penalty_type::Symbol=:quadratic, ρ::Float64=1.0, generation::Int=0, maxgen::Int=1)

Computes a penalty value based on the constraint violations `v`.

# Arguments
- `v::Vector{Float64}`: Vector of constraint violations.
- `penalty_type::Symbol`: Type of penalty calculation. Supported values:
    - `:linear`      → Linear penalty.
    - `:quadratic`   → Quadratic penalty (default).
    - `:inverse`     → Inverse penalty.
    - `:adaptive`    → Generation-based adaptive penalty.
- `ρ::Float64`: Penalty scaling factor.
- `generation::Int`: Current generation index (for adaptive penalties).
- `maxgen::Int`: Total number of generations.

# Returns
- `Float64`: The computed penalty.
"""
function compute_penalty(v::Vector{Float64}; penalty_type::Symbol=:quadratic, ρ::Float64=1.0, generation::Int=0, maxgen::Int=1)
    if isempty(v)
        return 0.0
    end
    if penalty_type == :linear
        return ρ * sum(v)
    elseif penalty_type == :quadratic
        return ρ * sum(v .^ 2)
    elseif penalty_type == :inverse
        return ρ * sum(1.0 ./ (1.0 .+ v))
    elseif penalty_type == :adaptive
        factor = 1.0 + generation / max(1, maxgen)
        return ρ * factor * sum(v .^ 2)
    else
        error("Invalid penalty type: $penalty_type")
    end
end

"""
    eval_objectives_affine!(out, xvec, obj_coefs, obj_consts)

Evaluates affine objectives based on pre-computed coefficients and constants.

# Arguments
- `out::Vector{Float64}`: Vector to store the evaluated objectives.
- `xvec::Vector{Float64}`: Decision variables.
- `obj_coefs::Vector{Vector{Float64}}`: Coefficients for each objective.
- `obj_consts::Vector{Float64}`: Constant terms for each objective.

# Returns
- `Vector{Float64}`: The updated objective values.
"""
@inline function eval_objectives_affine!(out::Vector{Float64}, xvec::Vector{Float64}, obj_coefs::Vector{Vector{Float64}}, obj_consts::Vector{Float64})
    for i in 1:length(out)
        out[i] = dot(obj_coefs[i], xvec) + obj_consts[i]
    end
    return out
end

"""
    compile_affine_objectives(obj_exprs, dvars)

Extracts the coefficients and constants from affine objective expressions.

# Arguments
- `obj_exprs::Vector`: JuMP objective expressions.
- `dvars::Vector{VariableRef}`: Decision variables.

# Returns
- `(Vector{Vector{Float64}}, Vector{Float64})`: Tuple containing the coefficients and constants.
"""
function compile_affine_objectives(obj_exprs::Vector, dvars::Vector{VariableRef})
    nd = length(dvars)
    m  = length(obj_exprs)
    coefs = [zeros(Float64, nd) for _ in 1:m]
    consts = zeros(Float64, m)

    for i in 1:m
        expr = obj_exprs[i]
        if !(expr isa JuMP.GenericAffExpr)
            @warn "Objective $i is not affine; it will be ignored in solver-free evaluation."
            continue
        end
        consts[i] = JuMP.constant(expr)
        for (c, v) in JuMP.linear_terms(expr)
            idx = findfirst(==(v), dvars)
            if idx !== nothing
                coefs[i][idx] += c
            end
        end
    end
    return coefs, consts
end

"""
    evaluate_population_with_penalty!(population, dvars, obj_coefs, obj_consts, cons_coefs, cons_rhs, cons_sense; ...)

Evaluates the objective functions for the entire population and applies penalties for constraint violations.

# Arguments
- `population::Vector{SolutionNSGA}`: Population of solutions.
- `dvars::Vector{VariableRef}`: Decision variables.
- `obj_coefs`: Objective coefficients.
- `obj_consts`: Objective constants.
- `cons_coefs`: Constraint coefficients.
- `cons_rhs`: Constraint right-hand sides.
- `cons_sense`: Constraint senses (`<=`, `>=`, `==`).

# Keyword Arguments
- `penalty_type::Symbol`: Penalty computation type.
- `ρ::Float64`: Penalty scaling factor.
- `generation::Int`: Current generation.
- `maxgen::Int`: Total number of generations.
- `sense_vec::Vector{String}`: Objective senses (`Max` or `Min`).

# Modifies
- Updates each individual's fitness values.
"""
function evaluate_population_with_penalty!(population::Vector{SolutionNSGA},
                                           dvars::Vector{VariableRef},
                                           obj_coefs::Vector{Vector{Float64}}, obj_consts::Vector{Float64},
                                           cons_coefs, cons_rhs, cons_sense;
                                           penalty_type::Symbol=:quadratic, ρ::Float64=0.5,
                                           generation::Int=0, maxgen::Int=1,
                                           sense_vec::Vector{String}=String[])

    nd = length(dvars)
    tmpx = zeros(Float64, nd)

    for ind in population
        # Copy variable values
        @inbounds for j in 1:nd
            tmpx[j] = ind.variables[Symbol(name(dvars[j]))]
        end

        # Evaluate objectives
        eval_objectives_affine!(ind.objectives, tmpx, obj_coefs, obj_consts)

        # Calculate constraint violations
        v = constraint_violations(tmpx, cons_coefs, cons_rhs, cons_sense)

        # Raw penalty calculation
        raw_penalty = compute_penalty(v; penalty_type=penalty_type,
                                         ρ=ρ, generation=generation, maxgen=maxgen)

        # Typical objective scale to avoid penalty domination
        avg_obj = mean(abs.(ind.objectives) .+ 1e-6)

        # Adaptive penalty factor based on generation progress
        pen_factor = ρ * (generation / maxgen + 1e-6)

        # Normalized penalty
        scaled_penalty = pen_factor * raw_penalty / avg_obj

        # Fitness adjustment
        if any(v .> 0.0)   # Penalize only if violation exists
            if sense_vec[1] == "Min"
                ind.fitness .= ind.objectives .+ scaled_penalty
            else
                ind.fitness .= ind.objectives .- scaled_penalty
            end
        else
            # No violation → fitness = objectives
            ind.fitness .= ind.objectives
        end

        # Store objectives in dictionary for compatibility
        ind.variables[:objs] = copy(ind.objectives)
    end
end

"""
    dominates_vec(a, b; sense)

Checks whether solution `a` dominates solution `b` based on objective sense.

# Arguments
- `a::Vector{Float64}`: Objectives of solution A.
- `b::Vector{Float64}`: Objectives of solution B.
- `sense::Vector{String}`: Objective sense (`Max` or `Min`).

# Returns
- `Bool`: `true` if `a` dominates `b`, otherwise `false`.
"""
function dominates_vec(a::Vector{Float64}, b::Vector{Float64}; sense::Vector{String})
    as_good_in_all = true
    at_least_better = false
    for i in 1:length(a)
        if sense[i] == "Min"
            if a[i] > b[i] + 1e-12
                as_good_in_all = false
                break
            elseif a[i] < b[i] - 1e-12
                at_least_better = true
            end
        else
            if a[i] < b[i] - 1e-12
                as_good_in_all = false
                break
            elseif a[i] > b[i] + 1e-12
                at_least_better = true
            end
        end
    end
    return as_good_in_all && at_least_better
end

"""
    fast_non_dominated_sort(population, sense_vec)

Performs the non-dominated sorting of the population based on NSGA-II.

# Arguments
- `population::Vector{SolutionNSGA}`: Set of solutions.
- `sense_vec::Vector{String}`: Objective senses (`Max` or `Min`).

# Returns
- `Vector{Vector{SolutionNSGA}}`: Sorted fronts of solutions.
"""
function fast_non_dominated_sort(population::Vector{SolutionNSGA}, sense_vec::Vector{String})
    N = length(population)
    S = [Int[] for _ in 1:N]
    n = zeros(Int, N)
    rank = zeros(Int, N)
    F1 = Int[]

    for p in 1:N
        for q in 1:N
            if p == q; continue; end
            if dominates_vec(population[p].fitness, population[q].fitness; sense=sense_vec)
                push!(S[p], q)
            elseif dominates_vec(population[q].fitness, population[p].fitness; sense=sense_vec)
                n[p] += 1
            end
        end
        if n[p] == 0
            rank[p] = 1
            push!(F1, p)
        end
    end

    fronts_idx = Vector{Vector{Int}}()
    push!(fronts_idx, F1)
    i = 1
    while i <= length(fronts_idx) && !isempty(fronts_idx[i])
        Q = Int[]
        for p in fronts_idx[i]
            for q in S[p]
                n[q] -= 1
                if n[q] == 0
                    rank[q] = i + 1
                    push!(Q, q)
                end
            end
        end
        push!(fronts_idx, Q)
        i += 1
    end

    for j in 1:N
        population[j].rank = rank[j]
    end

    out = Vector{Vector{SolutionNSGA}}()
    for F in fronts_idx
        push!(out, [population[i] for i in F])
    end
    return out
end

"""
    calculate_crowding_distance!(front)

Computes crowding distances for solutions within a given front.

# Arguments
- `front::Vector{SolutionNSGA}`: Solutions in the same front.
"""
function calculate_crowding_distance!(front::Vector{SolutionNSGA})
    l = length(front)
    if l == 0
        return
    end
    m = length(front[1].fitness)
    for ind in front
        ind.crowding_distance = 0.0
    end
    for i in 1:m
        sorted = sort(front, by=x->x.fitness[i])
        sorted[1].crowding_distance = Inf
        sorted[end].crowding_distance = Inf
        fmin = sorted[1].fitness[i]
        fmax = sorted[end].fitness[i]
        if abs(fmax - fmin) < 1e-12
            continue
        end
        for j in 2:l-1
            sorted[j].crowding_distance += (sorted[j+1].fitness[i] - sorted[j-1].fitness[i]) / (fmax - fmin)
        end
    end
end

"""
    selection(population, pop_size, sense_vec)

Selects individuals for the mating pool using tournament selection.

# Arguments
- `population::Vector{SolutionNSGA}`: Population of solutions.
- `pop_size::Int`: Number of individuals to select.
- `sense_vec::Vector{String}`: Objective senses.

# Returns
- `Vector{SolutionNSGA}`: Selected mating pool.
"""
function selection(population::Vector{SolutionNSGA}, pop_size::Int, sense_vec::Vector{String})
    mating_pool = SolutionNSGA[]
    while length(mating_pool) < pop_size
        a, b = rand(population, 2)
        winner = dominates_vec(a.fitness, b.fitness; sense=sense_vec) ? a :
                 dominates_vec(b.fitness, a.fitness; sense=sense_vec) ? b :
                 (a.crowding_distance > b.crowding_distance ? a : b)
        push!(mating_pool, winner)
    end
    return mating_pool
end

"""
    crossover(parent1, parent2; η=20.0)

Performs simulated binary crossover (SBX) between two parents.

# Arguments
- `parent1::SolutionNSGA`
- `parent2::SolutionNSGA`
- `η::Float64`: Distribution index (default = 20.0).

# Returns
- `(SolutionNSGA, SolutionNSGA)`: Two offspring.
"""
function crossover(parent1::SolutionNSGA, parent2::SolutionNSGA; η=20.0)
    child1_vars = copy(parent1.variables)
    child2_vars = copy(parent2.variables)

    for k in keys(parent1.variables)
        # Only crossover scalar decision variables
        if k == :objs || startswith(string(k), "_")
            continue
        end
        if rand() < 0.5
            x1 = parent1.variables[k]
            x2 = parent2.variables[k]
            if x1 != x2 && !(x1 isa AbstractVector) && !(x2 isa AbstractVector)
                β = 1 + (2*min(x1,x2)) / abs(x1-x2)
                α = 2 - β^(-(η+1))
                βq = rand() <= 1/α ? (rand()*α)^(1/(η+1)) : (1/(2-rand()*α))^(1/(η+1))
                c1 = 0.5*((1+βq)*x1 + (1-βq)*x2)
                c2 = 0.5*((1-βq)*x1 + (1+βq)*x2)
                child1_vars[k] = c1
                child2_vars[k] = c2
            end
        end
    end

    return SolutionNSGA(child1_vars, zeros(length(parent1.objectives)), zeros(length(parent1.fitness)), 0, 0.0),
           SolutionNSGA(child2_vars, zeros(length(parent1.objectives)), zeros(length(parent1.fitness)), 0, 0.0)
end

"""
    mutate!(ind; mutation_rate=0.1)

Applies mutation to a solution by adding random noise to its decision variables.

# Arguments
- `ind::SolutionNSGA`: Individual to mutate.
- `mutation_rate::Float64`: Probability of mutation.
"""
function mutate!(ind::SolutionNSGA; mutation_rate=0.1)
    for (k, v) in ind.variables
        # Only mutate scalar decision variables
        if k == :objs || startswith(string(k), "_") || v isa AbstractVector
            continue
        end
        if rand() < mutation_rate
            δ = 0.1 * (2rand() - 1)
            ind.variables[k] = v + δ
        end
    end
end

"""
    variation(mating_pool, crossover_rate, mutation_rate)

Generates offspring by performing crossover and mutation.

# Arguments
- `mating_pool::Vector{SolutionNSGA}`: Selected parents.
- `crossover_rate::Float64`: Probability of crossover.
- `mutation_rate::Float64`: Probability of mutation.

# Returns
- `Vector{SolutionNSGA}`: New offspring.
"""
function variation(mating_pool::Vector{SolutionNSGA}, crossover_rate::Float64, mutation_rate::Float64)
    offspring = SolutionNSGA[]
    shuffle!(mating_pool)
    for i in 1:2:length(mating_pool)-1
        p1, p2 = mating_pool[i], mating_pool[i+1]
        if rand() < crossover_rate
            c1, c2 = crossover(p1,p2)
        else
            c1, c2 = deepcopy(p1), deepcopy(p2)
        end
        mutate!(c1; mutation_rate=mutation_rate)
        mutate!(c2; mutation_rate=mutation_rate)
        push!(offspring, c1, c2)
    end
    return offspring
end

"""
    environmental_selection(combined, pop_size, sense_vec)

Selects the next generation from the combined parent and offspring population.

# Arguments
- `combined::Vector{SolutionNSGA}`: Parent + offspring solutions.
- `pop_size::Int`: Desired population size.
- `sense_vec::Vector{String}`: Objective senses.

# Returns
- `Vector{SolutionNSGA}`: New population.
"""
function environmental_selection(combined::Vector{SolutionNSGA}, pop_size::Int, sense_vec::Vector{String})
    new_pop = SolutionNSGA[]
    fronts = fast_non_dominated_sort(combined, sense_vec)
    for front in fronts
        calculate_crowding_distance!(front)
        if length(new_pop) + length(front) <= pop_size
            append!(new_pop, front)
        else
            sorted = sort(front, by=x->x.crowding_distance, rev=true)
            append!(new_pop, sorted[1:(pop_size - length(new_pop))])
            break
        end
    end
    return new_pop
end

