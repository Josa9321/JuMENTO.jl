"""
    radar(frontier_set::Matrix{F};
        sense_set ::Vector{Symbol} = [:max for i in axes(frontier_set, 1)],
        categories::Vector{String} = ["f_i" for i in axes(frontier_set, 1)],
        name_set ::Vector{String} = ["Solution j" for j in axes(frontier_set, 2)],
        eps::Float64=0.2
        ) where F <: Number

Plots a radar chart for the given frontier set.
The optional `sense_set` vector indicates whether each objective is to be maximized or minimized, which affects the normalization of the data. 
The `categories` vector provides labels for each objective, and 
the `name_set` vector provides labels for each solution (column) in the frontier set.
`eps` is used to slightly expand the normalization range to ensure that all points are visible within the radar chart.
"""
function radar(frontier_set::Matrix{F};
    sense_set=[:max for i in axes(frontier_set, 1)],
    categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)],
    name_set::Vector{String}=["Solution $(j)" for j in axes(frontier_set, 2)],
    eps::Float64=0.2) where {F<:Number}

    @assert size(frontier_set, 1) == length(categories) == length(sense_set) "The number of categories and senses must match the number of objectives (rows) in the frontier set."
    @assert size(frontier_set, 2) == length(name_set) "The number of names must match the number of solutions (columns) in the frontier set."

    normalized_set = normalize_frontier(frontier_set, sense_set, eps=eps)
    fig = Plot()
    for (j, name_j) in enumerate(name_set)
        normalized_j = @view normalized_set[:, j]
        original_j = @view frontier_set[:, j]
        addtraces!(fig,
            scatterpolar(
                r=normalized_j,
                theta=categories,
                fill="toself",
                mode="lines+markers+text",
                name=name_j,
                hovertext=string.(original_j),
                hovertemplate="<b>%{fullData.name}</b><br>" *
                              "Category: %{theta}<br>" *
                              "Value: %{hovertext}<extra></extra>",
                text=string.(original_j),
                textposition="top center",
            )
        )
    end
    relayout!(fig, polar=attr(radialaxis=attr(
        visible=true,
        showticklabels=false
    )))
    return fig
end
