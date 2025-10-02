function test_instances_set(instances_addresses_set; bypass)
    # println("\n\nSOLVING MOKP INSTANCES SET")
    
    # println("-"^25)
    # @printf("%-12s | %-02s | %-04s\n", "Name", "Thr", "#Sol")
    # println("-"^25)
    Threads.@threads for address in instances_addresses_set
        frontier, report = solve_kp_instance(address, bypass)
        # @printf("%-12s | %03i | %04i\n", basename(address), Threads.threadid(), length(frontier))

        frontier_saved = load_knapsack_sheet(address, "pareto_sols")
        
        for (idx, s) in enumerate(frontier)
            @test all(isapprox.(collect(frontier_saved[idx, :]), s.objectives))
            if !all(isapprox.(collect(frontier_saved[idx, :]), s.objectives)) 
                @show frontier_saved[idx, :], s.objectives
                break
            end
        end
    end
    # println("-"^25*"\n\n")
    return nothing
end

function solve_kp_instance(address, bypass)
    file_name = split(basename(address), ".")[1]
    instance = KnapsackInstance(address)
    model = knapsack_model(instance)
    if file_name in ["3kp40", "3kp50"]
        frontier, report = augmecon(model, grid_points=grid_points(file_name), bypass=bypass, nadir=nadir_point(file_name), dominance_eps=0.5)
    else
        frontier, report = augmecon(model, grid_points=grid_points(file_name), bypass=bypass, dominance_eps=0.5)
    end
    return frontier, report
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