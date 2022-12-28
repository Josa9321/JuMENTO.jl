function register_knapsack!(solution, augmecon_model::AugmeconJuMP, instance::KnapsackInstance)
    for i in Base.OneTo(num_variables(instance))
        solution.variables.x[i] = value(augmecon_model.model[:x][i])
    end
    return solution
end