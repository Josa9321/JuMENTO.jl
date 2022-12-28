function init_knapsack_variables(instance::KnapsackInstance)
    x = zeros(num_variables(instance))
    return KnapsackVariables(x)
end

function init_model(;gap, time_limit, log)
    model = Model(
        optimizer_with_attributes(CPLEX.Optimizer, 
            "CPXPARAM_MIP_Tolerances_MIPGap" => gap, 
            "CPX_PARAM_TILIM" => time_limit, 
            "CPX_PARAM_SCRIND" => log, 
            "CPX_PARAM_THREADS" => 2
        )
    )
    return model
end