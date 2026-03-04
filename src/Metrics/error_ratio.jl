"""
    error_ratio(frontier_set::Matrix{F}, reference_set::Matrix{F}; tol=1e-6) where F <: Number

Calculate the Error Ratio (ER) between the `frontier_set` and the `reference` set.
The ER is defined as the proportion of solutions in the frontier set that are not present in the reference set, within a given tolerance `tol`.

A lower ER indicates better performance, as it reflects stronger convergence toward the Pareto-optimal front.
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
