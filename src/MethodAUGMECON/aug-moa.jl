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
    constraints_set = __set_model(algorithm, inner, f, ranges_set)
    solutions = MOA.SolutionPoint[]

    status, solutions = __recursive_augmecon!(algorithm, model, inner, f, ranges_set, constraints_set, solutions)

    sense = MOI.get(model, MOI.ObjectiveSense())
    solutions = MOA.filter_nondominated(sense, solutions)

    return status, solutions
end

###################
# Intra functions #
###################


function __recursive_augmecon!(algorithm, model, inner, f, ranges_set, constraints_set, solutions; o=2)
    status = MOI.OPTIMAL
    variables = MOI.get(inner, MOI.ListOfVariableIndices())
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)
    for eps in ranges_set[o]
        MOI.set(model, MOI.ConstraintSet(), constraints_set[o-1], MOI.EqualTo(eps))
        if o < m
            __recursive_augmecon!(algorithm, model, inner, f, ranges_set, constraints_set, solutions, o=o + 1)
        else
            MOA.optimize_inner!(model)
            X, Y = MOA._compute_point(model, variables, f)
            MOA._log_subproblem_solve(model, Y)
            push!(solutions, MOA.SolutionPoint(X, Y))
        end
    end
    status = MOI.OPTIMAL
    return status, solutions
end

function __set_model(algorithm, inner, f, ranges_set)
    objs_set = MOI.Utilities.eachscalar(f)
    m = length(objs_set)

    c_v0 = MOI.GreaterThan(0.0)
    s = MOI.add_variables(inner, m - 1)
    MOI.add_constraints(inner, s, [MOI.GreaterThan(0.0) for _ in Base.OneTo(m - 1)])
    objective_term = - algorithm.penalty * sum(
        s[o-1] / (ranges_set[o][1] - ranges_set[o][end]) for o in 2:m)

    MOI.set(inner, MOI.ObjectiveFunction{typeof(objs_set[1])}(), objs_set[1] + objective_term)

    constraints_set = MOI.add_constraints(inner, [objs_set[o] + s[o-1] for o in 2:m
        ], [MOI.EqualTo(ranges_set[o][1]) for o in 2:m])
    return constraints_set
end

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
        MOA._compute_ideal_point(model)
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
        if !MOA._is_scalar_status_optimal(status)
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
