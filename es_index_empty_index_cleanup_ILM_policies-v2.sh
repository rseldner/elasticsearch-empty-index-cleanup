#!/bin/bash
### Lists the ILM policies responsible for the empty rollover indices, the amount of empty indices found, and their rollover and delete age vaules
# It works, but not a fan of the output format. Would be better to see in a table format.
#
#file references.
folder='es_empty_index_cleanup'
all_empty_ilm="$folder/3-es_index_cleanup_all_empty_ilm.txt"
policies_csv=$folder/es_empty_ilm_indices_policies.csv
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

if [ -f $policies_csv ]
  then
  rm $policies_csv
fi

#get ILM policy for each empty index
file_indices=$(cat $filename)
for index_name in $file_indices
  do
jq "[.indices.\"$index_name\".policy]" "$ilm_explain_json" |tr -d '[] "'|sed 's/null//g' >> $empty_ilm_indices_policy_name
done

#remove duplicates
cat $empty_ilm_indices_policy_name| sed '/^$/d'|sort -u > $empty_ilm_indices_policy_name_unique

#sort ILM policies based on their empty index count
filename=$empty_ilm_indices_policy_name_unique
ilm_policies=$(cat $filename)
for pol_name in $ilm_policies
  do
echo "$pol_name" "$(grep -c "$pol_name" "$empty_ilm_indices_policy_name")" >>$empty_ilm_indices_policy_name_unique_count
done
cat $empty_ilm_indices_policy_name_unique_count|sort -k2 -n -r >>$empty_ilm_indices_policy_name_unique_count_sort

echo "The following ILM policies are associated with empty indices."
echo "Consider adjusting the rollover max_age setting and/or the Delete phase min_age"
echo "In Elasticsearch 8.4 and above, you can add min_* settings"
echo "   Doc: https://www.elastic.co/guide/en/elasticsearch/reference/8.4/ilm-rollover.html"
echo "In Elasticsearch 8.5 and above, there is an indices.lifecycle.rollover.only_if_has_documents cluster level setting"
echo "   Doc: https://www.elastic.co/guide/en/elasticsearch/reference/8.5/ilm-settings.html"
echo
echo -e "Policy,empty count,rollover max_age,delete in_age">$policies_csv

# GET ILM POLICIES' empty indices count,rollover max_age, and delete phase min_age and output to csv
filename=$empty_ilm_indices_policy_name_unique_count_sort
ilm_policies=$(cut -f1 -d ' ' $filename)
for pol_name in $ilm_policies
  do
empty_count=$(grep -e ^"$pol_name " $filename| cut -f2 -d ' ')
rollover_max_age=$(jq -r "[.\"$pol_name\".policy.phases.hot.actions.rollover.max_age]| @tsv" "$ilm_policies_json" |tr -d '[] "')
delete_min_age=$(jq -r "[.\"$pol_name\".policy.phases.delete.min_age]| @tsv" "$ilm_policies_json" |tr -d '[] "')

#set value to "unset" if either setting is unconfigured. "column -s, -t" output will be incorrect with empty values
if [ -z "$rollover_max_age" ]; then
  rollover_max_age="unset"
fi
if [ -z "$delete_min_age" ]; then
  delete_min_age="unset"
fi
#output to a CSV file
echo -e "$pol_name,$empty_count,$rollover_max_age,$delete_min_age">>$policies_csv

done

column -s, -t < $policies_csv
echo
echo "################# ILM POLICY REVIEW [END] #################"
echo

#cleanup temp files
rm ilm_pol*.temp
