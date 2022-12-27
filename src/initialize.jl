function set_aux_augmecon(model, objectives; solution_type, grid_points)
    augmecon_model = set_augmecon_model(model, objectives)
    return AuxAUGMECON(
        augmecon_model,
        solution_type,
        grid_points
    )
end

function set_augmecon_model(model, objectives)
    return AugmeconJuMP(
        model,
        objectives,
        0,
        0.0,
        0.0
    )
end

function init_solution(instance)
    variables = init_augmecon_variables(instance)
    objectives = zeros(num_objectives(instance))
    return SolutionJuMP(variables, objectives)
end