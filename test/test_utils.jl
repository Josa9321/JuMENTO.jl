function test_normalization()
    frontier_set = [
        1 3 4 2 -4 7 -10;
        5 70 20 30 0 7 4;
        520 198 819 428 992 25 836;
        872 164 789 592 175 -611 260
    ]
    sense = [:min, :max, :min, :max]
    normalized_set = normalize_frontier(frontier_set, sense)

    correct_normalized = [
        0.352941176470588 0.235294117647059 0.176470588235294 0.294117647058824 0.647058823529412 0 1;
        0.0714285714285714 1 0.285714285714286 0.428571428571429 0 0.1 0.0571428571428571;
        0.488107549120993 0.821096173733195 0.178903826266805 0.583247156153051 0 1 0.161323681489142;
        1 0.522589345920432 0.944032366824005 0.811193526635199 0.530006743088335 0 0.58732299393122
    ]

    @test all(isapprox.(normalized_set, correct_normalized, atol=1e-6))
end

function test_dominance_relations()
end

function test_generate_pareto_frontier()
end
