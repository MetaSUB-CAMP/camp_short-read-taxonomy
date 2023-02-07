============
CAMP Short-Read Taxonomy
============


.. image:: https://readthedocs.org/projects/camp-short-read-taxonomy/badge/?version=latest
        :target: https://camp-short-read-taxonomy.readthedocs.io/en/latest/?version=latest
        :alt: Documentation Status

.. image:: https://img.shields.io/badge/version-0.4.1-brightgreen


Overview
--------

This module is designed to function as both a standalone short-read-taxonomy pipeline as well as a component of the larger CAMP/CAP2 metagenome analysis pipeline. As such, it is both self-contained (ex. instructions included for the setup of a versioned environment, etc.), and seamlessly compatible with other CAMP modules (ex. ingests and spawns standardized input/output config files, etc.). 

There are three taxonomic classification tools integrated which can be run in any combination: MetaPhlan4, Kraken2 (along with Bracken for relative abundance estimation), and XTree (formerly UTree). 

Installation
------------

1. Clone repo from `Github <https://github.com/MetaSUB-CAMP/camp_short-read-taxonomy>`_.

2. Set up the conda environment (contains, Snakemake) using ``configs/conda/short-read-taxonomy.yaml``. 

3. Kraken2 needs to be installed from Github directly and separately despite having an environment because, like Bowtie2, it frequently misbehaves. 
::
    git clone https://github.com/DerrickWood/kraken2.git
    cd kraken2/
    ./install_kraken2.sh ./

4. XTree also needs to be installed from Github directly with the following commands. After installation, the location of the executable (called ``xtree``, needs to ``chmod``-ed) needs to be added to ``configs/parameters.yaml`` under ``xtree_executable``.

5. The Metaphlan4 database can be downloaded to a central database folder using one of two options:
::
    # Option 1: Using MetaPhlan4
    metaphlan --install --bowtie2db /path/to/Databases/Metaphlan4_29122022
    # Option 2: Manually
    wget http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vJan21_CHOCOPhlAnSGB_202103.tar &
    wget http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_vJan21_CHOCOPhlAnSGB_202103.md5 &
    wget http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/mpa_latest &

6. The Kraken2 database also needs to be downloaded to a database folder. However, as of 29/12/2022, NCBI made changes to their FTP links such that some of ``kraken2-build``'s internals don't work. Instead, download a pre-built `database <https://benlangmead.github.io/aws-indexes/k2>`_ from:
::
    mkdir -p Kraken2_29122022/Prebuilt_09122022/
    cd Kraken2_29122022/Prebuilt_09122022/
    wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20221209.tar.gz
    tar -xf k2_standard_20221209.tar.gz

7. The NCBI Taxonomy database's pairing of names to accession IDs was downloaded along with the Kraken2 database. It can be found at ``/path/to/Databases/Kraken2_29122022/taxonomy/names.dmp``.

8. The XTree databases also need to be downloaded to a database folder. Details TBD.

9. Update the locations of the test datasets in ``samples.csv``, and the relevant parameters in ``test_data/parameters`` and ``configs/parameters.yaml``.

10. Make sure the installed pipeline works correctly. 
::
    # Create and activate conda environment 
    cd camp_short-read-taxonomy
    conda env create -f configs/conda/short-read-taxonomy.yaml
    conda activate short-read-taxonomy
    
    # Run tests on the included sample dataset
    python /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py test


Using the Module
----------------

**Input**: ``/path/to/samples.csv`` provided by the user.

**Output**: Summary reports from MetaPhlan4, Kraken2, and/or XTree. For more information, see the demo test output directory in ``test_data/test_out``. 

