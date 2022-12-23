import Combinatorics: permutations
include("non_dominated_with_sol.jl")

function fix_table_value(model, objective, numIt, time, gap)
    @objective(model, Max, objective)
    optimize!(model)
    numIt += 1
    time += solve_time(model)
    gap += relative_gap(model)
    set_lower_bound(objective, objective_value(model))
    return numIt, time, gap
end

function lexicographic!(model, objectives, objectives_found, solutions_found; register_solution = register_solution_pmsp)
    @assert length(objectives) >= 2 " The model has only 1 objective"
    @assert all(JuMP.is_valid.(Ref(model), objectives)) "At least one objective isn't defined in the model as a constraint"
    O = Base.OneTo(length(objectives))
    time = 0.0
    gap = 0.0
    numIt = 0
    table = zeros(O.stop, O.stop)
    for (i, obj_higher) in enumerate(objectives)
        numIt, time, gap = fix_table_value(model, obj_higher, numIt, time, gap)
        for (o, obj_minor) in enumerate(objectives)
            if i != o
                numIt, time, gap = fix_table_value(model, obj_minor, numIt, time, gap)
            end
        end
        table[i, :] .= lower_bound.(objectives)
        delete_lower_bound.(objectives)
    end
    @objective(model, Max, 0.0)
    return table, time, gap, numIt
end

function eps_con(model::Model, objectives, grid_points; 
    rm_equals = remove_equal_solutions, register_solution = register_solution_pmsp)
    
    penalty = 1e-3
    O = 2:length(objectives)
    objectives_found = Vector{Float64}[]
    solutions_found = [] # SolutionFromModel{Int64, Float64}
    table, time, gap, numIt = lexicographic!(model, objectives, objectives_found, solutions_found, register_solution = register_solution)
    gap = 0.0 # I won't collect lexicographic gaps
    # objective_values = [range(minimum(table[:, o]), stop = maximum(table[:, o]), length = (maximum(table[:, o]) - minimum(table[:, o]) > 0.0 ? grid_points+2 : 1)) for o in 1:O[end]]
    maximum_o = [maximum(table[:, o]) for o in 1:O[end]]
    minimum_o = [minimum(table[:, o]) for o in 1:O[end]]
    objective_range = [maximum_o[o] - minimum_o[o] for o in 1:O[end]]
    e = [range(minimum_o[o], maximum_o[o], length = (objective_range[o] != 0.0 ? grid_points : 1)) for o in 1:O[end]]
    @variable(model, s[O] >= 0)
    @objective(model, Max, objectives[1] + penalty*sum((objective_range[o] > 0.0 ? s[o]/objective_range[o] : 0.0) for o in O))
    @constraint(model, other_objectives[o in O], objectives[o] - s[o] == 0.0)

    aux_aug = AuxAUGMECON(model, objectives, other_objectives, grid_points, register_solution, numIt, time, gap)
    loop_objective_o!(aux_aug, objectives_found, solutions_found, e)
    
    aux_aug.gap = aux_aug.gap/aux_aug.numIt # Only mean
    paretto_solutions, paretto_values = rm_equals(solutions_found, objectives_found)
    
    # Since there is a possible gap between the best solution found and the best viable solution,
    # I need to garantee that I'll save only non dominated solutions
    paretto_values, paretto_solutions = generate_pareto(paretto_values, paretto_solutions)
    return paretto_solutions, paretto_values, aux_aug.time, aux_aug.gap
end

function loop_objective_o!(aux_aug::AuxAUGMECON, objectives_found, solutions_found, e; o = 2)
    for eps in e[o]
        set_normalized_rhs(aux_aug.other_objectives[o], eps) # e[o][i]
        if o < length(aux_aug.objectives)
            loop_objective_o!(aux_aug, objectives_found, solutions_found, e, o = o + 1)
        else
            optimize!(aux_aug.model)
            aux_aug.time += solve_time(aux_aug.model)
            if JuMP.has_values(aux_aug.model)
                aux_aug.numIt += 1
                aux_aug.gap += relative_gap(aux_aug.model)
                new_solution = value.(aux_aug.objectives)
                push!(objectives_found, new_solution)
                push!(solutions_found, aux_aug.register_solution(aux_aug.model))
            else
                break
            end
        end
    end
    return nothing
end