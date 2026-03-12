module TestAUGMECON

if false include("../../src/JuMENTO.jl") end

using Test

using JuMP, HiGHS, Ipopt

import MultiObjectiveAlgorithms as MOA
import MultiObjectiveAlgorithms: MOI

import JuMENTO: MethodAUGMECON


function run_tests()
    for aug_type in [1]
        name = "AUGMECON $(aug_type)"
        @testset "Test $(name)" begin
            test_simple_problems(simple_biobjective_problem(), simple_biobjective_frontier(), augmecon_type=aug_type)
            test_simple_problems(simple_triobjective_problem(), simple_triobjective_frontier(), augmecon_type=aug_type)
            test_biobjective_knapsack(augmecon_type=aug_type)
            test_infeasible(augmecon_type=aug_type)
            test_unbounded(augmecon_type=aug_type)
            test_unbounded_second(augmecon_type=aug_type)
            test_quadratic(augmecon_type=aug_type)
            test_poor_numerics(augmecon_type=aug_type)
            # test_vectornonlinearfunction(augmecon_type=aug_type)
            # test_time_limit(augmecon_type=aug_type)
            # test_time_limit_large(augmecon_type=aug_type)
            test_vector_of_variables_objective(augmecon_type=aug_type)
        end
    end
    return nothing
end

#####

function test_simple_problems(model, saved_frontier_set; augmecon_type)
    set_attribute(model, MethodAUGMECON.AugmeconType(), augmecon_type)

    optimize!(model)

    frontier_set = hcat(
        [objective_value(model, result=i
        ) for i in Base.OneTo(result_count(model))]...)
    frontier_set = frontier_set[:, sortperm(frontier_set[1, :])]

    @test all(isapprox.(frontier_set, saved_frontier_set))
    return nothing
end

##### Specific tests (from MOA tests)

