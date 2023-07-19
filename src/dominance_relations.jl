function generate_pareto(frontier)
    if length(frontier) == 0 
        @warn "frontier has 0 solutions"
        return frontier
    end

    pareto_set = typeof(frontier[1])[]
    for solution in frontier
        if is_efficient(solution, frontier) && !(solution_in_frontier(solution, pareto_set))
            push!(pareto_set, solution)
        end
    end
    return pareto_set
end

function is_efficient(solution, frontier)
    for sol_k in frontier
        if max_j_dominates_i(solution_i = solution, solution_j = sol_k) && !(solutions_are_equals(solution, sol_k))
            return false
        end
    end
    return true
end

function max_j_dominates_i(;solution_i, solution_j)
    at_least_better_in_one = false
    as_good_in_all = true
    for o in eachindex(solution_i.objectives)
        if solution_j.objectives[o] < solution_i.objectives[o]
            as_good_in_all = false
            break
        elseif solution_j.objectives[o] > solution_i.objectives[o]
            at_least_better_in_one = true
        end
    end
    return as_good_in_all && at_least_better_in_one
end

function solution_in_frontier(solution, frontier)
    for sol_k in frontier
        if solutions_are_equals(solution, sol_k)
            return true
        end
    end
    return false
end

function solutions_are_equals(solution_1, solution_2)
    for o in eachindex(solution_1.objectives)
        if !isapprox(solution_1.objectives[o], solution_2.objectives[o])
            return false
        end
    end
    return true
end