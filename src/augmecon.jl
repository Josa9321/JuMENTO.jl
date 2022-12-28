function solve_by_augmecon(instance, model, objectives; grid_points, penalty = 1e-3,
    init_variables = init_no_variables, register_variables! = register_no_variables!)

    aux_augmecon = set_aux_augmecon(model, objectives, grid_points = grid_points, penalty = penalty, 
        init_variables = init_variables, register_variables! = register_variables!)
    
    objectives_rhs = set_objectives_rhs_range(aux_augmecon)
    set_model_for_augmecon!(aux_augmecon, objectives_rhs)
    
    frontier = SolutionJuMP[]
    recursive_augmecon!(aux_augmecon, frontier, objectives_rhs, instance)
    return generate_pareto(frontier), aux_augmecon.augmecon_model
end

function set_objectives_rhs_range(aux_augmecon::AuxAUGMECON)
    O = Base.OneTo(aux_augmecon.num_objectives)
    table = payoff_table(aux_augmecon) 
    maximum_o = [maximum(table[:, o]) for o in O]
    minimum_o = [minimum(table[:, o]) for o in O]
    return [range(minimum_o[o], maximum_o[o], length = ((maximum_o[o] - minimum_o[o]) != 0.0 ? aux_augmecon.grid_points : 1)) for o in O]
end

function payoff_table(aux_augmecon::AuxAUGMECON)
    @assert length(aux_augmecon.augmecon_model.objectives) >= 2 "The model has only 1 objective"
    @assert all(JuMP.is_valid.(Ref(aux_augmecon.augmecon_model.model), aux_augmecon.augmecon_model.objectives)) "At least one objective isn't defined in the model as a constraint"

    table = zeros(aux_augmecon.num_objectives, aux_augmecon.num_objectives)
    for (i, obj_higher) in enumerate(aux_augmecon.augmecon_model.objectives)
        optimize_and_fix!(aux_augmecon.augmecon_model, obj_higher)
        for (o, obj_minor) in enumerate(aux_augmecon.augmecon_model.objectives)
            if i != o
                optimize_and_fix!(aux_augmecon.augmecon_model, obj_minor)
            end
        end
        save_on_table!(table, i, aux_augmecon)
        delete_lower_bound.(aux_augmecon.augmecon_model.objectives)
    end
    @objective(aux_augmecon.augmecon_model.model, Max, 0.0)
    return table
end

function save_on_table!(table, i::Int64, aux_augmecon::AuxAUGMECON)
    for o in Base.OneTo(aux_augmecon.num_objectives)
        table[i, o] = lower_bound(aux_augmecon.augmecon_model.objectives[o])
    end
    return table
end

function optimize_and_fix!(augmecon_model::AugmeconJuMP, objective)
    @objective(augmecon_model.model, Max, objective)
    optimize_augmecon!(augmecon_model)
    set_lower_bound(objective, objective_value(augmecon_model.model))
    return nothing
end

function set_model_for_augmecon!(aux_augmecon::AuxAUGMECON, objectives_rhs)
    O = 2:aux_augmecon.num_objectives
    @variable(aux_augmecon.augmecon_model.model, 
        s[O] >= 0)
        
    @objective(aux_augmecon.augmecon_model.model, Max, aux_augmecon.augmecon_model.objectives[1] + 
    aux_augmecon.penalty*sum((objectives_rhs_range(objectives_rhs, o) > 0.0 ? s[o]/objectives_rhs_range(objectives_rhs, o) : 0.0) for o in O))
    
    @constraint(aux_augmecon.augmecon_model.model, other_objectives[o in O], 
        aux_augmecon.augmecon_model.objectives[o] - s[o] == 0.0)
    return nothing
end

function objectives_rhs_range(objectives_rhs, o)
    return objectives_rhs[o][end] - objectives_rhs[o][1]
end

function recursive_augmecon!(aux_augmecon::AuxAUGMECON, frontier, objectives_rhs, instance; o = 2)
    for eps in objectives_rhs[o]
        set_normalized_rhs(aux_augmecon.augmecon_model.model[:other_objectives][o], eps)
        if o < aux_augmecon.num_objectives
            recursive_augmecon!(aux_augmecon, frontier, objectives_rhs, instance, o = o + 1)
        else
            optimize_augmecon!(aux_augmecon.augmecon_model)
            if JuMP.has_values(aux_augmecon.augmecon_model.model)
                push!(frontier, register_solution(aux_augmecon, instance))
            else
                break
            end
        end
    end
    return nothing
end

function optimize_augmecon!(augmecon_model::AugmeconJuMP)
    optimize!(augmecon_model.model)
    augmecon_model.time += solve_time(augmecon_model.model)
    augmecon_model.iterations_counter += 1
    return augmecon_model
end