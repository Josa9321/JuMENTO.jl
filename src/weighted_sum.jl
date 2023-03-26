mutable struct WeightedSumJuMP{M, V, N <: Integer, F <: AbstractFloat}
    model::M
    objectives::Vector{V}
    weights::Vector{N}
    iterations_counter::N
    time::F
    gap::F

    WeightedSumJuMP(model::M, objectives::V) where {M, V} = begin 
            set_model_for_weighted_sum!(model, objectives)

            new{M, V, Int64, FLoat64}(
            model,
            objectives,
            init_weights(objectives),
            0,
            0.0,
            0.0
        )
    end
end

function set_model_for_weighted_sum!(model, objectives)
    @objective(model, Max, sum(objectives))
end

function init_weights(objectives)
    result = zeros(length(objectives))
    result[end] = 1.0
    return result
end

num_objectives(weighted_sum_model::WeightedSumJuMP) = length(weighted_sum_model.objectives)

struct AuxWeightedSum{M, M1, M2, N <: Integer}
    weighted_sum_model::M
    init_variables::M1
    register_variables!::M2
    num_objectives::N

    AuxWeightedSum(
        model, objectives; 
        init_variables::M1 = init_no_variables, 
        register_variables!::M2 = register_no_variables!
    ) where {M1, M2} = begin 
        weighted_sum_model = WeightedSumJuMP(model, objectives)

        model_type = typeof(weighted_sum_model)
        new{model_type, M1, M2, Int64}(weighted_sum_model, init_variables, register_variables!, num_objectives(weighted_sum_model))
    end
end

function solve_by_weighted_sum(instance, model, objectives; grid_points, penalty = 1e-3,
        init_variables = init_no_variables, register_variables! = register_no_variables!)
    
    aux_weighted_sum = AuxWeightedSum(model, objectives, init_variables = init_variables, register_variables! = register_variables!)
    frontier = find_extreme_points(aux_weighted_sum)
    if no_dominated_or_equal_in_extreme_pareto(frontier)
        recursive_sum!(aux_augmecon, frontier, instance)
    end
    return generate_pareto(frontier), aux_augmecon.augmecon_model
end

function find_extreme_points(aux_weighted_sum::AuxWeightedSum)
    frontier = SolutionJuMP[]
    for i in Base.OneTo(aux_weighted_sum.num_objectives)
        set_extreme_weights!(aux_weighted_sum, priority_index)
        set_objective_weights!(aux_weighted_sum)
        optimize_mo_method_model!(aux_weighted_sum.weighted_sum_model)
        if JuMP.has_values(model)
            push!(frontier, register_solution(aux_augmecon, instance))
        end
    end
    return frontier
end

no_dominated_or_equal_in_extreme_pareto(a_pareto_extreme_set) = length(a_pareto_extreme_set) > 1



function recursive_sum!(aux_augmecon, frontier, instance)

end


function set_extreme_weights!(an_aux_weighted_sum::AuxWeightedSum, priority_index)
    aux_weighted_sum.model.weights .= 0.0
    aux_weighted_sum.model.weights[priority_index] = 1.0
    return nothing
end

function set_objective_weights!(an_aux_weighted_sum::AuxWeightedSum)
    weighted_sum_model = an_aux_weighted_sum.weighted_sum_model
    set_objective_coefficient.(
        Ref(weighted_sum_model.model), 
        weighted_sum_model.objectives, 
        weighted_sum_model.weights
    )
    return nothing
end