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
