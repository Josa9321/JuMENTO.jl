using Jumento, JuMP
include("test//runtests.jl")

function solve_instance(address; kwargs...)
    instance = KnapsackInstance(address)
    model, objs = knapsack_model(instance)
    frontier, report = augmecon(model, objs,
        grid_points = kwargs[:grid_points], objective_sense_set = kwargs[:objectives_sense]
    )
    return frontier, report
end

function number_of_grid_points_used(instance_address)
    
end

result = solve_instance("test//mokp//instances//2kp100.xlsx", grid_points = 823, objectives_sense = ["Max", "Max"])