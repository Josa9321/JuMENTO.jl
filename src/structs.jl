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
    grid_points::N
    report::SolveReport{F}
    penalty::F
    
    AugmeconJuMP(model, objectives, grid_points; penalty=1e-3) = new{Int64, Float64}(
        model, 
        objectives, 
        grid_points, 
        SolveReport(length(objectives)),
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