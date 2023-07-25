using Jumento

include("optimization_models.jl")
include("mokp//load.jl")

# test_instances(files_names=["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"], num_objs=2,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )
# test_instances(files_names=["3kp40.xlsx", "3kp50.xlsx", "3kp100.xlsx"], num_objs=3,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )
# test_instances(files_names=["4kp40.xlsx", "4kp50.xlsx"], num_objs=4,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )