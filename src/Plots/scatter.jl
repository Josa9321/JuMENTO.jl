function scatter_plot(set_of_frontiers::Vector{Matrix{F}},
    categories::Vector{String}=["f_$(i)" for i in axes(set_of_frontiers, 1)],
    names_set::Vector{String}=["Method $(k)" for k in eachindex(set_of_frontiers)];
    is_3d::Bool=false, type_plot::String="markers+lines") where {F<:Number}

    m = size(set_of_frontiers[1], 1)
    @assert all(f -> size(f, 1) == m, set_of_frontiers) "Not all frontiers have the same number of objectives (rows)"

    fig = nothing
    if m == 2
        fig = __2d_scatter(set_of_frontiers, categories, type_plot, names_set)
    elseif m == 3 && is_3d
        fig = __3d_scatter(set_of_frontiers[1], categories, type_plot, names_set[1])
    else
        fig = __nd_scatter(set_of_frontiers, categories, type_plot, names_set)
    end
    return fig
end

function scatter_plot(frontier_set::Matrix{F}, categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)];
    is_3d::Bool=false, name::String="Method", type_plot::String="markers+lines") where {F<:Number}
    fig = nothing
    if size(frontier_set, 1) == 2
        fig = __2d_scatter(frontier_set, categories, type_plot, name)
    elseif size(frontier_set, 1) == 3 && is_3d
        fig = __3d_scatter(frontier_set, categories, type_plot, name)
    else
        fig = __nd_scatter(frontier_set, categories, type_plot, name)
    end
    return fig
end

###################
# Intra functions #
###################


function __2d_scatter(frontiers, categories, type_plot, names)
    fig = plot(
        Layout(
            yaxis_title=categories[2], xaxis_title=categories[1]
        )
    )
    if typeof(frontiers) <: Matrix
        __2d_scatter!(fig, frontiers, type_plot, names)
    else
        for (k, set) in enumerate(frontiers)
            __2d_scatter!(fig, set, type_plot, names[k])
        end
    end
    return fig
end


function __2d_scatter!(fig, frontier_set::Matrix{F}, type_plot::String, name::String) where {F<:Number}
    x = view(frontier_set, 1, :)
    order = sortperm(x)
    add_trace!(fig,
        scatter(
            x=view(frontier_set, 1, order),
            y=view(frontier_set, 2, order),
            mode=type_plot,
            name=name
        ),
    )
    return fig
end

function __3d_scatter(frontier_set::Matrix{F}, categories, type_plot, name) where {F<:Number}
    fig = plot(
        scatter(
            x=frontier_set[1, :],
            y=frontier_set[2, :],
            z=frontier_set[3, :],
            mode=type_plot, type="scatter3d", name=name
        ),
    )
end


function __3d_scatter(frontier_set::Vector{Matrix{F}}, categories, type_plot, name) where {F<:Number}
    error("Still not defined for a set of frontiers, only for a frontier")
end

function __nd_scatter(frontiers, categories, type_plot, name)
    m = length(categories)
    fig = make_subplots(
        rows=m, cols=m,
        subplot_titles=[f_1 * " × " * f_2 for (f_1, f_2) in Iterators.product(categories, categories)]
    )
    if typeof(frontiers) <: Matrix
        __nd_scatter!(fig, frontiers, type_plot, name, 1)
    else
        for (idx, set) in enumerate(frontiers)
            __nd_scatter!(fig, set, type_plot, name[idx], idx)
        end
    end
    return fig
end


function __nd_scatter!(fig, frontier_set::Matrix{F}, type_plot, name, id) where {F<:Number}
    global COLORS_SET

    first_trace = true
    for i_1 in axes(frontier_set, 1)
        for i_2 in axes(frontier_set, 1)
            if i_1 == i_2
                continue
            end
            x = view(frontier_set, i_1, :)
            order = sortperm(x)
            color = COLORS_SET[mod1(id, length(COLORS_SET))]
            add_trace!(
                fig,
                scatter(
                    x=frontier_set[i_1, order],
                    y=frontier_set[i_2, order],
                    mode=type_plot,
                    marker=attr(color=color),
                    line=attr(color=color), legendgroup=name,
                    name=name,
                    showlegend=first_trace
                ),
                row=i_1, col=i_2,
            )
            first_trace = false
        end
    end
    return fig
end
