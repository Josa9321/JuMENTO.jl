"""
    augmecon(model::Model, objectives::Vector{VariableRef}; user_options...)

Augmecon is a function that solves a multiobjective optimization problem using the augmented ε-constraint method with a specified solver.

# Arguments
- `model::Model`: A JuMP model containing the optimization problem.
- `objectives::Vector{VariableRef}`: A user-provided vector that contains the objectives of the optimization problem.
- `user_options`: A set of required and optional keyword arguments (or Dict) that allow customization of the AUGMECON method.

# Options
- `grid_points` (required): The number of grid points used in the table solver.
- `objective_sense_set`: A vector that indicates the sense (e.g., minimizing or maximizing) of the optimization problem for each objective. The default value is `["Max", "Max", ...]`.
- `penalty`: A numeric value that indicates the penalty used in the augmented ε-constraint method. The default value is `1e-3`.
- `bypass`: A boolean value that indicates whether the bypass method should be used (AUGMECON2). The default value is `true`.
- `nadir`: A vector that indicates the nadir point of the optimization problem. 
- `dominance_eps`: The tolerance used when determining dominance relations. Default is `1e-8`.
- `print_level`: An integer value that indicates the level of printing during the execution of the AUGMECON method. The default value is `0` (no printing).

# Returns
- `pareto_set::Vector{SolutionJuMP}`: A vector containing the solutions of the optimization problem.
- `solve_report::SolveReport{F}`: A report of the solution obtained through the AUGMECON method using a specific solver.

# Examples
```julia
using JuMP
using HiGHS

# Create a JuMP model
model = Model(HiGHS.Optimizer)
@variables model begin
    x[1:2] >= 0
    objs[1:2]
end 
@constraints model begin
    c1, x[1] <= 20
    c2, x[2] <= 40
    c3, 5*x[1] + 4*x[2] <= 200
    objective_1, objs[1] == -x[1]
    objective_2, objs[2] == -(3*x[1] + 4*x[2])
end

# Solve the model using AUGMECON method
frontier, solve_report = augmecon(model, objs, grid_points = 10, objective_sense_set = ["Min", "Min"])
```
"""
function augmecon(model::Model, objectives::Vector{VariableRef}; user_options...)
    Base.depwarn(
        "Use the MethodAUGMECON module and implement the model following the MultiObjectiveAlgorithms interface.",
        :augmecon
    )
    options = augmecon_options(user_options, length(objectives)) 
    return _run_augmecon(model::Model, objectives::Vector{VariableRef}, options)
end

"""
    augmecon(model::Model; user_options...)

This function is an overload of the `augmecon` function that allows users to call the method without explicitly providing the objectives as a vector of `VariableRef`. 
Instead, it retrieves the objectives from the model and proceeds with the AUGMECON method.
If the sense of the objectives is not provided in the options, it will be set according to the model's objective sense (maximization or minimization) for all objectives.
"""
function augmecon(model::Model; user_options...)
    Base.depwarn(
        "Use the MethodAUGMECON module and implement the model following the MultiObjectiveAlgorithms interface.",
        :augmecon
    )
    objectives = objective_function(model)
    options = augmecon_options(user_options, length(objectives)) 

    @variable(model, __my_objective_variables[eachindex(objectives)])
    @constraint(model, __c_my_objective_variables[i in eachindex(objectives)], __my_objective_variables[i] == objectives[i])
    sense = objective_sense(model)

    __set_objective_sense_set!(options, model, objectives, user_options)

    results = _run_augmecon(model::Model, __my_objective_variables, options)

    __reset_model_objectives!(model, objectives, sense)
    return results
end

