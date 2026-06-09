abstract type AugmeconAlgorithms end
struct Augmecon1 <: AugmeconAlgorithms end
struct Augmecon2 <: AugmeconAlgorithms end
struct SAugmecon <: AugmeconAlgorithms end
struct RAugmecon <: AugmeconAlgorithms end


function MOA.minimize_multiobjective!(
    algorithm::Augmecon,
    model::MOA.Optimizer,
    inner::MOI.ModelLike,
    f::MOI.AbstractVectorFunction,
)

    @assert MOI.get(inner, MOI.ObjectiveSense()) == MOI.MIN_SENSE

    ranges_set = __get_range(algorithm, model, inner, f)
    if !(typeof(ranges_set) <: AbstractVector)
        return ranges_set, nothing
    end
    __set_ideal_point!(model, ranges_set)

    aug_type = get_augmecon_algorithm(algorithm.augmecon_type)
    surplus_variables, constraints_set = __set_model(algorithm, inner, f, ranges_set, aug_type)
    solutions = MOA.SolutionPoint[]

    status, solutions = __recursive_augmecon!(algorithm, model, inner, f, ranges_set,
        surplus_variables, constraints_set, solutions, aug_type)
    solutions = MOA.filter_nondominated(MOI.MIN_SENSE, solutions)

    return status, solutions
end

###################
# Intra functions #
###################

function get_augmecon_algorithm(number_augmecon)
    if number_augmecon == 1
        return Augmecon1()
    elseif number_augmecon == 2
        return Augmecon2()
    elseif number_augmecon == 3
        return SAugmecon()
    elseif number_augmecon == 4
        return RAugmecon()
    else
        error("The AUGMECON code is invalid $(number_augmecon). Choose between 1 to 4")
    end
    return
end

##### AUGMECON 1

function __set_model(algorithm, inner, f, ranges_set, ::Augmecon1)
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)

    surplus_variables = MOI.add_variables(inner, m - 1)
    MOI.add_constraints(inner, surplus_variables, [MOI.GreaterThan(0.0) for _ in Base.OneTo(m - 1)])

    sum_terms = map(2:m) do o
        return MOI.ScalarAffineTerm{Float64}(
            -algorithm.penalty / (ranges_set[o][1] - ranges_set[o][end]),
            surplus_variables[o-1],
        )
    end
    objective_term = MOI.ScalarAffineFunction(sum_terms, 0.0)
    new_obj = MOI.Utilities.operate(+, Float64, objs_set[1], objective_term)
    MOI.set(inner, MOI.ObjectiveFunction{typeof(new_obj)}(), new_obj)

    constraints_set = MOI.add_constraints(inner, [MOI.Utilities.operate(+, Float64, objs_set[o], surplus_variables[o-1]) for o in 2:m
        ], [MOI.EqualTo(ranges_set[o][1]) for o in 2:m])
    return surplus_variables, constraints_set
end

function __recursive_augmecon!(algorithm, model, inner, f, ranges_set, surplus_variables, constraints_set,
    solutions, aug_type::Augmecon1; o=2
)
    variables = MOI.get(inner, MOI.ListOfVariableIndices())
    m = length(ranges_set)
    status = MOI.OPTIMAL
    for eps in ranges_set[o]
        if (ret = _check_premature_termination(model)) !== nothing || status == MOI.TIME_LIMIT
            status = MOI.TIME_LIMIT
            break
        end

        MOI.set(model, MOI.ConstraintSet(), constraints_set[o-1], MOI.EqualTo(eps))
        if o < m
            status, solutions = __recursive_augmecon!(algorithm, model, inner, f, ranges_set, surplus_variables, constraints_set,
                solutions, aug_type, o=o + 1)
        else
            MOA.optimize_inner!(model)
            status_ik = MOI.get(inner, MOI.PrimalStatus())
            if _is_scalar_status_feasible_point(status_ik)
                X, Y = _get_solution_point_data(model, variables, f)
                _log_subproblem_solve(model, Y)
                push!(solutions, MOA.SolutionPoint(X, Y))
            else
                break
            end
        end
    end
    return status, solutions
end

##### AUGMECON 2

