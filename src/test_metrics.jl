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
        @printf("Hypervolume          : %.4e\n", hy)
        println("---------------------------------------------")
    end

    println("=============================================")
end

function generate_reference_point(frontier)
    alpha = 1.1

    if frontier isa Vector{<:SolutionJuMP}
        frontier = [sol.objectives for sol in frontier]
    end

    if frontier isa Vector{<:Vector}
        frontier = Matrix(hcat(frontier...)')
    end

    max_values = maximum(frontier, dims=1)
    reference_point = vec(alpha .* max_values)
    return reference_point
end

function test_with_get(frontier, reference=nothing; reference_point=nothing)

    if frontier isa Vector
        if eltype(frontier) <: SolutionJuMP
            frontier = hcat([sol.objectives for sol in frontier]...)'
        elseif eltype(frontier) <: SolutionNSGA
            frontier = hcat([sol.objectives for sol in frontier]...)'
        elseif eltype(frontier) <: AbstractVector
            frontier = hcat(frontier...)'
        else
            error("No recognized format: $(eltype(frontier))")
        end
    end

    if reference !== nothing
        if reference isa Vector
            if eltype(reference) <: SolutionJuMP
                reference = hcat([sol.objectives for sol in reference]...)'
            elseif eltype(reference) <: SolutionNSGA
                reference = hcat([sol.objectives for sol in reference]...)'
            elseif eltype(reference) <: AbstractVector
                reference = hcat(reference...)'
            else
                error("No recognized format: $(eltype(reference))")
            end
        end
    end

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

    hv = hypervolume(frontier, reference_point)

    print_metrics(sp, gd, dm, me, ve, mp, er, hv)
end