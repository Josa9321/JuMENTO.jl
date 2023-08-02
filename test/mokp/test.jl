function solve_kp_instance(address)
    file = instance_name(address)
    instance = KnapsackInstance(address)
    model, objs = knapsack_model(instance)
    if file in ["3kp40", "3kp50"]
        frontier, report = augmecon(model, objs, grid_points=grid_points(file), nadir=nadir_point(file))
    else
        frontier, report = augmecon(model, objs, grid_points=grid_points(file), dominance_eps=0.5)
    end
    return frontier, report
end

function instance_name(address)
    first = findlast("//", address)[end]+1
    last = findlast(".", address)[end]-1
    return address[first:last]
end

function grid_points(file)
    result = Dict("2kp50" => 492, "2kp100" => 823, "2kp250" => 2534,
        "3kp40" => 540, "3kp50" => 847
    )
    return result[file]
end

function nadir_point(file)
    result = Dict("3kp40" => [1031.0, 1069.0], "3kp50" => [1124.0, 1041.0])
    return result[file]
end