function __set_model(algorithm, inner, f, ranges_set, ::Augmecon2)
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)

    surplus_variables = MOI.add_variables(inner, m - 1)
    MOI.add_constraints(inner, surplus_variables, [MOI.GreaterThan(0.0) for _ in Base.OneTo(m - 1)])

    sum_terms = map(2:m) do o
        return MOI.ScalarAffineTerm{Float64}(
            -algorithm.penalty * (10.0^(2 - o)) / (ranges_set[o][1] - ranges_set[o][end]),
            surplus_variables[o-1],
        )
    end
    objective_term = MOI.ScalarAffineFunction(sum_terms, 0.0)
    new_obj = MOI.Utilities.operate(+, Float64, objs_set[1], objective_term)
    MOI.set(inner, MOI.ObjectiveFunction{typeof(new_obj)}(), new_obj)

    constraints_set = MOI.add_constraints(inner, [MOI.Utilities.operate(+, Float64, objs_set[o], surplus_variables[o-1]) for o in 2:m
        ], [MOI.EqualTo(ranges_set[o][1]) for o in 2:m])
    return surplus_variables, constraints_set
end

function __recursive_augmecon!(algorithm, model, inner, f, ranges_set, surplus_variables, constraints_set,
    solutions, aug_type::Augmecon2; o=length(ranges_set)
)
    variables = MOI.get(inner, MOI.ListOfVariableIndices())
    i_k = 0
    status = MOI.OPTIMAL
    while i_k < length(ranges_set[o])
        if (ret = _check_premature_termination(model)) !== nothing || status == MOI.TIME_LIMIT
            status = MOI.TIME_LIMIT
            break
        end

        i_k += 1
        eps = ranges_set[o][i_k]
        MOI.set(model, MOI.ConstraintSet(), constraints_set[o-1], MOI.EqualTo(eps))
        if o > 2
            status, solutions = __recursive_augmecon!(algorithm, model, inner, f, ranges_set, surplus_variables, constraints_set,
                solutions, aug_type, o=o - 1)
        else
            MOA.optimize_inner!(model)
            status_ik = MOI.get(inner, MOI.PrimalStatus())
            if _is_scalar_status_feasible_point(status_ik)
                X, Y = _get_solution_point_data(model, variables, f)
                push!(solutions, MOA.SolutionPoint(X, Y))
                _log_subproblem_solve(model, Y)

                b = __get_number_of_redundant_iterations(inner, surplus_variables[1], ranges_set[o])
                i_k += b
            else
                i_k = length(ranges_set[o])
            end
        end
    end
    return status, solutions
end

##### S AUGMECON

function __set_model(algorithm, inner, f, ranges_set, ::SAugmecon)
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)
    var_objs = MOI.add_variables(inner, m - 1)
    MOI.add_constraints(inner, [MOI.Utilities.operate(-, Float64, objs_set[o], var_objs[o-1]) for o in 2:m
        ], [MOI.EqualTo(0.0) for o in 2:m])

    sum_terms = map(2:m) do o
        return MOI.ScalarAffineTerm{Float64}(
            algorithm.penalty / (ranges_set[o][1] - ranges_set[o][end]),
            var_objs[o-1],
        )
    end
    objective_term = MOI.ScalarAffineFunction(sum_terms, 0.0)
    new_obj = MOI.Utilities.operate(+, Float64, objs_set[1], objective_term)
    MOI.set(inner, MOI.ObjectiveFunction{typeof(new_obj)}(), new_obj)

    constraints_set = MOI.add_constraints(inner, [objs_set[o] for o in 2:m
        ], [MOI.LessThan(ranges_set[o][1]) for o in 2:m])
    return nothing, constraints_set
end

function __recursive_augmecon!(algorithm, model, inner, f, ranges_set, surplus_variables, constraints_set,
    solutions, ::SAugmecon
)
    variables = MOI.get(inner, MOI.ListOfVariableIndices())
    m = length(ranges_set)
    status = MOI.OPTIMAL
    positions = ones(Int64, m)
    relative_worst_values = [R_o[end] for R_o in ranges_set]
    R_2 = ranges_set[2]
    while positions[m] <= length(ranges_set[m])
        if (ret = _check_premature_termination(model)) !== nothing
            status = MOI.TIME_LIMIT
            break
        end

        for o in 2:m
            eps_o = ranges_set[o][positions[o]]
            MOI.set(model, MOI.ConstraintSet(), constraints_set[o-1], MOI.LessThan(eps_o))
        end

        MOA.optimize_inner!(model)
        status_ik = MOI.get(inner, MOI.PrimalStatus())
        if _is_scalar_status_feasible_point(status_ik)
            X, Y = _get_solution_point_data(model, variables, f)
            _log_subproblem_solve(model, Y)
            push!(solutions, MOA.SolutionPoint(X, Y))
            __update_relative_worst_values!(relative_worst_values, Y, ranges_set)

            new_pos = findlast(idx -> R_2[idx] >= Y[2], eachindex(R_2))
            if new_pos > positions[2]
                positions[2] = new_pos
            end
        else
            __update_positions_if_inviable!(positions, ranges_set)
        end

        __update_positions!(positions, relative_worst_values, ranges_set)
    end
    return status, solutions
