using CPLEX
function knapsack_model(instance::KnapsackInstance)
    model = init_configured_model()
    @variables model begin 
        x[instance.I], Bin
        obj[instance.O]
    end
    @constraints model begin 
        c[j in instance.J], 
            sum(instance.constraints_coefs[i, j] * x[i] for i in instance.I) <= instance.RHS[j]
        objectives[o in instance.O],
            sum(instance.objectives_coefs[i, o] * x[i] for i in instance.I) == obj[o]
    end
    return model, obj
end

function init_configured_model()
    result = Model(CPLEX.Optimizer)
    set_silent(result)
    set_time_limit_sec(result, 60.0)
    return result
end