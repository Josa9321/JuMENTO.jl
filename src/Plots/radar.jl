function radar_plot(frontier_set::Matrix{F}, categories::Vector{String} = ["f_$(i)" for i in axes(frontier_set, 1)];
        name_set = "Solution " .* string.(collect(axes(frontier_set, 2)))) where F <: Number
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
