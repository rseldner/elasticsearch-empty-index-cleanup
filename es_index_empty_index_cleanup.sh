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

index_stats='indices_stats.json'
index_aliases='cat/cat_aliases.txt'
folder='es_index_cleanup'
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_ilm="$folder/2-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_write="$folder/3-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_sys_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
summary="$folder/0-es_index_cleanup_summary.txt"

#create directory
mkdir $folder

#get empty indices
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats| tr -d ' "[],'|grep -E '\S' > $all_empty

#get empty indices with ILM rollover naming scheme
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats |tr -d ' "[],'|grep -E '\-\d{6}$' > $all_empty_ilm

#get empty indices with ILM rollover naming scheme and are not the current write index
grep -f $all_empty_ilm $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_write

#get empty indices with ILM naming scheme and non system/hidden
jq '[.indices | to_entries[]| select(.value.total.docs.count == 0)]|from_entries|.|keys' $index_stats | tr -d ' "[],'|grep -E '\-\d{6}$'|grep -v '^\.' > $all_empty_ilm_non_sys

#get empty indices with ILM naming scheme and non system/hidden and are not the current write index
grep -f $all_empty_ilm_non_sys $index_aliases|grep false|awk -F ' ' '{print $2}'|sort > $all_empty_ilm_non_sys_non_write

#Summary
echo "################ Index Cleanup Summary [START] ################" >$summary
echo>>$summary

echo "1 - Total Empty Indices ( Caution - manual review recommended )" >>$summary
wc -l $all_empty|awk -F ' ' '{print $1}'>>$summary
echo>>$summary

echo "2 - Total Empty ILM rollover indices ( Caution - This includes current write indices" >>$summary
wc -l $all_empty_ilm|awk -F ' ' '{print $1}'>>$summary
echo>>$summary

echo "3 - Total Empty ILM rollover and non write indices (Safer but note that it includes system/hidden indices; which is usually fine)">>$summary
wc -l $all_empty_ilm_non_write|awk -F ' ' '{print $1}'>>$summary
echo>>$summary

echo "4 - Total Empty ILM rollover non-system/hidden indices ( Caution - This includes current write indices)">>$summary
wc -l $all_empty_ilm_non_sys|awk -F ' ' '{print $1}'>>$summary
echo>>$summary

echo "5 - Total Empty ILM rollover non-system/hidden and not current write indices (Safest to remove)">>$summary
wc -l $all_empty_ilm_non_sys_non_write|awk -F ' ' '{print $1}'>>$summary
echo>>$summary
echo "################ Index Cleanup Summary [END] ################" >>$summary
echo>>$summary

echo

head -n 20 $summary
