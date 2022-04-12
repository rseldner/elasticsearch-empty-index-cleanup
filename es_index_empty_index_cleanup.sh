#!/bin/bash

#Exmaple Use Case: https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices
#If you’re using ILM and roll over indices based on a max_age threshold, you can inadvertently create indices with no documents.
#These empty indices provide no benefit but still consume resources.

# Current version
# v1.3.1 20220406
# added check to exit if the source files don't exist or contain an error.
# added commands for each type that will generate a file containing a DELETE for the respective indices
# call shard counter (test)

# previous versions
# v1.3.0 20220328
# changed output filenemes to include numerical prefix for easier reference/identification
# updated descriptions in summary

# v1.2.0 20220308
# added output for es_index_cleanup_all_empty_ilm_non_write

# v1.1.0 20220228
# misc jq and grep corrections

# v1.0 202202??
# created this mess

#file references
index_stats='indices_stats.json'
index_aliases='cat/cat_aliases.txt'
folder='es_index_cleanup'
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_user="$folder/2-es_index_cleanup_all_empty_user.txt"
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
summary="$folder/0-es_index_cleanup_summary.txt"

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

#check and create output directory
if [ ! -d $folder ]
then
mkdir $folder
fi

# 1 - get all empty indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S' > $all_empty
#echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'| paste -s -d, -` > $all_empty-DELETE.txt

# 2 - get all empty user/custom (i.e. non system) indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'|grep -v -E '\..*' > $all_empty_user
#echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S'|grep -v -E '\..*'| paste -s -d, -` > $all_empty_user-DELETE.txt

# 3 - get empty indices with ILM rollover naming scheme
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' > $all_empty_ilm
#echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' | paste -s -d, -` > $all_empty_ilm-DELETE.txt

# 4 - get empty indices with ILM naming scheme and non system/hidden
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' > $all_empty_ilm_non_sys
#echo DELETE `jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' | paste -s -d, -` > $all_empty_ilm_non_sys-DELETE.txt

# 5 - get empty indices with ILM rollover naming scheme and are not the current write index
grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_write
echo DELETE `grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort| paste -s -d, -`>$all_empty_ilm_non_write-DELETE.txt

# 6 - get empty indices with ILM naming scheme and non system/hidden and are not the current write index
grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_sys_non_write
echo DELETE `grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort| paste -s -d, -`>$all_empty_ilm_non_sys_non_write-DELETE.txt

#count lines in outputs (line count = index count)
count_1=`wc -l $all_empty|awk -F ' ' '{print $1}'`
count_2=`wc -l $all_empty_user|awk -F ' ' '{print $1}'`
count_3=`wc -l $all_empty_ilm|awk -F ' ' '{print $1}'`
count_4=`wc -l $all_empty_ilm_non_sys|awk -F ' ' '{print $1}'`
count_5=`wc -l $all_empty_ilm_non_write|awk -F ' ' '{print $1}'`
count_6=`wc -l $all_empty_ilm_non_sys_non_write|awk -F ' ' '{print $1}'`

#Summary file output
echo "################ Index Cleanup Summary [START] ################" >$summary
echo >>$summary
echo "Use this to identify and quickly remove empty indices." >>$summary
echo >>$summary
echo "Particularly created this for when a large amount of indices are inadvertently created due to ILM max_age rollovers" >>$summary
echo "https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices" >>$summary
echo >>$summary
echo "⭐ My goto output is the Empty non-write ILM rollover indices file: ⭐ 5-es_index_cleanup_all_empty_ilm_non_write.txt ⭐" >>$summary
echo >>$summary
echo "-----------------------------#1---------------------------------" >>$summary
echo >>$summary
echo "$count_1 Total empty indices">>$summary
echo "🛑 Notes:  Caution - manual review recommended" >>$summary
echo "File (list): $all_empty" >>$summary
echo >>$summary
echo "Terminal Command to generate a DELETE file (copy/paste to run):" >>$summary
echo >>$summary
echo "echo DELETE \$(cat $all_empty| paste -s -d, -) > $all_empty-DELETE.txt" >>$summary
echo >>$summary
echo "-----------------------------#2---------------------------------" >>$summary
echo >>$summary
echo "$count_2 Empty User indices" >>$summary
echo "🟡 Notes: User/Custom Indices.  Excludes indices beggining with a \".\"" >>$summary
echo "File (list): $all_empty_user" >>$summary
echo "Terminal Command to generate a DELETE file (copy/paste to run):" >>$summary
echo >>$summary
echo "echo DELETE \$(cat $all_empty_user| paste -s -d, -) > $all_empty_user-DELETE.txt" >>$summary
echo >>$summary
echo "-----------------------------#3---------------------------------" >>$summary
echo >>$summary
echo "$count_3 Empty ILM rollover indices" >>$summary
echo "🟡 Notes: ❕Caution - This includes current write indices, which can result in annoying errors when removed" >>$summary
echo "File (list): $all_empty_ilm" >>$summary
echo "Terminal Command to generate a DELETE file (copy/paste to run):" >>$summary
echo >>$summary
echo "echo DELETE \$(cat $all_empty_ilm| paste -s -d, -) > $all_empty_ilm-DELETE.txt" >>$summary
echo >>$summary
echo "-----------------------------#4---------------------------------" >>$summary
echo >>$summary
echo "$count_4 Empty non-system ILM rollover indices" >>$summary
echo "🟡 Notes: Caution - This includes the current write indices. Probably not recommended ">>$summary
echo "File (list): $all_empty_ilm_non_sys" >>$summary
echo "Terminal Command to generate a DELETE file (copy/paste to run):" >>$summary
echo >>$summary
echo "echo DELETE \$(cat $all_empty_ilm_non_sys| paste -s -d, -) > $all_empty_ilm_non_sys-DELETE.txt" >>$summary
echo >>$summary
echo "-----------------------------#5---------------------------------" >>$summary
echo >>$summary
echo "$count_5 Empty non-write ILM rollover indices" >>$summary
echo "🟢 Notes: Subset of #3.  Safer but note that it includes system/hidden indices (usually fine - haven't tested if a super \"duper\" user is needed for 8.x)">>$summary
echo "File (list): $all_empty_ilm_non_write" >>$summary
echo  >>$summary
echo File containing DELETE was automatically created by script: >>$summary
echo -e '\t'less $all_empty_ilm_non_write-DELETE.txt >>$summary
echo >>$summary
echo "-----------------------------#6---------------------------------" >>$summary
echo >>$summary
echo "$count_6 Empty non-system AND non-write ILM rollover indices">>$summary
echo "🟢 Notes: Subset of #4. Safest to remove" >>$summary
echo "File (list): $all_empty_ilm_non_sys_non_write" >>$summary
echo  >>$summary
echo File containing DELETE was automatically created by script: >>$summary
echo -e '\t'less $all_empty_ilm_non_sys_non_write-DELETE.txt >>$summary
echo >>$summary
echo "################ Index Cleanup Summary [END] ################" >>$summary
echo>>$summary

echo
# Terminal output
echo "################ Index Cleanup Summary [START] ################"
echo
grep --color=always -E '^\d+' $summary
echo
echo See $summary and output files in $folder path for details
echo
echo -e '\t' less $summary
echo
echo "################ Index Cleanup Summary [END] ################"
echo

me=$(realpath $0)
my_path=$(dirname $me)
$my_path/es_index_empty_index_cleanup_shard_counter.sh
$my_path/es_index_empty_index_cleanup_ILM_policies.sh
