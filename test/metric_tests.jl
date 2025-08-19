using JuMENTO

function test_all_metrics()

    ##############################
    frontier1 = [10.0 20.0; 100.0 80.0]
    reference1 = [10.0 20.0; 100.0 80.0]

    sp1 = spacing_metric(frontier1)
    gd1 = general_distance(frontier1, reference1)
    dm1 = diversity_metric(frontier1, reference1)
    me1, ve1, mpe1 = calculate_error_metrics(frontier1, reference1)
    er1 = error_ratio(frontier1, reference1)
    hv1 = hypervolume(frontier1, [25.0, 120.0])

    @assert isapprox(sp1, 0.0; atol=1e-6) "Case 1 - Spacing metric failed"
    @assert isapprox(gd1, 0.0; atol=1e-6) "Case 1 - General distance failed"
    @assert isapprox(dm1, 0.0; atol=1e-6) "Case 1 - Diversity metric failed"
    @assert isapprox(me1, 0.0; atol=1e-6) "Case 1 - Mean error failed"
    @assert isapprox(ve1, 0.0; atol=1e-6) "Case 1 - Variance error failed"
    @assert isapprox(mpe1, 0.0; atol=1e-6) "Case 1 - MPE failed"
    @assert isapprox(er1, 0.0; atol=1e-6) "Case 1 - Error ratio failed"
    @assert hv1 > 0.0 "Case 1 - Hypervolume failed"

    ##############################
    frontier2 = [11.0 19.0; 99.0 81.0]
    reference2 = [10.0 20.0; 100.0 80.0]

    sp2 = spacing_metric(frontier2)
    gd2 = general_distance(frontier2, reference2)
    dm2 = diversity_metric(frontier2, reference2)
    me2, ve2, mpe2 = calculate_error_metrics(frontier2, reference2)
    er2 = error_ratio(frontier2, reference2)
    hv2 = hypervolume(frontier2, [25.0, 120.0])

    @assert sp2 == 0.0 "Case 2 - Spacing metric failed"
    @assert gd2 > 0.0 "Case 2 - General distance failed"
    @assert dm2 > 0.0 "Case 2 - Diversity metric failed"
    @assert me2 > 0.0 "Case 2 - Mean error failed"
    @assert ve2 > 0.0 "Case 2 - Variance error failed"
    @assert mpe2 > 0.0 "Case 2 - MPE failed"
    @assert isapprox(er2, 1.0; atol=1e-6) "Case 2 - Error ratio failed"
    @assert hv2 > 0.0 "Case 2 - Hypervolume failed"

    ##############################
    frontier3 = [12.0 18.0; 98.0 82.0]
    reference3 = [10.0 20.0; 100.0 80.0]

    sp3 = spacing_metric(frontier3)
    gd3 = general_distance(frontier3, reference3)
    dm3 = diversity_metric(frontier3, reference3)
    me3, ve3, mpe3 = calculate_error_metrics(frontier3, reference3)
    er3 = error_ratio(frontier3, reference3)
    hv3 = hypervolume(frontier3, [25.0, 120.0])

    @assert sp3 == 0.0 "Case 3 - Spacing metric failed"
    @assert gd3 > 1.0 "Case 3 - General distance failed"
    @assert dm3 > 0.0 "Case 3 - Diversity metric failed"
    @assert me3 > 0.0 "Case 3 - Mean error failed"
    @assert ve3 > 0.0 "Case 3 - Variance error failed"
    @assert mpe3 > 0.0 "Case 3 - MPE failed"
    @assert isapprox(er3, 1.0; atol=1e-6) "Case 3 - Error ratio failed"
    @assert hv3 > 0.0 "Case 3 - Hypervolume failed"
end

test_all_metrics()
