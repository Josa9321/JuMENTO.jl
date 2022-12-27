function test_initialize()
    model = Model()
    @variable(model, a[1:3])
    aux_augmecon = set_aux_augmecon(model, a, solution_type = KnapsackVariables, grid_points = 5)
    return nothing
end