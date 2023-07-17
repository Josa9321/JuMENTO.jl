struct SolveReport{F <: AbstractFloat}
    counter::Dict{String, F}
    table_gap::Vector{F}
    gap::Vector{F}
    table::Matrix{F}

    SolveReport(num_objectives) = new{Float64}(
        Dict{String, Float64}("iterations" => 0.0, "solve_time" => 0.0, "table_solve_time" => 0.0), 
        Float64[],
        Float64[], 
        zeros(num_objectives, num_objectives)
    )
end 

struct AugmeconJuMP{N <: Integer, F <: AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    objectives_maximize::Vector{VariableRef}
    sense_value::Vector{F}
    grid_points::N
    report::SolveReport{F}
    penalty::F
    
    AugmeconJuMP(model, objectives, grid_points, objective_sense_set; penalty=1e-3) = begin
        sense_in_num = convert_sense_to_num(objective_sense_set)
        O = eachindex(objectives)
        @variable(model, objectives_maximize[O])
        @constraints model begin
            objectives_in_correct_sense[o in O],
                objectives_maximize[o] == objectives[o] * sense_in_num[o]
        end
        return new{Int64, Float64}(
            model, 
            objectives,
            objectives_maximize,
            sense_in_num,
            grid_points, 
            SolveReport(length(objectives)),
            penalty
        )
    end
        
end

function convert_sense_to_num(objective_sense_set)
    result = fill(1.0, length(objective_sense_set))
    for (o, sense) in enumerate(objective_sense_set)
        if sense == "Min"
            result[o] = -1.0
        end
    end
    return result
end

num_objectives(augmecon_JuMP::AugmeconJuMP) = length(augmecon_JuMP.objectives)

struct SolutionJuMP{V, F <: AbstractFloat}
    variables::V
    objectives::Vector{F}

    SolutionJuMP(augmecon_model::AugmeconJuMP) = begin
        variables = save_variables!(augmecon_model)
        return new{typeof(variables), Float64}(
            variables,
            save_objetives!(augmecon_model)
        )
    end
end

get_objectives(solution::SolutionJuMP) = solution.objectives

function save_objetives!(augmecon_model)
    return value.(augmecon_model.objectives)
end

function save_variables!(augmecon_model)
    result = Dict()
    model_JuMP = augmecon_model.model
    objects_set = model_JuMP.obj_dict
    for k in keys(objects_set)
        if typeof(objects_set[k]) <: Array{VariableRef} && k != :objectives_maximize
            result[k] = value.(objects_set[k])
        end
    end
    return result 
end