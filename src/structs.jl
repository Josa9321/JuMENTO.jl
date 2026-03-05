"""
    struct ReportAUG

A `ReportAUG` struct represents a report of the solution obtained through the AUGMECON method using a specific solver.
It holds the following attributes:
- `counter::Dict{String, F}`: A dictionary containing the number of iterations, the total time spent in the solver and the total time spent in the table solver.
- 'has_nadir_ideal::B': A boolean value indicating whether the solver has found viables solutions to define nadir and ideal points.
- `table::Matrix{F}`: A matrix storing the values of the payoff table.
"""
mutable struct ReportAUG{F<:AbstractFloat,B<:Integer}
    counter::Dict{String,F}
    has_nadir_ideal::B
    table::Matrix{F}

    ReportAUG(num_objectives) = new{Float64,Bool}(
        Dict{String,Float64}("iterations" => 0.0, "solve_time" => 0.0, "table_solve_time" => 0.0,
            "has_viable_nadir_ideal" => true),
        true,
        zeros(num_objectives, num_objectives)
    )
end

"""
    struct AugmeconJuMP

A `AugmeconJuMP` struct represents an optimization problem formulated using the JuMENTO Package.
It holds the following attributes:
- `model::Model`: A JuMP model containing the optimization problem.
- `objectives::Vector{VariableRef}`: A vector that contains the objectives of the optimization problem.
- `objectives_maximize::Vector{VariableRef}`: A vector that contains the objectives converted into a maximization form.
- `sense_value::Vector{F}`:  A vector that indicates the sense (e.g., minimizing or maximizing) of the optimization problem for each objective.
- `grid_points::N`: The number of grid points used in the table solver.
- `report::ReportAUG{F, B}`: A report of the solution obtained through the AUGMECON method using a specific solver.
"""
struct AugmeconJuMP{N<:Integer,B<:Integer,F<:AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    objectives_maximize::Vector{VariableRef}
    sense_value::Vector{F}
    grid_points::N
    report::ReportAUG{F,B}

    AugmeconJuMP(model, objectives, options) = begin
        sense_in_num = __convert_sense_to_num(options[:objective_sense_set])
        O = eachindex(objectives)
        @variable(model, objectives_maximize[O])
        @constraints model begin
            objectives_in_correct_sense[o in O],
            objectives_maximize[o] == objectives[o] * sense_in_num[o]
        end
        return new{Int64,Bool,Float64}(
            model,
            objectives,
            objectives_maximize,
            sense_in_num,
            options[:grid_points],
            ReportAUG(length(objectives))
        )
    end
end

abstract type AbstractSolution end

"""
    struct SolutionJuMP

A `SolutionJuMP` struct represents a solution obtained through the AUGMECON method using a specific solver. It holds the following attributes:
- `variables::V`: A dictionary containing variable names as keys and their corresponding values from the solution.
- `objectives::Vector{Float64}`: A vector storing the values of the objectives from the solution.
"""
struct SolutionJuMP{V,F<:AbstractFloat} <: AbstractSolution
    variables::V
    objectives::Vector{F}

    SolutionJuMP(augmecon_model::AugmeconJuMP) = begin
        variables = __save_variables!(augmecon_model.model)
        return new{typeof(variables),Float64}(
            variables,
            __get_objetives!(augmecon_model)
        )
    end

    SolutionJuMP(model::Model) = begin
        variables = __save_variables!(model)
        sense = objective_sense(model)

        return new{typeof(variables),Float64}(
            variables,
            [__get_objective(model)]
        )
    end
end

###################
# Inter functions #
###################

function has_viable_ideal_nadir(augmecon_model::AugmeconJuMP)
    solve_report = augmecon_model.report
    return solve_report.has_nadir_ideal
end

num_objectives(augmecon_JuMP::AugmeconJuMP) = length(augmecon_JuMP.objectives)

###################
# Intra functions #
###################

function __convert_sense_to_num(objective_sense_set)
    result = fill(1.0, length(objective_sense_set))
    for (o, sense) in enumerate(objective_sense_set)
        if sense == "Min"
            result[o] = -1.0
        end
    end
    return result
end

function __get_objective(model)
    if has_values(model)
        return objective_value(model)
    elseif objective_sense(model) == MAX_SENSE::OptimizationSense
        return -Inf
    elseif objective_sense(model) == MIN_SENSE::OptimizationSense
        return Inf
    else
        return 0.0
    end
end

function __get_objetives!(augmecon_model::AugmeconJuMP)
    if has_values(augmecon_model.model)
        return value.(augmecon_model.objectives)
    else
        return -Inf * augmecon_model.sense_value
    end
end

function __save_variables!(model::Model)
    result = Dict{Symbol,Any}()
    objects_set = model.obj_dict
    for k in keys(objects_set)
        if (typeof(objects_set[k]) <: Array{VariableRef} || typeof(objects_set[k]) <: VariableRef || typeof(objects_set[k]) <: JuMP.Containers.DenseAxisArray{VariableRef}) && k != :objectives_maximize
            if has_values(model)
                result[k] = value.(objects_set[k])
            end
        end
    end
    return result
end