function test_biobjective_knapsack(;augmecon_type)
    p1 = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91, 99, 63, 84, 87, 79, 94, 90]
    p2 = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92, 74, 97, 60, 60, 65, 97, 93]
    w = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93, 98, 72, 100, 89, 67, 86, 91]
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(59))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    
    x = MOI.add_variables(model, length(w))
    MOI.add_constraint.(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = MOI.Utilities.operate(
        vcat,
        Float64,
        [sum(1.0 * p[i] * x[i] for i in eachindex(w)) for p in [p1, p2]]...,
    )
    f.constants[1] = 1.0
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(
        model,
        sum(1.0 * w[i] * x[i] for i in eachindex(w)),
        MOI.LessThan(900.0),
    )
    
    MOI.optimize!(model)
    
    results = [
        [919, 983] => [2, 3, 4, 5, 6, 8, 10, 11, 12, 16, 17],
        [928, 972] => [2, 3, 5, 6, 8, 9, 10, 11, 12, 16, 17],
        [935, 971] => [2, 3, 5, 6, 8, 10, 11, 12, 15, 16, 17],
        [936, 947] => [2, 5, 6, 8, 9, 10, 11, 12, 15, 16, 17],
        [937, 942] => [1, 2, 3, 5, 6, 10, 11, 12, 15, 16, 17],
        [944, 940] => [2, 3, 5, 6, 8, 9, 10, 11, 15, 16, 17],
        [949, 939] => [1, 2, 3, 5, 6, 8, 10, 11, 15, 16, 17],
        [950, 915] => [1, 2, 5, 6, 8, 9, 10, 11, 15, 16, 17],
        [956, 906] => [2, 3, 5, 6, 9, 10, 11, 14, 15, 16, 17],
    ]
    reverse!(results)
    @test MOI.get(model, MOI.ResultCount()) == 9
    for i in 1:MOI.get(model, MOI.ResultCount())
        x_sol = MOI.get(model, MOI.VariablePrimal(i), x)
        X = findall(elt -> elt > 0.9, x_sol)
        Y = MOI.get(model, MOI.ObjectiveValue(i))
        @test results[i] == (round.(Int, Y) => X)
    end
    @test MOI.get(model, MOI.ObjectiveBound()) == [956.0, 983.0]
    return
end

function test_infeasible(;augmecon_type)
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    x = MOI.add_variables(model, 2)
    MOI.add_constraint.(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint(model, 1.0 * x[1] + 1.0 * x[2], MOI.LessThan(-1.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    f = MOI.Utilities.operate(vcat, Float64, 1.0 .* x...)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.INFEASIBLE
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.NO_SOLUTION
    @test MOI.get(model, MOI.DualStatus()) == MOI.NO_SOLUTION
    return
end

function test_unbounded(;augmecon_type)
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    x = MOI.add_variables(model, 2)
    MOI.add_constraint.(model, x, MOI.GreaterThan(0.0))
    f = MOI.Utilities.operate(vcat, Float64, 1.0 .* x...)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.DUAL_INFEASIBLE
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.NO_SOLUTION
    @test MOI.get(model, MOI.DualStatus()) == MOI.NO_SOLUTION
    return
end

function test_unbounded_second(;augmecon_type)
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    x = MOI.add_variables(model, 2)
    MOI.add_constraint.(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint(model, x[1], MOI.LessThan(1.0))
    f = MOI.Utilities.operate(vcat, Float64, 1.0 .* x...)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.DUAL_INFEASIBLE
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.NO_SOLUTION
    @test MOI.get(model, MOI.DualStatus()) == MOI.NO_SOLUTION
    return
end

function test_quadratic(; augmecon_type)
    μ = [0.05470748600000001, 0.18257110599999998]
    Q = [0.00076204 0.00051972; 0.00051972 0.00546173]
    N = 2
    model = MOA.Optimizer(Ipopt.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    w = MOI.add_variables(model, N)
    MOI.add_constraint.(model, w, MOI.GreaterThan(0.0))
    MOI.add_constraint.(model, w, MOI.LessThan(1.0))
    MOI.add_constraint(model, sum(1.0 * w[i] for i in 1:N), MOI.EqualTo(1.0))
    var = sum(Q[i, j] * w[i] * w[j] for i in 1:N, j in 1:N)
    mean = sum(-μ[i] * w[i] for i in 1:N)
    f = MOI.Utilities.operate(vcat, Float64, var, mean)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ResultCount()) == 10
    for i in 1:MOI.get(model, MOI.ResultCount())
        w_sol = MOI.get(model, MOI.VariablePrimal(i), w)
        y = MOI.get(model, MOI.ObjectiveValue(i))
        @test y ≈ [w_sol' * Q * w_sol, -μ' * w_sol]
    end
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    return
end

function test_poor_numerics(;augmecon_type)
    μ = [0.006898463772627643, -0.02972609131603086]
    Q = [0.030446 0.00393731; 0.00393731 0.00713285]
    N = 2
    model = MOA.Optimizer(Ipopt.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    w = MOI.add_variables(model, N)
    sharpe = MOI.add_variable(model)
    MOI.add_constraint.(model, w, MOI.GreaterThan(0.0))
    MOI.add_constraint.(model, w, MOI.LessThan(1.0))
    MOI.add_constraint(model, sum(1.0 * w[i] for i in 1:N), MOI.EqualTo(1.0))
    variance = Expr(:call, :+)
    for i in 1:N, j in 1:N
        push!(variance.args, Expr(:call, :*, Q[i, j], w[i], w[j]))
    end
    nlp = MOI.Nonlinear.Model()
    MOI.Nonlinear.add_constraint(
        nlp,
        :(($(μ[1]) * $(w[1]) + $(μ[2]) * $(w[2])) / sqrt($variance) - $sharpe),
        MOI.EqualTo(0.0),
    )
    evaluator = MOI.Nonlinear.Evaluator(
        nlp,
        MOI.Nonlinear.SparseReverseMode(),
        [w; sharpe],
    )
    MOI.set(model, MOI.NLPBlock(), MOI.NLPBlockData(evaluator))
    f = MOI.Utilities.operate(vcat, Float64, μ' * w, sharpe)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ResultCount()) == 1
    for i in 1:MOI.get(model, MOI.ResultCount())
        w_sol = MOI.get(model, MOI.VariablePrimal(i), w)
        sharpe_sol = MOI.get(model, MOI.VariablePrimal(i), sharpe)
        y = MOI.get(model, MOI.ObjectiveValue(i))
        @test y ≈ [μ' * w_sol, sharpe_sol]
    end
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    return
end

#####################
#####################

function test_vectornonlinearfunction(;augmecon_type)
    μ = [0.006898463772627643, -0.02972609131603086]
    Q = [0.030446 0.00393731; 0.00393731 0.00713285]
    N = 2
    model = MOA.Optimizer(Ipopt.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    w = MOI.add_variables(model, N)
    MOI.add_constraint.(model, w, MOI.GreaterThan(0.0))
    MOI.add_constraint.(model, w, MOI.LessThan(1.0))
    MOI.add_constraint(model, sum(1.0 * w[i] for i in 1:N), MOI.EqualTo(1.0))
    f = MOI.VectorNonlinearFunction([
        μ' * w,
        MOI.ScalarNonlinearFunction(
            :/,
            Any[μ'*w, MOI.ScalarNonlinearFunction(:sqrt, Any[w'*Q*w])],
        ),
    ])
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ResultCount()) >= 1
    for i in 1:MOI.get(model, MOI.ResultCount())
        w_sol = MOI.get(model, MOI.VariablePrimal(i), w)
        y = MOI.get(model, MOI.ObjectiveValue(i))
        @test y ≈ [μ' * w_sol, (μ' * w_sol) / sqrt(w_sol' * Q * w_sol)]
    end
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    return
end

function test_time_limit(;augmecon_type)
    p1 = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91, 99, 63, 84, 87, 79, 94, 90]
    p2 = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92, 74, 97, 60, 60, 65, 97, 93]
    w = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93, 98, 72, 100, 89, 67, 86, 91]
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.TimeLimitSec(), 0.0)
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    x = MOI.add_variables(model, length(w))
    MOI.add_constraint.(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = MOI.Utilities.operate(
        vcat,
        Float64,
        [sum(1.0 * p[i] * x[i] for i in 1:length(w)) for p in [p1, p2]]...,
    )
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(
        model,
        sum(1.0 * w[i] * x[i] for i in 1:length(w)),
        MOI.LessThan(900.0),
    )
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.TIME_LIMIT
    # Check time limits in subsolves
    @test_broken MOI.get(model, MOI.ResultCount()) == 0
    return
end

function test_time_limit_large(;augmecon_type)
    p1 = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91, 99, 63, 84, 87, 79, 94, 90]
    p2 = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92, 74, 97, 60, 60, 65, 97, 93]
    w = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93, 98, 72, 100, 89, 67, 86, 91]
    model = MOA.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    MOI.set(model, MOI.TimeLimitSec(), 1.0)
    x = MOI.add_variables(model, length(w))
    MOI.add_constraint.(model, x, MOI.ZeroOne())
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = MOI.Utilities.operate(
        vcat,
        Float64,
        [sum(1.0 * p[i] * x[i] for i in 1:length(w)) for p in [p1, p2]]...,
    )
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(
        model,
        sum(1.0 * w[i] * x[i] for i in 1:length(w)),
        MOI.LessThan(900.0),
    )
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ResultCount()) >= 0
    return
