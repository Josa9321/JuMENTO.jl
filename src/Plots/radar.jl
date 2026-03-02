function radar_plot(set::Vector{Vector{V}}, categories::Vector{String}; name_set = string.(collect(eachindex(set)))) where V
    fig = Plot()
    for (i, (values_i, name_i)) in enumerate(zip(set, name_set))
        addtraces!(fig,
            scatterpolar(
                r=values_i,
                theta=categories,
                fill="toself",
                name=name_i
            )
        )
    end
    relayout!(fig, polar=attr(radialaxis=attr(visible=true)))
    return fig
end
