#!/bin/sh

#### THIS IS A TEST.  Not sure where to put this yet, but it's worth knowing for each group. Should probably be its own script.
# Only capturing shard count from one group at the moment

#file references
index_stats='indices_stats.json'
folder='es_index_cleanup'
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_user="$folder/2-es_index_cleanup_all_empty_user.txt"
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
summary="$folder/0-es_index_cleanup_summary.txt"

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

#### THIS IS A TEST.  Not sure where to put this yet, but it's worth knowing for each group. Should probably be its own script.
# Only capturing shard count from one group at the moment
echo
echo
echo "####### 💰 Total Shards Savings (cluster wide) 💰 #######"

#cleanup temp file in case previous runs were aborted
if [ -f shard_count.temp ]
  then
  rm shard_count.temp
fi

#if grep -q "shard_stats" $index_stats
#then
  #shard counter Method 1
  #use jq to loop through index list and query indices_stats.json for total.shard_stats.total_count

  #jq '[.indices."my-index".total.shard_stats.total_count]' indices_stats.json|tr -d '[] \n'
  echo "Shard count Method 1 (indices_stats) - might take several seconds"
  echo "This will accurately count total assigned shards"
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
#else

  #shard counter Method 2
  #includes unassigned shards in its count.  Inaccurate if 1 node w/ replicas. Though unassigned replicas do count towards max shards.
  #loop through index list and grep/awk cat_indices.txt for the primary and replica counts, and calculate the resulting shards.
  echo "Shard count Method 2 (cat_indices)"
  echo "This will count total configured shards; so unassigned shards will be included in the count"

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

#else
#shard counter Method 3
#loop through index list and count the occurance of each index in shards.json
#probably accurate. results match the two methds above.

echo "Used shard count Method 3 (shards.json)"
echo "This will also count total configured shards; so unassigned shards will be included in the count"
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

#fi
echo
