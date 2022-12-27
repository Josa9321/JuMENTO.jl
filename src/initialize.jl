function augmecon_model(model, objectives)
    return AugmeconJuMP(
        model,
        objectives,
        0,
        0.0,
        0.0
    )
end