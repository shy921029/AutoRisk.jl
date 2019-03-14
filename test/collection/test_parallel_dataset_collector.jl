# using Base.Test
# using AutoRisk

# const NUM_FEATURES = 398
# const NUM_TARGETS = 5
# const BASE_TEST_DIR = ".."

# include("testing_utils.jl")

function test_generate_dataset_parallel()
    num_col = 2
    filepaths = [joinpath(BASE_TEST_DIR, "data/test_dataset_collector_$(i).h5")
        for i in 1:num_col]
    cols = [build_debug_dataset_collector(
        output_filepath = filepaths[i],
        num_samples = 3,
        min_num_veh = 4,
        max_num_veh = 4,
        chunk_dim = 1,
        init_file = false) for i in 1:num_col]
    seeds = collect(1:3)
    output_filepath = joinpath(BASE_TEST_DIR, "data/test_dataset_collector.h5")
    pcol = ParallelDatasetCollector(cols, seeds, output_filepath)

    for col in pcol.cols
        @test 1 <= length(col.seeds) <= 2
    end

    generate_dataset(pcol)

    h5open(output_filepath, "r") do file
        features = file["risk/features"]
        @test !any(isnan.(mean(read(features), dims=3)))
        @test size(features, 3) == 12

        targets = file["risk/targets"]
        @test !any(isnan.(mean(read(targets), dims=3)))
        @test size(targets, 3) == 12

        seeds = read(file["risk/seeds"])
        @test length(seeds) == 3
        @test seeds == collect(1:3)

        batch_idxs = read(file["risk/batch_idxs"])
        @test batch_idxs == collect(4:4:12)
    end
    rm(output_filepath)
end

@time test_generate_dataset_parallel()