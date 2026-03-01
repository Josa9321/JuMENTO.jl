if false include("../src/JuMENTO.jl") end
using JuMENTO

function test_multiobjective_metrics()

    ##############################
    frontier1 = [10.0 20.0; 100.0 80.0]
    reference1 = [10.0 20.0; 100.0 80.0]

    sp1 = Metrics.spacing_metric(frontier1, reference1)
    gd1 = Metrics.general_distance(frontier1, reference1)
    dm1 = Metrics.diversity_metric(frontier1, reference1)
    me1, ve1, mpe1 = Metrics.calculate_error_metrics(frontier1, reference1)
    er1 = Metrics.error_ratio(frontier1, reference1)
    hv1 = Metrics.hypervolume(frontier1, [25.0, 120.0])

    @test isapprox(sp1, 0.0, atol=1e-6)
    @test isapprox(gd1, 0.0, atol=1e-6)
    @test isapprox(dm1, 0.0, atol=1e-6)
    @test isapprox(me1, 0.0, atol=1e-6)
    @test isapprox(ve1, 0.0, atol=1e-6)
    @test isapprox(mpe1, 0.0, atol=1e-6)
    @test isapprox(er1, 0.0, atol=1e-6)
    @test hv1 > 0.0

    ##############################
    frontier2 = [11.0 19.0; 99.0 81.0]
    reference2 = [10.0 20.0; 100.0 80.0]

    sp2 = Metrics.spacing_metric(frontier2, reference2)
    gd2 = Metrics.general_distance(frontier2, reference2)
    dm2 = Metrics.diversity_metric(frontier2, reference2)
    me2, ve2, mpe2 = Metrics.calculate_error_metrics(frontier2, reference2)
    er2 = Metrics.error_ratio(frontier2, reference2)
    hv2 = Metrics.hypervolume(frontier2, [25.0, 120.0])

    @test sp2 == 0.0
    @test gd2 > 0.0
    @test dm2 > 0.0
    @test me2 > 0.0
    @test ve2 > 0.0
    @test mpe2 > 0.0
    @test isapprox(er2, 1.0, atol=1e-6)
    @test hv2 > 0.0

    ##############################
    frontier3 = [12.0 18.0; 98.0 82.0]
    reference3 = [10.0 20.0; 100.0 80.0]

    sp3 = Metrics.spacing_metric(frontier3, reference3)
    gd3 = Metrics.general_distance(frontier3, reference3)
    dm3 = Metrics.diversity_metric(frontier3, reference3)
    me3, ve3, mpe3 = Metrics.calculate_error_metrics(frontier3, reference3)
    er3 = Metrics.error_ratio(frontier3, reference3)
    hv3 = Metrics.hypervolume(frontier3, [25.0, 120.0])

    @test sp3 == 0.0 #"Case 3 - Spacing metric failed"
    @test gd3 > 1.0 #"Case 3 - General distance failed"
    @test dm3 > 0.0 #"Case 3 - Diversity metric failed"
    @test me3 > 0.0 #"Case 3 - Mean error failed"
    @test ve3 > 0.0 #"Case 3 - Variance error failed"
    @test mpe3 > 0.0 #"Case 3 - MPE failed"
    @test isapprox(er3, 1.0, atol=1e-6) #"Case 3 - Error ratio failed"
    @test hv3 > 0.0 #"Case 3 - Hypervolume failed"


    ##############################
    frontier4 = [3 6 9; 15 9 4.0]
    reference4 = [1 2 3 4 5 6 7 8 9 10; 10 9 8 7 6 5 4 3 2 1.0]

    sp4 = Metrics.spacing_metric(frontier4, reference4)
    gd4 = Metrics.general_distance(frontier4, reference4)
    dm4 = Metrics.diversity_metric(frontier4, reference4)
    dm4_without_reference_set = Metrics.diversity_metric(frontier4)
    me4, ve4, mpe4 = Metrics.calculate_error_metrics(frontier4, reference4)
    er4 = Metrics.error_ratio(frontier4, reference4)
    hv4 = Metrics.hypervolume(frontier4, [10.1, 15.15])

    @test isapprox(sp4, 2.0126831744720173, atol=1e-6) #"Case 4 - Spacing metric failed"
    @test isapprox(gd4, 2.0816659994661326, atol=1e-6) #"Case 4 - General distance failed"
    @test isapprox(dm4, 0.39696030366206303, atol=1e-6) #"Case 4 - Diversity metric failed"
    @test isapprox(dm4_without_reference_set, 0.0699610125062014, atol=1e-6)
    @test isapprox(er4, 1.0, atol=1e-6) #"Case 4 - Error ratio failed"
    @test isapprox(hv4, 31.165, atol=1e-6) #"Case 4 - Hypervolume failed"

    frontier4_for_err_1 = [1 2 3; 10 9 8.0]
    er4_1 = Metrics.error_ratio(frontier4_for_err_1, reference4)
    @test isapprox(er4_1, 0.0, atol=1e-6)
    frontier4_for_err_2 = [1 2 3 4; 10 9 8 7.5]
    er4_2 = Metrics.error_ratio(frontier4_for_err_2, reference4)
    @test isapprox(er4_2, 0.25, atol=1e-6)

    return nothing
end
