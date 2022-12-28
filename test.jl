using AugmeconMethods
aug = AugmeconMethods

instance = aug.load_instance("src//knapsack//instances//2kp50.xlsx")
model, objs = aug.knapsack_model(instance)

frontier = solve_by_augmecon(instance, model, objs, grid_points = 492, register_variables! = aug.register_knapsack!, init_variables = aug.init_knapsack_variables)