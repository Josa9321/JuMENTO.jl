"""
    generate_pareto_max(solution_set{<:AbstractSolution}, efficiency_eps)

Extract the non-dominated solution set from the given solution set by filtering out duplicate objective vectors and removing all dominated solutions

# Arguments
- `solution_set`: A vector containing the solutions from which the Pareto set will be generated. It considers that all objectives are to be maximized.
- `efficiency_eps::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `pareto_set`: A vector containing the solutions that compose the Pareto set.
"""
function generate_pareto_max(solution_set::Vector{S}, efficiency_eps::Float64) where S <: AbstractSolution

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
    return pareto_set
end

"""
    generate_pareto(solution_set::Matrix{F}, efficiency_eps; sense_set) where F <: Number

Extract the non-dominated solution set from the given solution set by filtering out duplicate objective vectors and removing all dominated solutions, considering the sense of each objective.
"""
function generate_pareto(solution_set::Matrix{F}, efficiency_eps::Float64=1e-6; sense_set=fill(:max, size(solution_set, 1))) where F <: Number
    @assert size(solution_set, 1) == length(sense_set) "The length of the sense vector must match the number of objectives (rows) in the solution set."
    @assert all(s -> s == :max || s == :min, sense_set) "Sense vector must contain only :max or :min values."

    to_maximize_set = copy(solution_set)
    __convert_to_maximize!(to_maximize_set, sense_set)

    pareto_set = generate_pareto_max(to_maximize_set, efficiency_eps)
    __convert_to_maximize!(pareto_set, sense_set)
    return pareto_set
end

"""
    generate_pareto_max(solution_set::Matrix{<:Number}, efficiency_eps)

Extract the non-dominated solution set from the given solution set by filtering out duplicate objective vectors and removing all dominated solutions.

# Arguments
- `solution_set`: A `m × n` matrix containing the `n` solutions from which the Pareto set will be generated. It considers that all objectives are to be maximized.
- `efficiency_eps::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `pareto_set`: A vector containing the solutions that compose the Pareto set.
"""
function generate_pareto_max(solution_set::Matrix{F}, efficiency_eps::Float64) where F <: Number

    if size(solution_set, 2) == 0
        print("The solution set is empty.\n")
        return solution_set
    end

    pareto_set = zeros(F, size(solution_set, 1), 0)
    for i in axes(solution_set, 2)
        solution = @view solution_set[:, i]
        if __is_efficient(solution, solution_set, efficiency_eps
                         ) && !(__is_solution_in_frontier(solution, pareto_set, efficiency_eps))
            pareto_set = hcat(pareto_set, solution)
        end
    end
    return pareto_set
end

###################
# Intra functions #
###################

function __convert_to_maximize!(solution_set, sense_set)
    for i in axes(sense_set, 1)
        if sense_set[i] == :min
            __convert_line_maximize!(solution_set, i)
        end
    end
    return solution_set
end

function __convert_line_maximize!(solution_set, i)
    for j in axes(solution_set, 2)
        solution_set[i, j] = -solution_set[i, j]
    end
    return solution_set
end


"""
    __is_efficient(solution::SolutionJuMP, solution_set, error)

Checks whether a solution is efficient with respect to a set of solutions.
"""
function __is_efficient(solution, solution_set, error::Float64)
    for k in __get_set_of_solutions(solution_set)
        sol_k = __get_solution_from_set(solution_set, k)
        if _is_dominated_by(solution_to_check = __objs(solution), dominating_solution = __objs(sol_k), error=error
                           ) && !(_solutions_are_equals(__objs(solution), __objs(sol_k), error))
            return false
        end
    end
    return true
end

"""
    __is_solution_in_frontier(solution::SolutionJuMP, frontier, error)

Checks whether a solution is present in a given frontier and returns a boolean value indicating its existence in the frontier.
"""
function __is_solution_in_frontier(solution, frontier, error::Float64)
    for k in __get_set_of_solutions(frontier)
        sol_k = __get_solution_from_set(frontier, k)
        if _solutions_are_equals(__objs(solution), __objs(sol_k), error)
            return true
        end
    end
    return false
end


"""
    _solutions_are_equals(solution_1, solution_2, error)

Checks whether two solutions are equal, and returns a boolean value indicating their equality.
"""
function _solutions_are_equals(solution_1, solution_2, error::Float64)
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
function _is_dominated_by(;solution_to_check, dominating_solution, error::Float64)
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

####################
# Helper functions #
####################

function __get_solution_from_set(solution_set::Vector{S}, index::Int) where S <: AbstractSolution
    return solution_set[index]
end

function __get_solution_from_set(solution_set::Matrix{F}, index::Int) where F <: Number
    return @view solution_set[:, index]
end

function __objs(solution::S) where S <: AbstractSolution
    return solution.objectives
end

function __objs(solution::AbstractArray)
    return solution
end

function __get_set_of_solutions(solution_set::Vector{S}) where S <: AbstractSolution
    return eachindex(solution_set)
end

function __get_set_of_solutions(solution_set::Matrix{F}) where F <: Number
    return axes(solution_set, 2)
end
