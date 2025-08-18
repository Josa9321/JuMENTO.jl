############################
# Dominance Functions
############################

"""
    dominates(a, b)

Check if solution `a` dominates solution `b` based on Pareto dominance.
Returns `true` if `a` is no worse in all objectives and better in at least one.
"""
function dominates(a::AbstractVector{Float64}, b::AbstractVector{Float64}; sense::Vector{String}=fill("Min", length(a)))
    @assert length(a) == length(b) == length(sense) "Incompatible dimensions."
    
    as_good_in_all = true
    at_least_better_in_one = false

    for i in 1:length(a)
        if sense[i] == "Min"
            if a[i] > b[i]
                as_good_in_all = false
                break
            elseif a[i] < b[i]
                at_least_better_in_one = true
            end
        elseif sense[i] == "Max"
            if a[i] < b[i]
                as_good_in_all = false
                break
            elseif a[i] > b[i]
                at_least_better_in_one = true
            end
        else
            error("sense[$i] must be \"Min\" or \"Max\".")
        end
    end

    return as_good_in_all && at_least_better_in_one
end

"""
    is_dominated_by_reference(point, reference)

Check if a given `point` is dominated by any point in the `reference` set.
"""
function is_dominated_by_reference(point::Vector{Float64}, reference::AbstractMatrix{Float64}; sense::Vector{String}=fill("Min", size(reference, 1)))
    @assert size(reference, 1) == length(point) "Incompatible dimensions."

    for i in 1:size(reference, 2)
        if dominates(reference[:, i], point; sense=sense)
            return true
        end
    end
    return false
end

############################
# Normalize Front
############################

function normalize_front(data)
    if data isa Vector
        if !isempty(data) && eltype(data) <: SolutionJuMP
            return hcat([sol.objectives for sol in data]...)
        elseif !isempty(data) && eltype(data) <: SolutionNSGA
            return hcat([sol.objectives for sol in data]...)
        elseif !isempty(data) && eltype(data) <: AbstractVector
            mat = hcat(data...)
            return size(mat, 1) <= size(mat, 2) ? mat : mat'
        else
            error("Unsupported vector format: $(eltype(data))")
        end

    elseif data isa AbstractMatrix
        return size(data, 1) <= size(data, 2) ? data : data'

    else
        error("Unsupported data type: $(typeof(data))")
    end
end



############################
# Spacing Metric
############################

"""
    spacing_metric(frontier)

Calculates the spacing metric, which measures the distribution uniformity
of solutions in the Pareto front. Lower values indicate more uniform distribution.
"""
function spacing_metric(frontier)
    frontier = normalize_front(frontier)

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
function general_distance(frontier, reference)
    frontier = normalize_front(frontier)
    reference = normalize_front(reference)
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
function diversity_metric(frontier, reference)
    frontier = normalize_front(frontier)
    reference = normalize_front(reference)
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
function calculate_error_metrics(frontier, reference)
    frontier = normalize_front(frontier)
    reference = normalize_front(reference)
    @assert size(frontier, 1) == size(reference, 1) "Objectives dimensions do not match."

    m, n_f = size(frontier)
    _, n_r = size(reference)

    mre_terms = Float64[]
    vre_terms = Float64[]
    mpe_terms = Float64[]

    for i in 1:n_f
        fsol = frontier[:, i]
        dists = [norm(fsol .- reference[:, j]) for j in 1:n_r]
        j_best = argmin(dists)
        rsol = reference[:, j_best]

        for k in 1:m
            vs = fsol[k]
            rs = rsol[k]

            mre = 100 * abs(rs - vs) / max(abs(rs), 1e-8)
            vre = 100 * abs(vs - rs) / max(abs(rs), 1e-8)

            psi = 100 * abs(rs - vs) / max(abs(vs), 1e-8)
            beta = 100 * abs(sqrt(abs(rs)) - sqrt(abs(vs))) / max(sqrt(abs(vs)), 1e-8)
            mpe = min(beta, psi)

            push!(mre_terms, mre)
            push!(vre_terms, vre)
            push!(mpe_terms, mpe)
        end
    end

    return mean(mre_terms), mean(vre_terms), mean(mpe_terms)
end

############################
# Error Ratio (ER)
############################

"""
    error_ratio(frontier, reference)

Calculates the Error Ratio (ER), which is the proportion of solutions in the
frontier that are dominated by any solution in the reference set.
"""
function error_ratio(frontier, reference; tol=1e-8)
    frontier = normalize_front(frontier)
    reference = normalize_front(reference)
    @assert size(frontier, 1) == size(reference, 1) "Dimensions not match."

    n = size(frontier, 2)
    erros = 0

    for j in 1:n
        dist_min = minimum(norm(frontier[:, j] .- reference[:, k]) for k in 1:size(reference, 2))
        if dist_min > tol
            erros += 1
        end
    end

    return erros / n
end

"""
    hypervolume(frontier, ref; sense)

Computes the hypervolume (HV) indicator of a given Pareto frontier with respect 
to a reference point. The hypervolume is a metric that measures the size of the objective 
space dominated by a Pareto front with respect to a reference point.
"""
function hypervolume(frontier, ref::Vector{Float64}; sense::Vector{String}=fill("Min", length(ref)))
    frontier = normalize_front(frontier)
    if size(frontier, 1) != length(ref)
        frontier = frontier'
    end
    @assert size(frontier, 1) == length(ref) "Number of objectives does not match reference."

    n_obj = length(ref)

    auto_sense = copy(sense)
    for j in 1:n_obj
        col = frontier[j, :]
        if sense[j] == "Max" && maximum(col) <= ref[j]
            auto_sense[j] = "Min"
        end
    end

    P = copy(frontier')
    R = copy(ref)

    for j in 1:n_obj
        if auto_sense[j] == "Max"
            P[:, j] .= -P[:, j]
            R[j] = -R[j]
        elseif auto_sense[j] != "Min"
            error("Sense must only contain \"Min\" or \"Max\"")
        end
    end

    return hv_recursive(P, R)
end

"""
    hv_recursive(P, R)

Recursive helper function that computes the hypervolume.
"""
function hv_recursive(P::Matrix{Float64}, R::Vector{Float64})

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
            hv += hv_recursive(sub_points, R[1:m-1]) * height
        end
        prev = p[m]
        P = P[1:end-1, :]
    end
    return hv
end