module JuMENTO

using JuMP

include("structs.jl")
include("dominance_relations.jl")
include("options.jl")
include("augmecon.jl")

export augmecon, SolutionJuMP, SolveReport, get_objectives

end