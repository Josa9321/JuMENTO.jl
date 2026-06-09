using Test, Aqua

using jumento

Aqua.test_all(jumento)

include("test_metrics.jl")
include("methods/test_augmecon.jl")

