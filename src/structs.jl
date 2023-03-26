abstract type MultiobjectiveAux end

mutable struct AugmeconJuMP{N <: Integer, F <: AbstractFloat}
    model::Model
    objectives::Vector{VariableRef}
    iterations_counter::N
    time::F
    gap::F
end

struct AuxAUGMECON{N <: Integer, F <: AbstractFloat, M1, M2} <: MultiobjectiveAux
    augmecon_model::AugmeconJuMP{N, F}
    grid_points::N
    penalty::F
    num_objectives::N
    init_variables::M1
    register_variables!::M2
end

abstract type VariablesJuMP end

struct SolutionJuMP{V <: VariablesJuMP, F <: AbstractFloat}
    variables::V
    objectives::Vector{F}
end

struct NoVariables <: VariablesJuMP end