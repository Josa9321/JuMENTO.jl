module JuMENTO

using JuMP
import MathOptInterface as MOI 

using Plots
using Printf
using LinearAlgebra
using Statistics
using Random

include("structs.jl")
include("dominance_relations.jl")

include("options.jl")
include("augmecon.jl")
include("metrics.jl")
include("save_results_and_plot.jl")

include("nsga2_options.jl")
include("nsga2.jl")

include("utils.jl")

export augmecon, SolutionJuMP, SolveReport, get_objectives, test_with_get, spacing_metric, general_distance, diversity_metric, error_ratio, calculate_error_metrics, hypervolume, save_results_to_file, plot_result, nsga2

end