function _run_augmecon(model::Model, objectives::Vector{VariableRef}, options)
    @assert length(objectives) >= 2 "The model has only 1 objective"
    @assert all(JuMP.is_valid.(Ref(model), objectives)) "At least one objective isn't defined in the model as a constraint"
    
    println_if_necessary("Initializing AUGMECON with $(length(objectives)) objectives.", options)
    println_if_necessary("AUGMECON$(options[:bypass]::Bool ? "-2" : "") model initialized.", options)
    print_options(options)

    start_augmecon_time = __tic()
    augmecon_model = AugmeconJuMP(model, objectives, options)
    augmecon_model.report.counter["start_time_global"] = start_augmecon_time
    augmecon_model.report.counter["grid_counter"] = 0

    # From now, solutions will be generated
    objectives_rhs = __get_objectives_rhs(augmecon_model, options)
    __set_model_for_augmecon!(augmecon_model, objectives_rhs, options)
    
    solve_report = augmecon_model.report
    start_recursion_time = __tic()
    frontier = SolutionJuMP[]
    println_if_necessary("", options)
    println_if_necessary("-"^76, options)
    if has_viable_ideal_nadir(augmecon_model)
        printf_if_necessary(options, "%-12s | %15s | %23s | %17s", 
            "Iterations", "Time (s)", "Accumulated solutions", "% Grid Explored")
        println_if_necessary("-"^76, options)

        if options[:bypass]
            s_2 = augmecon_model.model[:s][2]
            __recursive_augmecon2!(augmecon_model, frontier, objectives_rhs, start_augmecon_time, options, s_2 = s_2)
        else
            __recursive_augmecon!(augmecon_model, frontier, objectives_rhs, start_augmecon_time, options)
        end
    end
    println_if_necessary("-"^76, options)

    solve_report.counter["recursion_total_time"] = __toc(start_recursion_time)
    solve_report.counter["total_time"] = __toc(start_augmecon_time)
    
    println_if_necessary("Total execution time: $(solve_report.counter["total_time"]) seconds", options)
    println_if_necessary("Execution completed\n", options)

    __convert_table_to_correct_sense!(augmecon_model)
    frontier = generate_pareto_max(frontier, options[:dominance_eps])
    __reset_augmecon_model!(model)
    return frontier, solve_report
end

function __set_objective_sense_set!(options, model, objectives, user_options)
    if !(:objective_sense_set in keys(user_options))
        options[:objective_sense_set] = objective_sense(model) == MAX_SENSE ? ["Max" for _ in eachindex(objectives)] : ["Min" for _ in eachindex(objectives)]
    end
    return nothing
end

function __reset_model_objectives!(model, objectives, sense)
    delete(model, model[:__c_my_objective_variables])
    unregister(model, :__c_my_objective_variables)
    
    delete(model, model[:__my_objective_variables])
    unregister(model, :__my_objective_variables)
    
    sense == 1 ? @objective(model, Max, objectives) : @objective(model, Min, objectives)
    return nothing
end

function __reset_augmecon_model!(model)
    delete(model, model[:objectives_maximize])
    unregister(model, :objectives_maximize)

    delete(model, model[:objectives_in_correct_sense])
    unregister(model, :objectives_in_correct_sense)

    delete.(Ref(model), model[:other_objectives])
    unregister(model, :other_objectives)
    
    if :s in keys(model.obj_dict)
        delete.(Ref(model), model[:s])
        unregister(model, :s)
    end

    return nothing
end

"""
    get_objectives_rhs(augmecon_model, options)

This function computes and returns the range of each objective in the optimization problem, considering either a specified nadir point or the payoff table.

# Arguments
- `augmecon_model::AugmeconJuMP`: A model containing the optimization problem.
- `options`: A set of options that can be used to customize the AUGMECON method.

# Options
- `:grid_points`: The number of grid points used in the table solver.
- `:nadir`: A vector that indicates the nadir point of the optimization problem. The default value is `nothing`.

# Returns
- `objectives_rhs::Vector{Vector{Float64}}`: A vector containing the range of each objective in the optimization problem.

# Notes
- If the nadir point is not specified, then the payoff table is used to define a possible nadir point.
"""
function __get_objectives_rhs(augmecon_model, options)
    if :nadir in keys(options)
        ideal_point = _get_ideal_point(augmecon_model, options)
        return __set_objectives_rhs_range(ideal_point, options)
    end
    __payoff_table!(augmecon_model) 
    return __set_objectives_rhs_range(augmecon_model)
