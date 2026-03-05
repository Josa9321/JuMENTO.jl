"""
    normalize_frontier(frontier_set::Matrix{F}, sense=fill(:max, size(frontier_set, 1));
        eps=0.0,
        min_point = minimum(frontier_set, dims=2) .* (1.0 - eps),
        max_point = maximum(frontier_set, dims=2) .* (1.0 + eps)
    ) where F <: Number

Normalizes the given frontier set to a [0, 1] range for each objective.
The `sense` vector indicates whether each objective is to be maximized or minimized, which affects the normalization.
The `eps` parameter allows for a slight expansion of the normalization range if necessary.
The `min_point` and `max_point` parameters can be explicitly provided to control the normalization range, or they will be computed from the frontier set.
"""
function normalize_frontier(frontier_set::Matrix{F}, sense=fill(:max, size(frontier_set, 1));
        eps=0.0,
        min_point = minimum(frontier_set, dims=2) .* (1.0 - eps),
        max_point = maximum(frontier_set, dims=2) .* (1.0 + eps)
    ) where F <: Number
    @assert size(frontier_set, 1) == length(sense) == length(min_point) == length(max_point) "The length of the sense vector, min and max point must match the number of objectives (rows) in the frontier set."
    @assert all(s -> s == :max || s == :min, sense) "Sense vector must contain only :max or :min values."

    result = (frontier_set .- min_point
             ) ./ (max_point .- min_point)
    for i in axes(sense, 1)
        if sense[i] == :min
            result[i, :] = 1 .- result[i, :]
        end
    end
    return result
end
