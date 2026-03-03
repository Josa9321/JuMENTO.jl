function level_diagrams_plot(set_of_frontiers::Vector{Matrix{F}},
    normalized_set_of_frontiers=__normalize_sets(set_of_frontiers),
    categories::Vector{String}=["f_$(i)" for i in axes(set_of_frontiers, 1)],
    names_set::Vector{String}=["Method $(k)" for k in eachindex(set_of_frontiers)];
    type_plot::String="markers+lines",
    p=2) where {F<:Number}

    m = size(set_of_frontiers[1], 1)
    @assert all(f -> size(f, 1) == m, set_of_frontiers) "Not all frontiers have the same number of objectives (rows)"

    fig = make_subplots(
        rows=m,
        subplot_titles=categories[:, :]
    )
    for (idx, set) in enumerate(set_of_frontiers)
        __level_diagrams!(fig, set, normalized_set_of_frontiers[idx], type_plot, names_set[idx], idx)
    end
    return fig
end


function level_diagrams_plot(frontier_set::Matrix{F},
    normalized_set=normalize_frontier(frontier_set),
    categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)],
    name::String="Method";
    type_plot::String="markers+lines",
    p=2) where {F<:Number}

    m = size(frontier_set, 1)

    fig = make_subplots(
        rows=m,
        subplot_titles=categories[:, :]
    )
    __level_diagrams!(fig, frontier_set, normalized_set, type_plot, name, 1)
    return fig
end

# function level_diagrams_plot(frontier::Matrix{F}, cats=["f_$(i)" for i in axes(frontier, 1)];
#     p=2, type_plot::String="markers+lines") where {F<:Number}
#
#     @warn("Still not done")
#     m = size(frontier, 1)
#     fig = make_subplots(
#         rows=m,
#         subplot_titles=cats[:, :]
#     )
#     J_norm = get_common_yaxis_LD(frontier, p=p)
#     for i in axes(frontier, 1)
#         obj_i = view(frontier, i, :)
#         order = sortperm(obj_i)
#         add_trace!(
#             fig,
#             scatter(
#                 x=view(frontier, i, :)[order],
#                 y=J_norm[order],
#                 mode=type_plot,
#             ),
#             row=i
#         )
#     end
#     return fig
# end
#

function __normalize_sets(set_of_frontiers)
    minimum_point = minimum(hcat(minimum.(set_of_frontiers, dims=2)...), dims=2)
    maximum_point = maximum(hcat(maximum.(set_of_frontiers, dims=2)...), dims=2)
    result = Vector{typeof(set_of_frontiers[1])}(undef, length(set_of_frontiers))
    for (k, set) in enumerate(set_of_frontiers)
        result[k] = normalize_frontier(set, min_point=minimum_point, max_point = maximum_point)
    end
    return result
end

function get_common_yaxis_LD(normalized_set; p=2)
    # normalized_set = normalize_frontier(frontier_set)
    return [norm(1.0 .- view(normalized_set, :, j), p) for j in axes(normalized_set, 2)]
end


function __level_diagrams!(fig, frontier_set::Matrix{F}, normalized_set::Matrix{F}, type_plot, name, id) where {F<:Number}
    global COLORS_SET

    first_trace = true
    for i in axes(frontier_set, 1)
        x = view(frontier_set, i, :)
        order = sortperm(x)
        y = get_common_yaxis_LD(normalized_set)
        color = COLORS_SET[mod1(id, length(COLORS_SET))]
        add_trace!(
            fig,
            scatter(
                x=frontier_set[i, order],
                y=y[order],
                mode=type_plot,
                marker=attr(color=color),
                line=attr(color=color), legendgroup=name,
                name=name,
                showlegend=first_trace
            ),
            row=i
        )
        first_trace = false
    end
    return fig
end