end

"""
    get_ideal_point(augmecon_model)

This function computes and returns the ideal point of the optimization problem. It is intended for use when a user specifies a nadir point in the options.
"""
function _get_ideal_point(augmecon_model, options)
    objectives = augmecon_model.objectives_maximize

    start_time = __tic()
    println_if_necessary("Calculating ideal point", options)
    ideal_point = zeros(length(objectives))
    println_if_necessary("Checking if model has viable idel and nadir points.", options)
    for i in 2:length(ideal_point)
        if !has_viable_ideal_nadir(augmecon_model)
            continue
        end
        obj = objectives[i]
        has_ideal_nadir = __optimize_and_fix!(augmecon_model, obj)
        __set_if_has_viable_ideal_nadir!(augmecon_model, has_ideal_nadir)
        if has_viable_ideal_nadir(augmecon_model)
            ideal_point[i] = lower_bound(obj)
            delete_lower_bound(obj)
        end
    end
    solve_report = augmecon_model.report
    solve_report.counter["tables_generation_total_time"] = __toc(start_time)
    println_if_necessary("Calculated ideal point: $ideal_point", options)
    @objective(augmecon_model.model, Max, 0.0)
    return ideal_point
end

"""
    set_objectives_rhs_range(ideal_point, options)

This function computes and returns the range of each objective in the optimization problem, considering a specified nadir point.
"""
function __set_objectives_rhs_range(ideal_point, options)
    nadir = options[:nadir]

    __verify_nadir(ideal_point, nadir)
    return [
        range(nadir[o], ideal_point[o], length = ((ideal_point[o] - nadir[o]) != 0.0 ? options[:grid_points] : 1)) 
            for o in eachindex(ideal_point)
    ]
end

"""
    verify_nadir(ideal_point, nadir)

This function verifies whether the nadir point is better than the ideal point in at least one objective.
"""
function __verify_nadir(ideal_point, nadir)
    for (o, value) in enumerate(ideal_point)
        @assert nadir[o] <= value "nadir is better than ideal point in at least $o"
    end
    return nothing
end


###############################
###############################

"""
    verify_objectives_sense_set(objective_sense_set, objectives)

This function verifies whether the objective sense set is valid.
"""
function _verify_objectives_sense_set(objective_sense_set, objectives)
    for sense in objective_sense_set
        @assert (sense == "Max" || sense == "Min") """Objective sense should be "Max" or "Min" """
    end
    @assert length(objectives) == length(objective_sense_set) """Number of objectives ($(length(objectives))) is different than the length of objective_sense_set ($(length(objective_sense_set)))"""
    return nothing
end

###############################
###############################

"""
    payoff_table!(augmecon_model::AugmeconJuMP)

This function computes and returns the payoff table of the optimization problem.
"""
function __payoff_table!(augmecon_model::AugmeconJuMP)
    objectives = augmecon_model.objectives_maximize
    start_time = __tic()
    solve_report = augmecon_model.report
    table = solve_report.table
    for (i, obj_higher) in enumerate(objectives)
        if !has_viable_ideal_nadir(augmecon_model)
            continue
        end
        has_ideal_nadir = __optimize_and_fix!(augmecon_model, obj_higher)
        __set_if_has_viable_ideal_nadir!(augmecon_model, has_ideal_nadir)
        for (o, obj_minor) in enumerate(objectives)
            if i != o && has_viable_ideal_nadir(augmecon_model)
                has_ideal_nadir = __optimize_and_fix!(augmecon_model, obj_minor)
                __set_if_has_viable_ideal_nadir!(augmecon_model, has_ideal_nadir)
            end
        end
        if has_viable_ideal_nadir(augmecon_model)
            __save_on_table!(table, i, augmecon_model)
            delete_lower_bound.(objectives)
        end
    end
    solve_report.counter["tables_generation_total_time"] = __toc(start_time)
    @objective(augmecon_model.model, Max, 0.0)
    return table
end

"""
    set_objectives_rhs_range(augmecon_model::AugmeconJuMP)

This function computes and returns the range of each objective in the optimization problem, considering the payoff table.
"""
function __set_objectives_rhs_range(augmecon_model::AugmeconJuMP)
    solve_report = augmecon_model.report
    table = solve_report.table
    O = Base.OneTo(num_objectives(augmecon_model))
    maximum_o = [maximum(table[:, o]) for o in O]
    minimum_o = [minimum(table[:, o]) for o in O]
    return [range(minimum_o[o], maximum_o[o], length = ((maximum_o[o] - minimum_o[o]) != 0.0 ? augmecon_model.grid_points : 1)) for o in O]
end

"""
    save_on_table!(table, i::Int64, augmecon_model::AugmeconJuMP)

This function stores the lower bound for each objective of the found solution in the payoff table.
"""
function __save_on_table!(table, i::Int64, augmecon_model::AugmeconJuMP)
    for o in Base.OneTo(num_objectives(augmecon_model))
        table[i, o] = lower_bound(augmecon_model.objectives_maximize[o])
    end
    return table
end

"""
    optimize_and_fix!(augmecon_model::AugmeconJuMP, objective)

This function optimizes the model and fixes the lower bound of the given objective.
"""
function __optimize_and_fix!(augmecon_model::AugmeconJuMP, objective)
    model = augmecon_model.model
    @objective(model, Max, objective)
    optimize!(model)
    has_a_solution = has_values(model)

    # Save report
    solve_report = augmecon_model.report
    solve_report.counter["table_solve_time"] += solve_time(model)
    if has_a_solution
        set_lower_bound(objective, objective_value(model))
    end
    return has_a_solution
end

###############################
###############################

"""
    set_model_for_augmecon!(augmecon_model::AugmeconJuMP, objectives_rhs, options)

This function sets the model for the AUGMECON method.
"""
function __set_model_for_augmecon!(augmecon_model::AugmeconJuMP, objectives_rhs, options)
    O = 2:num_objectives(augmecon_model)
    @variable(augmecon_model.model, 
        s[O] >= 0.0)
        
    if options[:bypass]
        @objective(augmecon_model.model, Max, augmecon_model.objectives_maximize[1] + 
            options[:penalty]*sum((__objectives_rhs_range(objectives_rhs, o) > 0.0 ? (10.0^float(2-o)) * s[o]/__objectives_rhs_range(objectives_rhs, o) : 0.0) for o in O))
            
    else
        @objective(augmecon_model.model, Max, augmecon_model.objectives_maximize[1] + 
            options[:penalty]*sum((__objectives_rhs_range(objectives_rhs, o) > 0.0 ? s[o]/__objectives_rhs_range(objectives_rhs, o) : 0.0) for o in O))
    end
    @constraint(augmecon_model.model, other_objectives[o in O], 
        augmecon_model.objectives_maximize[o] - s[o] == 0.0)
    return nothing
end

"""
    objectives_rhs_range(objectives_rhs, o)

This function computes and returns the range of the given objective.
"""
function __objectives_rhs_range(objectives_rhs, o)
    return objectives_rhs[o][end] - objectives_rhs[o][1]
end

###############################
###############################