end

function test_vector_of_variables_objective(;augmecon_type)
    model = MOI.instantiate(; with_bridge_type = Float64) do
        return MOA.Optimizer(HiGHS.Optimizer)
    end
    MOI.set(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MethodAUGMECON.AugmeconType(), augmecon_type)
    x = MOI.add_variables(model, 2)
    MOI.add_constraint.(model, x, MOI.ZeroOne())
    f = MOI.VectorOfVariables(x)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(model, sum(1.0 * xi for xi in x), MOI.GreaterThan(1.0))
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    return
end

##### Results for general problems

function simple_biobjective_table()
    return [
        20.0 160.0;
        7.999999999999993 184.0
    ]
end

function simple_biobjective_frontier()
    return [
        8.0 9.333333333333329 10.666666666666671 12.0 13.333333333333329 14.666666666666671 16.0 17.33333333333333 18.66666666666667 20.0;
        184.0 181.33333333333334 178.66666666666666 176.0 173.33333333333334 170.66666666666666 168.0 165.33333333333334 162.66666666666666 160.0
    ]
end

function simple_triobjective_table()
    return [
        3.075e6 62460.0 33000.0;
        3.855000000000002e6 45179.99999999995 37000.00000000001;
        3.2250000000000005e6 55259.99999999997 22999.999999999996
    ]
