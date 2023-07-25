using Jumento, JuMP, CPLEX
include("test//runtests.jl")

# instance = KnapsackInstance("test//mokp//instances//2kp250.xlsx")
# model, objs = knapsack_model(instance)

# @objective(model, Max, objs[1])
# @constraint(model, seiLa, objs[2] == 10095)
# optimize!(model)

# f, report = solve_kp_instance("test//mokp//instances//2kp250.xlsx", 
#     objectives_sense = ["Max" for i in Base.OneTo(2)]
# )