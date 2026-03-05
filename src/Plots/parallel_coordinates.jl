"""
    parallel_coordinates(frontier_set::Matrix{F};
        categories::Vector{String}=["f_i" for i in axes(frontier_set, 1)]) where {F<:Number}

Plots a parallel coordinates chart for the given frontier set.
The optional `categories` vector provides labels for each objective.
"""
function parallel_coordinates(frontier_set::Matrix{F};
    sense_set=[:max for i in axes(frontier_set, 1)],
    name_set::Vector{String}=["Solution $(j)" for j in axes(frontier_set, 2)],
    categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)]) where {F<:Number}

    global COLORS_SET

    @assert size(frontier_set, 1) == length(categories) == length(sense_set) "The number of categories and senses must match the number of objectives (rows) in the frontier set."
    @assert all(s -> s == :max || s == :min, sense_set) "Sense vector must contain only :max or :min values."
    @assert size(frontier_set, 2) == length(name_set) "The number of names must match the number of solutions (columns) in the frontier set."

    min_point = minimum(frontier_set, dims=2)
    max_point = maximum(frontier_set, dims=2)
    dims = [
        attr(
            range=(sense_set[i] == :min ? [max_point[i], min_point[i]] : [min_point[i], max_point[i]]),
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
    fig = plot(data, config=PlotConfig(responsive=false))

    # Little hack to add legend entries for each solution, since parcoords doesn't support legends natively
    for (j, name_j) in enumerate(name_set)
        addtraces!(fig, PlotlyJS.scatter(
            x=[nothing], y=[nothing],
            mode="lines",
            line=attr(color=COLORS_SET[mod1(j, length(COLORS_SET))]),
            name=name_j,
            showlegend=true
        ))
    end

    relayout!(fig,
        showlegend=true,
        legend=attr(title=attr(text="Solutions")),
        paper_bgcolor="white",
        plot_bgcolor="white",
        xaxis=attr(
            showgrid=false,
            showline=false,
            showticklabels=false,
            zeroline=false
        ),
        yaxis=attr(
            showgrid=false,
            showline=false,
            showticklabels=false,
            zeroline=false
        ),
        margin=attr(t=100) # Give some space for labels
    )

    return fig
end