end

function __update_relative_worst_values!(relative_worst_values, Y, ranges_set)
    for o in 3:length(ranges_set)
        if Y[o] > relative_worst_values[o]
            relative_worst_values[o] = Y[o]
        end
    end
    return
end

function __update_positions!(positions, relative_worst_values, ranges_set)
    positions[2] += 1
    for o in 2:length(ranges_set)-1
        R_o = ranges_set[o]
        if positions[o] > length(R_o)
            positions[o] = 1
            R_n = ranges_set[o+1]
            positions[o+1] += 1
            if positions[o+1] <= length(R_n)
                better_position = findlast(idx -> R_n[idx] >= relative_worst_values[o+1] - 1e-5, eachindex(R_n)) + 1
                relative_worst_values[o+1] = R_n[end]
                if better_position >= positions[o+1]
                    positions[o+1] = better_position
                end
            end
        end
    end
    return
end

function __update_positions_if_inviable!(positions, ranges_set)
    for o in 2:length(ranges_set)
        aux = positions[o]
        positions[o] = length(ranges_set[o])
        if aux > 1
            break
        end
    end
    return
end

######################
# Auxiliar functions #
######################

function __set_ideal_point!(model, ranges_set)
    for (o, range) in enumerate(ranges_set)
        model.ideal_point[o] = range[end]
    end
    return
end

function __get_range(algorithm, model, inner, f)
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)
    if !isnothing(algorithm.nadir)
        _compute_ideal_point(model)
        ideal_point = MOI.get(model, MOI.ObjectiveBound())
        nadir_point = algorithm.nadir
        return [range(nadir_point[i], ideal_point[i], !isapprox(nadir_point[i], ideal_point[i]) ? algorithm.grid_points : 1) for i in Base.OneTo(m)]
    end

    table = __payoff_table(model, inner, f)
    if !(typeof(table) <: Matrix)
        return table
    end
    ideal_point = minimum(table, dims=2)
    nadir_point = maximum(table, dims=2)
    return [range(nadir_point[i], ideal_point[i], !isapprox(nadir_point[i], ideal_point[i]) ? algorithm.grid_points : 1) for i in Base.OneTo(m)]
end

"""
    __payoff_table!(model, inner, f)

This function computes and returns the payoff table of the optimization problem.
"""
function __payoff_table(model, inner, f)
    objs_set = MOI.Utilities.eachscalar(f)

    m = length(objs_set)
    priority_set = zeros(m)

    table = zeros(m, m)
    alg = MOA.Hierarchical()
    for j in Base.OneTo(m)
        priority_set[j] = 1.0
        MOI.set.(Ref(alg), MOA.ObjectivePriority.(Base.OneTo(m)), priority_set)

        status, solution_i = MOA.minimize_multiobjective!(alg, model, inner, f)
        if !_is_scalar_status_optimal(status)
            return status
        end

        solution_i = only(solution_i)
        for i in Base.OneTo(m)
            table[i, j] = solution_i.y[i]
        end
        priority_set[j] = 0.0
    end
    return table
end


function __get_number_of_redundant_iterations(inner, s_2, objective_range)
    value = MOI.get(inner, MOI.VariablePrimal(), s_2)
    division = value / abs(objective_range.step.hi)
    return trunc(Int64, division)
end


##########################
# MOA internal functions #
##########################

"""
    _check_premature_termination(model::Optimizer)

Checks if the optimization process should be terminated early due to user interrupts 
or exceeding the time limit. If a time limit is set, it updates the remaining time 
budget for the underlying inner solver.

Returns `MOI.TIME_LIMIT`, `MOI.INTERRUPTED`, or `nothing` if execution can safely continue.
"""
function _check_premature_termination(model::Optimizer)
    return _check_interrupt() do
        time_limit = MOI.get(model, MOI.TimeLimitSec())
        if time_limit !== nothing
            time_remaining = time_limit - (time() - model.start_time)
            if time_remaining <= 0
                return MOI.TIME_LIMIT
            end
            if MOI.supports(model.inner, MOI.TimeLimitSec())
                MOI.set(model.inner, MOI.TimeLimitSec(), time_remaining)
            end
        end
        return
    end
