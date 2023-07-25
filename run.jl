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
    xf = XLSX.readxlsx(instance_address)
    try 
        sh = xf["e_points"]
        return size(sh[:][2:end, 2:end], 2)
    catch
        return 5000
    end
end

address = "test//mokp//instances//3kp50.xlsx"
result, report = solve_kp_instance(address, objectives_sense = ["Max", "Max"])

function compare_frontier(address)
    addresses_set = []


end