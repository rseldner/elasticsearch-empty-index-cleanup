#!/bin/bash
### Lists the ILM policies responsible for the empty rollover indices, the amount of empty indices found, and their rollover and delete age vaules
# It works, but not a fan of the output format. Would be better to see in a table format.
#
#file references. Some are superflous and will need to cleanup later.  I was lazy and copy/pasted from original empty index cleanup script
index_stats='indices_stats.json'
folder='es_empty_index_cleanup'
all_empty="$folder/1-es_index_cleanup_all_empty.txt"
all_empty_user="$folder/2-es_index_cleanup_all_empty_user.txt"
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
all_empty_ilm_non_sys="$folder/4-es_index_cleanup_all_empty_ilm_non_sys.txt"
all_empty_ilm_non_write="$folder/5-es_index_cleanup_all_empty_ilm_non_write.txt"
all_empty_ilm_non_sys_non_write="$folder/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt"
summary="$folder/0-es_index_cleanup_summary.txt"
#can probably hard code "commercial" dir instead of using find
ilm_explain_json=$(find . -name "ilm_explain.json")
ilm_policies_json=$(find . -name "ilm_policies.json")

#temp files

empty_ilm_indices_policy_name=ilm_pol1.temp
empty_ilm_indices_policy_name_unique=ilm_pol2.temp
empty_ilm_indices_policy_name_unique_count=ilm_pol3.temp
empty_ilm_indices_policy_name_unique_count_sort=ilm_pol4.temp

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


# Targeting the 3-es_index_cleanup_all_empty_ilm.txt since this will contain all types of indices with rollover naming scheme, including datas streams
filename=$all_empty_ilm

echo
echo "################# ILM POLICY REVIEW [START] #################"
echo
# GET ILM POLICIES
#cleanup temp file in case previous runs were aborted
if [ -f $empty_ilm_indices_policy_name ]
  then
  rm ilm_pol*.temp
fi

#get ILM policy for each empty index
file_indices=$(cat $filename)
for index_name in $file_indices
  do
jq "[.indices.\"$index_name\".policy]" $ilm_explain_json |tr -d '[] "'|sed 's/null//g' >> $empty_ilm_indices_policy_name
done

#remove duplicates
cat $empty_ilm_indices_policy_name| sed '/^$/d'|sort -u > $empty_ilm_indices_policy_name_unique

#sort ILM policies based on their empty index count
filename=$empty_ilm_indices_policy_name_unique
ilm_policies=$(cat $filename)
for pol_name in $ilm_policies
  do
echo $pol_name $(grep -c $pol_name $empty_ilm_indices_policy_name) >>$empty_ilm_indices_policy_name_unique_count
done
cat $empty_ilm_indices_policy_name_unique_count|sort -k2 -n -r >>$empty_ilm_indices_policy_name_unique_count_sort

echo "The following ILM policies are associated with empty indices."
echo "Consider adjusting the rollover max_age setting and/or the Delete phase min_age"
echo "For 8.4 and above, you can add min_docs setting.  See https://www.elastic.co/guide/en/elasticsearch/reference/8.4/ilm-rollover.html"
# GET ILM POLICIES' rollover max_age and delete phase min_age
filename=$empty_ilm_indices_policy_name_unique_count_sort
ilm_policies=$(cut -f1 -d ' ' $filename)
for pol_name in $ilm_policies
  do
echo
echo $pol_name
echo -e \($(grep $pol_name $filename| cut -f2 -d ' ') empty rollover indices found\)
#$(jq -r "[.\"$pol_name\".policy.phases.hot.actions.rollover.max_age,.\"$pol_name\".policy.phases.delete.min_age]| @tsv" commercial/ilm_policies.json |tr -d '[] "')
echo -e '\t' Rollover max_age: '\t' $(jq -r "[.\"$pol_name\".policy.phases.hot.actions.rollover.max_age]| @tsv" $ilm_policies_json |tr -d '[] "')
echo -e '\t' Delete min_age: '\t' $(jq -r "[.\"$pol_name\".policy.phases.delete.min_age]| @tsv" $ilm_policies_json |tr -d '[] "')
echo
done
echo
echo "################# ILM POLICY REVIEW [END] #################"
echo

#cleanup temp files
rm ilm_pol*.temp
