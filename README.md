# Benchmarking Potential Methods

Evaluation of interatomic-potential energy methods across multiple datasets.


## Description

> [!IMPORTANT]
> Still under construction


## Usage

```shell
01-evaluate-dataset.sh -n PLA15 -m PM6-ML UMA-S
```

### Dependencies

Install **Cuby** following the official [instructions](http://cuby4.molecular.cz/installation.html).


## Results

Results are available [here](https://github.com/tobiasmarek/protein-ligand-benchmarks.github.io).


## Methods

Each potential method is defined in the `methods/` directory.

### Adding new methods

Use existing directories as templates when adding your own. **Cuby** must know how to handle them as well.


## Datasets

Several datasets are available in **[Cuby](http://cuby4.molecular.cz/datasets.html)**. 

### Adding new datasets

Place the dataset in the `datasets/` directory and follow the structure of `datasets/example_dataset`.