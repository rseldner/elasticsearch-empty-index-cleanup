#!/bin/sh

# Current version
# v1.3 20220328
# changed output filenemes to include numerical prefix for easier reference/identification
# updated descriptions in summary

# previous versions
# v1.2 20220308
# added output for es_index_cleanup_all_empty_ilm_non_write

# v1.1 20220228
# misc jq and grep corrections

# v1.0 202202??
# created this mess

#Exmaple Use Case: https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices
#If you’re using ILM and roll over indices based on a max_age threshold, you can inadvertently create indices with no documents. 
#These empty indices provide no benefit but still consume resources.

index_stats='indices_stats.json'
index_aliases='cat/cat_aliases.txt'
folder='es_index_cleanup'
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_ilm="$folder/2-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/3-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/4-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
summary="$folder/0-es_index_cleanup_summary.txt"


#create directory
mkdir $folder

# 1 - get all empty indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S' > $all_empty

# 2 - get empty indices with ILM rollover naming scheme
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' > $all_empty_ilm

# 3 - get empty indices with ILM naming scheme and non system/hidden
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' > $all_empty_ilm_non_sys

# 4 - get empty indices with ILM rollover naming scheme and are not the current write index
grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_write

# 5 - get empty indices with ILM naming scheme and non system/hidden and are not the current write index
grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_sys_non_write


count_1=`wc -l $all_empty|awk -F ' ' '{print $1}'`
count_2=`wc -l $all_empty_ilm|awk -F ' ' '{print $1}'`
count_3=`wc -l $all_empty_ilm_non_sys|awk -F ' ' '{print $1}'`
count_4=`wc -l $all_empty_ilm_non_write|awk -F ' ' '{print $1}'`
count_5=`wc -l $all_empty_ilm_non_sys_non_write|awk -F ' ' '{print $1}'`

#Summary
echo "################ Index Cleanup Summary [START] ################" >$summary
echo "-----------------------------#1---------------------------------" >>$summary
echo "$count_1 Empty Indices">>$summary
echo "Notes: Caution - manual review recommended" >>$summary
echo "Output File: 1-es_index_cleanup_all_empty.txt" >>$summary
echo >>$summary
echo "-----------------------------#2---------------------------------" >>$summary
echo "$count_2 Empty ILM rollover indices" >>$summary
echo "Notes: Caution - This includes current write indices" >>$summary
echo "Output File: 2-es_index_cleanup_all_empty_ilm.txt" >>$summary
echo >>$summary
echo "-----------------------------#3---------------------------------" >>$summary
echo "$count_3 Empty ILM rollover non-system/hidden indices" >>$summary
echo "Notes: Caution - This includes current write indices, which can result in annoying errors when removed">>$summary
echo "Output File: 3-es_index_cleanup_all_empty_ilm_non_sys.txt" >>$summary
echo >>$summary
echo "-----------------------------#4---------------------------------" >>$summary
echo "$count_4 Empty ILM rollover and non write indices" >>$summary
echo "Notes: Subset of #2.  Safer but note that it includes system/hidden indices (usually fine - might require super \"duper\" user if 8.x)">>$summary
echo "Output File: 4-es_index_cleanup_all_empty_ilm_non_write.txt" >>$summary
echo >>$summary
echo "-----------------------------#5---------------------------------" >>$summary
echo "$count_5 Empty ILM rollover non-system/hidden and not current write indices">>$summary
echo "Notes: Subset of #3. Safest to remove" >>$summary
echo "Output File: 5-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt" >>$summary
echo >>$summary
echo "----------------------------------------------------------------" >>$summary
echo "################ Index Cleanup Summary [END] ################" >>$summary
echo>>$summary

echo

cat $summary
