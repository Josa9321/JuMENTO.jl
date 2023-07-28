using Jumento, JuMP, CPLEX
include("test//runtests.jl")

function save_instances_results(; files_names, num_objs, solve_instance, folder)
    for file in files_names
        address = folder*file
        frontier, report = solve_instance(address)
        Jumento.save_results_XLSX(frontier, report, file_path = file)
        println("Instance $file saved")
    end
    return nothing
end

# test_instances(files_names=["2kp50.xlsx"], num_objs=2, compare_payoff = true,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )

# test_instances(files_names=["3kp50.xlsx"], num_objs=3, compare_payoff = false,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )

# save_instances_results(files_names = ["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"], num_objs = 2, solve_instance = solve_kp_instance, folder = "test//mokp//instances//")#, "2kp500.xlsx", "2kp750.xlsx"], num_objs = 2, solve_instance = solve_kp_instance, folder = "test//mokp//instances//")
# save_instances_results(files_names = ["3kp40.xlsx", "3kp50.xlsx"], num_objs = 3, solve_instance = solve_kp_instance, folder = "test//mokp//instances//")
# save_instances_results(files_names = ["4kp40.xlsx", "4kp50.xlsx"], num_objs = 4, solve_instance = solve_kp_instance, folder = "test//mokp//instances//")