"""
    SolutionNSGA{F<:AbstractFloat}

Container for an NSGA-II individual.

# Fields
- `variables::Dict{Symbol,Any}`: Decision variables (by name) and other attached data (e.g., `:objs`).
- `objectives::Vector{F}`: Raw objective values for the individual.
- `fitness::Vector{F}`: Fitness values used for dominance comparisons (may include penalties).
- `rank::Int`: Non-dominated rank (front index starting at 1).
- `crowding_distance::Float64`: Crowding distance for diversity preservation within a front.
"""
mutable struct SolutionNSGA{F<:AbstractFloat}
    variables::Dict{Symbol,Any}
    objectives::Vector{F}
    fitness::Vector{F}
    rank::Int
    crowding_distance::Float64
end

"""
    SolveReportNSGA

Minimal report structure for an NSGA-II run.

# Fields
- `counter::Dict{Symbol,Any}`: Summary metrics and configuration used to generate the results.
"""
mutable struct SolveReportNSGA
    counter::Dict{Symbol,Any}
end

"""
    decision_vars(model::Model) -> Vector{VariableRef}

Returns the decision variables of `model`, filtering out auxiliary variables
(e.g., names starting with `"__"`, `"objectives_maximize"`, or `"s"`).
"""
function decision_vars(model::Model)
    dvars = VariableRef[]
    for v in all_variables(model)
        n = String(name(v))
        if startswith(n, "__") || n == "objectives_maximize" || n == "s"
            continue
        end
        push!(dvars, v)
    end
    return dvars
end

"""
    model_objectives(model::Model) -> Vector

Returns the objective function(s) of `model` as a vector. If the model has a
single objective, it is wrapped in a one-element vector.
"""
function model_objectives(model::Model)
    obj = JuMP.objective_function(model)
    return obj isa Vector ? obj : [obj]
end

"""
    extract_linear_constraints(model::Model, dvars::Vector{VariableRef})
        -> (coefs_list, rhs_list, sense_list)

Extracts linear constraints of types `<=`, `>=`, and `==` from `model` and maps
coefficients to the provided decision variable order `dvars`.

# Returns
- `coefs_list::Vector{Vector{Float64}}`: Each constraint's coefficients aligned with `dvars`.
- `rhs_list::Vector{Float64}`: Right-hand side values with constant offsets accounted for.
- `sense_list::Vector{Symbol}`: One of `:Le`, `:Ge`, or `:Eq` for each constraint.
"""
function extract_linear_constraints(model::Model, dvars::Vector{VariableRef})
    coefs_list = Vector{Vector{Float64}}()
    rhs_list   = Float64[]
    sense_list = Symbol[]
    nd = length(dvars)

    # <= constraints
    for cref in all_constraints(model, JuMP.AffExpr, MOI.LessThan{Float64})
        func = JuMP.constraint_object(cref).func
        setc = JuMP.constraint_object(cref).set
        a = zeros(Float64, nd)
        for (c, v) in JuMP.linear_terms(func)
            idx = findfirst(==(v), dvars)
            if idx !== nothing
                a[idx] += c
            end
        end
        offset = JuMP.constant(func)
        b = setc.upper
        push!(coefs_list, a)
        push!(rhs_list, b - offset)
        push!(sense_list, :Le)
    end

    # >= constraints
    for cref in all_constraints(model, JuMP.AffExpr, MOI.GreaterThan{Float64})
        func = JuMP.constraint_object(cref).func
        setc = JuMP.constraint_object(cref).set
        a = zeros(Float64, nd)
        for (c, v) in JuMP.linear_terms(func)
            idx = findfirst(==(v), dvars)
            if idx !== nothing
                a[idx] += c
            end
        end
        offset = JuMP.constant(func)
        b = setc.lower
        push!(coefs_list, a)
        push!(rhs_list, b - offset)
        push!(sense_list, :Ge)
    end

    # == constraints
    for cref in all_constraints(model, JuMP.AffExpr, MOI.EqualTo{Float64})
        func = JuMP.constraint_object(cref).func
        setc = JuMP.constraint_object(cref).set
        a = zeros(Float64, nd)
        for (c, v) in JuMP.linear_terms(func)
            idx = findfirst(==(v), dvars)
            if idx !== nothing
                a[idx] += c
            end
        end
        offset = JuMP.constant(func)
        b = setc.value
        push!(coefs_list, a)
        push!(rhs_list, b - offset)
        push!(sense_list, :Eq)
    end

    return coefs_list, rhs_list, sense_list
end

"""
    model_sense(model::Model) -> String

Returns the objective sense of `model` as a string: `"Max"` or `"Min"`.
"""
function model_sense(model::Model)
    s = JuMP.objective_sense(model)
    return s == MOI.MAX_SENSE ? "Max" : "Min"
end

