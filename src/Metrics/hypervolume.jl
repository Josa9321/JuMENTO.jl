"""
    hypervolume(frontier_set::Matrix{F}, ref_point::Vector{F}) where F <: Number

Compute the Hypervolume (HV) indicator of a given Pareto frontier with respect
to a reference point.

The hypervolume measures the volume of the objective space that is dominated
by the Pareto front and bounded by the specified `ref_point`. Larger values
indicate better performance.
"""
function hypervolume(frontier_set::Matrix{F}, ref_point::Vector{F}) where F <: Number
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
