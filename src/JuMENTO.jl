module JuMENTO

using JuMP, Printf, LinearAlgebra, Statistics, Random
import MultiObjectiveAlgorithms as MOA
import MultiObjectiveAlgorithms: MOI

export normalize_frontier, Metrics, MultiPlots, MethodAUGMECON

include("utils/normalize.jl")

include("MethodAUGMECON/MethodAUGMECON.jl")

include("Metrics/Metrics.jl")
include("Plots/MultiPlots.jl")

include("utils/print_msgs.jl")

end