"""
    constraint_violations(xvec, coefs_list, rhs_list, sense_list) -> Vector{Float64}

Computes a non-negative violation measure per constraint for a given decision vector `xvec`.

- For `:Le` constraints: `max(0, a⋅x - b)`.
- For `:Ge` constraints: `max(0, b - a⋅x)`.
- For `:Eq` constraints: `abs(a⋅x - b)`.
"""
function constraint_violations(xvec::Vector{Float64}, coefs_list, rhs_list, sense_list)
    m = length(coefs_list)
    v = zeros(Float64, m)
    for i in 1:m
        a = coefs_list[i]
        b = rhs_list[i]
        s = sense_list[i]
        val = dot(a, xvec)
        if s == :Le
            v[i] = max(0.0, val - b)
        elseif s == :Ge
            v[i] = max(0.0, b - val)
        else # :Eq
            v[i] = abs(val - b)
        end
    end
    return v
end

"""
    initialize_population(dvars, n_obj, pop_size; default_range=100.0)

Builds an initial population sampling each variable within available bounds.
If a variable has only a lower bound `lb`, an upper range is inferred as
`lb + 10*abs(lb) + default_range`. If no bounds are set, the range defaults to
`[0, default_range]`.

Also attaches an `:objs` field to each individual's `variables` dict as a
placeholder vector of objective values.
"""
function initialize_population(dvars::Vector{VariableRef}, n_obj::Int, pop_size::Int; default_range::Float64=100.0)
    population = SolutionNSGA[]
    for _ in 1:pop_size
        vars = Dict{Symbol,Any}()
        for var in dvars
            lb = has_lower_bound(var) ? lower_bound(var) : 0.0
            ub = if has_upper_bound(var)
                upper_bound(var)
            elseif lb != 0.0
                lb + abs(lb)*10 + default_range
            else
                lb + default_range
            end
            if lb > ub
                lb, ub = ub, lb
            end
            vars[Symbol(name(var))] = rand()*(ub - lb) + lb
        end
        # Also initialize empty objectives vector
        vars[:objs] = zeros(Float64, n_obj)
        push!(population, SolutionNSGA(vars, zeros(Float64, n_obj), zeros(Float64, n_obj), 0, 0.0))
    end
    return population
end

"""
    nsga2_options(user_options::Dict, model::Model) -> Dict{Symbol,Any}

Builds the finalized options dictionary for NSGA-II by combining:
1) Information inferred from `model`,
2) User-provided overrides in `user_options`, and
3) Sensible defaults for missing keys.

Validated keys include (non-exhaustive):
- `:pop_size`::Int (> 2)
- `:generations`::Int (> 0)
- `:crossover_rate`::Float64 in [0,1]
- `:mutation_rate`::Float64 in [0,1]
- `:penalty` in `[:linear, :quadratic, :inverse, :adaptive]`
- `:rho`::Float64
- `:print_level`::Int
- `:default_range`::Float64
"""
function nsga2_options(user_options::Dict, model::Model)
    options = Dict{Symbol, Any}()

    # From model
    dvars = decision_vars(model)
    options[:num_variables] = length(dvars)

    obj_exprs = model_objectives(model)
    options[:num_objectives] = length(obj_exprs)

    sense_label = model_sense(model)
    options[:objective_sense_set] = fill(sense_label, options[:num_objectives])

    # From user
    for (k, v) in pairs(user_options)
        options[Symbol(k)] = v
    end

    # Defaults
    add_default!(options, :pop_size, 50)
    add_default!(options, :generations, 100)
    add_default!(options, :crossover_rate, 0.9)
    add_default!(options, :mutation_rate, 0.1)
    add_default!(options, :penalty, :linear)
    add_default!(options, :rho, 1.0)
    add_default!(options, :print_level, 0)
    add_default!(options, :default_range, 10.0)

    verify_nsga2_options(options)

    return options
end

"""
    verify_nsga2_options(options)

Asserts basic validity of the most important NSGA-II options.
Throws an error if any assertion fails.
"""
function verify_nsga2_options(options)
    @assert typeof(options[:pop_size]) == Int "pop_size must be Int"
    @assert options[:pop_size] > 2 "pop_size must be > 2"

    @assert typeof(options[:generations]) == Int "generations must be Int"
    @assert options[:generations] > 0 "generations must be positive"

    @assert 0.0 <= options[:crossover_rate] <= 1.0 "crossover_rate must be in [0,1]"
    @assert 0.0 <= options[:mutation_rate] <= 1.0 "mutation_rate must be in [0,1]"

    @assert options[:penalty] in [:linear, :quadratic, :inverse, :adaptive] "invalid penalty"

    return nothing
end

"""
    nsga2_report(pareto_front, total_time, options) -> SolveReportNSGA

Builds a compact report summarizing the NSGA-II run and results.
"""
function nsga2_report(pareto_front, total_time, options)
    counter = Dict(
        :pop_size        => options[:pop_size],
        :generations     => options[:generations],
        :penalty         => options[:penalty],
        :rho             => options[:rho],
        :objs            => options[:num_objectives],
        :objective_sense => options[:objective_sense_set],
        :total_time      => total_time,
        :iterations      => options[:generations],
        :solutions       => length(pareto_front)
    )
    return SolveReportNSGA(counter)
end
