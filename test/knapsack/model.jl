function knapsack_model(instance::KnapsackInstance)
    model = init_model(gap = 1e-4, time_limit = 50.0, log = 0)
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

