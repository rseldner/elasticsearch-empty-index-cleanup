#!/bin/bash
me=$(realpath "$0")
my_path=$(dirname "$me")
#run main script
"$my_path"/es_index_empty_index_cleanup.sh
#testing - get a shard count of each grouping.
"$my_path"/es_index_empty_index_cleanup_shard_counter-v2.sh
#testing - get ILM policies and count how many empty indices are associated with them
"$my_path"/es_index_empty_index_cleanup_ILM_policies-v2.sh