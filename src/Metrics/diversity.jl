"""
    diversity(frontier_set::Matrix{F},
              reference_set::Matrix{F} = zeros(size(frontier_set, 1), 0)) where F <: Number

Compute the diversity metric (Δ), which evaluates the dispersion of the solution set. 
Lower values indicate better diversity, which is preferable.

The `reference_set` argument can be used in the computation of Δ; however, it is optional and may be omitted.
"""
function diversity(frontier_set::Matrix{F}, reference_set::Matrix{F}=zeros(size(frontier_set, 1), 0)) where F <: Number
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
