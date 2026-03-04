module JuMENTO

using JuMP
import MathOptInterface as MOI

using Printf
using LinearAlgebra
using Statistics
using Random

include("structs.jl")
include("dominance_relations.jl")
include("normalize.jl")
include("options.jl")

# Colocar em um módulo os métodos da família AUGMECON
# Colocar em um módulo as heurísticas
# Reaproveitar funções declaradas para o AUGMECON para serem usadas nas heurísticas

include("augmecon.jl")

include("nsga2_options.jl")
include("nsga2.jl")

include("Metrics/Metrics.jl")
include("Plots/MultiPlots.jl")

include("utils.jl")

export normalize_frontier, Metrics, MultiPlots, SolutionJuMP, ReportAUG, augmecon, nsga2

end
