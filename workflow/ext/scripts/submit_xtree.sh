#!/bin/bash

IFS=','

read -a samples <<< "${1}"
read -a taxa_groups <<< "${2}"
work_dir="${3}"
declare -A xtree_dbs
xtree_dbs['bacterial_archaeal']=''
xtree_dbs['protozoa_fungi']=''
xtree_dbs['viral']=''

for tg in "${taxa_groups[@]}"
do
   mkdir -p "${work_dir}/short-read-taxonomy/3_xtree/${tg}"
done

for s in "${samples[@]}"
do
    concat_fq="${work_dir}/short-read-taxonomy/3_xtree/${s}.fastq"
    # cat ${work_dir}/short-read-taxonomy/1_metaphlan/${s}*.fastq > "${concat_fq}"
    for tg in "${taxa_groups[@]}"
    do
        sample_dir="${work_dir}/short-read-taxonomy/3_xtree/${tg}/${s}/"
        mkdir -p "${sample_dir}"
        cd "${sample_dir}"
	sbatch -J "xtree_${s}_${tg}" -n 20 --mem 200GB \
        -o "${work_dir}/logs/xtree/${s}.${tg}.out" \
        /path/to/camp_short-read-taxonomy/workflow/ext/scripts/run_xtree.sh \
        "${concat_fq}" "${xtree_dbs[${tg}]}" "${sample_dir}/${tg}" "${s}"
    done
done

