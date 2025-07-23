"""
    generate_pareto(solutions_set, efficiency_eps)

Generate the Pareto set from a given solutions_set.

# Arguments
- `solution_set`: A vector containing the solutions from which the Pareto set will be generated.
- `efficiency_eps::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `pareto_set`: A vector containing the solutions that compose the Pareto set.
"""
function generate_pareto(solutions_set, efficiency_eps)

    if length(solutions_set) == 0 
        print("The solution set is empty.\n")
        return solutions_set
    end

    pareto_set = typeof(solutions_set[1])[]
    for solution in solutions_set
        if is_efficient(solution, solutions_set, efficiency_eps) && !(is_solution_in_frontier(solution, pareto_set, efficiency_eps))
            push!(pareto_set, solution)
        end
    end
    pareto_plot(solutions_set)
    print("Plotting Pareto set.\n")
    return pareto_set
end

"""
    is_efficient(solution::SolutionJuMP, solutions_set, error)

Checks whether a solution is efficient with respect to a set of solutions, where higher values are considered better.

# Arguments
- `solution::SolutionJuMP`: A solution to be checked.
- `solutions_set`: A vector containing the solutions to be compared with the given solution.
- `error::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `is_efficient::Bool`: A boolean value indicating if the given solution is efficient with respect to the given set of solutions.

# Notes
- A solution is efficient if it is not dominated by any other solution in the set.
- A solution is considered dominated by another solution if it is strictly worse in at least one objective and not better in any objective.
"""
function is_efficient(solution::SolutionJuMP, solutions_set, error)
    for sol_k in solutions_set
        if is_dominated_by(solution_to_check = solution, dominating_solution = sol_k, error=error) && !(solutions_are_equals(solution, sol_k, error))
            return false
        end
    end
    return true
end

"""
    is_dominated_by(;solution_to_check, dominating_solution, error)

Checks whether a solution is dominated by another solution, where higher values are considered better.

# Arguments
- `solution_to_check::SolutionJuMP`: A solution to be checked.
- `dominating_solution::SolutionJuMP`: A solution to be compared with the given solution.
- `error::Float64`: A float value indicating the error tolerance for the comparison.

# Returns
- `result::Bool`: A boolean value indicating if the given solution is dominated by the given solution.
"""

function is_dominated_by(;solution_to_check, dominating_solution, error)
    at_least_better_in_one = false
    as_good_in_all = true
    for o in eachindex(solution_to_check.objectives)
        if dominating_solution.objectives[o] + error < solution_to_check.objectives[o]
            as_good_in_all = false
            break
        elseif dominating_solution.objectives[o] + error > solution_to_check.objectives[o]
            at_least_better_in_one = true
        end
    end
    result = as_good_in_all && at_least_better_in_one
    return result
end

"""
    is_solution_in_frontier(solution::SolutionJuMP, frontier, error)

Checks whether a solution is present in a given frontier and returns a boolean value indicating its existence in the frontier.
"""

function is_solution_in_frontier(solution, frontier, error)
    for sol_k in frontier
        if solutions_are_equals(solution, sol_k, error)
            return true
        end
    end
    return false
end


"""
    solutions_are_equals(solution_1::SolutionJuMP, solution_2::SolutionJuMP, error)

Checks whether two solutions are equal, and returns a boolean value indicating their equality.
"""
function solutions_are_equals(solution_1, solution_2, error)
    for o in eachindex(solution_1.objectives)
        if abs(solution_1.objectives[o] - solution_2.objectives[o]) > error
            return false
        end
    end
    return true
end


"""
    Function that asks the user if he wants to plot the results
"""
function plot_result(frontier, model::Model)

    plot_both(frontier, model)

end

"""
    Function that plots the Pareto frontier and returns the plot object
"""
function pareto_plot(frontier)
    x_p = [s.objectives[1] for s in frontier]
    y_p = [s.objectives[2] for s in frontier]

    p = scatter(x_p, y_p, label="Pareto Frontier", marker=:circle, color=:red, markersize=8)
    xlabel!("First Criterion")
    ylabel!("Second Criterion")
    title!("Pareto Frontier")
    return p
end

"""
    Function that plots the variables space and returns the plot object
"""
function variables_plot(frontier, model::Model)
    variables = save_variables!(model)
    size = length(variables) - 1
    if size != 2
        print("Invalid number of variables for plotting\n.")
        return nothing
    end

    x_variable = [s.variables[:x][1] for s in frontier]
    y_variable = [s.variables[:x][2] for s in frontier]

    p = scatter(x_variable, y_variable, label="Solutions", marker=:star, color=:blue, markersize=8)
    xlabel!("First Variable")
    ylabel!("Second Variable")
    title!("Variable Space")
    return p
end

function plot_both(frontier, model::Model)
    p1 = plot(pareto_plot(frontier))

    p2 = variables_plot(frontier, model)
    
    if p2 !== nothing
        plot(p1, p2, layout = (1, 2))
        display(plot(p1, p2, layout = (1, 2)))
    else
        @warn "Variables space cannot be plotted due to invalid number of variables."
        plot(p1)
        display(plot(p1))
    end
end

