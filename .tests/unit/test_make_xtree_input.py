import os
import sys

import subprocess as sp
from tempfile import TemporaryDirectory
import shutil
from pathlib import Path, PurePosixPath

sys.path.insert(0, os.path.dirname(__file__))

import common


def test_make_xtree_input():

    with TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        data_path = PurePosixPath("/home/lam4003/bin/camp_short-read-taxonomy/.tests/unit/make_xtree_input/data")
        expected_path = PurePosixPath("/home/lam4003/bin/camp_short-read-taxonomy/.tests/unit/make_xtree_input/expected")

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir)

        # dbg
        print("/home/lam4003/bin/camp_short-read-taxonomy/test_out/short-read-taxonomy/3_xtree/zymo_pos_ctrl.fastq", file=sys.stderr)

        # Run the test job.
        sp.check_output([
            "python",
            "-m",
            "snakemake", 
            "/home/lam4003/bin/camp_short-read-taxonomy/test_out/short-read-taxonomy/3_xtree/zymo_pos_ctrl.fastq",
            "-f", 
            "-j1",
            "--keep-target-files",
            "--configfile",
            /home/lam4003/bin/camp_short-read-taxonomy/test_data/parameters.yaml
            /home/lam4003/bin/camp_short-read-taxonomy/configs/resources.yaml
    
            "--use-conda",
            "--directory",
            workdir,
        ])

        # Check the output byte by byte using cmp.
        # To modify this behavior, you can inherit from common.OutputChecker in here
        # and overwrite the method `compare_files(generated_file, expected_file), 
        # also see common.py.
        common.OutputChecker(data_path, expected_path, workdir).check()
