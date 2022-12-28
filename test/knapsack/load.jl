using JuMP, CPLEX, XLSX

include("structs.jl")
include("init.jl")
include("instances.jl")
include("model.jl")
include("solution.jl")


include("test.jl")
include("test_payoff_table.jl")
include("test_pareto_set.jl")
include("test_objectives_e_set.jl")