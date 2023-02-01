# CAMP: Short-Read Taxonomy

Overview
--------

This module is designed to function as both a standalone short-read-taxonomy pipeline as well as a component of the larger CAMP/CAP2 metagenome analysis pipeline. As such, it is both self-contained (ex. instructions included for the setup of a versioned environment, etc.), and seamlessly compatible with other CAMP modules (ex. ingests and spawns standardized input/output config files, etc.). 

There are three taxonomic classification tools integrated which can be run in any combination: MetaPhlan4, Kraken2 (along with Bracken for relative abundance estimation), and XTree (formerly UTree). 

Approach
--------
<INSERT PIPELINE IMAGE>

Installation
------------

1. Clone repo: 

```
git clone <https://github.com/MetaSUB-CAMP/camp_short-read-taxonomy>
```

2. Set up the conda environment using ``configs/conda/short-read-taxonomy.yaml``. (Another option would be to use mamba for higher speed)

```
cd camp_short-read-taxonomy
conda env create -f configs/conda/short-read-taxonomy.yaml
conda activate short-read-taxonomy
```

3. Download the databases for the taxonomic pipelines you want to use. Be sure to update the locations of the dbs in the parameters.yaml file. This may take a few hours -- protip, if you want to speed up downloading, trying installing ``axel`` and replacing the ``wget`` with ``axel -a``!

For MetaPhlAn4:

```
wget https://s3.us-east-1.wasabisys.com/camp-databases/v0.1.1/taxonomy/metaphlan_20220926.tar.gz; tar -zxvf metaphlan_20220926.tar.gz
```

(Another potential option would be to use  `metaphlan --install --bowtie2db your_path_to_save_database/` for automatic installation through MetaPhlAn4.)

For Kraken2:

```
wget https://s3.us-east-1.wasabisys.com/camp-databases/v0.1.1/taxonomy/Kraken2.tar.gz; tar -zxvf Kraken2.tar.gz
```

for xtree:

```
wget https://s3.us-east-1.wasabisys.com/camp-databases/v0.1.1/orfcalling/xtree_db_gtdb207_kmer29_comp2_20220722.tar.gz
```



Quickstart
----------

Running each CAMP module takes the same three steps, listed below.

1. As with all CAMP modules, update the `configs/parameters.yaml` file:

| parameter | explanation and options.                                                    |   |   |   |
|-----------|-----------------------------------------------------------------------------|---|---|---|
| ext       | path to the executed scripts, usually the path to your workflow/ext folder. |   |   |   |
| mask      | whether to use bbmask to mask reads, True or False.                         |   |   |   |
| metaphlan | whether to use metaphlan4 to conduct taxonomy calling, True or False.       |   |   |   |
| kraken2   | whether to use kraken2 to conduct taxonomy calling, True or False.          |   |   |   |
| xtree     | whether to use xtree to conduct taxonomy calling, True or False.            |   |   |   |
| metaphlan_database    | [Mandatory only if 'True' for 'metaphlan'] path to your metaphlan database folder that you installed above.            |   |   |   |
| kraken2_executable    | [Mandatory only if 'True' for 'kraken2'] path to your kraken2 database/executable folder that you installed above.            |   |   |   |
| read_len    | [Mandatory only if 'True' for 'kraken2'] integer parameter of kraken2.             |   |   |   |
| bacterial_archaeal_database    | [Mandatory only if 'True' for 'xtree'] path to bacteria/archaeal databases for xtree.            |   |   |   |
| viral_database    | [Mandatory only if 'True' for 'xtree'] path to viral databases for xtree.            |   |   |   |
| protozoa_fungi_database    | [Mandatory only if 'True' for 'xtree'] path to fungi databases for xtree.            |   |   |   |
| xtree_executable    | [Mandatory only if 'True' for 'xtree'] path to executable for xtree.            |   |   |   |
| thresh    | [Mandatory only if 'True' for 'xtree'] fraction parameter for xtree, e.g. 0.02.            |   |   |   |
| hthresh    | [Mandatory only if 'True' for 'xtree'] fraction parameter for xtree, e.g. 0.05.            |   |   |   |
| uthresh    | [Mandatory only if 'True' for 'xtree'] fraction parameter for xtree, e.g. 0.01.            |   |   |   |

