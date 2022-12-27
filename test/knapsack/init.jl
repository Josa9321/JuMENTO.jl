function init_augmecon_variables(instance::KnapsackInstance)
    x = zeros(num_variables(instance))
    return KnapsackVariables(x)
end
