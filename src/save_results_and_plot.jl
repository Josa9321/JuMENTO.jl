"""
    Function that saves the results in a specified directory.
    
    Usage:
        save_results_to_file(frontier, solve_report, "caminho/do/diretorio")
"""
function save_results_to_file(frontier, solve_report, save_dir::String)
    if !isdir(save_dir)
        println("Directory does not exist. Creating directory...")
        mkpath(save_dir)
    end

    pareto_path = joinpath(save_dir, "pareto_front.txt")
    report_path = joinpath(save_dir, "solve_report.txt")

    open(pareto_path, "w") do file
        println(file, "Pareto Front Solutions:")
        for solution in frontier
            obj = solution.variables[:objs]
            println(file, "Objectives: ", obj)

            vars = Dict(k => v for (k, v) in solution.variables if k != :s && k != :objs)
            println(file, "Variables: ", vars)
            println(file, "\n")
        end
    end

    open(report_path, "w") do file
        println(file, "Solve Report Summary:")
        println(file, "Total solutions: ", length(frontier))
        for (key, value) in solve_report.counter
            println(file, "$key: $value")
        end
    end

    println("Results saved in '$pareto_path' and '$report_path'")
end

"""
    Function that asks the user if he wants to plot the results
"""
function plot_result(frontier, model::Model)

    plot_both(frontier, model)

end

"""
    Function that plots the Pareto frontier and returns the plot object
"""
function pareto_plot(frontier)
    x_p = [s.objectives[1] for s in frontier]
    y_p = [s.objectives[2] for s in frontier]

    p = scatter(x_p, y_p, label="Pareto Frontier", marker=:circle, color=:red, markersize=8)
    xlabel!("First Criterion")
    ylabel!("Second Criterion")
    title!("Pareto Frontier")
    return p
end

"""
    Function that plots the variables space and returns the plot object
"""
function variables_plot(data, model=nothing)
    var_names = Symbol[]
    
    if model !== nothing
        dvars = decision_vars(model)
        var_names = Symbol.(JuMP.name.(dvars))
    elseif !isempty(data)
        first_solution = data[1]
        if haskey(first_solution.variables, :objs)
            var_names = [k for k in keys(first_solution.variables) if k != :objs]
        else
            var_names = collect(keys(first_solution.variables))
        end
    else
        println("No data.")
        return nothing
    end

    # Agora checar quantidade
    if length(var_names) != 2
        println("Variables space cannot be plotted: variables number = $(length(var_names))")
        return nothing
    end

    # Extrair valores
    x_vals = [sol.variables[var_names[1]] for sol in data]
    y_vals = [sol.variables[var_names[2]] for sol in data]

    p = scatter(x_vals, y_vals, label="Solutions", marker=:star, color=:blue, markersize=8)
    xlabel!(string(var_names[1]))
    ylabel!(string(var_names[2]))
    title!("Variable Space")
    return p
end


function plot_both(frontier, model::Model)
    p1 = plot(pareto_plot(frontier))

    p2 = variables_plot(frontier, model)
    
    if p2 !== nothing
        plot(p1, p2, layout = (1, 2))
        display(plot(p1, p2, layout = (1, 2)))
    else
        println("Variables space cannot be plotted due to Invalid number of variables")
        plot(p1)
        display(plot(p1))
    end
end