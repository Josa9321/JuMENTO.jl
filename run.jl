using Jumento, JuMP
# include("src//Jumento.jl")
# include("ignore_for_now//runtests.jl")
include("test//runtests.jl")

# m_simple, obj_simple = simple_biobjective_problem()
# frontier, report = augmecon(m_simple, obj_simple, grid_points = 10, objective_sense_set = ["Max", "Max"]);
# nothing
# Jumento.save_results_XLSX(frontier, report, file_path = "simple_biobjective")
# Jumento.save_results_csv(frontier, report, file_path = "simple_biobjective")

# model_3, objectives_3 = simple_triobjective_problem()
# frontier_3, report_3 = augmecon(model_3, objectives_3, grid_points = 15, objective_sense_set = ["Min", "Min", "Min"])
# Jumento.save_results_XLSX(frontier_3, report_3, file_path = "simple_triobjective")
# Jumento.save_results_csv(frontier_3, report_3, file_path = "simple_triobjective")


# addresses_set = [
#     "ignore_for_now//knapsack//instances//2kp50.xlsx",
#     # "ignore_for_now//knapsack//instances//2kp100.xlsx",
#     "ignore_for_now//knapsack//instances//2kp250.xlsx",
#     # "ignore_for_now//knapsack//instances//2kp500.xlsx",
#     # "ignore_for_now//knapsack//instances//2kp750.xlsx",
#     # "ignore_for_now//knapsack//instances//3kp40.xlsx",
#     # "ignore_for_now//knapsack//instances//3kp50.xlsx",
#     # "ignore_for_now//knapsack//instances//4kp40.xlsx",
#     # "ignore_for_now//knapsack//instances//4kp50.xlsx"
# ]


# frontier = []
# for instance_address in addresses_set
#     name_indices = findlast("//", instance_address)[end]+1:findfirst(".", instance_address)[end]-1
#     instance_name = instance_address[name_indices]
#     instance = KnapsackInstance(instance_address)
#     model, objs = knapsack_model(instance)
#     println("Solving ", instance_name)
#     global frontier
#     frontier, m, table = augmecon(model, objs, grid_points = 10)
#     objectives = zeros(length(frontier), instance.O[end])
#     for (i, solution) in enumerate(frontier)
#         for (j, obj_j) in enumerate(solution.objectives)
#             objectives[i, j] = obj_j
#         end
#     end

#     this_objs_table = DataFrame(objectives, ["obj_$(j)" for j in axes(objectives, 2)])
#     this_payoff_table = DataFrame(table, ["obj_$(j)" for j in axes(objectives, 2)])


#     XLSX.openxlsx("$(instance_name)_solution.xlsx", mode="w") do xf
#         obj_sheet = xf[1]
#         XLSX.rename!(obj_sheet, "objs")
#         XLSX.writetable!(obj_sheet, this_objs_table)

#         XLSX.addsheet!(xf)
#         payoff_sheet = xf[2]
#         XLSX.rename!(payoff_sheet, "payoffs")
#         XLSX.writetable!(payoff_sheet, this_payoff_table)
#     end
# end