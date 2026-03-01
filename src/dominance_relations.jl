"""
    generate_pareto(solution_set, efficiency_eps)

Extract the non-dominated solution set from the given solution set by filtering out duplicate objective vectors and removing all dominated solutions

# Arguments
- `solution_set`: A vector containing the solutions from which the Pareto set will be generated.
- `efficiency_eps::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `pareto_set`: A vector containing the solutions that compose the Pareto set.
"""
function generate_pareto(solution_set::Vector{S}, efficiency_eps::Float64) where S <: AbstractSolution

    if length(solution_set) == 0 
        print("The solution set is empty.\n")
        return solution_set
    end

    pareto_set = typeof(solution_set[1])[]
    for solution in solution_set
        if __is_efficient(solution, solution_set, efficiency_eps
                         ) && !(__is_solution_in_frontier(solution, pareto_set, efficiency_eps))
            push!(pareto_set, solution)
        end
    end
    pareto_plot(solution_set)
    return pareto_set
end

function generate_pareto(solution_set::Matrix{F}, efficiency_eps::Float64) where F <: Number

    if size(solution_set, 2) == 0
        print("The solution set is empty.\n")
        return solution_set
    end

    pareto_set = zeros(type(eltype(solution_set)), size(solution_set, 1), 0)
    for i in axes(solution_set, 2)
        solution = @view solution_set[:, i]
        if __is_efficient(solution, solution_set, efficiency_eps
                         ) && !(__is_solution_in_frontier(solution, pareto_set, efficiency_eps))
            pareto_set = hcat(pareto_set, solution)
        end
    end
    pareto_plot(solution_set)
    return pareto_set
end

###################
# Intra functions #
###################

"""
    __is_efficient(solution::SolutionJuMP, solution_set, error)

Checks whether a solution is efficient with respect to a set of solutions.
"""
function __is_efficient(solution::S, solution_set::Vector{S}, error::Float64) where S <: AbstractSolution
    for sol_k in solution_set
        if _is_dominated_by(solution_to_check = solution.objectives, dominating_solution = sol_k.objectives, error=error
                            ) && !(_solutions_are_equals(solution.objectives, sol_k.objectives, error))
            return false
        end
    end
    return true
end

function __is_efficient(solution::Vector{F}, solution_set::Matrix{F}, error::Float64) where F <: Number
    for k in axes(solution_set, 2)
        sol_k = @view solution_set[:, k]
        if _is_dominated_by(solution_to_check = solution, dominating_solution = sol_k, error=error
                            ) && !(_solutions_are_equals(solution, sol_k, error))
            return false
        end
    end
    return true
end

"""
    __is_solution_in_frontier(solution::SolutionJuMP, frontier, error)

Checks whether a solution is present in a given frontier and returns a boolean value indicating its existence in the frontier.
"""
function __is_solution_in_frontier(solution::S, frontier::Vector{S}, error::Float64) where S <: AbstractSolution
    for sol_k in frontier
        if _solutions_are_equals(solution.objectives, sol_k.objectives, error)
            return true
        end
    end
    return false
end

function __is_solution_in_frontier(solution::Vector{F}, frontier::Matrix{F}, error::Float64) where F <: Number
    for k in axes(frontier, 2)
        sol_k = @view frontier[:, k]
        if _solutions_are_equals(solution, sol_k, error)
            return true
        end
    end
    return false
end

"""
    _solutions_are_equals(solution_1, solution_2, error)

Checks whether two solutions are equal, and returns a boolean value indicating their equality.
"""
function _solutions_are_equals(solution_1::Vector{F}, solution_2::Vector{F}, error::Float64) where F <: Number
    for o in eachindex(solution_1)
        if abs(solution_1[o] - solution_2[o]) > error
            return false
        end
    end
    return true
end

"""
    _is_dominated_by(solution_to_check, dominating_solution, error)

Check if `solution_to_check` is dominated by `dominating_solution`, considering the error tolerance. 
The function should return true if the `dominating_solution` dominates `solution_to_check`, and false otherwise.
"""
function _is_dominated_by(;solution_to_check::Vector{F}, dominating_solution::Vector{F}, error::Float64) where F <: Number
    at_least_better_in_one = false
    as_good_in_all = true
    for o in eachindex(solution_to_check)
        if dominating_solution[o] + error < solution_to_check[o]
            as_good_in_all = false
            break
        elseif dominating_solution[o] + error > solution_to_check[o]
            at_least_better_in_one = true
        end
    end
    result = as_good_in_all && at_least_better_in_one
    return result
end

