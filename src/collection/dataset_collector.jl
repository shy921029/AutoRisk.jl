export 
    DatasetCollector,
    ParallelDatasetCollector,
    rand!,
    generate_dataset

"""
# Description:
    - DatasetCollector orchestrates the serial collection of a dataset.
"""
mutable struct DatasetCollector
    seeds::Vector{Int64}

    gen::Generator
    eval::Evaluator
    dataset::Dataset

    scene::Scene
    models::Dict{Int, DriverModel}
    roadway::Roadway

    id::Int
    monitor::Any
    function DatasetCollector(seeds::Vector{Int64}, gen::Generator,
            eval::Evaluator, dataset::Dataset, scene::Scene, 
            models::Dict{Int, DriverModel}, roadway::Roadway; id::Int = 0,
            monitor::Any = nothing)
        return new(seeds, gen, eval, dataset, scene, models, roadway, id, 
            monitor)
    end
end

"""
# Description:
    - Reset the state randomly according to the random seed

# Args:
    - col: the collector being used
    - seed: the random seed uniquely identifying the resulting state
"""
function Random.rand!(col::DatasetCollector, seed::Int64)
    @info("id $(col.id) collecting seed $(seed)")
    rand!(col.gen, col.roadway, col.scene, col.models, seed)
end

"""
Description:
    - need this because it is possible that monitoring will not be available, 
    and when that is the case the montior with be a nothing object. 
"""
monitor(mon::Nothing, col::DatasetCollector, seed::Int) = col

"""
# Description:
    - Generate a dataset for each seed of the collector

# Args:
    - col: the collector to use
"""
function generate_dataset(col::DatasetCollector)
    for seed in col.seeds
        rand!(col, seed)
        evaluate!(col.eval, col.scene, col.models, col.roadway, seed)
        update!(col.dataset, get_features(col.eval), get_targets(col.eval), 
            get_weights(col.gen), seed)
        monitor(col.monitor, col, seed)
    end
    finalize!(col.dataset)
end

"""
# Description:
    - ParallelDatasetCollector orchestrates the parallel generation 
        of a dataset.
"""
mutable struct ParallelDatasetCollector
    cols::Vector{DatasetCollector}
    output_filepath::String

    """
    # Args:
        - cols: a vector of dataset collectors 
        - seeds: the seeds for which states should be generated and simulated.
            note that these are partitioned in the constructor
        - output_filepath: filepath for the final dataset
    """
    function ParallelDatasetCollector(cols::Vector{DatasetCollector}, 
            seeds::Vector{Int64}, output_filepath::String)
        seedsets = ordered_partition(seeds, length(cols))
        for (col, seeds) in zip(cols, seedsets)
            col.seeds = seeds
        end
        return new(cols, output_filepath)
    end
end

"""
# Description:
    - Generate a dataset in parallel.

# Args:
    - pcol: the parallel dataset collector to use
"""
function generate_dataset(pcol::ParallelDatasetCollector)
    pmap(generate_dataset, pcol.cols)
    filepaths = [c.dataset.filepath for c in pcol.cols]
    aggregate_datasets(filepaths, pcol.output_filepath)
    [rm(f) for f in filepaths]
end

