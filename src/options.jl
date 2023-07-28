function augmecon_options(grid_points, num_objectives, user_options) 
    options = set_options_dict(grid_points, num_objectives, user_options)
    add_default_options_if_needed!(options)
    verify_options(options)
    return options
end

###########################
###########################

function set_options_dict(grid_points, num_objectives, user_options)
    options = Dict{Symbol, Any}(
        :grid_points => grid_points,
        :num_objectives => num_objectives,
    )
    for (k, value) in pairs(user_options)
        options[k] = value
    end
    return options
end

function add_default_options_if_needed!(options)
    add_default!(options, :objective_sense_set, ["Max" for i in Base.OneTo(options[:num_objectives])])
    add_default!(options, :penalty, 1e-3)
    add_default!(options, :bypass, true)
    return options
end


function add_default!(options_set, key, value) 
    !(key in keys(options_set)) ? options_set[key] = value : nothing
end

###########################
###########################

function verify_options(options)
    verify_bypass(options) 
    verify_grid_points(options) 
    verify_penalty(options) 
    verify_objectives_sense_set(options)
    verify_nadir(options)
end

verify_bypass(options) = @assert typeof(options[:bypass]) == Bool "bypass option should be a Bool type"

function verify_grid_points(options)
    grid_points = options[:grid_points]
    @assert typeof(grid_points) == Int64 "Number of grid_points should be integer"
    @assert grid_points > 0 "Number of grid_points should be positive"
    return nothing
end

function verify_penalty(options)
    penalty = options[:penalty]
    @assert typeof(penalty) == Float64 "penalty should be a Float64"
    if !(penalty <= 1e-3 && penalty >= 1e-6) 
        @warn "Penalty is outside the interval suggested by the AUGMECON authors (1e-3, 1e-6)"
    end
    return nothing
end

function verify_objectives_sense_set(options)
    objective_sense_set = options[:objective_sense_set]
    @assert typeof(objective_sense_set) == Vector{String} "The sense set isn't a Float Vector"
    for sense in objective_sense_set
        @assert (sense == "Max" || sense == "Min") """Objective sense should be "Max" or "Min" """
    end
    @assert length(objective_sense_set) == options[:num_objectives] """Number of objectives ($(length(objectives))) is different than the length of objective_sense_set ($(length(objective_sense_set)))"""
    return true
end

function verify_nadir(options)
    try 
        nadir = options[:nadir]
        @assert typeof(nadir) == Vector{Float64} "typeof nadir isn't equal to Vector{Float64}"
        @assert length(nadir) == options[:num_objectives] "Number of objectives in nadir point should be equal to the number of objectives"
    catch
    end
end