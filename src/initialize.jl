function set_aux_augmecon(model, objectives; grid_points, penalty = 1e-3)
    augmecon_model = set_augmecon_model(model, objectives)
    return AuxAUGMECON(
        augmecon_model,
        grid_points,
        penalty,
        length(objectives)
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