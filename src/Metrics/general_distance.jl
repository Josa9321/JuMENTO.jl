"""
    general_distance(frontier_set::Matrix{F}, reference_set::Matrix{F}; p = 2) where F <: Number

Compute the Generalized Distance (GD) between the `frontier_set` and the `reference_set`.

The GD is defined as the `p`-norm of the Euclidean distances from each solution
in the `frontier_set` to its nearest neighbor in the `reference_set`.

Smaller GD values indicate that the `frontier_set` lies closer to the reference
set, reflecting better convergence toward the Pareto-optimal front.
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
