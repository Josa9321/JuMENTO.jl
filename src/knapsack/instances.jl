function load_instance(address)
    objectives_coefs = load_knapsack_sheet(address, 3)
    constraints_coefs = load_knapsack_sheet(address, 1)
    RHS = load_knapsack_sheet(address, 2)
    
    I = Base.OneTo(num_variables(constraints_coefs))
    J = Base.OneTo(num_constraints(RHS))
    O = Base.OneTo(num_objectives(objectives_coefs))

    return KnapsackInstance(
        objectives_coefs, 
        constraints_coefs, 
        RHS,
        I, 
        J, 
        O
    )
end

function load_knapsack_sheet(address, sheet_number)
    # 2:end is to read all the sheet without the indexes
    return copy(Float64.(XLSX.readxlsx(address)[sheet_number][:][2:end, 2:end])')
end

function num_variables(coefs)
    return size(coefs, 1)
end

function num_variables(instance::KnapsackInstance)
    return instance.I.stop
end

function num_constraints(RHS)
    return length(RHS)
end

function num_constraints(instance::KnapsackInstance)
    return instance.J.stop
end

function num_objectives(objectives_coefs)
    return size(objectives_coefs, 2)
end

function num_objectives(instance::KnapsackInstance)
    return instance.O.stop
end