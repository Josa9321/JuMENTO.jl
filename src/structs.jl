using JuMP

mutable struct AugmeconJuMP{N <: Integer, F <: AbstractFloat}
    JuMP_model::Model
    objectives::Vector{VariableRef}
    iterations_counter::N
    time::F
    gap::F
end

struct AuxAUGMECON{N <: Integer, F <: AbstractFloat, D}
    augmecon_model::AugmeconJuMP{N, F}
    solution_type::D
    grid_points::N
end

abstract type VariablesJuMP end

struct SolutionJuMP{V <: VariablesJuMP, F <: AbstractFloat}
    variables::V
    objectives::Vector{F}
end