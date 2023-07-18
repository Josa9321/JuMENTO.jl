function buggy_max_j_dominates_i(instance)
    good_in_one_efficient = init_solution(instance)
    nadir_solution = init_solution(instance)
    average_efficient_solution = set_efficient_average(instance)
    ideal_solution = set_ideal(instance)
    for o in instance.O
        set_efficient_by_one_objective!(good_in_one_efficient, o)
        
        @assert max_j_dominates_i(solution_j = average_efficient_solution, solution_i = good_in_one_efficient) == false "buggy_max_j_dominates_i: bug case 1"
        @assert max_j_dominates_i(solution_j = good_in_one_efficient, solution_i = average_efficient_solution) == false "buggy_max_j_dominates_i: bug case 2"
        
        @assert buggy_j_dominates(solution_j = average_efficient_solution, solution_i = nadir_solution) "buggy_max_j_dominates_i: bug case 3"
        @assert buggy_j_dominates(solution_j = good_in_one_efficient, solution_i = nadir_solution) "buggy_max_j_dominates_i: bug case 4"

        @assert buggy_j_is_dominated(solution_j = average_efficient_solution, solution_i = ideal_solution) "buggy_max_j_dominates_i: bug case 5"
        @assert buggy_j_is_dominated(solution_j = good_in_one_efficient, solution_i = ideal_solution) "buggy_max_j_dominates_i: bug case 6"

        reset_solution!(good_in_one_efficient)
    end
    return false
end

function buggy_j_dominates(;solution_j, solution_i)
    return max_j_dominates_i(solution_j = solution_j, solution_i = solution_i) && max_j_dominates_i(solution_i = solution_j, solution_j = solution_i) == false
end

function buggy_j_is_dominated(;solution_j, solution_i)
    return max_j_dominates_i(solution_j = solution_j, solution_i = solution_i) == false && max_j_dominates_i(solution_i = solution_j, solution_j = solution_i) == true
end

function set_efficient_average(instance)
    solution = init_solution(instance)
    return set_efficient_average!(solution)
end

function set_efficient_average!(solution)
    solution.objectives .= 50.0
    return solution
end

function set_efficient_by_one_objective!(solution, o)
    solution.objectives[o] = 102.0
    return solution
end

function set_ideal(instance)
    solution = init_solution(instance)
    return set_ideal!(solution)
end

function set_ideal!(solution)
    solution.objectives .= Inf
    return solution
end

function reset_solution!(solution)
    solution.objectives .= 0.0
end