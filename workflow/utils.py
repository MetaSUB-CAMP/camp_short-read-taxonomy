'''Utilities.'''


# --- Workflow setup --- #


import gzip
import os
from os import makedirs, symlink
from os.path import abspath, basename, exists, join
import pandas as pd
import shutil


def ingest_samples(samples, tmp):
    df = pd.read_csv(samples, header = 0, index_col = 0) 
    s = list(df.index)
    lst = df.values.tolist()
    for i,l in enumerate(lst):
        if not exists(join(tmp, s[i] + '_1.fastq.gz')):
            symlink(abspath(l[0]), join(tmp, s[i] + '_1.fastq.gz'))
            symlink(abspath(l[1]), join(tmp, s[i] + '_2.fastq.gz'))
    return s


class Workflow_Dirs:
    '''Management of the working directory tree.'''
    OUT = ''
    TMP = ''
    LOG = ''

    def __init__(self, work_dir, module):
        self.OUT = join(work_dir, module)
        self.TMP = join(work_dir, 'tmp') 
        self.LOG = join(work_dir, 'logs') 
        if not exists(self.OUT):
            makedirs(self.OUT)
            makedirs(join(self.OUT, '0_masked_fastqs'))            
            makedirs(join(self.OUT, '1_metaphlan'))            
            makedirs(join(self.OUT, '2_kraken2'))            
            makedirs(join(self.OUT, '3_xtree'))            
            makedirs(join(self.OUT, 'final_reports'))            
        if not exists(self.TMP):
            makedirs(self.TMP)
        if not exists(self.LOG):
            makedirs(self.LOG)
            makedirs(join(self.LOG, 'masking'))            
            makedirs(join(self.LOG, 'metaphlan'))            
            makedirs(join(self.LOG, 'kraken2'))            
            makedirs(join(self.LOG, 'bracken'))            
            makedirs(join(self.LOG, 'xtree'))            


def cleanup_files(work_dir, df):
    smps = list(df.index)
    for d in ['1', '2']:
         for s in smps:
            masked_fq = join(work_dir, 'short-read-taxonomy', '0_masked_fastqs', s + '_' + d + '.masked.fastq.gz')
            if exists(masked_fq):
                os.remove(masked_fq)
            os.remove(join(work_dir, 'short-read-taxonomy', '1_metaphlan', s + '_' + d + '.fastq'))
            os.remove(join(work_dir, 'short-read-taxonomy', '3_xtree', s + '.fastq'))


def print_cmds(log):
    fo = basename(log).split('.')[0] + '.cmds'
    lines = open(log, 'r').read().split('\n')
    fi = [l for l in lines if l != '']
    write = False
    with open(fo, 'w') as f_out:
        for l in fi:
            if 'rule' in l:
                f_out.write('# ' + l.strip().replace('rule ', '').replace(':', '') + '\n')
            if 'wildcards' in l: 
                f_out.write('# ' + l.strip().replace('wildcards: ', '') + '\n')
            if 'resources' in l:
                write = True 
                l = ''
            if '[' in l: 
                write = False 
            if write:
                f_out.write(l.strip() + '\n')
            if 'rule make_config' in l:
                break


# --- Workflow functions --- #


import io


def scrub_fastq_captions(fi, fo):
    with io.TextIOWrapper(io.BufferedReader(gzip.open(fi, 'rb'))) as f_in, open(fo, 'w') as f_out:
        for l in f_in:
            if l.startswith('+'):
                f_out.write('+\n')
            else:
                f_out.write(l)
