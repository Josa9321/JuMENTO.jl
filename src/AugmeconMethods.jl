module AugmeconMethods

using JuMP, XLSX, CPLEX

import Combinatorics: permutations

include("structs.jl")
include("solution.jl")
include("initialize.jl")
include("dominance_relations.jl")
include("augmecon.jl")

include("knapsack//load.jl")

export solve_by_augmecon

end