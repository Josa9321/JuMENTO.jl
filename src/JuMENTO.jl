module JuMENTO

using JuMP, Printf, LinearAlgebra, Statistics, Random
import MathOptInterface as MOI
import MultiObjectiveAlgorithms as MOA

export generate_pareto, normalize_frontier, Metrics, MultiPlots, SolutionJuMP, ReportAUG, augmecon, nsga2, MethodAUGMECON

include("utils/structs.jl")
include("utils/dominance_relations.jl")
include("utils/normalize.jl")

# Colocar em um módulo os métodos da família AUGMECON
# Colocar em um módulo as heurísticas
# Reaproveitar funções declaradas para o AUGMECON para serem usadas nas heurísticas

include("MethodAUGMECON/MethodAUGMECON.jl")

include("MethodAUGMECON/options.jl")
include("MethodAUGMECON/augmecon.jl")
# include("MethodAUGMECON/aug-moa.jl")

include("MethodNSGA/nsga2_options.jl")
include("MethodNSGA/nsga2.jl")

include("Metrics/Metrics.jl")
include("Plots/MultiPlots.jl")

include("utils/print_msgs.jl")

end
