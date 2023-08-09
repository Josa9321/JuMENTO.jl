function test_simple_problems(model_function, saved_frontier, saved_table; is_augmecon_2)
    frontier, results = run_augmecon_for_simple_problems(model_function, augmecon_2=is_augmecon_2)
    test_payoff_tables(results.table, saved_table)
    test_frontiers(get_objectives.(frontier), saved_frontier)
    println("$(model_function) passed (is_augmecon_2 = $(is_augmecon_2))")
    return nothing
end

########################
#####
########################


function run_augmecon_for_simple_problems(model_function; augmecon_2)
    model, objs = model_function()
    frontier, report = augmecon(model, objs, grid_points=10, bypass=augmecon_2)
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
    for i in axes(frontier_1, 1)
        for j in axes(frontier_1[1], 2)
            @assert isapprox(frontier_1[i][j], frontier_2[i][j]) "Frontiers should be equal"
        end
    end
end

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

function simple_triobjective_frontier()
    return [
        3.075e6 62460.0 33000.0; 
        3.085e6 61980.0 32333.33; 
        3.10833333e6 60860.0 30777.78; 
        3.115e6 60540.0 30333.33; 
        3.13166667e6 59740.0 29222.22; 
        3.155e6 58620.0 27666.67; 
        3.17833333e6 57500.0 26111.11; 
        3.195e6 56700.0 25000.0; 
        3.20166667e6 56380.0 24555.56; 
        3.225e6 55260.0 23000.0; 
        3.255e6 54780.0 23666.67; 
        3.375e6 52860.0 26333.33; 
        3.495e6 50940.0 29000.0; 
        3.615e6 49020.0 31666.67; 
        3.735e6 47100.0 34333.33; 
        3.855e6 45180.0 37000.0
    ]
end