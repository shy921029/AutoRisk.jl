
export 
    LearnedBehaviorGenerator,
    rand!

mutable struct LearnedBehaviorGenerator <: BehaviorGenerator
    filepath::String
end
function Random.rand!(gen::LearnedBehaviorGenerator, models::Dict{Int, DriverModel}, 
        scene::Scene, seed::Int64)
    if length(models) == 0
        for veh in scene.vehicles
            if veh.id == 1
                extractor = MultiFeatureExtractor(gen.filepath)
                gru_layer = contains(gen.filepath, "gru")
                model = load_gaussian_mlp_driver(gen.filepath, extractor, 
                    gru_layer = gru_layer)
                models[veh.id] = model
            else
                models[veh.id] = Tim2DDriver(.1)
            end
        end
    end
    return models
end