module JUMENTO

using JuMP

import Combinatorics: permutations

include("structs.jl")
include("dominance_relations.jl")
include("augmecon.jl")
# include("weighted_sum.jl")

export augmecon

end

#===================
= When using, if I want to save the solution, I need to declare:
 * Variable <: VariablesJuMP
 * init_augmecon_variables(instance)
 * register_variables!(solution, augmecon_model, instance)
=#