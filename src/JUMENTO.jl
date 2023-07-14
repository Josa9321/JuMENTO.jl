module JUMENTO

using JuMP

import Combinatorics: permutations

include("structs.jl")
include("dominance_relations.jl")
include("augmecon.jl")

export augmecon

end