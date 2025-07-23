function print_metrics(sp, gd, dm, me, ve, mp, er, hy)
    println("=========== METRICS ===========")
    @printf("Spacing metric       : %.4f\n", sp)
    if gd!==nothing
        @printf("General distance     : %.4f\n", gd)
        @printf("Diversity metric     : %.4f\n", dm)
        println("---------------------------------------------")
        @printf("Error mean           : %.4f\n", me)
        @printf("Error variance       : %.4f\n", ve)
        @printf("Error mean (%%)       : %.4f\n", mp)
        @printf("Error ratio          : %.4f\n", er)
        println("---------------------------------------------")
    end

    if hy !== missing
        @printf("Hypervolume          : %.4e\n", hy)
    else
        println("Hypervolume          : Only 2D Calculated")
    end

    println("=============================================")
end


function generate_reference_point(frontier::Matrix{Float64})
    alpha=1.1
    max_values = maximum(frontier, dims=2)
    reference_point = vec(alpha .* max_values)
    return reference_point
end

function test_with_get(frontier::Matrix{Float64}, reference::Matrix{Float64}; reference_point=nothing)
    gd = nothing

    if reference_point === nothing
        reference_point = generate_reference_point(frontier)
        println("Automatic Reference Point Used: ", reference_point)
    end

    sp = spacing_metric(frontier)
    if reference !== nothing
        gd = general_distance(frontier, reference)
        dm = diversity_metric(frontier, reference)
        me, ve, mp = calculate_error_metrics(frontier, reference)
        er = error_ratio(frontier, reference)
    end

    hv = missing
    num_obj = size(frontier, 1)
    if num_obj == 2
        hv = hypervolume(frontier, reference_point)
    else
        println("Hypervolume only supports 2D")
    end

    print_metrics(sp, gd, dm, me, ve, mp, er, hv)
end