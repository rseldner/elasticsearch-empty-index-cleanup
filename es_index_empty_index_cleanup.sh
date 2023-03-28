#!/bin/bash

#Exmaple Use Case: https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices
#If you’re using ILM and roll over indices based on a max_age threshold, you can inadvertently create indices with no documents.
#These empty indices provide no benefit but still consume resources.

# file references
  # data sources
index_stats='indices_stats.json'
index_aliases='cat/cat_aliases.txt'
data_streams='commercial/data_stream.json'
  # output files
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
  # temp files
all_empty_datastreams="$folder/all_empty_datastreams.temp"
all_current_write_datastreams="$folder/all_current_write_datastreams.temp"
count_temp=$folder/count_temp


#check if this tool will even work
if [ ! -f $index_stats ] || [ ! -f $index_aliases ] || grep -q "Bad Request. Rejected" $index_stats || ! grep -q "_shards" $index_stats
then
  echo
  echo "####################################################"
  echo 🎺Womp Womp🎺 There is an problem w/ the source files.
  echo This can happen when there are closed indices or
  echo running from the wrong directory
  echo Check location and content of indices_stats.json.
  echo "####################################################"
  echo
  exit 1
fi

#check and warn for files with circuit breaking exceptions.  Tool can potentially work to a degree
if grep -q "circuit_breaking_exception" $index_stats || grep -q "circuit_breaking_exception" $index_aliases
then
  echo
  echo "####################################################"
  echo 
  echo 🛑 circuit breaking exceptions found.  tool will still run but output will be incomplete.
  echo
  echo "####################################################"
  echo
fi



#check and create output directory
if [ ! -d $folder ]
then
mkdir $folder
fi

# 1 - get all empty indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S' > $all_empty
  #echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'| paste -s -d, -` > $all_empty-DELETE.txt

# 2 - get all empty user/custom (i.e. non system) indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'|grep -v -E "^\..*" > $all_empty_user
  #echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'|grep -v -E '\..*'| paste -s -d, -` > $all_empty_user-DELETE.txt

# 3 - get empty indices with ILM rollover naming scheme
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' > $all_empty_ilm
  #echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' | paste -s -d, -` > $all_empty_ilm-DELETE.txt

# 4 - get empty indices with ILM naming scheme and non system/hidden
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' > $all_empty_ilm_non_sys
  #echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' | paste -s -d, -` > $all_empty_ilm_non_sys-DELETE.txt

# 5 - get empty indices with ILM rollover naming scheme and are not the current write index
grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_write
  #create a DELETE API request
echo DELETE "$(grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort| paste -s -d, -)">$all_empty_ilm_non_write-DELETE.txt

# 6 - get empty indices with ILM naming scheme and non system/hidden and are not the current write index
grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_sys_non_write
  #create a DELETE API request
echo DELETE "$(grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort| paste -s -d, -)">$all_empty_ilm_non_sys_non_write-DELETE.txt

# 7 - get all empty datastream backing indices excluding the current write index
  #cat commercial/data_stream.json| jq '..|."indices"? | select(. != null)|[last]' |grep index_name|sed 's/"index_name": //g'|tr -d " ,\"">ds_current_write.temp
  # extract the current write indices
jq '..|."indices"? | select(. != null)|[last]' $data_streams |grep index_name|sed 's/"index_name": //g'|tr -d " ,\"">$all_current_write_datastreams
  # extract the datastreams from output #3 ($all_empty_ilm)
grep -E "^\.ds-.*-\d{6}" $all_empty_ilm > $all_empty_datastreams
  # remove current write indices from list of empty datastreams
grep -v -x -f $all_current_write_datastreams $all_empty_datastreams>$all_empty_non_write_datastreams
  #create a DELETE API request
echo DELETE "$(grep -v -x -f $all_current_write_datastreams $all_empty_datastreams|sort| paste -s -d, -)">$all_empty_non_write_datastreams-DELETE.txt

 # cleanup temp files
 rm $all_empty_datastreams
 rm $all_current_write_datastreams

