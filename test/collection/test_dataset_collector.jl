# using Base.Test
# using AutoRisk

# const NUM_FEATURES = 398
# const NUM_TARGETS = 5
# const BASE_TEST_DIR = ".."

# include("testing_utils.jl")

function test_reset_determinism()
    filepath_1 = joinpath(BASE_TEST_DIR, "data/test_dataset_collector_1.h5")
    col_1 = build_debug_dataset_collector(output_filepath = filepath_1)
    rand!(col_1, 3)

    filepath_2 = joinpath(BASE_TEST_DIR, "data/test_dataset_collector_2.h5")
    col_2 = build_debug_dataset_collector(output_filepath = filepath_2)
    rand!(col_2, 3)

    @test col_1.roadway == col_2.roadway
    @test col_1.scene == col_2.scene

    rm(filepath_1)
    rm(filepath_2)
end

function test_generate_dataset_determinism()
    filepath = joinpath(BASE_TEST_DIR, "data/test_dataset_collector.h5")
    feature_dim, target_dim = NUM_FEATURES, NUM_TARGETS
    col = build_debug_dataset_collector(
        output_filepath = filepath,
        num_samples = 10,
        feature_dim = feature_dim,
        target_dim = target_dim)
    generate_dataset(col)

    file = h5open(filepath, "r")
    features_1 = read(file["risk/features"])
    targets_1 = read(file["risk/targets"])

    @test size(features_1, 1) == feature_dim
    @test size(targets_1, 1) == target_dim

    rm(filepath)

    col = build_debug_dataset_collector(
        output_filepath = filepath,
        num_samples = 10,
        feature_dim = feature_dim,
        target_dim = target_dim)
    generate_dataset(col)

    file = h5open(filepath, "r")
    features_2 = read(file["risk/features"])
    targets_2 = read(file["risk/targets"])

    @test features_1 == features_2
    @test targets_1 == targets_2

    rm(filepath)
end

function test_generate_dataset()
    filepath = joinpath(BASE_TEST_DIR, "data/test_dataset_collector.h5")
    col = build_debug_dataset_collector(
        output_filepath = filepath,
        num_samples = 2,
        min_num_veh = 20,
        max_num_veh = 20,
        chunk_dim = 1,
        max_vehicle_length = 10,
        roadway_length = 100.,
        roadway_radius = 50.,
        lon_σ = 2.,
        lat_σ = .5
    )
    generate_dataset(col)
    file = h5open(filepath, "r")
    features = read(file["risk/features"])
    targets = read(file["risk/targets"])
    
    # check for valid targets
    @test !any(isnan.(features))
    @test !any(isnan.(targets))

    # check that some targets are between 0 and 1 in order to ensure that 
    # monte carlo runs are being accounted for
    valid = false
    for sample in targets
        for target in sample
            if target > 0 && target < 1
                valid = true
                break
            end
        end
    end
    # if this fails, that means all the collected targets were either 0 or 1
    # which means the monte carlo runs are not being accounted for
    @test valid

    rm(filepath)
end

function test_generate_multi_timestep_dataset()
    filepath = joinpath(BASE_TEST_DIR, "data/test_dataset_collector.h5")
    col = build_debug_dataset_collector(
        output_filepath = filepath,
        num_samples = 2,
        min_num_veh = 4,
        max_num_veh = 4,
        chunk_dim = 1,
        feature_timesteps = 2
    )
    generate_dataset(col)
    file = h5open(filepath, "r")
    features = read(file["risk/features"])
    targets = read(file["risk/targets"])
    
    @test size(features) == (NUM_FEATURES, 2, 8)
    @test size(targets) == (NUM_TARGETS, 30, 8)
    @test !any(isnan.(features))
    @test !any(isnan.(targets))

    rm(filepath)
end


@time test_reset_determinism()
@time test_generate_dataset_determinism()
@time test_generate_dataset()
@time test_generate_multi_timestep_dataset()
