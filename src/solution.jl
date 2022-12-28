function register_solution(aux_augmecon::AuxAUGMECON, instance)
    solution = init_solution(instance, aux_augmecon)
    aux_augmecon.register_variables!(solution, aux_augmecon.augmecon_model, instance)
    register_objetives!(solution, aux_augmecon.augmecon_model)
    return solution
end

function register_objetives!(solution::SolutionJuMP, aux_augmecon::AuxAUGMECON)
    for o in Base.OneTo(aux_augmecon.num_objectives)
        solution.objectives[o] = value(aux_augmecon.augmecon_model.objectives[o])
    end
    return solution
end