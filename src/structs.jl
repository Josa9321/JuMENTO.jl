"""
    struct SolveReport

A `SolveReport` struct represents a report of the solution obtained through the AUGMECON method using a specific solver. It holds the following attributes:
- `counter::Dict{String, F}`: A dictionary containing the number of iterations, the total time spent in the solver and the total time spent in the table solver. Each key is mapped to its corresponding value.
- 'has_nadir_ideal::B': A boolean value indicating whether the solver has found viables nadir and ideal points.
- `table_gap::Vector{F}`: A vector storing the gap of the payoff table in each iteration (not working for now).
- `gap::Vector{F}`: A vector storing the gap of the solver in each iteration (not working for now).
- `table::Matrix{F}`: A matrix storing the values of the payoff table. Each row represents the values of the table solver in an iteration.
"""
mutable struct SolveReport{F <: AbstractFloat, B <: Integer}
    counter::Dict{String, F}
    has_nadir_ideal::B
    table_gap::Vector{F}
    gap::Vector{F}
    table::Matrix{F}

    SolveReport(num_objectives) = new{Float64, Bool}(
        Dict{String, Float64}("iterations" => 0.0, "solve_time" => 0.0, "table_solve_time" => 0.0, "has_viable_nadir_ideal" => true), 
        true,
        Float64[],
        Float64[], 
        zeros(num_objectives, num_objectives)
    )
end 

"""
    struct AugmeconJuMP

A `AugmeconJuMP` struct represents an optimization problem formulated using the JuMENTO Package. It holds the following attributes:
- `model::Model`: A JuMP model containing the optimization problem.
- `objectives::Vector{VariableRef}`: A user-provided vector that contains the objectives of the optimization problem.
- `objectives_maximize::Vector{VariableRef}`: A vector that contains the objectives of the optimization problem, multiplied by the optimization sense, to convert the problem into a maximization form.
- `sense_value::Vector{F}`:  A vector that indicates the sense (e.g., minimizing or maximizing) of the optimization problem for each objective.
- `grid_points::N`: The number of grid points used in the table solver.
- `report::SolveReport{F}`: A report of the solution obtained through the AUGMECON method using a specific solver.
"""
struct AugmeconJuMP{N <: Integer, B <: Integer, F <: AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    objectives_maximize::Vector{VariableRef}
    sense_value::Vector{F}
    grid_points::N
    report::SolveReport{F, B}
    
    AugmeconJuMP(model, objectives, options) = begin
        print("Initializing AugmeconJuMP with $(length(objectives)) objectives.\n")
        sense_in_num = convert_sense_to_num(options[:objective_sense_set])
        O = eachindex(objectives)
        @variable(model, objectives_maximize[O])
        @constraints model begin
            objectives_in_correct_sense[o in O],
                objectives_maximize[o] == objectives[o] * sense_in_num[o]
        end
        return new{Int64, Bool, Float64}(
            model, 
            objectives,
            objectives_maximize,
            sense_in_num,
            options[:grid_points], 
            SolveReport(length(objectives))
        )
    end
end

function has_viable_ideal_nadir(augmecon_model::AugmeconJuMP)
    solve_report = augmecon_model.report
    return solve_report.has_nadir_ideal
end

"""
    convert_sense_to_num(objective_sense_set)

Converts the sense of the optimization problem from a string to a numeric value. The numeric value is used to convert the problem into a maximization form. For example, if the sense is "Min", then the numeric value is -1.0. If the sense is "Max", then the numeric value is 1.0.
# example
```julia-repl
julia> convert_sense_to_num(["Min", "Max"])
2-element Vector{Float64}:
 -1.0
  1.0
```
"""
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

"""
    struct SolutionJuMP

A `SolutionJuMP` struct represents a solution obtained through the AUGMECON method using a specific solver. It holds the following attributes:
- `variables::Dict{String, Float64}`: A dictionary containing variable names as keys and their corresponding values from the solution. Each variable name is mapped to its numeric value in the solution.
- `objectives::Vector{Float64}`: A vector storing the values of the objectives from the solution. Each element in the vector represents the value of an objective in the optimization problem.
"""
struct SolutionJuMP{V, F <: AbstractFloat}
    variables::V
    objectives::Vector{F}

    SolutionJuMP(augmecon_model::AugmeconJuMP) = begin
        variables = save_variables!(augmecon_model.model)
        return new{typeof(variables), Float64}(
            variables,
            get_objetives!(augmecon_model)
        )
    end

    SolutionJuMP(model::Model) = begin
        variables = save_variables!(model)
        sense = objective_sense(model)

        return new{typeof(variables), Float64}(
            variables,
            [get_objective_value(model)]
        )
    end
end


function get_objective_value(model)
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

"""
    get_variables(solution::SolutionJuMP)

A function that returns the objectives from a solution obtained through the AUGMECON method using a specific solver.
"""
get_objectives(solution::SolutionJuMP) = solution.objectives

"""
    get_variables(solution::SolutionJuMP)

A function that returns the objectives performance from a solution stored at a AugmeconJuMP model obtained through the AUGMECON method using a specific solver.

# Arguments
- `augmecon_model`: A AugmeconJuMP model.

# Example
```julia-repl
julia> get_objectives(augmecon_model)
```
"""
function get_objetives!(augmecon_model::AugmeconJuMP)
    if has_values(augmecon_model.model)
        return value.(augmecon_model.objectives)
    else
        return -Inf * augmecon_model.sense_value
    end
end

"""
    save_variables!(model::Model)
    
A function that save the value of variables from a solution stored at a Model type.

# Arguments
- `model`: A model.

# Example
```julia-repl
julia> save_variables!(model)
```
"""
function save_variables!(model::Model)
    result = Dict{Symbol, Any}()
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