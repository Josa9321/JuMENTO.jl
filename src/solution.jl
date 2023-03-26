function register_solution(aux_method::MultiobjectiveAux, instance)
    solution = init_solution(instance, aux_method)
    aux_method.register_variables!(solution, aux_method.augmecon_model, instance)
    register_objetives!(solution, aux_method)
    return solution
end

function register_objetives!(solution::SolutionJuMP, aux_method::MultiobjectiveAux)
    for o in Base.OneTo(aux_method.num_objectives)
        solution.objectives[o] = value(aux_method.augmecon_model.objectives[o])
    end
    return solution
end