end

"""
    _is_scalar_status_feasible_point(status::MOI.ResultStatusCode)

Returns `true` if the subproblem result status yields a valid feasible point.
"""
function _is_scalar_status_feasible_point(status::MOI.ResultStatusCode)
    return status == MOI.FEASIBLE_POINT
end

"""
    _is_scalar_status_optimal(status::MOI.TerminationStatusCode)

Returns `true` if the subproblem termination status indicates an optimal or locally solved state.
"""
function _is_scalar_status_optimal(status::MOI.TerminationStatusCode)
    return status == MOI.OPTIMAL || status == MOI.LOCALLY_SOLVED
end

"""
    _is_scalar_status_optimal(model::Optimizer)

Queries the inner solver's termination status and checks if it is optimal.
"""
function _is_scalar_status_optimal(model::Optimizer)
    status = MOI.get(model.inner, MOI.TerminationStatus())
    return _is_scalar_status_optimal(status)
end

"""
    _compute_ideal_point(model::Optimizer)

Computes the ideal objective point by minimizing/maximizing each objective function 
individually. Used in multi-objective optimization to establish a baseline boundary.
"""
function _compute_ideal_point(model::Optimizer)
    for (i, f) in enumerate(MOI.Utilities.eachscalar(model.f))
        if _check_premature_termination(model) !== nothing
            return
        end
        if !isnan(model.ideal_point[i])
            continue
        end
        MOI.set(model.inner, MOI.ObjectiveFunction{typeof(f)}(), f)
        optimize_inner!(model)
        status = MOI.get(model.inner, MOI.TerminationStatus())
        if _is_scalar_status_optimal(status)
            model.ideal_point[i] = MOI.get(model.inner, MOI.ObjectiveValue())
        end
    end
    return
end

"""
    _get_solution_point_data(model::Optimizer, variables::Vector{MOI.VariableIndex}, f)

Extracts the primal variable values from the inner solver and evaluates the 
corresponding multi-objective vector value `Y`.
"""
function _get_solution_point_data(
    model::Optimizer,
    variables::Vector{MOI.VariableIndex},
    f,
)
    X = Dict{MOI.VariableIndex,Float64}(
        x => MOI.get(model.inner, MOI.VariablePrimal(), x) for x in variables
    )
    Y = MOI.Utilities.eval_variables(Base.Fix1(getindex, X), model, f)
    return X, Y
end

"""
    _log_subproblem_solve(model::Optimizer, arg)

Dispatches subproblem solving logs if the optimizer's `silent` flag is set to false.
"""
function _log_subproblem_solve(model::Optimizer, arg)
    if !model.silent
        _log_subproblem_inner(model, arg)
    end
    return
end

# Inner Logger: Accepts variable indices, computes their objective space image, and logs it.
function _log_subproblem_inner(model::Optimizer, x::Vector{MOI.VariableIndex})
    _, Y = _get_solution_point_data(model, x, model.f)
    _log_subproblem_solve(model, Y)
    return
end

# Inner Logger: Displays subproblem iteration count, objective values vector (Y), and runtime.
function _log_subproblem_inner(model::Optimizer, Y::Vector)
    print(_format(model.subproblem_count), "  ")
    for y in Y
        print(" ", _format(y))
    end
    println(" ", _format(time() - model.start_time))
    return
end

# Inner Logger: Displays a placeholder message (e.g., "ERROR", "INFEASIBLE") if a subproblem fails.
function _log_subproblem_inner(model::Optimizer, msg::String)
    print(_format(model.subproblem_count), "  ")
    print(rpad(msg, 13 * MOI.output_dimension(model.f)))
    println(" ", _format(time() - model.start_time))
    return
end

# --- Formatting Helpers ---
# Format integers (e.g. Iteration Counts) right-aligned to a width of 5
_format(x::Int) = Printf.@sprintf("%5d", x)

# Format floats (e.g. Objective values, elapsed time) using scientific notation
_format(x::Float64) = Printf.@sprintf("% .5e", x)

"""
    _check_interrupt(f)

Executes a function block while safely listening for system `InterruptException`s (Ctrl+C). 
If an interrupt occurs, it prevents a hard crash and gracefully flags an `MOI.INTERRUPTED` status.
"""
function _check_interrupt(f)
    try
        return reenable_sigint(f)
    catch ex
        if !(ex isa InterruptException)
            rethrow(ex)
        end
        return MOI.INTERRUPTED
    end
end
