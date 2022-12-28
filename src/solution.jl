function register_solution(aux_augmecon::AuxAUGMECON, instance)
    solution = init_solution(instance, aux_augmecon)
    aux_augmecon.register_variables!(solution, aux_augmecon.augmecon_model, instance)
    register_objetives!(solution, aux_augmecon.augmecon_model, instance)
    return solution
end

function register_objetives!(solution::SolutionJuMP, augmecon_model::AugmeconJuMP, instance)
    for o in Base.OneTo(num_objectives(instance))
        solution.objectives[o] = value(augmecon_model.objectives[o])
    end
    return solution
end