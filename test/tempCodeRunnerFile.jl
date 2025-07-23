test_simple_problems(
    simple_biobjective_problem, 
    simple_biobjective_frontier(), 
    simple_biobjective_table(),
    is_augmecon_2 = true
)

test_simple_problems(
    simple_triobjective_problem, 
    simple_triobjective_frontier(), 
    simple_triobjective_table(),
    is_augmecon_2 = false
)
test_simple_problems(
    simple_triobjective_problem, 
    simple_triobjective_frontier(), 
    simple_triobjective_table(),
    is_augmecon_2 = true
)