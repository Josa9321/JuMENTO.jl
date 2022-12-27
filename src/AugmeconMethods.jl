module AugmeconMethods
include("structs.jl")
include("initialize.jl")
include("non_dominated_with_sol.jl")


include("augmecon.jl")

export solve_by_augmecon

end