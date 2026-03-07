module JuMENTO

using JuMP, Printf, LinearAlgebra, Statistics, Random
import MathOptInterface as MOI

export generate_pareto, normalize_frontier, Metrics, MultiPlots, SolutionJuMP, ReportAUG, augmecon, nsga2

include("utils/structs.jl")
include("utils/dominance_relations.jl")
include("utils/normalize.jl")

# Colocar em um módulo os métodos da família AUGMECON
# Colocar em um módulo as heurísticas
# Reaproveitar funções declaradas para o AUGMECON para serem usadas nas heurísticas

include("MethodAUGMECON/options.jl")
include("MethodAUGMECON/augmecon.jl")

include("MethodNSGA/nsga2_options.jl")
include("MethodNSGA/nsga2.jl")

include("Metrics/Metrics.jl")
include("Plots/MultiPlots.jl")

include("utils/print_msgs.jl")

end
