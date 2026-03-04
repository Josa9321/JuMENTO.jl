"""
    spacing(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number

This metric is defined as the standard deviation of the Euclidean distances
from each solution in the `frontier_set` to its nearest neighbor in the
`reference_set`.

Lower values indicate a more uniformly distributed set of solutions along
the Pareto front, which is desirable.
"""
function spacing(frontier_set::Matrix{F}, reference_set::Matrix{F}) where F <: Number
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
