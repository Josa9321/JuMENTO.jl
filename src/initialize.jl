function set_aux_augmecon(model, objectives; grid_points, penalty = 1e-3, 
    init_variables = init_no_variables, register_variables! = register_no_variables!)
    augmecon_model = set_augmecon_model(model, objectives)
    return AuxAUGMECON(
        augmecon_model,
        grid_points,
        penalty,
        length(objectives),
        init_variables,
        register_variables!
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

function init_solution(instance, aux_augmecon::AuxAUGMECON)
    variables = aux_augmecon.init_variables(instance)
    objectives = zeros(aux_augmecon.num_objectives)
    return SolutionJuMP(variables, objectives)
end

function init_no_variables(instance)
    return NoVariables()
end
function register_no_variables!(solution, augmecon_model, instance)
    return nothing
end