function test_simple_problems(model_function, saved_frontier, saved_table; is_augmecon_2)
    frontier, results = run_augmecon_for_simple_problems(model_function, augmecon_2=is_augmecon_2)
    test_payoff_tables(results.table, saved_table)
    test_frontiers(frontier, saved_frontier)
    println("$(model_function) $(is_augmecon_2 ? "AUGMECON_2" : "AUGMECON") passed ")
    return nothing
end

########################
#####
########################


function run_augmecon_for_simple_problems(model_function; augmecon_2)
    model, objs, objs_sense = model_function()
    frontier, report = augmecon(model, objs, grid_points=10, bypass=augmecon_2, objective_sense_set=objs_sense)
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
    @assert length(frontier_1) == length(frontier_2) "Frontiers should have the same length"
    for solution in frontier_1
        @assert is_solution_in_frontier(solution, frontier_2) "Solution $(solution) is not in frontier"
    end
end

#########################

function is_solution_in_frontier(solution, frontier)
    for sol_k in frontier
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

#########################

function simple_biobjective_table()
    return [
        20.0 160.0; 
        7.999999999999993 184.0
    ]
end

function simple_biobjective_frontier()
    return [
        [20.0, 160.0], 
        [18.66666666666667, 162.66666666666666], 
        [17.33333333333333, 165.33333333333334], 
        [16.0, 168.0], 
        [14.666666666666671, 170.66666666666666], 
        [13.333333333333329, 173.33333333333334], 
        [12.0, 176.0], 
        [10.666666666666671, 178.66666666666666], 
        [9.333333333333329, 181.33333333333334], 
        [8.0, 184.0]
    ]
end

#########################

function simple_triobjective_table()
    return [
        3.075e6 62460.0 33000.0; 
        3.855000000000002e6 45179.99999999995 37000.00000000001; 
        3.2250000000000005e6 55259.99999999997 22999.999999999996
    ]
end

function simple_triobjective_frontier()
    return [
        [3.075e6, 62460.0, 33000.0], 
        [3.115e6, 60540.0, 30333.333333333332], 
        [3.155e6, 58619.999999999985, 27666.666666666646], 
        [3.195e6, 56699.999999999985, 24999.999999999978], 
        [3.2550000000000014e6, 54779.99999999998, 23666.666666666697], 
        [3.3750000000000023e6, 52859.99999999997, 26333.33333333338], 
        [3.4950000000000023e6, 50939.99999999996, 29000.00000000005], 
        [3.6150000000000023e6, 49019.99999999997, 31666.666666666715], 
        [3.735000000000003e6, 47099.999999999956, 34333.333333333394], 
        [3.8550000000000037e6, 45179.99999999995, 37000.00000000007], 
        [3.085e6, 61980.0, 32333.333333333336], 
        [3.1083333333333335e6, 60860.0, 30777.77777777778], 
        [3.131666666666667e6, 59740.0, 29222.222222222223], 
        [3.178333333333333e6, 57500.0, 26111.11111111111], 
        [3.2016666666666665e6, 56380.0, 24555.555555555555], 
        [3.225e6, 55260.0, 22999.999999999996]
    ]
end