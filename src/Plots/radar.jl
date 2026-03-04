"""
    radar(frontier_set::Matrix{F};
        categories::Vector{String} = ["f_i" for i in axes(frontier_set, 1)],
        name_set ::Vector{String} = ["Solution j" for j in axes(frontier_set, 2)]) where F <: Number

Plots a radar chart for the given frontier set.
The optional `categories` vector provides labels for each objective, and 
the `name_set` vector provides labels for each solution (column) in the frontier set.
"""
function radar(frontier_set::Matrix{F};
        categories::Vector{String} = ["f_$(i)" for i in axes(frontier_set, 1)],
        name_set ::Vector{String} = ["Solution $(j)" for j in axes(frontier_set, 2)]) where F <: Number

    @assert size(frontier_set, 1) == length(categories) "The number of categories must match the number of objectives (rows) in the frontier set."
    @assert size(frontier_set, 2) == length(name_set) "The number of names must match the number of solutions (columns) in the frontier set."

    fig = Plot()
    for (j, name_j) in enumerate(name_set)
        values_j = @view frontier_set[:, j]
        addtraces!(fig,
            scatterpolar(
                r=values_j,
                theta=categories,
                fill="toself",
                name=name_j
            )
        )
    end
    relayout!(fig, polar=attr(radialaxis=attr(visible=true)))
    return fig
end
