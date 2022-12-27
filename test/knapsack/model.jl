using XLSX

include("structs.jl")
include("instances.jl")

function knapsack_model(instance::KnapsackInstance)
    model = Model()
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

