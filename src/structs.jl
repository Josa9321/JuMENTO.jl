mutable struct SolveReport{N <: Integer, F <: AbstractFloat}
    iterations_counter::N
    time::F
    gap::F

    SolveReport() = new{Int64, Float64}(0, 0.0, 0.0)
end 

struct AugmeconJuMP{N <: Integer, F <: AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    grid_points::N
    report::SolveReport{N, F}
    penalty::F
    
    AugmeconJuMP(model, objectives, grid_points; penalty=1e-3) = new{Int64, Float64}(
        model, 
        objectives, 
        grid_points, 
        SolveReport(),
        penalty
    )
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

function save_objetives!(augmecon_model)
    return value.(augmecon_model.objectives)
end

function save_variables!(augmecon_model)
    result = Dict()
    model_JuMP = augmecon_model.model
    objects_set = model_JuMP.obj_dict
    for k in keys(objects_set)
        if typeof(objects_set[k]) <: Array{VariableRef}
            result[k] = value.(objects_set[k])
        end
    end
    return result 
end