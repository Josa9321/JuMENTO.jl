function augmecon(model, objectives; grid_points, penalty = 1e-3)
    augmecon_model = AugmeconJuMP(model, objectives, grid_points; penalty=penalty)
    table = payoff_table(augmecon_model) 
    objectives_rhs = set_objectives_rhs_range(augmecon_model, table)
    set_model_for_augmecon!(augmecon_model, objectives_rhs)
    
    frontier = SolutionJuMP[]
    recursive_augmecon!(augmecon_model, frontier, objectives_rhs)
    return generate_pareto(frontier), augmecon_model, table
end

function payoff_table(augmecon_model::AugmeconJuMP)
    objectives = augmecon_model.objectives
    @assert length(objectives) >= 2 "The model has only 1 objective"
    @assert all(JuMP.is_valid.(Ref(augmecon_model.model), objectives)) "At least one objective isn't defined in the model as a constraint"

    table = zeros(num_objectives(augmecon_model), num_objectives(augmecon_model))
    for (i, obj_higher) in enumerate(objectives)
        optimize_and_fix!(augmecon_model, obj_higher)
        for (o, obj_minor) in enumerate(objectives)
            if i != o
                optimize_and_fix!(augmecon_model, obj_minor)
            end
        end
        save_on_table!(table, i, augmecon_model)
        delete_lower_bound.(objectives)
    end
    @objective(augmecon_model.model, Max, 0.0)
    return table
end

function set_objectives_rhs_range(augmecon_model::AugmeconJuMP, table)
    O = Base.OneTo(num_objectives(augmecon_model))
    maximum_o = [maximum(table[:, o]) for o in O]
    minimum_o = [minimum(table[:, o]) for o in O]
    return [range(minimum_o[o], maximum_o[o], length = ((maximum_o[o] - minimum_o[o]) != 0.0 ? augmecon_model.grid_points : 1)) for o in O]
end

function save_on_table!(table, i::Int64, augmecon_model::AugmeconJuMP)
    for o in Base.OneTo(num_objectives(augmecon_model))
        table[i, o] = lower_bound(augmecon_model.objectives[o])
    end
    return table
end

function optimize_and_fix!(augmecon_model::AugmeconJuMP, objective)
    @objective(augmecon_model.model, Max, objective)
    optimize_mo_method_model!(augmecon_model)
    set_lower_bound(objective, objective_value(augmecon_model.model))
    return nothing
end

function set_model_for_augmecon!(augmecon_model::AugmeconJuMP, objectives_rhs)
    O = 2:num_objectives(augmecon_model)
    @variable(augmecon_model.model, 
        s[O] >= 0)
        
    @objective(augmecon_model.model, Max, augmecon_model.objectives[1] + 
    augmecon_model.penalty*sum((objectives_rhs_range(objectives_rhs, o) > 0.0 ? s[o]/objectives_rhs_range(objectives_rhs, o) : 0.0) for o in O))
    
    @constraint(augmecon_model.model, other_objectives[o in O], 
        augmecon_model.objectives[o] - s[o] == 0.0)
    return nothing
end

function objectives_rhs_range(objectives_rhs, o)
    return objectives_rhs[o][end] - objectives_rhs[o][1]
end

function recursive_augmecon!(augmecon_model::AugmeconJuMP, frontier, objectives_rhs; o = 2)
    for eps in objectives_rhs[o]
        set_normalized_rhs(augmecon_model.model[:other_objectives][o], eps)
        if o < num_objectives(augmecon_model)
            recursive_augmecon!(augmecon_model, frontier, objectives_rhs, o = o + 1)
        else
            optimize_mo_method_model!(augmecon_model)
            if JuMP.has_values(augmecon_model.model)
                push!(frontier, SolutionJuMP(augmecon_model))
            else
                break
            end
        end
    end
    return nothing
end

function optimize_mo_method_model!(augmecon_model::AugmeconJuMP)
    optimize!(augmecon_model.model)
    augmecon_model.report.time += solve_time(augmecon_model.model)
    augmecon_model.report.iterations_counter += 1
    return augmecon_model
end