function max_j_dominates_i(objectives_found_i, objectives_found_j)
    # Maximize objective
    num_objs = length(objectives_found_i)
    at_least_better_in_one = false
    as_good_in_all = true
    for o in Base.OneTo(num_objs)
        if objectives_found_j[o] < objectives_found_i[o]
            as_good_in_all = false
        elseif objectives_found_j[o] > objectives_found_i[o]
            at_least_better_in_one = true
        end
    end
    return as_good_in_all && at_least_better_in_one
end

function index_solution_is_efficient(objectives_found, i)
    is_efficient = true
    for j in eachindex(objectives_found)
        if j != i && max_j_dominates_i(objectives_found[i], objectives_found[j])
            is_efficient = false
            return is_efficient
        end
    end
    return is_efficient
end

function generate_pareto(objectives_found, solutions_found)
    paretto_values = typeof(objectives_found[1])[]
    paretto_solutions = typeof(solutions_found[1])[]
    for i in eachindex(objectives_found)
        if index_solution_is_efficient(objectives_found, i)
            push!(paretto_values, objectives_found[i])
            push!(paretto_solutions, solutions_found[i])
        end
    end
    return paretto_values, paretto_solutions
end