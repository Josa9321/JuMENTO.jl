############################
# Dominance Functions
############################

"""
    dominates(a, b)

Check if solution `a` dominates solution `b` based on Pareto dominance.
Returns `true` if `a` is no worse in all objectives and better in at least one.
"""
function dominates(a::AbstractVector{Float64}, b::AbstractVector{Float64})
    as_good_in_all = true
    at_least_better_in_one = false

    for i in 1:length(a)
        if a[i] > b[i]
            as_good_in_all = false
            break
        elseif a[i] < b[i]
            at_least_better_in_one = true
        end
    end

    return as_good_in_all && at_least_better_in_one
end

"""
    is_dominated_by_reference(point, reference)

Check if a given `point` is dominated by any point in the `reference` set.
"""
function is_dominated_by_reference(point::Vector{Float64}, reference::Matrix{Float64})
    for i in 1:size(reference, 2)
        if dominates(reference[:, i], point)
            return true
        end
    end
    return false
end

############################
# Spacing Metric
############################

"""
    spacing_metric(frontier)

Calculates the spacing metric, which measures the distribution uniformity
of solutions in the Pareto front. Lower values indicate more uniform distribution.
"""
function spacing_metric(frontier::Matrix{Float64})
    n = size(frontier, 2)
    if n < 2
        return 0.0
    end

    di = Float64[]
    for i in 1:n
        dmin = Inf
        for j in 1:n
            if i != j
                d = norm(frontier[:, i] .- frontier[:, j])
                dmin = min(dmin, d)
            end
        end
        push!(di, dmin)
    end

    dmean = mean(di)
    result = sqrt(sum((di .- dmean).^2) / (n - 1))

    return result < 1e-10 ? 0.0 : result
end

############################
# General Distance (GD)
############################

"""
    general_distance(frontier, reference)

Computes the Generalized Distance (GD) between the `frontier` and the `reference`.
It measures how close the frontier is to the reference Pareto front.
"""
function general_distance(frontier::Matrix{Float64}, reference::Matrix{Float64})
    @assert size(frontier, 1) == size(reference, 1) "Dimensions not match."

    n = size(frontier, 2)
    distances = zeros(n)

    for i in 1:n
        dists = [norm(frontier[:, i] .- reference[:, j]) for j in 1:size(reference, 2)]
        distances[i] = minimum(dists)
    end

    return sqrt(sum(distances .^ 2)) / n
end

############################
# Diversity Metric (Δ)
############################

"""
    diversity_metric(frontier, reference)

Computes the diversity metric (Δ), which evaluates both the distribution 
and spread of the solutions along the Pareto front.
"""
function diversity_metric(frontier::Matrix{Float64}, reference::Matrix{Float64})
    n = size(frontier, 2)
    if n < 2
        return 0.0
    end

    objs = collect(eachcol(frontier))
    sort!(objs, by = x -> x[1])

    di = [norm(objs[i + 1] .- objs[i]) for i in 1:n - 1]
    d_mean = mean(di)

    first_extreme = reference[:, argmin(reference[1, :])]
    last_extreme = reference[:, argmax(reference[1, :])]

    df = norm(objs[1] .- first_extreme)
    dl = norm(objs[end] .- last_extreme)

    delta = (df + dl + sum(abs.(di .- d_mean))) / (df + dl + (n - 1) * d_mean)
    return delta
end

############################
# Error Metrics (ME, VE, MPE)
############################

"""
    calculate_error_metrics(frontier, reference)

Computes error metrics between `frontier` and `reference`:
- ME: Mean Error
- VE: Variance Error
- MPE: Mean Percentage Error considering both absolute and square root differences.
"""
function calculate_error_metrics(frontier::Matrix{Float64}, reference::Matrix{Float64})
    @assert size(frontier) == size(reference) "Dimensions not match."

    m, n = size(frontier)
    mre_terms = Float64[]
    vre_terms = Float64[]
    mpe_terms = Float64[]

    for j in 1:m
        vs = frontier[j, 1]
        rs = frontier[j, 2]
        vh = reference[j, 1] 
        rh = reference[j, 2] 

        mre = 100 * abs(rs - rh) / max(abs(rh), 1e-8)

        vre = 100 * abs(vs - vh) / max(abs(vh), 1e-8)

        psi = 100 * abs(rh - rs) / max(abs(rs), 1e-8)
        beta = 100 * abs(sqrt(abs(rh)) - sqrt(abs(rs))) / max(sqrt(abs(rs)), 1e-8)
        mpe = min(beta, psi)

        push!(mre_terms, mre)
        push!(vre_terms, vre)
        push!(mpe_terms, mpe)
    end

    mean_return_error = mean(mre_terms)
    variance_return_error = mean(vre_terms)
    mean_percentage_error = mean(mpe_terms)

    return mean_return_error, variance_return_error, mean_percentage_error
end

############################
# Error Ratio (ER)
############################

