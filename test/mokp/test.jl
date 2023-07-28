function solve_kp_instance(address; kwargs...)
    instance = KnapsackInstance(address)
    model, objs = knapsack_model(instance)
    frontier, report = augmecon(model, objs,
        number_of_grid_points_used(address), objective_sense_set = kwargs[:objectives_sense],
    )
    return frontier, report
end