# 8 - get all empty frozen (partially mounted) searchable snapshot indices
grep -E "^partial-.*" $all_empty > $all_empty_frozen_searchable_snapshots
  #create a DELETE API request
echo DELETE "$(grep -E "^partial-.*" $all_empty |sort| paste -s -d, -)">$all_empty_frozen_searchable_snapshots-DELETE.txt

# 9 - get all empty cold (fully mounted) searchable snapshot indices
grep -E "^restored-.*" $all_empty > $all_empty_cold_searchable_snapshots
  #create a DELETE API request
echo DELETE "$(grep -E "^restored-.*" $all_empty |sort| paste -s -d, -)">$all_empty_cold_searchable_snapshots-DELETE.txt

#split into multiple DELETEs if > ~4kb
for delete_txt in "$folder"/*DELETE.txt
do
  char_count=$(wc -c<"$delete_txt")
  if [[ $char_count -gt 4000 ]]; then
    sed 's/,/\nDELETE /50; P; D' "$delete_txt">"$delete_txt"-SPLIT.temp
    sed 'G' "$delete_txt"-SPLIT.temp>"$delete_txt"
    rm "$delete_txt"-SPLIT.temp
  fi
done

#count lines in outputs (line count = index count)
count_1=$(wc -l $all_empty|awk -F ' ' '{print $1}')
count_2=$(wc -l $all_empty_user|awk -F ' ' '{print $1}')
count_3=$(wc -l $all_empty_ilm|awk -F ' ' '{print $1}')
count_4=$(wc -l $all_empty_ilm_non_sys|awk -F ' ' '{print $1}')
count_5=$(wc -l $all_empty_ilm_non_write|awk -F ' ' '{print $1}')
count_6=$(wc -l $all_empty_ilm_non_sys_non_write|awk -F ' ' '{print $1}')
count_7=$(wc -l $all_empty_non_write_datastreams|awk -F ' ' '{print $1}')
count_8=$(wc -l $all_empty_frozen_searchable_snapshots|awk -F ' ' '{print $1}')
count_9=$(wc -l $all_empty_cold_searchable_snapshots|awk -F ' ' '{print $1}')

#write count per group to temp file
echo "$count_1 Total empty indices(1)">$count_temp
{
echo "$count_2 Empty non-system indices (2)"
echo "$count_3 Empty ILM rollover indices (3)"
echo "$count_4 Empty non-system ILM rollover indices(4)"
echo "$count_5 * Empty non-write ILM rollover indices(5)"
echo "$count_6 * Empty non-system AND non-write ILM rollover indices(6)"
echo "$count_7 * Empty non-write datastream backing indices(7)"
echo "$count_8 * Empty frozen searchable snapshot indices(8)"
echo "$count_9 * Empty cold searchable snapshot indices(9)"
}>>$count_temp
# Terminal output
echo
echo "################ Empty Index Cleanup Summary [START] ################"
echo
cat $count_temp
echo
echo "* = safest to remove (exclude write indices)"
echo
echo See $summary and output files in $folder path for details
echo
echo -e '\t' less $summary
echo
echo "################ Empty Index Cleanup Summary [END] ################"
echo
rm $count_temp

#Summary file output.  Should probably move this out of the script...

echo "################ Empty Index Cleanup Summary [START] ################" >$summary
{
echo 
echo "Use this to identify and quickly remove empty indices." 
echo 
echo "Particularly created this for when a large amount of indices are inadvertently created due to ILM max_age rollovers" 
echo "https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices" 
echo 
echo "⭐ My goto output is the Empty non-write ILM rollover indices file: ⭐ 5-es_index_cleanup_all_empty_ilm_non_write.txt ⭐" 
echo 
echo "-----------------------------#1---------------------------------" 
echo 
echo "$count_1 Total empty indices"
echo "🛑 Notes:  Recommended for general reference purposes." 
echo "File (list): $all_empty" 
echo 
echo "Terminal Command to generate a DELETE file (copy/paste to run):" 
echo 
echo "echo DELETE \$(cat $all_empty| paste -s -d, -) > $all_empty-DELETE.txt" 
echo 
echo "-----------------------------#2---------------------------------" 
echo 
echo "$count_2 Empty User indices" 
echo "🟡 Notes: User/Custom Indices.  Excludes indices beggining with a \".\"" 
echo "File (list): $all_empty_user" 
echo "Terminal Command to generate a DELETE file (copy/paste to run):" 
echo 
echo "echo DELETE \$(cat $all_empty_user| paste -s -d, -) > $all_empty_user-DELETE.txt" 
echo 
echo "-----------------------------#3---------------------------------" 
echo 
echo "$count_3 Empty ILM rollover indices" 
echo "🟡 Notes: ❕Caution - This includes system and current write indices" 
echo "File (list): $all_empty_ilm" 
echo "Terminal Command to generate a DELETE file (copy/paste to run):" 
echo 
echo "echo DELETE \$(cat $all_empty_ilm| paste -s -d, -) > $all_empty_ilm-DELETE.txt" 
echo 
echo "-----------------------------#4---------------------------------" 
echo 
echo "$count_4 Empty non-system ILM rollover indices" 
echo "🟡 Notes: ❕Caution - This includes the current write indices."
echo "File (list): $all_empty_ilm_non_sys" 
echo "Terminal Command to generate a DELETE file (copy/paste to run):" 
echo 
echo "echo DELETE \$(cat $all_empty_ilm_non_sys| paste -s -d, -) > $all_empty_ilm_non_sys-DELETE.txt" 
echo 
echo "-----------------------------#5---------------------------------" 
echo 
echo "$count_5 Empty non-write ILM rollover indices" 
echo "🟢 Notes: Subset of #3.  Safer but note that it includes system/hidden indices (there *may* be a situation where a need a super \"duper\" user is needed 8.x.  Have not run into this yet though.)"
echo "File (list): $all_empty_ilm_non_write" 
echo  
echo File containing DELETE was automatically created by script: 
echo -e '\t'less $all_empty_ilm_non_write-DELETE.txt 
echo 
echo "-----------------------------#6---------------------------------" 
echo 
echo "$count_6 Empty non-system AND non-write ILM rollover indices"
echo "🟢 Notes: Subset of #4. Safest to remove" 
echo "File (list): $all_empty_ilm_non_sys_non_write" 
echo  
echo File containing DELETE was automatically created by script: 
echo -e '\t'less $all_empty_ilm_non_sys_non_write-DELETE.txt 
echo 
echo "-----------------------------#7---------------------------------" 
echo 
echo "$count_7 Empty non-write datastream backing indices"
echo "🟢 Notes: Subset of #3. Safe to remove" 
echo "File (list): $all_empty_non_write_datastreams" 
echo  
echo File containing DELETE was automatically created by script: 
echo -e '\t'less $all_empty_non_write_datastreams-DELETE.txt 
echo 
echo "-----------------------------#8---------------------------------" 
echo 
echo "$count_8 Empty frozen searchable snapshot indices"
echo "🟢 Notes: Subset of #1. Presumed safe as they would not be write indices and are in a snapshot" 
echo "File (list): $all_empty_frozen_searchable_snapshots" 
echo  
echo File containing DELETE was automatically created by script: 
echo -e '\t'less $all_empty_frozen_searchable_snapshots-DELETE.txt 
echo 
echo "-----------------------------#9---------------------------------" 
echo 
echo "$count_9 Empty cold searchable snapshot indices"
echo "🟢 Notes: Subset of #1. Presumed safe as they would not be write indices and are in a snapshot" 
echo "File (list): $all_empty_cold_searchable_snapshots" 
echo  
echo File containing DELETE was automatically created by script: 
echo -e '\t'less $all_empty_cold_searchable_snapshots-DELETE.txt 
echo 

echo "################ Empty Index Cleanup Summary [END] ################" 
echo
}>>$summary