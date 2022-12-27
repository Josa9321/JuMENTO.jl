struct AuxAUGMECON{N <: Integer, F <: AbstractFloat, D <: DataType}
    #, registerFunction, removeFunction}
    model::AugmeconJuMP{N, F}
    solution_type::D
    grid_points::N
    # register_solution::registerFunction
    # remove_equals::removeFunction
end

mutable struct AugmeconJuMP{N <: Integer, F <: AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    iterations_counter::N
    time::F
    gap::F
end

abstract type VariablesJuMP end

struct SolutionJuMP{V <: VariablesJuMP, F <: AbstractFloat}
    variables::V
    objectives::Vector{F}
end

struct KnapsackVariables{F <: AbstractFloat} <: VariablesJuMP
    x::Matrix{F}
end