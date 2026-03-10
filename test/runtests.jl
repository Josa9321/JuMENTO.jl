using JuMENTO
using Test, Aqua
import MultiObjectiveAlgorithms as MOA

Augmecon = MethodAUGMECON.Augmecon

include("test_utils.jl")
include("metric_tests.jl")
include("simple_models.jl")
include("test_simple_models.jl")
include("mokp//mokp.jl")

Aqua.test_all(JuMENTO)

@testset "JuMENTO.jl" begin
    # @testset "Test Utils" begin
    #     test_normalization()
    #     test_dominance_relations()
    #     test_generate_pareto_frontier()
    # end
    #
    # @testset "Test Metrics" begin
    #     test_multiobjective_metrics()
    # end

    # mokp_instances_addresses_set = readdir("./mokp/instances/", join=true)[1:2]
    # @testset "test AUGMECON" begin
    #     test_simple_problems(simple_biobjective_problem, simple_biobjective_frontier(), simple_biobjective_table(), is_augmecon_2=false)
    #     test_simple_problems(simple_triobjective_problem, simple_triobjective_frontier(), simple_triobjective_table(), is_augmecon_2=false)
    #     # mokp.test_instances_set(mokp_instances_addresses_set; bypass = false)
    # end
    #
    # @testset "Test AUGMECON 2" begin
    #     test_simple_problems(simple_biobjective_problem, simple_biobjective_frontier(), simple_biobjective_table(), is_augmecon_2=true)
    #     test_simple_problems(simple_triobjective_problem, simple_triobjective_frontier(), simple_triobjective_table(), is_augmecon_2=true)
    #     # mokp.test_instances_set(mokp_instances_addresses_set; bypass = true)
    # end
    #
    # @testset "Test NSGA-II" begin
    #     test_simple_problems_nsga2_2objectives(simple_biobjective_problem)
    #     test_simple_problems_nsga2_3objectives(simple_triobjective_problem)
    # end
end

@testset "Test JuMENTO and MOA" begin
    @testset "Test AUGMECON" begin
        test_simple_problems(simple_biobjective_problem(), simple_biobjective_frontier(); is_augmecon_2=false)
        test_simple_problems(simple_triobjective_problem(), simple_triobjective_frontier(); is_augmecon_2=false)
    end
end
