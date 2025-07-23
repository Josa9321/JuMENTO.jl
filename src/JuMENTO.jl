module JuMENTO

using JuMP
using Plots
using CSV
using Printf
using PrettyTables
using LinearAlgebra
using Statistics

include("structs.jl")
include("dominance_relations.jl")
include("options.jl")
include("augmecon.jl")
include("metrics.jl")
include("test_metrics.jl")

export augmecon, SolutionJuMP, SolveReport, get_objectives, test_with_get, spacing_metric, general_distance, diversity_metric, error_ratio, calculate_error_metrics, hypervolume

end