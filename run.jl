using Jumento, JuMP
include("test//runtests.jl")

function solve_kp_instance(address; kwargs...)
    instance = KnapsackInstance(address)
    model, objs = knapsack_model(instance)
    frontier, report = augmecon(model, objs,
        grid_points = number_of_grid_points_used(address), objective_sense_set = kwargs[:objectives_sense]
    )
    return frontier, report
end

function number_of_grid_points_used(instance_address)
    return size(load_knapsack_sheet(instance_address, "e_points"), 2)
end

function solve_test(; files_names, num_objs)
    for file in files_names
        address = "test//mokp//instances//$(file)"
        frontier, report = solve_kp_instance(address, objectives_sense = ["Max" for i in Base.OneTo(num_objs)])
        compare_payoff_table(report, address)
        compare_frontier(frontier, address)
    end
end

function compare_payoff_table(report::SolveReport, address)
    table = report.table
    excel_table = load_knapsack_sheet(address, "payoff_table")
    for i in eachindex(table)
        @assert isapprox(table[i], excel_table[i]) "Tables are not equals"
    end
    return nothing
end

function compare_frontier(frontier, address)
    excel_pareto = load_knapsack_sheet(address, "pareto_sols")
    @assert length(frontier) == size(excel_pareto, 1) "Number of solutions are different: num_sol_frontier -> $(length(frontier)), num_excel_pareto -> $(size(excel_pareto, 1))"
    for solution in frontier
        @assert is_solution_in_excel_frontier(solution, excel_pareto) "solution is not in pareto $(solution.objectives)"
    end
    return nothing
end


function is_solution_in_excel_frontier(solution, excel_frontier)
    for k in axes(excel_frontier, 1)
        sol_k = @views excel_frontier[k, :]
        if solutions_are_equals(solution, sol_k)
            return true
        end
    end
    return false
end

function solutions_are_equals(solution_1, solution_2)
    for o in eachindex(solution_1.objectives)
        if !isapprox(solution_1.objectives[o], solution_2[o])
            return false
        end
    end
    return true
end

solve_test(files_names=["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"], num_objs=2)
# f, report = solve_kp_instance("test//mokp//instances//2kp750.xlsx", objectives_sense = ["Max" for i in Base.OneTo(2)])
# solve_test(files_names=["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"], num_objs=2)
# solve_test(files_names=["3kp40.xlsx", "3kp50.xlsx", "3kp100.xlsx"], num_objs=3)
# solve_test(files_names=["4kp40.xlsx", "4kp50.xlsx"], num_objs=4)

#"2kp100.xlsx", "2kp250.xlsx"