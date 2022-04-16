#!/bin/bash
#### THIS IS A TEST.  Not sure where to put this yet
#Lists the ILM policies responsible for the empty rollover indices, the amount of empty indices found, and their rollover and delete age vaules

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
#can probably hard code "commercial" dir instead of using find
ilm_explain_json=$(find . -name "ilm_explain.json")
ilm_policies_json=$(find . -name "ilm_policies.json")

filename=$all_empty_ilm

echo
echo "################# ILM POLICY REVIEW [START] #################"
echo
# GET ILM POLICIES
#cleanup temp file in case previous runs were aborted
if [ -f ilm_pol1.temp ]
  then
  rm ilm_pol*.temp
fi

#get ILM policy for each empty index
file_indices=$(cat $filename)
for index_name in $file_indices
  do
jq "[.indices.\"$index_name\".policy]" $ilm_explain_json |tr -d '[] "'|sed 's/null//g' >> ilm_pol1.temp
done

#remove duplicates
cat ilm_pol1.temp| sed '/^$/d'|sort -u > ilm_pol2.temp

echo "Consider adjusting the rollover max_age or Delete phase min_age in the following ILM Policies"

# GET ILM POLICIES' rollover max_age and delete phase min_age
filename=ilm_pol2.temp
ilm_policies=$(cat $filename)
for pol_name in $ilm_policies
  do
echo
echo $pol_name
echo -e \($(grep -c $pol_name ilm_pol1.temp) empty rollover indices found\)
#$(jq -r "[.\"$pol_name\".policy.phases.hot.actions.rollover.max_age,.\"$pol_name\".policy.phases.delete.min_age]| @tsv" commercial/ilm_policies.json |tr -d '[] "')
echo -e '\t' Rollover max_age: '\t' $(jq -r "[.\"$pol_name\".policy.phases.hot.actions.rollover.max_age]| @tsv" $ilm_policies_json |tr -d '[] "')
echo -e '\t' Delete min_age: '\t' $(jq -r "[.\"$pol_name\".policy.phases.delete.min_age]| @tsv" $ilm_policies_json |tr -d '[] "')
echo
done

echo "################# ILM POLICY REVIEW [END] #################"
