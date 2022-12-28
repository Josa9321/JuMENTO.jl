function buggy_pareto()
    instances_2objs = ["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"]
    buggy_pareto_set(instances_2objs)
    instances_3objs = ["3kp40.xlsx", "3kp50.xlsx"]
    buggy_pareto_set(instances_3objs)
    instances_4objs = ["4kp50.xlsx"]
    buggy_pareto_set(instances_4objs)
    return false
end

function buggy_pareto_set(instances_set)
    for instance_name in instances_set
        println("Testing $(instance_name)")
        pareto_xlsx = load_pareto_xlsx(merge_with_folder(instance_name))
        grid_points = grid_points_xlsx(merge_with_folder(instance_name))
        frontier = generate_frontier(instance_name, grid_points)
        @assert is_same_frontier(pareto_xlsx, frontier) "The frontiers for $(instance_name) are different"
    end
    return false
end

function load_pareto_xlsx(instance_address)
    unordered_pareto = copy(load_knapsack_sheet(instance_address, 6)')
    order = sortperm(unordered_pareto[:, end])
    return unordered_pareto[order, :]
end

function grid_points_xlsx(instance_address)
    return length(load_knapsack_sheet(instance_address, 5))
end

function generate_frontier(instance_name::String, grid_points::Int64)
    instance = load_instance(merge_with_folder(instance_name))
    model, objs = knapsack_model(instance)

    only_frontier = 1
    return solve_by_augmecon(instance, model, objs, grid_points = grid_points)[only_frontier]#, 
        # register_variables! = register_knapsack!, init_variables = init_knapsack_variables)[1]
end

function is_same_frontier(pareto_xlsx, frontier)
    for (i, sol_i) in enumerate(frontier)
        for j in axes(pareto_xlsx, 2)
            if abs(sol_i.objectives[j] - pareto_xlsx[i, j]) > 0.5
                println(sol_i)
                println("i = $i, j = $j")
                return false
            end
        end
    end
    return true
end

function load_payoff_table(instance_address)
    return load_knapsack_sheet(instance_address, 4)
end

