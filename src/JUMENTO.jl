module JUMENTO

using JuMP, DataFrames, XLSX, CSV

import Combinatorics: permutations

include("structs.jl")
include("dominance_relations.jl")
include("augmecon.jl")
include("solve.jl")

export augmecon, SolutionJuMP, get_objectives

end