"""
    recursive_augmecon2!(augmecon_model::AugmeconJuMP, frontier, objectives_rhs; o = num_objectives(augmecon_model), s_2)

This function recursively solves the model using the AUGMECON method with the bypass method.
"""
function __recursive_augmecon2!(augmecon_model::AugmeconJuMP, frontier, objectives_rhs, start_time, options; o = num_objectives(augmecon_model), s_2)
    i_k = 0
    while i_k < length(objectives_rhs[o]) # augmecon_model.grid_points
        i_k += 1
        set_normalized_rhs(augmecon_model.model[:other_objectives][o], objectives_rhs[o][i_k])
        if o > 2
            __recursive_augmecon2!(augmecon_model, frontier, objectives_rhs, start_time, options, o = o - 1, s_2 = s_2)
        else
            augmecon_model.report.counter["grid_counter"] += 1
            __optimize_mo_method_model!(augmecon_model, frontier, start_time, options)
            if JuMP.has_values(augmecon_model.model)
                push!(frontier, SolutionJuMP(augmecon_model))
                b = __get_number_of_redundant_iterations(s_2, objectives_rhs[o])
                i_k += b
            else
                i_k = augmecon_model.grid_points
            end
        end
    end
    return nothing
end

"""
    recursive_augmecon!(augmecon_model::AugmeconJuMP, frontier, objectives_rhs; o = 2)

This function recursively solves the model using the AUGMECON method.
"""
function __recursive_augmecon!(augmecon_model::AugmeconJuMP, frontier, objectives_rhs, start_time, options; o = 2)

    for eps in objectives_rhs[o]
        set_normalized_rhs(augmecon_model.model[:other_objectives][o], eps)
        if o < num_objectives(augmecon_model)
            __recursive_augmecon!(augmecon_model, frontier, objectives_rhs, start_time, options, o = o + 1)
        else
            augmecon_model.report.counter["grid_counter"] += 1
            __optimize_mo_method_model!(augmecon_model, frontier, start_time, options)
            if JuMP.has_values(augmecon_model.model)
                push!(frontier, SolutionJuMP(augmecon_model))
            else
                break
            end
        end
    end
    return nothing
end

###############################
###############################

function __convert_table_to_correct_sense!(augmecon_model::AugmeconJuMP)
    table = augmecon_model.report.table
    sense = augmecon_model.sense_value
    for i in axes(table, 1)
        for j in axes(table, 2)
            table[i, j] = table[i, j] * sense[j]
        end
    end
    return table
end

function __optimize_mo_method_model!(augmecon_model::AugmeconJuMP, frontier::Vector{SolutionJuMP}, start_time::Float64, options)
    optimize!(augmecon_model.model)

    augmecon_model.report.counter["solve_time"] += solve_time(augmecon_model.model)
    augmecon_model.report.counter["iterations"] += 1.0

    if JuMP.has_values(augmecon_model.model)
        push!(frontier, SolutionJuMP(augmecon_model))
    end

    __printf_optimize_mo_if_necessary(augmecon_model, frontier, start_time, options)

    return augmecon_model
end

function __printf_optimize_mo_if_necessary(augmecon_model, frontier, start_time, options)
    if options[:print_level]::Int64 > 0
        time_elapsed = round(time() - start_time, digits=4)
        num_sol = length(frontier)        
        iter = Int(augmecon_model.report.counter["iterations"])

        n = length(augmecon_model.objectives)
        total_grid = augmecon_model.grid_points ^ (n - 1)
        grid_counter = augmecon_model.report.counter["grid_counter"]
        grid = round((grid_counter / total_grid) * 100, digits=2)

        printf_if_necessary(options, "%-12d | %15.4f | %23d | %17.2f", iter, time_elapsed, num_sol, grid)
    end
    return nothing
end

function __get_number_of_redundant_iterations(s_2, objective_range)
    division = value(s_2)/objective_range.step.hi
    return __since_solver_could_let_s_2_less_than_zero(division)
end

function __since_solver_could_let_s_2_less_than_zero(b)
    result = trunc(Int64, b)
    return result
end

function __set_if_has_viable_ideal_nadir!(augmecon_model::AugmeconJuMP, has_found)
    augmecon_model.report.has_nadir_ideal = has_found
    return nothing
end

__tic() = time()
__toc(start_time) = time() - start_time 
