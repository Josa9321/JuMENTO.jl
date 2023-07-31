#=================================
= This file contains functions to 
= save the results of the 
= optimization process.
=#


"""
    save_results(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path, file_type="csv")

Saves the Pareto set and associated optimization report to a specified file format.

# Arguments
- `pareto_set`: The Pareto set containing a collection of solutions that form the Pareto frontier.
- `report`::SolveReport: The optimization report, typically generated after solving the optimization problem, containing relevant information about the optimization process and results.
- `file_path`: The file path specifying the location where the results will be saved. The path should include the filename, but without its format.
- `file_type="csv"`: (Optional) The file type for saving the results. The available options are "csv" and "xlsx". The default value is "csv".
"""
function save_results(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path, file_type="csv")
    if file_type == "csv"
        save_results_csv(pareto_set, report; file_path=file_path)
    elseif file_type == "xlsx"
        save_results_XLSX(pareto_set, report; file_path=file_path)
    else
        error("File type not supported")
    end
    return nothing
end

"""
    save_results_csv(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path)

Saves the results of the optimization process in CSV files. The CSV files are the following:
- `objs`: A file containing the values of the objectives for each solution in the pareto_set.
- `payoffs`: A file containing the values of the objectives for each solution in the pareto_set, but in the payoff space.
- `counters`: A file containing the values of the counters of the solver in each iteration.

# Arguments
- `pareto_set`: A vector containing the solutions of the pareto_set.
- `report`: A report of the solution obtained through the AUGMECON method using a specific solver.
- `file_path`: The path where the files will be saved without its format.

# Example
```julia-repl
julia> save_results_csv(pareto_set, report; file_path="results")
```
"""
function save_results_csv(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path)
    df_objectives = generate_dataframe_objectives(pareto_set)
    CSV.write("$(file_path)_objectives.csv", df_objectives)

    df_payoff, df_counter = generate_solve_report_dataframes(report)
    CSV.write("$(file_path)_payoff.csv", df_payoff)
    CSV.write("$(file_path)_counter.csv", df_counter)
    return nothing
end

"""
    save_results_XLSX(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path)

Saves the results of the optimization process in a XLSX file. The file's sheets are the following:
- `objs`: A sheet containing the values of the objectives for each solution in the pareto_set.
- `payoffs`: A sheet containing the values of the objectives for each solution in the pareto_set, but in the payoff space.
- `counters`: A sheet containing the values of the counters of the solver in each iteration.

# Arguments
- `pareto_set`: A vector containing the solutions of the pareto_set without its format.
- `report`: A report of the solution obtained through the AUGMECON method using a specific solver.
- `file_path`: The path where the files will be saved.

# Example
```julia-repl
julia> save_results_XLSX(pareto_set, report; file_path="results")
```
"""
function save_results_XLSX(pareto_set::Vector{SolutionJuMP}, report::SolveReport; file_path)
    df_objectives = generate_dataframe_objectives(pareto_set)
    df_payoff, df_counter = generate_solve_report_dataframes(report)

    XLSX.openxlsx("$(file_path).xlsx", mode="w") do xf
        obj_sheet = xf[1]
        XLSX.rename!(obj_sheet, "objs")
        XLSX.writetable!(obj_sheet, df_objectives)

        XLSX.addsheet!(xf)
        payoff_sheet = xf[2]
        XLSX.rename!(payoff_sheet, "payoffs")
        XLSX.writetable!(payoff_sheet, df_payoff)

        XLSX.addsheet!(xf)
        counter_sheet = xf[3]
        XLSX.rename!(counter_sheet, "counters")
        XLSX.writetable!(counter_sheet, df_counter)
    end
    return nothing
end

"""
    generate_dataframe_objectives(pareto_set::Vector{SolutionJuMP})

Generates a dataframe containing the values of the objectives for each solution in the pareto_set.

# Arguments
- `pareto_set`: A vector containing the solutions of the pareto_set.

# Example
```julia-repl
julia> df_objectives = generate_dataframe_objectives(pareto_set)
```
"""
function generate_dataframe_objectives(pareto_set::Vector{SolutionJuMP})
    objectives = frontier_to_objective_matrix(pareto_set)
    df_objectives = DataFrame(objectives, ["obj_$(j)" for j in axes(objectives, 2)])
    return df_objectives
end

"""
    generate_solve_report_dataframes(report::SolveReport)

Generates dataframes containing the values of the objectives in the payoff table, if it was used, and the values of the counters of the solver in each iteration.

# Arguments
- `report`: A report of the solution obtained through the AUGMECON method using a specific solver.

# Example
```julia-repl
julia> df_payoff, df_counter = generate_solve_report_dataframes(report)
```
"""
function generate_solve_report_dataframes(report::SolveReport)
    df_payoff = DataFrame(report.table, ["obj_$(j)" for j in axes(report.table, 2)])
    df_counter = DataFrame(report.counter)
    return df_payoff, df_counter
end


"""
    frontier_to_objective_matrix(pareto_set::Vector{SolutionJuMP})

Converts the values of the objectives of the solutions in the pareto_set into a matrix.

# Arguments
- `pareto_set`: A vector containing the solutions of the pareto_set.

# Example
```julia-repl
julia> objectives = frontier_to_objective_matrix(pareto_set)
```
"""
function frontier_to_objective_matrix(pareto_set::Vector{SolutionJuMP})
    num_objectives = length(pareto_set[1].objectives)
    result = zeros(length(pareto_set), num_objectives)
    
    for (i, solution) in enumerate(pareto_set)
        for (j, obj_j) in enumerate(solution.objectives)
            result[i, j] = obj_j
        end
    end
    return result
end