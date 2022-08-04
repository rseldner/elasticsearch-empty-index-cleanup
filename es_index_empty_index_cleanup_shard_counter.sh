#!/bin/bash

#### Still testing this. 
# Only capturing shard count from one group at the moment.  Would be too time consuming to get a precise count from each grouping
# perhaps the sum of 5 and 7

#file references. Some are superflous and will need to cleanup later.  I was lazy and copy/pasted from original empty index cleanup script

 #data source
index_stats='indices_stats.json'
 #output files
folder='es_empty_index_cleanup'
summary="$folder/0-es_index_cleanup_summary.txt"
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_user="$folder/2-es_index_cleanup_all_empty_user.txt"
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
all_empty_non_write_datastreams="$folder/7-es_index_cleanup_all_empty_non_write_datastreams.txt"
all_empty_frozen_searchable_snapshots="$folder/8-all_empty_frozen_searchable_snapshots.txt"
all_empty_cold_searchable_snapshots="$folder/9-all_empty_cold_searchable_snapshots.txt"

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

#if grep -q "shard_stats" $index_stats
#then
  #shard counter Method 1
  #use jq to loop through index list and query indices_stats.json for total.shard_stats.total_count

  #jq '[.indices."my-index".total.shard_stats.total_count]' indices_stats.json|tr -d '[] \n'
echo "1 - Shard count Method 1 (total_count in indices_stats.json) - This is the most accurate.  Might take between a few seconds to several minutes depending on the amount of empty indices found.  This will count total assigned shards. Unfortunately, this is not included in some cluster/diag versions, so it might be skipped"
if grep -q "shard_stats" indices_stats.json && grep -q "total_count" indices_stats.json
then

  #filename=$all_empty_ilm_non_sys_non_write
  filename=$all_empty_ilm_non_write
  file_indices=$(cat $filename)
  for index_name in $file_indices
    do
    jq "[.indices.\"$index_name\".total.shard_stats.total_count]" indices_stats.json|tr -d '[] '>>shard_count.temp
  done
  #sum each line
  awk '{s+=$1} END {print s}' shard_count.temp
  #clean up temp file
  rm shard_count.temp
fi
  echo
#else

  #shard counter Method 2
  #includes unassigned shards in its count.  Inaccurate if 1 node w/ replicas. Though unassigned replicas do count towards max shards.
  #loop through index list and grep/awk cat_indices.txt for the primary and replica counts, and calculate the resulting shards.
echo "#########"
echo
  echo "2 - Shard count Method 2 (looks at P & R columns cat_indices) - This will count total configured shards; so unassigned shards will be included in the count"
  #filename=$all_empty_ilm_non_sys_non_write
  filename=$all_empty_ilm_non_write
  file_indices=$(cat $filename)
  for index_name in $file_indices
    do
    grep $index_name cat/cat_indices.txt | awk -F ' ' '{print $5,$6}'>>shard_count.temp
  done
  awk '{a=$1} {b=$2} {print a+(a*b)}' shard_count.temp|awk '{s+=$1} END {print s}'
  #clean up temp file
  rm shard_count.temp
  echo

#else
#shard counter Method 3
#loop through index list and count the occurance of each index in shards.json
#probably accurate. results have been matching the two methods above.
echo "#########"
echo
  echo "3 - Used shard count Method 3 (count of index name in shards.json - 1 instance = 1 shard). This will count total configured shards; so unassigned shards will be included in the count"
#filename=$all_empty_ilm_non_sys_non_write
 filename=$all_empty_ilm_non_write
 file_indices=$(cat $filename)
 for index_name in $file_indices
  do
   grep $index_name shards.json | wc -l >>shard_count.temp
  done
 awk '{s+=$1} END {print s}' shard_count.temp
#clean up temp file
 rm shard_count.temp
 echo

#fi
echo "###### 💰 Total Shards Savings (cluster wide) [END] 💰 ######"

