function test_simple_problems(model_function, saved_frontier, saved_table; is_augmecon_2=false)
    frontier, results = run_augmecon_for_simple_problems(model_function, 1, saved_frontier, nothing; augmecon_2=is_augmecon_2)
    test_payoff_tables(results.table, saved_table)
    test_frontiers(frontier, saved_frontier)
    println("$(model_function) $(is_augmecon_2 ? "AUGMECON_2" : "AUGMECON") passed.")
    return nothing
end

########################
#####
########################

function run_augmecon_for_simple_problems(model_function, plot, saved_frontier, reference_point; augmecon_2=false)
    model, objs, objs_sense = model_function()
    frontier, report = augmecon(model, objs, plot; saved_frontier=saved_frontier, reference_point=reference_point, grid_points=10, bypass=augmecon_2, objective_sense_set=objs_sense)
    return frontier, report
end

function test_payoff_tables(table_1, table_2)
    for i in axes(table_1, 1)
        for j in axes(table_1, 2)
            @assert isapprox(table_1[i, j], table_2[i, j]) "Payoff tables should be equal"
        end
    end
end

function test_frontiers(frontier_1, frontier_2)
    @assert size(frontier_1, 2) == size(frontier_2, 2) "Frontiers should have the same number of solutions"
    for i in 1:size(frontier_1, 2)
        solution = frontier_1[:, i]
        @assert is_solution_in_frontier(solution, frontier_2) "Solution $(solution) is not in frontier"
    end
end

#########################

function is_solution_in_frontier(solution, frontier)
    for i in 1:size(frontier, 2)
        sol_k = frontier[:, i]
        if solutions_are_equals(solution, sol_k)
            return true
        end
    end
    return false
end

function solutions_are_equals(solution_1, solution_2)
    for o in eachindex(solution_1)
        if !isapprox(solution_1[o], solution_2[o]; atol=1e-5)
            return false
        end
    end
    return true
end

############################

function simple_biobjective_table()
    return [
        20.0 160.0; 
        8.0 184.0
    ]
end

function simple_triobjective_table()
    return [
        3.075e6 62460.0 33000.0; 
        3.855e6 45180.0 37000.0; 
        3.225e6 55260.0 23000.0
    ]
end


############################

function simple_biobjective_frontier()
    return [
        20.0 18.66666666666667 17.33333333333333 16.0 14.666666666666671 13.333333333333329 12.0 10.666666666666671 9.333333333333329 8.0;
        160.0 162.66666666666666 165.33333333333334 168.0 170.66666666666666 173.33333333333334 176.0 178.66666666666666 181.33333333333334 184.0
    ]
end

function simple_triobjective_frontier()
    return [
        3.075e6 3.115e6 3.155e6 3.195e6 3.255e6 3.375e6 3.495e6 3.615e6 3.735e6 3.855e6 3.085e6 3.1083333333333335e6 3.131666666666667e6 3.178333333333333e6 3.2016666666666665e6 3.225e6;
        62460.0 60540.0 58620.0 56700.0 54780.0 52860.0 50940.0 49020.0 47100.0 45180.0 61980.0 60860.0 59740.0 57500.0 56380.0 55260.0;
        33000.0 30333.333333333332 27666.666666666646 24999.999999999978 23666.666666666697 26333.33333333338 29000.00000000005 31666.666666666715 34333.333333333394 37000.00000000007 32333.333333333336 30777.77777777778 29222.222222222223 26111.11111111111 24555.555555555555 23000.0
    ]
end