"""
    level_diagrams(set_of_frontiers::Vector{Matrix{F}};
        sense_set=fill(:max, size(set_of_frontiers[1], 1)),
        categories::Vector{String}=["f_\$(i)" for i in axes(set_of_frontiers[1], 1)],
        name_set::Vector{String}=["Method \$(k)" for k in eachindex(set_of_frontiers)],
        type_plot::String="markers+lines",
        p=2) where {F<:Number}

Create level diagrams for a collection of Pareto frontiers.

Each element of `set_of_frontiers` must follow the `m × n` convention,
where rows correspond to objectives and columns correspond to solutions.

For each objective, a subplot is generated in which:
- The x-axis represents the values of that objective across the solutions.
- The y-axis represents the distance from each solution to the ideal point,
  computed using the `p`-norm.

Arguments:
- `sense_set` indicates whether each objective is to be maximized or minimized.
- `categories` defines the labels for each objective.
- `name_set` defines the labels for each frontier (e.g., different methods).
- `type_plot` specifies the scatter style (e.g., `"markers"`, `"lines"`,
  or `"markers+lines"`).
- `p` specifies the norm used to compute the distance to the ideal point.

Level diagrams are useful for simultaneously analyzing convergence
(distance to the ideal point) and distribution along each objective.
"""
function level_diagrams(set_of_frontiers::Vector{Matrix{F}};
    sense_set=fill(:max, size(set_of_frontiers[1], 1)),
    categories::Vector{String}=["f_$(i)" for i in axes(set_of_frontiers[1], 1)],
    name_set::Vector{String}=["Method $(k)" for k in eachindex(set_of_frontiers)],
    type_plot::String="markers+lines",
    p=2) where {F<:Number}

    m = size(set_of_frontiers[1], 1)
    @assert all(f -> size(f, 1) == m, set_of_frontiers) "Not all frontiers have the same number of objectives (rows)"

    fig = make_subplots(
        cols=m,
        subplot_titles=categories[:, :]
    )

    normalized_set_of_frontiers = __normalize_sets(set_of_frontiers, sense_set)
    for (idx, set) in enumerate(set_of_frontiers)
        __level_diagrams!(fig, set, normalized_set_of_frontiers[idx], type_plot, name_set[idx], idx)
    end
    return fig
end

"""
    level_diagrams(frontier_set::Matrix{F};
        sense_set=fill(:max, size(frontier_set, 1)),
        categories::Vector{String} = ["f_\$(i)" for i in axes(frontier_set, 1)],
        name::String = "Method",
        type_plot::String = "markers+lines",
        p = 2) where {F <: Number}

Create level diagrams for a single Pareto frontier.

The `frontier_set` must follow the `m × n` convention, where rows correspond
to objectives and columns correspond to solutions.

For each objective, a subplot is generated in which:
- The x-axis represents the values of that objective across the solutions.
- The y-axis represents the distance from each solution to the ideal point,
  computed using the `p`-norm.

Arguments:
- `normalized_set` is the normalized version of the frontier. If not
  explicitly provided, the function normalizes the frontier before
  computing distances to the ideal point, assuming maximization objectives.
- `categories` defines the labels for each objective.
- `name` specifies the label of the frontier (e.g., the method name).
- `type_plot` specifies the scatter style (e.g., `"markers"`, `"lines"`,
  or `"markers+lines"`).
- `p` specifies the norm used to compute the distance to the ideal point.

Level diagrams provide a visual assessment of both convergence
(distance to the ideal point) and distribution along each objective.
"""
function level_diagrams(frontier_set::Matrix{F};
    sense_set=fill(:max, size(frontier_set, 1)),
    categories::Vector{String}=["f_$(i)" for i in axes(frontier_set, 1)],
    name::String="Method",
    type_plot::String="markers+lines",
    p=2) where {F<:Number}

    m = size(frontier_set, 1)

    fig = make_subplots(
        cols=m,
        subplot_titles=categories[:, :]
    )

    normalized_set = normalize_frontier(frontier_set, sense_set)
    __level_diagrams!(fig, frontier_set, normalized_set, type_plot, name, 1)
    return fig
end

function __normalize_sets(set_of_frontiers, sense_set)
    minimum_point = minimum(hcat(minimum.(set_of_frontiers, dims=2)...), dims=2)
    maximum_point = maximum(hcat(maximum.(set_of_frontiers, dims=2)...), dims=2)
    result = Vector{typeof(set_of_frontiers[1])}(undef, length(set_of_frontiers))
    for (k, set) in enumerate(set_of_frontiers)
        result[k] = normalize_frontier(set, sense_set, min_point=minimum_point, max_point=maximum_point)
    end
    return result
end

function get_common_yaxis_LD(normalized_set; p=2)
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
            PlotlyJS.scatter(
                x=frontier_set[i, order],
                y=y[order],
                mode=type_plot,
                marker=attr(color=color),
                line=attr(color=color), legendgroup=name,
                name=name,
                showlegend=first_trace
            ),
            col=i
        )
        first_trace = false
    end
    return fig
end
