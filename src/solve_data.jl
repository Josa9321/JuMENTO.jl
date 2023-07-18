function save_results_csv(frontier, report::SolveReport; file_path)
    df_objectives = generate_dataframe_objectives(frontier)
    CSV.write("$(file_path)_objectives.csv", df_objectives)

    df_payoff, df_counter = generate_all_dataframes_solve_report(report)
    CSV.write("$(file_path)_payoff.csv", df_payoff)
    CSV.write("$(file_path)_counter.csv", df_counter)
    return nothing
end

function save_results_XLSX(frontier, report::SolveReport; file_path)
    df_objectives = generate_dataframe_objectives(frontier)
    df_payoff, df_counter = generate_all_dataframes_solve_report(report)

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

function generate_dataframe_objectives(frontier)
    objectives = frontier_to_objective_matrix(frontier)
    df_objectives = DataFrame(objectives, ["obj_$(j)" for j in axes(objectives, 2)])
    return df_objectives
end

function generate_all_dataframes_solve_report(report::SolveReport)
    df_payoff = DataFrame(report.table, ["obj_$(j)" for j in axes(report.table, 2)])
    df_counter = DataFrame(report.counter)
    return df_payoff, df_counter
end

function frontier_to_objective_matrix(frontier)
    num_objectives = length(frontier[1].objectives)
    result = zeros(length(frontier), num_objectives)
    
    for (i, solution) in enumerate(frontier)
        for (j, obj_j) in enumerate(solution.objectives)
            result[i, j] = obj_j
        end
    end
    return result
end