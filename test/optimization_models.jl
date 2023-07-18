using JuMP, Cbc, CPLEX

function simple_biobjective_problem()
    model = init_configured_model()
    @variables model begin
        x[1:2] >= 0
        objs[1:2]
    end 

    @constraints model begin
        c1, x[1] <= 20
        c2, x[2] <= 40
        c3, 5*x[1] + 4*x[2] <= 200

        objective_1, objs[1] == x[1]
        objective_2, objs[2] == 3*x[1] + 4*x[2]
    end

    return model, objs
end

function simple_triobjective_problem()
    model = init_configured_model()
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

        objs[1:3]
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

        objective_1, objs[1] == (30.0 * LIGN + 75.0 * OIL + 60.0 * NG + 90.0 * RES)
        objective_2, objs[2] == (1.44 * LIGN + 0.72 * OIL + 0.45 * NG)
        objective_3, objs[3] == (OIL + NG)
    end

    return model, objs
end

function init_configured_model()
    result = Model(Cbc.Optimizer)
    # result = Model(CPLEX.Optimizer)
    set_silent(result)
    set_time_limit_sec(result, 60.0)
    return result
end

