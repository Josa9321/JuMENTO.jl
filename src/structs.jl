mutable struct AuxAUGMECON{M, Vars, Cons, Function, N <: Integer, F <: AbstractFloat}
    model::M
    objectives::Vars
    other_objectives::Cons
    grid_points::N
    register_solution::Function
    numIt::N
    time::F
    gap::F
end

mutable struct AugmeconModel
    model
    numIterations
    time
    gap
end