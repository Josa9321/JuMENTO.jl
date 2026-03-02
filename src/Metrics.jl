module Metrics

using LinearAlgebra, Statistics

##################
# Spacing Metric #
##################

"""
    spacing_metric(frontier_set, reference_set)

Calculates the standard deviation of distances between each solution in the `frontier_set` and its nearest neighbor in the `reference_set`.
A lower value indicates a more uniform distribution of solutions along the Pareto front, which is desirable.
"""
function spacing_metric(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."
    n = size(frontier_set, 2)
    if n < 2
        return 0.0
    end
    distances_set = zeros(n)
    for i in axes(frontier_set, 2)
        dmin = Inf
        for j in axes(reference_set, 2)
            d = norm(frontier_set[:, i] .- reference_set[:, j])
            dmin = min(dmin, d)
        end
        distances_set[i] = dmin
    end
    return std(distances_set)
end

#########################
# General Distance (GD) #
#########################

"""
    general_distance(frontier_set, reference)

Computes the Generalized Distance (GD) between the `frontier_set` and the `reference_set`.
The GD is calculated as the square root of the average of the squared distances from each solution in the frontier_set to its nearest neighbor in the reference set.
The smaller the GD, the closer the frontier_set is to the reference set, indicating better convergence towards the Pareto optimal front.
"""
function general_distance(frontier_set::Matrix{F}, reference_set::Matrix{F}; p = 2) where F <: Number
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."
    n = size(frontier_set, 2)
    distances = 0.0
    for i in axes(frontier_set, 2)
        dmin = Inf
        sol_i = @view frontier_set[:, i]
        for j in axes(reference_set, 2)
            sol_j = @view reference_set[:, j]
            d = norm(sol_i - sol_j)
            dmin = min(dmin, d)
        end
        distances += dmin^p
    end

    return (distances^(1/p)) / n
end

############################
# Diversity Metric (Δ)
############################

"""
    diversity_metric(frontier_set, reference)

Computes the diversity metric (Δ), which evaluates both the distribution 
and spread of the solutions along the Pareto front.
"""
function diversity_metric(frontier_set::Matrix{F}, reference_set::Matrix{F}=zeros(size(frontier_set, 1), 0)) where F <: Number
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."
    n = size(frontier_set, 2)
    if n < 2
        return 0.0
    end

    objs = collect(eachcol(frontier_set))
    sort!(objs, by = x -> x[1])

    consecutive_distances = [norm(objs[i + 1] .- objs[i]) for i in 1:n - 1]
    d_mean = mean(consecutive_distances)

    extremes_df_dl = fill(Inf, 2)
    for j in axes(reference_set, 2)
        d1 = norm(objs[1] .- reference_set[:, j])
        d2 = norm(objs[end] .- reference_set[:, j])
        extremes_df_dl[1] = min(extremes_df_dl[1], d1)
        extremes_df_dl[2] = min(extremes_df_dl[2], d2)
    end
    if size(reference_set, 2) == 0
        extremes_df_dl .= 0.0;
    end

    delta = (extremes_df_dl[1] + extremes_df_dl[2] + sum(abs.(consecutive_distances .- d_mean))) / (
        extremes_df_dl[1] + extremes_df_dl[2] + (n - 1) * d_mean)
    return delta
end

############################
# Error Metrics (ME, VE, MPE)
############################

"""
    calculate_error_metrics(frontier_set, reference)

Computes error metrics between `frontier_set` and `reference`:
- ME: Mean Error
- VE: Variance Error
- MPE: Mean Percentage Error considering both absolute and square root differences.
"""
function calculate_error_metrics(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number
    @warn("Maybe with bugs")
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."

    m, n_f = size(frontier_set)
    _, n_r = size(reference_set)

    mre_terms = Float64[]
    vre_terms = Float64[]
    mpe_terms = Float64[]

    for i in 1:n_f
        fsol = frontier_set[:, i]
        dists = [norm(fsol .- reference_set[:, j]) for j in 1:n_r]
        j_best = argmin(dists)
        rsol = reference_set[:, j_best]

        for k in 1:m
            vs = fsol[k]
            rs = rsol[k]

            mre = 100 * abs(rs - vs) / (abs(rs) > 1e-12 ? abs(rs) : abs(rs - vs) + 1e-12)
            vre = 100 * abs(vs - rs) / (abs(rs) > 1e-12 ? abs(rs) : abs(rs - vs) + 1e-12)

            psi  = 100 * abs(rs - vs) / (abs(vs) > 1e-12 ? abs(vs) : abs(rs - vs) + 1e-12)
            beta = 100 * abs(sqrt(abs(rs)) - sqrt(abs(vs))) / (sqrt(abs(vs)) > 1e-12 ? sqrt(abs(vs)) : sqrt(abs(rs - vs)) + 1e-12)
            mpe = min(beta, psi)

            push!(mre_terms, mre)
            push!(vre_terms, vre)
            push!(mpe_terms, mpe)
        end
    end

    return mean(mre_terms), mean(vre_terms), mean(mpe_terms)
end


####################
# Error Ratio (ER) #
####################

"""
    error_ratio(frontier_set, reference)

Calculate the Error Ratio (ER) between the `frontier_set` and the `reference` set. 
The ER is defined as the percentage of solutions in the frontier that are not in the reference set. 
A lower ER indicates better convergence towards the Pareto optimal front, while a higher ER suggests that many solutions in the frontier are dominated by those in the reference set, indicating poorer performance.
"""
function error_ratio(frontier_set::Matrix{F}, reference_set::Matrix{F}; tol=1e-6) where F <: Number
    @assert size(frontier_set, 1) == size(reference_set, 1) "Number of objectives do not match. Each line must represent an objective."

    n = size(frontier_set, 2)
    num_solutions_not_in_ref_set = 0

    for j in axes(frontier_set, 2)
        dist_min = minimum(norm(frontier_set[:, j] .- reference_set[:, k]) for k in axes(reference_set, 2))
        if dist_min > tol
            num_solutions_not_in_ref_set += 1
        end
    end

    return num_solutions_not_in_ref_set / n
end

############################
# Hypervolume (HV)
############################

"""
    hypervolume(frontier_set, ref)

Computes the hypervolume (HV) indicator of a given Pareto frontier with respect 
to a reference point. The hypervolume is a metric that measures the size of the objective 
space dominated by a Pareto front with respect to a reference point.
"""
function hypervolume(frontier_set::Matrix{F}, ref_point::Vector{F}) where F <: Number
    @warn("Maybe with bugs")
    @assert size(frontier_set, 1) == length(ref_point) "Number of objectives does not match reference."
    P = copy(frontier_set')
    R = copy(ref_point)
    return __hv_recursive(P, R)
end

function __hv_recursive(P::Matrix{F}, R::Vector{F}) where F <: Number
    n, m = size(P)
    if n == 0
        println("No points")
        return 0.0
    end
    if m == 1
        return maximum(R[1] .- P[:, 1])
    end

    idx = sortperm(P[:, m])
    P = P[idx, :]

    hv = 0.0
    prev = R[m]
    while size(P, 1) > 0
        p = P[end, :]
        height = prev - p[m]
        if height > 0
            sub_points = P[:, 1:m-1]
            hv += __hv_recursive(sub_points, R[1:m-1]) * height
        end
        prev = p[m]
        P = P[1:end-1, :]
    end
    return hv
end

end
