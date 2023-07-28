using Jumento

include("optimization_models.jl")
include("tests.jl")
include("mokp//load.jl")

# test_instances(files_names=["2kp50.xlsx", "2kp100.xlsx", "2kp250.xlsx"], num_objs=2,
#     solve_instance = solve_kp_instance, folder = "mokp//instances//"
# )
# test_instances(files_names=["3kp40.xlsx", "3kp50.xlsx"], num_objs=3,
#     solve_instance = solve_kp_instance, folder = "test//mokp//instances//"
# )