============
CAMP Short-Read Taxonomy
============


.. image:: https://readthedocs.org/projects/camp-short-read-taxonomy/badge/?version=latest
        :target: https://camp-short-read-taxonomy.readthedocs.io/en/latest/?version=latest
        :alt: Documentation Status

.. image:: https://img.shields.io/badge/version-0.1.0-brightgreen


Overview
--------

This module is designed to function as both a standalone short-read-taxonomy pipeline as well as a component of the larger CAMP/CAP2 metagenome analysis pipeline. As such, it is both self-contained (ex. instructions included for the setup of a versioned environment, etc.), and seamlessly compatible with other CAMP modules (ex. ingests and spawns standardized input/output config files, etc.). 

There are three taxonomic classification tools integrated which can be run in any combination: MetaPhlan4, Kraken2 (along with Bracken for relative abundance estimation), and XTree (formerly UTree). 

Installation
------------

1. Clone repo from `Github tutorial <https://github.com/MetaSUB-CAMP/camp_short-read-taxonomy>`_.

2. Set up the conda environment (contains, Snakemake) using ``configs/conda/short-read-taxonomy.yaml``. 

3. XTree needs to be installed from Github directly with the following commands. After installation, the location of the executable needs to be added to ``configs/parameters.yaml`` under ``xtree_executable``.
::
    git clone https://github.com/GabeAl/UTree.git
    cd UTree/
    gcc -std=gnu11 -m64 -O3 itree.c -fopenmp -D BUILD -o utree-build 
    gcc -std=gnu11 -m64 -O3 itree.c -fopenmp -D COMPRESS -o xtree-compress 
    gcc -std=gnu11 -m64 -O3 itree.c -fopenmp -D SEARCH -o xtree-search

4. Kraken2 also needs to be installed separately despite having an environment because, like Bowtie2, it frequently misbehaves. 
::
    git clone https://github.com/DerrickWood/kraken2.git
    cd kraken2/
    ./install_kraken2.sh ./

5. Make sure the installed pipeline works correctly. ``pytest`` only generates temporary outputs so no files should be created.
::
    cd camp_short-read-taxonomy
    conda env create -f configs/conda/camp_short-read-taxonomy.yaml
    conda activate camp_short-read-taxonomy
    pytest .tests/unit/

Using the Module
----------------

**Input**: ``/path/to/samples.csv`` provided by the user.

**Output**: Summary reports from MetaPhlan4, Kraken2, and/or XTree. 

- ``/path/to/camp/dir/short-read-taxonomy/final_reports/*.tsv`` where ``*`` is one of the classification algorithms

**Structure**:
::
    └── workflow
        ├── Snakefile
        ├── short-read-taxonomy.py
        ├── utils.py
        └── __init__.py
- ``workflow/short-read-taxonomy.py``: Click-based CLI that wraps the ``snakemake`` and unit test generation commands for clean management of parameters, resources, and environment variables.
- ``workflow/Snakefile``: The ``snakemake`` pipeline. 
- ``workflow/utils.py``: Sample ingestion and work directory setup functions, and other utility functions used in the pipeline and the CLI.

1. Make your own ``samples.csv`` based on the template in ``configs/samples.csv``. Sample test data can be found in ``test_data/``.
    - ``samples.csv`` requires either absolute paths or paths relative to the directory that the module is being run in
    - Note: Metaphlan and Bracken merge outputs from all samples to get aggregated relative abundances across all samples. To get relative abundances for a single sample, put each sample in its own ``samples.csv``.

2. Update the relevant parameters in ``configs/parameters.yaml``.
    * Note: For some reason, ``abspath(__file__)`` does not work to extract the directory that the Snakefile is in, so the directory containing external files and scripts needs to be manually set. 

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

6. Because XTree writes the intermediate file ``DbgPost.txt`` to the work directory which is shared by all runs (samples and taxonomic groups), the XTree rules cannot actually be used in their current states. As such, the paths to the scripts, XTree, and the databases need to be updated in the scripts ``submit_xtree.sh, run_xtree.sh, merge_xtree.sh`` in ``workflow/ext/scripts`` 

7. Then, the commands need to be run separately as follows:
::
    /path/to/camp_short-read-taxonomy/workflow/dirs/scripts/submit_xtree.sh sample_1,...,sample_n bacterial_archaeal,protozoa_fungi,viral /path/to/work/dir
    /path/to/camp_short-read-taxonomy/workflow/dirs/scripts/merge_xtree.sh bacterial_archaeal,protozoa_fungi,viral /path/to/work/dir

8. After checking over ``final_reports/`` and making sure you have everything you need, you can delete all intermediate files to save space. 
::

    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        cleanup \
        -d /path/to/work/dir \
        -s /path/to/samples.csv

9. If for some reason the module keeps failing, CAMP can print a script containing all of the remaining commands that can be run manually. 
::

    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        --dry_run \
        -d /path/to/work/dir \
        -s /path/to/samples.csv > cmds.txt
    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        commands cmds.txt

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
5. Run the pipeline once through to make sure everything works using the test data in ``test_data/`` if appropriate, or your own appropriately-sized test data. Then, generate unit tests to ensure that others can sanity-check their installations.
    * Note: Python functions imported from ``utils.py`` into ``Snakefile`` should be debugged on the command-line first before being added to a rule because Snakemake doesn't port standard output/error well when using ``run:``.
::
    python3 /path/to/camp_short-read-taxonomy/workflow/short-read-taxonomy.py \
        --unit_test \
        -d /path/to/work/dir \
        -s /path/to/samples.csv

6. Increment the version number of the modular pipeline.
::
    bump2version --allow-dirty --commit --tag major workflow/__init__.py \
                 --current-version A.C.E --new-version B.D.F

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
