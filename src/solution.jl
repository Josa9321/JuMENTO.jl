function register_solution(augmecon_model::AugmeconJuMP, instance)
    solution = init_solution(instance)
    register_variables!(solution, augmecon_model, instance)
    register_objetives!(solution, augmecon_model, instance)
    return solution
end

function register_objetives!(solution::SolutionJuMP, augmecon_model::AugmeconJuMP, instance)
    for o in Base.OneTo(num_objectives(instance))
        solution.objectives[o] = value(augmecon_model.objectives[o])
    end
    return solution
end