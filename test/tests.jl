function test_instances(; files_names, num_objs, solve_instance, folder)
    for file in files_names
        address = folder*file
        frontier, report = solve_instance(address, objectives_sense = ["Max" for i in Base.OneTo(num_objs)])
        compare_payoff_table(report, address)
        compare_frontier(frontier, address)
        println("Instance $file verified")
    end
    return nothing
end

###########################

function compare_payoff_table(report::SolveReport, address)
    table = report.table
    excel_table = load_excel_table(address)
    println(excel_table)
    println(table)
    for i in eachindex(table)
        @assert isapprox(table[i], excel_table[i]) "Tables are not equals"
    end
    return nothing
end

function compare_frontier(frontier, address)
    excel_pareto = load_knapsack_sheet(address, "frontier")
    @assert length(frontier) == size(excel_pareto, 1) "Number of solutions are different: num_sol_frontier -> $(length(frontier)), num_excel_pareto -> $(size(excel_pareto, 1))"
    for solution in frontier
        @assert is_solution_in_excel_frontier(solution, excel_pareto) "solution is not in pareto $(solution.objectives)"
    end
    return nothing
end

###########################

load_excel_table(address) = load_knapsack_sheet(address, "payoff_table")[:, 2:end]

function number_of_grid_points_used(address)
    first = findlast("//", address)[end]+1
    last = findlast(".", address)[end]-1
    file = address[first:last]
    grid_points = Dict("2kp100" => 822, "2kp250" => 2533, "2kp500" => 4175, "2kp750" => 7231,)
    # "3kp40" => 421, "3kp50" => 722, "3kp100" => 1094, 
    # "4kp40" => 121, "4kp50" => 56)
    return grid_points[file]
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