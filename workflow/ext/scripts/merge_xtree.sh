#!/bin/bash

IFS=','

read -a taxa_groups <<< "${1}"
work_dir="${2}"
out_dir="${work_dir}/short-read-taxonomy/3_xtree/merged"

mkdir -p "${out_dir}"

for tg in "${taxa_groups[@]}"
do
    Rscript /path/to/camp_short-read-taxonomy/workflow/ext/scripts/post_process_xtree.R \
        "${work_dir}/short-read-taxonomy/3_xtree/${tg}" 0 0 0 "${out_dir}" ${tg} \
        /path/to/camp_short-read-taxonomy/workflow/ext/xtree_all_db_mapping
done