"""
    error_ratio(frontier, reference)

Calculates the Error Ratio (ER), which is the proportion of solutions in the
frontier that are dominated by any solution in the reference set.
"""
function error_ratio(frontier::Matrix{Float64}, reference::Matrix{Float64})
    @assert size(frontier, 1) == size(reference, 1) "Dimensions not match."

    n = size(frontier, 2)
    error = 0
    for i in 1:n
        if is_dominated_by_reference(frontier[:, i], reference)
            error += 1
        end
    end
    return error / n
end

############################
# Hypervolume (HV)
############################

"""
    hypervolume(frontier, reference_point)

Calculates the Hypervolume (HV) for 2D Pareto fronts.
Returns `missing` if more than 2 objectives are given.
"""
function hypervolume(frontier::Matrix{Float64}, reference_point::Vector{Float64})
    num_obj = size(frontier, 1)
    if num_obj == 2
        return hypervolume_2d(frontier, reference_point)
    else
        @warn "Hypervolume only supports 2D. Received $num_obj objectives."
        return missing
    end
end

"""
    hypervolume_2d(frontier, reference_point)

Helper function for hypervolume calculation in 2D.
Computes the area dominated by the Pareto front with respect to the reference point.
"""
function hypervolume_2d(frontier::Matrix{Float64}, reference_point::Vector{Float64})
    objs = collect(eachcol(frontier))
    sort!(objs, by = x -> x[1])

    hv = 0.0
    prev_f2 = reference_point[2]

    for point in objs
        f1, f2 = point
        width = abs(reference_point[1] - f1)
        height = abs(prev_f2 - f2)

        hv += width * height
        prev_f2 = f2
    end

    return hv
end

function test_all_metrics()

    ##############################
    frontier1 = [10.0 20.0; 100.0 80.0]
    reference1 = [10.0 20.0; 100.0 80.0]

    sp1 = spacing_metric(frontier1)
    gd1 = general_distance(frontier1, reference1)
    dm1 = diversity_metric(frontier1, reference1)
    me1, ve1, mpe1 = calculate_error_metrics(frontier1, reference1)
    er1 = error_ratio(frontier1, reference1)
    hv1 = hypervolume(frontier1, [25.0, 120.0])

    @assert isapprox(sp1, 0.0; atol=1e-6) "Case 1 - Spacing metric failed"
    @assert isapprox(gd1, 0.0; atol=1e-6) "Case 1 - General distance failed"
    @assert isapprox(dm1, 0.0; atol=1e-6) "Case 1 - Diversity metric failed"
    @assert isapprox(me1, 0.0; atol=1e-6) "Case 1 - Mean error failed"
    @assert isapprox(ve1, 0.0; atol=1e-6) "Case 1 - Variance error failed"
    @assert isapprox(mpe1, 0.0; atol=1e-6) "Case 1 - MPE failed"
    @assert isapprox(er1, 0.0; atol=1e-6) "Case 1 - Error ratio failed"
    @assert hv1 > 0.0 "Case 1 - Hypervolume failed"

    ##############################
    frontier2 = [11.0 19.0; 99.0 81.0]
    reference2 = [10.0 20.0; 100.0 80.0]

    sp2 = spacing_metric(frontier2)
    gd2 = general_distance(frontier2, reference2)
    dm2 = diversity_metric(frontier2, reference2)
    me2, ve2, mpe2 = calculate_error_metrics(frontier2, reference2)
    er2 = error_ratio(frontier2, reference2)
    hv2 = hypervolume(frontier2, [25.0, 120.0])

    @assert sp2 == 0.0 "Case 2 - Spacing metric failed"
    @assert gd2 > 0.0 "Case 2 - General distance failed"
    @assert dm2 > 0.0 "Case 2 - Diversity metric failed"
    @assert me2 > 0.0 "Case 2 - Mean error failed"
    @assert ve2 > 0.0 "Case 2 - Variance error failed"
    @assert mpe2 > 0.0 "Case 2 - MPE failed"
    @assert er2 == 0.0 "Case 2 - Error ratio failed"
    @assert hv2 > 0.0 "Case 2 - Hypervolume failed"

    ##############################
    frontier3 = [12.0 18.0; 98.0 82.0]
    reference3 = [10.0 20.0; 100.0 80.0]

    sp3 = spacing_metric(frontier3)
    gd3 = general_distance(frontier3, reference3)
    dm3 = diversity_metric(frontier3, reference3)
    me3, ve3, mpe3 = calculate_error_metrics(frontier3, reference3)
    er3 = error_ratio(frontier3, reference3)
    hv3 = hypervolume(frontier3, [25.0, 120.0])

    @assert sp3 == 0.0 "Case 3 - Spacing metric failed"
    @assert gd3 > 1.0 "Case 3 - General distance failed"
    @assert dm3 > 0.0 "Case 3 - Diversity metric failed"
    @assert me3 > 0.0 "Case 3 - Mean error failed"
    @assert ve3 > 0.0 "Case 3 - Variance error failed"
    @assert mpe3 > 0.0 "Case 3 - MPE failed"
    @assert er3 == 0.0 "Case 3 - Error ratio failed"
    @assert hv3 > 0.0 "Case 3 - Hypervolume failed"
end
test_all_metrics()