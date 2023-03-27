#!/bin/bash

#### Still testing this. 
# Only capturing shard count from one group at the moment.  Would be too time consuming to get a precise count from each grouping
# perhaps the sum of 5 and 7

#file references. Some are superflous and will need to cleanup later.  I was lazy and copy/pasted from original empty index cleanup script

 #data source
###index_stats='indices_stats.json'
 #output files
folder='es_empty_index_cleanup'
###summary="$folder/0-es_index_cleanup_summary.txt"
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_user="$folder/2-es_index_cleanup_all_empty_user.txt"
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
all_empty_non_write_datastreams="$folder/7-es_index_cleanup_all_empty_non_write_datastreams.txt"
all_empty_frozen_searchable_snapshots="$folder/8-all_empty_frozen_searchable_snapshots.txt"
all_empty_cold_searchable_snapshots="$folder/9-all_empty_cold_searchable_snapshots.txt"


group_array=( "$all_empty" "$all_empty_user" "$all_empty_ilm" "$all_empty_ilm_non_sys" "$all_empty_ilm_non_write" "$all_empty_ilm_non_sys_non_write" "$all_empty_non_write_datastreams" "$all_empty_frozen_searchable_snapshots" "$all_empty_cold_searchable_snapshots")

#check es_empty_index_cleanup folder already exists (i.e. es_index_empty+index_cleanup.sh has been run)
if [ ! -d $folder ]
then
  echo
  echo "####################################################"
  echo 🎺Womp Womp🎺 There is an problem w/ the source files.
  echo The $folder directory does not exist
  echo Run this AFTER running the empty index cleanup script
  echo this is not a standalone script
  echo "####################################################"
  echo
  exit 1
fi

#cleanup temp file in case previous runs were aborted
if [ -f shard_count.temp ]
  then
  rm shard_count.temp
fi

#### 
# Only capturing shard count from one group at the moment
echo
echo "##### 💰 Total Shards Savings (cluster wide) [START] 💰 #####"
echo
echo -e 'Shards | Group Filename'
echo '-------|---------------'
### ARRAY TEST START

for group in "${group_array[@]}"
  do
  filename=$group
  file_indices=$(cat "$filename")
 #check if file is empty and skip
  if [ -s "$filename" ]; then
  
  for index_name in $file_indices
    do
    grep -F "$index_name" cat/cat_indices.txt | awk -F ' ' '{print $5,$6}'>>shard_count.temp
  done
  echo -e $(awk '{a=$1} {b=$2} {print a+(a*b)}' shard_count.temp|awk '{s+=$1} END {print s}') ' \t' $(echo $group| sed 's/es_empty_index_cleanup\///g') 
  rm shard_count.temp
  else
    echo -e 0 ' \t' "$(echo "$group"| sed 's/es_empty_index_cleanup\///g')"
  fi
done

echo
echo "###### 💰 Total Shards Savings (cluster wide) [END] 💰 ######"

