"""
    Augmecon(grid_points::Int63; sense_set::Union{Vector{String}, Nothing}=nothing,
            nadir::Union{Vector{Float64}, Nothing}=nothing, penalty::Float64=1e-3, bypass::Bool=true,
            print_level::Int=0, atol::Union{Float64, nothing}=nothing)

`Augmecon` implements some of the variants of the AUGMECON method, including AUGMECON and AUGMECON 2. 
It can solve problems with any number of objectives.

## Supported optimizer attributes

 * SenseSet: Vector{String} with the sense of each objective, either `:min` or `:max`.
   If not provided, it assumes that all objectives follow the objective declaration.
 * Nadir: Vector{Float64} with the nadir point of the problem.
   If not provided, it is estimated as defined in AUGMECON paper.
 * Penalty: Float with the value of the penalty term in the AUGMECON method. Default is 1e-3.
 * Bypass: Bool that indicates whether to use the bypass strategy of AUGMECON 2. Default is true.
 * PrintLevel: Int that indicates the level of printing during the optimization process. Default is 0 (no printing).
 * Atol: Float with the absolute tolerance for the optimization process. If not provided, it is set to 0.
"""
mutable struct Augmecon <: MOA.AbstractAlgorithm
    grid_points::Int64
    sense_set::Union{Vector{String}, Nothing}
    nadir::Union{Vector{Float64}, Nothing}
    penalty::Float64
    augmecon_type::Int64
    print_level::Int
    atol::Float64

    function Augmecon(grid_points::Int64; sense_set::Union{Vector{String}, Nothing}=nothing,
            nadir::Union{Vector{Float64}, Nothing}=nothing, penalty::Float64=1e-3, augmecon_type::Int64=1,
            print_level::Int=0, atol::Float64=0.0)
        return new(grid_points, sense_set, nadir, penalty, augmecon_type, print_level, atol)
    end
end

######################
# Attributes support #
######################

struct GridPoints <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::GridPoints) = true
function MOI.set(alg::Augmecon, ::GridPoints, value)
    alg.grid_points = value
    return
end
function MOI.get(alg::Augmecon, ::GridPoints)
    return alg.grid_points
end

struct SenseSet <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::SenseSet) = true
function MOI.set(alg::Augmecon, ::SenseSet, value)
    alg.sense_set = value
    return
end
function MOI.get(alg::Augmecon, ::SenseSet)
    return alg.sense_set
end

struct Nadir <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::Nadir) = true
function MOI.set(alg::Augmecon, ::Nadir, value)
    alg.nadir = value
    return
end
function MOI.get(alg::Augmecon, ::Nadir)
    return alg.nadir
end

struct Penalty <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::Penalty) = true
function MOI.set(alg::Augmecon, ::Penalty, value)
    alg.penalty = value
    return
end
function MOI.get(alg::Augmecon, ::Penalty)
    return alg.penalty
end

struct AugmeconType <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::AugmeconType) = true
function MOI.set(alg::Augmecon, ::AugmeconType, value)
    alg.augmecon_type = value
    return
end
function MOI.get(alg::Augmecon, ::AugmeconType)
    return alg.augmecon_type
end

struct PrintLevel <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::PrintLevel) = true
function MOI.set(alg::Augmecon, ::PrintLevel, value)
    alg.print_level = value
    return
end
function MOI.get(alg::Augmecon, ::PrintLevel)
    return alg.print_level
end

struct Atol <: MOA.AbstractAlgorithmAttribute end
MOI.supports(::Augmecon, ::Atol) = true
function MOI.set(alg::Augmecon, ::Atol, value)
    alg.atol = value
    return
end
function MOI.get(alg::Augmecon, ::Atol)
    return alg.atol
end
