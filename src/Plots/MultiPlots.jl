"""
    MultiPlots

This module provides visual representations of Pareto frontiers to analyze and compare the performance of different solutions or algorithms in a multi-objective optimization context.

The module includes the following visualization tools:
- `parallel_coordinates` plot;
- `radar` chart;
- `scatter` plot; and
- `level_diagram` plot.

The module relies on the PlotlyJS library for interactive plotting.
The `COLORS_SET` constant provides a predefined set of 25 colors for consistent and visually appealing plots - if the number of needed colors exceeds this set, it will cycle through the colors.
"""
module MultiPlots

using PlotlyJS, LinearAlgebra

import ..JuMENTO.normalize_frontier

const COLORS_SET = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
    "#393b79", "#637939", "#8c6d31", "#843c39", "#7b4173",
    "#3182bd", "#31a354", "#756bb1", "#636363", "#e6550d",
    "#969696", "#9c9ede", "#cedb9c", "#e7ba52", "#ad494a"
]

include("parallel_coordinates.jl")
include("radar.jl")
include("scatter.jl")
include("level_diagrams.jl")

end
