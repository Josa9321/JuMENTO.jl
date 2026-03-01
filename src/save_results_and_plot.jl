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
            obj = hasproperty(solution, :objectives) ? solution.objectives :
                  (haskey(solution.variables, :objs) ? solution.variables[:objs] : "N/A")

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
    if isempty(data)
        println("No data.")
        return nothing
    end

    var_names = Symbol[]
    if model !== nothing
        dvars = decision_vars(model)
        var_names = Symbol.(JuMP.name.(dvars)) 
    else
        var_names = collect(keys(data[1].variables))
    end

    if length(var_names) >= 2 && all(haskey(data[1].variables, vn) for vn in var_names[1:2])
        x_vals = [sol.variables[var_names[1]] for sol in data]
        y_vals = [sol.variables[var_names[2]] for sol in data]
        xlabel!(string(var_names[1]))
        ylabel!(string(var_names[2]))

    elseif haskey(data[1].variables, :x) && length(data[1].variables[:x]) >= 2
        x_vals = [sol.variables[:x][1] for sol in data]
        y_vals = [sol.variables[:x][2] for sol in data]
        xlabel!("x[1]"); ylabel!("x[2]")

    else
        println("Variables space cannot be plotted. Found keys = $(keys(data[1].variables))")
        return nothing
    end

    p = scatter(x_vals, y_vals, label="Solutions", marker=:star, color=:blue, markersize=8)
    title!("Variable Space")
    return p
end


"""
    Function that plots the variables space and returns the plot object
"""
function variables_plot(frontier, model::Model)
    variables = __save_variables!(model)
    size = length(variables) - 1
    if size != 2
        @warn "Invalid number of variables for plotting\n."
        return nothing
    end

    x_variable = [s.variables[:x][1] for s in frontier]
    y_variable = [s.variables[:x][2] for s in frontier]

    p = scatter(x_variable, y_variable, label="Solutions", marker=:star, color=:blue, markersize=8)
    xlabel!("First Variable")
    ylabel!("Second Variable")
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
