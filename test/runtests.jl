using JuMENTO, Test

include("./metric_tests.jl")
include("simple_models.jl")
include("test_simple_models.jl")
include("mokp//load.jl")

@testset "Test Metrics" begin
    test_all_metrics()
end

@testset "Test AUGMECON" begin
    test_simple_problems(simple_biobjective_problem, simple_biobjective_frontier(), simple_biobjective_table(), is_augmecon_2 = false)
    test_simple_problems(simple_triobjective_problem, simple_triobjective_frontier(), simple_triobjective_table(), is_augmecon_2 = false)
end

@testset "Test AUGMECON 2" begin
    test_simple_problems(simple_biobjective_problem, simple_biobjective_frontier(), simple_biobjective_table(), is_augmecon_2 = true)
    test_simple_problems(simple_triobjective_problem, simple_triobjective_frontier(), simple_triobjective_table(), is_augmecon_2 = true)
end

@testset "Test NSGA-II" begin
    test_simple_problems_nsga2_2objectives(simple_biobjective_problem)
    test_simple_problems_nsga2_3objectives(simple_triobjective_problem)
end