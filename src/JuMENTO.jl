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

# Colocar em um módulo os métodos da família AUGMECON
# Colocar em um módulo as heurísticas
# Reaproveitar funções declaradas para o AUGMECON para serem usadas nas heurísticas
# Colocar em um módulos os plots e as métricas

include("options.jl")


include("augmecon.jl")
include("Metrics.jl")
include("save_results_and_plot.jl")

include("nsga2_options.jl")
include("nsga2.jl")

include("utils.jl")

export augmecon, nsga2, Metrics, SolutionJuMP, ReportAUG, save_results_to_file, plot_result

end
