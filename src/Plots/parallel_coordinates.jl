"""
    parallel_coordinates(frontier_set::Matrix{F};
        categories::Vector{String}=["f_i" for i in axes(frontier_set, 1)]) where {F<:Number}

Plots a parallel coordinates chart for the given frontier set.
The optional `categories` vector provides labels for each objective.
"""
function parallel_coordinates(frontier_set::Matrix{F};
        categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)]) where {F<:Number}

    global COLORS_SET
    @assert size(frontier_set, 1) == length(categories) "The number of categories must match the number of objectives (rows) in the frontier set."

    min_point = minimum(frontier_set, dims=2)
    max_point = maximum(frontier_set, dims=2)
    dims = [
        attr(
            range=[min_point[i], max_point[i]],
            label=categories[i],
            values=view(frontier_set, i, :),
        )
        for i in axes(frontier_set, 1)]

    color_ids = [mod1(i, length(COLORS_SET)) for i in axes(frontier_set, 2)]

    colorscale = [
        ((i - 1) / (length(COLORS_SET) - 1), COLORS_SET[i])
        for i in eachindex(COLORS_SET)
    ]
    data = parcoords(
        line=attr(
            color=color_ids,
            colorscale=colorscale,
            cmin=1,
            cmax=length(COLORS_SET),
            showscale=false
        ),
        dimensions=dims
    )
    fig = plot(data)

    return fig
end
