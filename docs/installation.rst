.. highlight:: shell

============
Installation
============


Stable release
--------------

1. Clone repo from `github <https://github.com/b-tierney/camp_short-read-taxonomy>_`. 

2. Set up the conda environment (contains, Snakemake) using ``configs/conda/camp_short-read-taxonomy.yaml``. 

3. Make sure the installed pipeline works correctly. ``pytest`` only generates temporary outputs so no files should be created.
::
    cd camp_short-read-taxonomy
    conda env create -f configs/conda/camp_short-read-taxonomy.yaml
    conda activate camp_short-read-taxonomy
    pytest .tests/unit/

