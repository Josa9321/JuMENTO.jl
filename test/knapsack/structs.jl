struct KnapsackVariables{F <: AbstractFloat} <: VariablesJuMP
    x::Vector{F}
end

struct KnapsackInstance{F <: AbstractFloat, R <: AbstractRange}
    objectives_coefs::Matrix{F}
    constraints_coefs::Matrix{F}
    RHS::Matrix{F}
    I::R
    J::R
    O::R
end