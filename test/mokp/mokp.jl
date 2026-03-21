module MOKP

using JuMP, HiGHS, XLSX, Test

import MultiObjectiveAlgorithms as MOA
import MultiObjectiveAlgorithms: MOI

import JuMENTO: MethodAUGMECON

export solve_kp_instance, test_instances_set




const GRID_POINTS = Dict("2kp50" => 492, "2kp100" => 823, "2kp250" => 2534, "3kp40" => 540, "3kp50" => 847)
const NADIR = Dict("3kp40" => [1115, 1031.0, 1069.0], "3kp50" => [1396, 1124.0, 1041.0])

function test_instances_set(instances_addresses_set; aug_type, is_silent=true)
    for address in instances_addresses_set
        frontier_set = solve_kp_instance(address, aug_type, is_silent=is_silent)
        frontier_saved = load_and_transpose_sheet(address, "pareto_sols")

        frontier_set = frontier_set[:, sortperm(frontier_set[1, :])]
        frontier_saved = frontier_saved[:, sortperm(frontier_saved[1, :])]

        @test all(isapprox.(frontier_set, frontier_saved))
    end
    return nothing
end

function solve_kp_instance(address, aug_type; is_silent=true)
    global GRID_POINTS, NADIR

    file_name = split(basename(address), ".")[1]
    instance = KnapsackInstance(address)

    model = knapsack_model(instance)
    MOI.set(model, MethodAUGMECON.AugmeconType(), aug_type)
    MOI.set(model, MethodAUGMECON.GridPoints(), GRID_POINTS[file_name])
    if file_name in ["3kp40", "3kp50"]
        MOI.set(model, MethodAUGMECON.Nadir(), NADIR[file_name])
    end
    optimize!(model)
    if !is_silent
        println(file_name)
        println(" - Number of sub problems: ", MOI.get(model, MOA.SubproblemCount()))
    end
    frontier_set = hcat([objective_value(model, result=i) for i in 1:result_count(model)]...)
    return frontier_set
end

###########################

struct KnapsackInstance{F <: AbstractFloat, R <: AbstractRange}
    objectives_coefs::Matrix{F}
    constraints_coefs::Matrix{F}
    RHS::Matrix{F}
    I::R
    J::R
    O::R

    KnapsackInstance(address::String) = begin
        constraints_coefs = load_and_transpose_sheet(address, "a")
        RHS = load_and_transpose_sheet(address, "b")
        objectives_coefs = load_and_transpose_sheet(address, "c")

        new{Float64, Base.OneTo}(
            objectives_coefs,
            constraints_coefs,
            RHS,
            axes(objectives_coefs, 1),
            eachindex(RHS),
            axes(objectives_coefs, 2)
        )
    end
end

function knapsack_model(instance::KnapsackInstance)
    model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))

    set_attribute(model, MOA.Algorithm(), MethodAUGMECON.Augmecon(10))
    set_time_limit_sec(model, 30*60.0)
    set_silent(model)

    @variable(model, x[instance.I], Bin)

    @constraint(model, c[j in instance.J], 
        sum(instance.constraints_coefs[i, j] * x[i] for i in instance.I) <= instance.RHS[j])

    @objective(model, Max, [sum(instance.objectives_coefs[i, o] * x[i] for i in instance.I) for o in instance.O])
    return model
end

###### Auxiliar functions

function load_and_transpose_sheet(address, sheet_ref)
    sheet_loaded = load_knapsack_sheet(address, sheet_ref)
    return copy(transpose(sheet_loaded))
end

function load_knapsack_sheet(address, sheet_ref)
    return Float64.(XLSX.readxlsx(address)[sheet_ref][:][2:end, 2:end])
end

end