end

function simple_triobjective_frontier()
    return [
        3.075e6 3.085e6 3.1083333333333335e6 3.115e6 3.131666666666667e6 3.155e6 3.178333333333333e6 3.195e6 3.2016666666666665e6 3.225e6 3.2550000000000014e6 3.3750000000000023e6 3.4950000000000023e6 3.6150000000000023e6 3.735000000000003e6 3.8550000000000037e6;
        62460.0 61980.0 60860.0 60540.0 59740.0 58619.999999999985 57500.0 56699.999999999985 56380.0 55260.0 54779.99999999998 52859.99999999997 50939.99999999996 49019.99999999997 47099.999999999956 45179.99999999995;
        33000.0 32333.333333333336 30777.77777777778 30333.333333333332 29222.222222222223 27666.666666666646 26111.11111111111 24999.999999999978 24555.555555555555 22999.999999999996 23666.666666666697 26333.33333333338 29000.00000000005 31666.666666666715 34333.333333333394 37000.00000000007
    ]
end

##### Declaring models

function simple_biobjective_problem()
    model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))
    set_silent(model)

    set_attribute(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))

    @variables model begin
        x[1:2] >= 0
    end

    @constraints model begin
        c1, x[1] <= 20
        c2, x[2] <= 40
        c3, 5 * x[1] + 4 * x[2] <= 200
    end
    @objective(model, Max, [x[1], 3 * x[1] + 4 * x[2]])
    return model
end

function simple_triobjective_problem()
    model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))
    set_silent(model)

    set_attribute(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))

    @variables model begin
        LIGN >= 0
        LIGN1 >= 0
        LIGN2 >= 0
        OIL >= 0
        OIL2 >= 0
        OIL3 >= 0
        NG >= 0
        NG1 >= 0
        NG2 >= 0
        NG3 >= 0
        RES >= 0
        RES1 >= 0
        RES3 >= 0
    end 

    @constraints model begin
        c1, LIGN - LIGN1 - LIGN2 == 0
        c2, OIL - OIL2 - OIL3 == 0
        c3, NG - NG1 - NG2 - NG3 == 0
        c4, RES - RES1 - RES3 == 0
        c5, LIGN <= 31000
        c6, OIL <= 15000
        c7, NG <= 22000
        c8, RES <= 10000
        c9, LIGN1 + NG1 + RES1 >= 38400
        c10, LIGN2 + OIL2 + NG2 >= 19200
        c11, OIL3 + NG3 + RES3 >= 6400
    end
    @objective(model, Min, [
        (30.0 * LIGN + 75.0 * OIL + 60.0 * NG + 90.0 * RES),
        (1.44 * LIGN + 0.72 * OIL + 0.45 * NG),
        (OIL + NG)
    ])
    return model
end

end

TestAUGMECON.run_tests()
