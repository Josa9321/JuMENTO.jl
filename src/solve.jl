function convert_frontier_to_objectives_dataframe(frontier, report::SolveReport; file)
    objectives = frontier_to_objective_matrix(frontier)
    this_objs_table = DataFrame(objectives, ["obj_$(j)" for j in axes(objectives, 2)])
    this_payoff_table = DataFrame(report.table, ["obj_$(j)" for j in axes(objectives, 2)])
    this_counter_report = DataFrame(report.counter)

    XLSX.openxlsx("$(file).xlsx", mode="w") do xf
        obj_sheet = xf[1]
        XLSX.rename!(obj_sheet, "objs")
        XLSX.writetable!(obj_sheet, this_objs_table)

        XLSX.addsheet!(xf)
        payoff_sheet = xf[2]
        XLSX.rename!(payoff_sheet, "payoffs")
        XLSX.writetable!(payoff_sheet, this_payoff_table)

        XLSX.addsheet!(xf)
        counter_sheet = xf[3]
        XLSX.rename!(counter_sheet, "counters")
        XLSX.writetable!(counter_sheet, this_counter_report)
    end
    return println("Results saved")
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