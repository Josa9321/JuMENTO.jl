module Jumento

using JuMP, DataFrames, XLSX, CSV

import Combinatorics: permutations

include("structs.jl")
include("dominance_relations.jl")
include("options.jl")
include("augmecon.jl")
include("solve_data.jl")

export augmecon, SolutionJuMP, SolveReport, get_objectives

end