- ``/path/to/camp/dir/short-read-taxonomy/final_reports/*.tsv`` where ``*`` is one of the classification algorithms

**Structure**:
::
    └── workflow
        ├── Snakefile
        ├── short-read-taxonomy.py
        ├── utils.py
        └── __init__.py
- ``workflow/short-read-taxonomy.py``: Click-based CLI that wraps the ``snakemake`` and other commands for clean management of parameters, resources, and environment variables.
- ``workflow/Snakefile``: The ``snakemake`` pipeline. 
- ``workflow/utils.py``: Sample ingestion and work directory setup functions, and other utility functions used in the pipeline and the CLI.

1. Make your own ``samples.csv`` based on the template in ``configs/samples.csv``.
    - ``samples.csv`` requires either absolute paths or paths relative to the directory that the module is being run in
    - Note: Metaphlan and Bracken merge outputs from all samples to get aggregated relative abundances across all samples. To get relative abundances for a single sample, put each sample in its own ``samples.csv``.

2. Update the relevant parameters in ``configs/parameters.yaml``.

3. Update the computational resources available to the pipeline in ``resources.yaml``. 

4. To run CAMP on the command line, use the following, where ``/path/to/work/dir`` is replaced with the absolute path of your chosen working directory, and ``/path/to/samples.csv`` is replaced with your copy of ``samples.csv``. 
    - The default number of cores available to Snakemake is 1 which is enough for test data, but should probably be adjusted to 10+ for a real dataset.
    - Relative or absolute paths to the Snakefile and/or the working directory (if you're running elsewhere) are accepted!
::
    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        -d /path/to/work/dir \
        -s /path/to/samples.csv
* Note: This setup allows the main Snakefile to live outside of the work directory.
* Note: If the module failed for some reason previously, use the flag ``--unlock`` to allow changes to be made to the directory. 

5. To run CAMP on a job submission cluster (for now, only Slurm is supported), use the following.
    - ``--slurm`` is an optional flag that submits all rules in the Snakemake pipeline as ``sbatch`` jobs. 
    - In Slurm mode, the ``-c`` flag refers to the maximum number of ``sbatch`` jobs submitted in parallel, **not** the pool of cores available to run the jobs. Each job will request the number of cores specified by threads in ``configs/resources/slurm.yaml``.
::
    sbatch -J jobname -o jobname.log << "EOF"
    #!/bin/bash
    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        --slurm (-c max_number_of_parallel_jobs_submitted) \
        -d /path/to/work/dir \
        -s /path/to/samples.csv
    EOF

6. After checking over ``final_reports/`` and making sure you have everything you need, you can delete all intermediate files to save space. 
::

    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        cleanup \
        -d /path/to/work/dir \
        -s /path/to/samples.csv

7. If for some reason the module keeps failing, CAMP can print a script containing all of the remaining commands that can be run manually. 
::

    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        --dry_run \
        -d /path/to/work/dir \
        -s /path/to/samples.csv > cmds.txt
    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        commands cmds.txt

8. To plot grouped bar graph(s) of the sample alpha and beta diversities remaining after each quality control step in each sample, set up the dataviz environment and follow the instructions in the Jupyter notebook:
::
    conda env create -f configs/conda/dataviz.yaml
    conda activate dataviz
    jupyter notebook &

Updating the Module
--------------------

What if you've customized some components of the module, but you still want to update the rest of the module with latest version of the standard CAMP? Just do the following from within the module's home directory:
    - The flag with the setting ``-X ours`` forces conflicting hunks to be auto-resolved cleanly by favoring the local (i.e.: your) version.
::
    cd /path/to/camp_short-read-taxonomy
    git pull -X ours

Extending the Module
--------------------

We love to see it! This module was partially envisioned as a dependable, prepackaged sandbox for developers to test their shiny new tools in. 

These instructions are meant for developers who have made a tool and want to integrate or demo its functionality as part of a standard short-read taxonomy workflow, or developers who want to integrate an existing short-read taxonomy tool. 

1. Write a module rule that wraps your tool and integrates its input and output into the pipeline. 
    - This is a great `Snakemake tutorial <https://bluegenes.github.io/hpc-snakemake-tips/>`_ for writing basic Snakemake rules.
    - If you're adding new tools from an existing YAML, use ``conda env update --file configs/conda/existing.yaml --prune``.
    - If you're using external scripts and resource files that i) cannot easily be integrated into either `utils.py` or `parameters.yaml`, and ii) are not as large as databases that would justify an externally stored download, add them to ``workflow/ext/`` and use ``rule external_rule`` as a template to wrap them. 
2. Update the ``make_config`` in ``workflow/Snakefile`` rule to check for your tool's output files. Update ``samples.csv`` to document its output if downstream modules/tools are meant to ingest it. 
    - If you plan to integrate multiple tools into the module that serve the same purpose but with different input or output requirements (ex. for alignment, Minimap2 for Nanopore reads vs. Bowtie2 for Illumina reads), you can toggle between these different 'streams' by setting the final files expected by ``make_config`` using the example function ``workflow_mode``.
    - Update the description of the ``samples.csv`` input fields in the CLI script ``workflow/short-read-taxonomy.py``. 
3. If applicable, update the default conda config using ``conda env export > config/conda/short-read-taxonomy.yaml`` with your tool and its dependencies. 
    - If there are dependency conflicts, make a new conda YAML under ``configs/conda`` and specify its usage in specific rules using the ``conda`` option (see ``first_rule`` for an example).
4. Add your tool's installation and running instructions to the module documentation and (if applicable) add the repo to your `Read the Docs account <https://readthedocs.org/>`_ + turn on the Read the Docs service hook.
5. Run the pipeline once through to make sure everything works using the test data in ``test_data/`` if appropriate, or your own appropriately-sized test data. 
    * Note: Python functions imported from ``utils.py`` into ``Snakefile`` should be debugged on the command-line first before being added to a rule because Snakemake doesn't port standard output/error well when using ``run:``.

6. Increment the version number of the modular pipeline- ``patch`` for bug fixes (changes E), ``minor`` for substantial changes to the rules and/or workflow (changes C), and ``major`` only applies to major releases of the CAMP. 
::

    bump2version --current-version A.C.E patch

7. If you want your tool integrated into the main CAMP pipeline, send a pull request and we'll have a look at it ASAP! 
    - Please make it clear what your tool intends to do by including a summary in the commit/pull request (ex. "Release X.Y.Z: Integration of tool A, which does B to C and outputs D").

.. ..

 <!--- 
 Bugs
 ----
 Put known ongoing problems here
 --->


Credits
-------

* This package was created with `Cookiecutter <https://github.com/cookiecutter/cookiecutter>`_ as a simplified version of the `project template <https://github.com/audreyr/cookiecutter-pypackage>`_.
* Free software: MIT 
* Documentation: https://short-read-taxonomy.readthedocs.io. 