2. Generate your samples.csv file in the following format (in a csv file):

|  | illumina_fwd                                                    |  illumina_rev |   |   |
|-----------|-----------------------------------------------------------------------------|---|---|---|
| SAMPLE_NAME      | path to forward read fastq.gz file | path to backward read fastq.gz file  |   |   |
| ...      | ...                         |...   |   |   |

3. Deploy! You can try this example command from the camp_short-read-taxonomy repo:

```
python3 workflow/short-read-taxonomy.py -d testrun -s configs/samples.csv
```

Note: to speed up, you can specify the number of cores with the `--core` flag; to continue a Snakemake process that broke accidentally, you might need to use the `--unlock` Snakemake flag. This can be applied when you run the pipeline on a cluster as well.

```
python3 workflow/short-read-taxonomy.py --cores 5 -d testrun -s configs/samples.csv --unlock
```

Module details
---------------
- ``workflow/short-read-taxonomy.py``: Click-based CLI that wraps the ``snakemake`` and unit test generation commands for clean management of parameters, resources, and environment variables.
- ``workflow/Snakefile``: The ``snakemake`` pipeline. 
- ``workflow/utils.py``: Sample ingestion and work directory setup functions, and other utility functions used in the pipeline and the CLI.

1. Make your own ``samples.csv`` based on the template in ``configs/samples.csv``. Sample test data can be found in ``test_data/``.
    - ``samples.csv`` requires either absolute paths or paths relative to the directory that the module is being run in
    - Note: Metaphlan and Bracken merge outputs from all samples to get aggregated relative abundances across all samples. To get relative abundances for a single sample, put each sample in its own ``samples.csv``.

2. Update the relevant parameters in ``configs/parameters.yaml``.
    * Note: For some reason, ``abspath(__file__)`` does not work to extract the directory that the Snakefile is in, so the directory containing external files and scripts needs to be manually set. 

3. Update the computational resources available to the pipeline in ``resources.yaml``. 

Command line deployment
-----------------------
To run CAMP on the command line, use the following, where ``/path/to/work/dir`` is replaced with the absolute path of your chosen working directory, and ``/path/to/samples.csv`` is replaced with your copy of ``samples.csv``. 
    - The default number of cores available to Snakemake is 1 which is enough for test data, but should probably be adjusted to 10+ for a real dataset.
    - Relative or absolute paths to the Snakefile and/or the working directory (if you're running elsewhere) are accepted!
```
python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py -d /path/to/work/dir -s /path/to/samples.csv
```

* Note: This setup allows the main Snakefile to live outside of the work directory.

Running on a slurm cluster
--------------------------
To run CAMP on a job submission cluster (for now, only Slurm is supported), use the following.
    - ``--slurm`` is an optional flag that submits all rules in the Snakemake pipeline as ``sbatch`` jobs. 
    - In Slurm mode, the ``-c`` flag refers to the maximum number of ``sbatch`` jobs submitted in parallel, **not** the pool of cores available to run the jobs. Each job will request the number of cores specified by threads in ``configs/resources/slurm.yaml``.
```
sbatch -J jobname -o jobname.log << "EOF"
#!/bin/bash
python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
    --slurm (-c max_number_of_parallel_jobs_submitted) \
    -d /path/to/work/dir \
    -s /path/to/samples.csv
    EOF
```
Dependencies
------------    
<LIST ALL DEPENDENCIES>

Credits
-------

* This package was created with `Cookiecutter <https://github.com/cookiecutter/cookiecutter>`_ as a simplified version of the `project template <https://github.com/audreyr/cookiecutter-pypackage>`_.
* Free software: MIT
* Documentation: https://short-read-quality-control.readthedocs.io. 
