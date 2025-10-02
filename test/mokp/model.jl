function knapsack_model(instance::KnapsackInstance)
    model = init_configured_model()
    @variable(model, x[instance.I], Bin)
    
    @constraint(model, c[j in instance.J], 
        sum(instance.constraints_coefs[i, j] * x[i] for i in instance.I) <= instance.RHS[j])

    @objective(model, Max, [sum(instance.objectives_coefs[i, o] * x[i] for i in instance.I) for o in instance.O])
    return model
end

function init_configured_model()
    result = Model(HiGHS.Optimizer)
    # set_attribute(result, "presolve", "on")
    set_silent(result)
    set_time_limit_sec(result, 60.0)
    return result
end