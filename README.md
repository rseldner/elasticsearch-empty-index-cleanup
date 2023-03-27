# empty-index-cleanup
 tool to help identify empty indices that can be removed; particularly those that have resulted from [max_age ILM rollovers](https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices).
 The tool will organize the empty indices into groups, and will provide a separate output for each subset.
 This will also generate files containing the DELETE API calls for the different groupings.  I attempt to break the DELETEs into separate 4KB requests.

 ## But why? Why not just delete all the empty things?
 **Main reasons I had in mind:**
 1. Indices using ILM rollovers - Deleting the current write index breaks the rollover.  You will also encounter errors when you try to write to the alias.
 2. Datastreams - While you cannot delete the current write index of a data stream, attempting to do so will produce an error.  So you have to make sure a write index is not specified when deleting in bulk.  This makes deleting the datastream backing indices a tedious process.
 3. Avoid accidental deletions.  Using index patterns to delete batches of indices is risky.  Also, a cluster might have [action-destructive-requires-name](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-management-settings.html#action-destructive-requires-name) enabled to begin with, preventing the use of wildcards.
 4. This is faster than scrolling through pages and pages of indices in Kibana

## This currently creates separate outputs for:
1. ALL Empty Indices
2. Empty User indices (aka indices that don't begin with "."; including datastreams)
3. Empty ILM rollover indices
4. Empty ILM rollover non-system/hidden indices
5. Empty ILM rollover and non write indices
6. Empty ILM rollover non-system/hidden and not current write indices
7. Empty non-write datastream backing indices
8. Empty frozen searchable snapshot indices
9. Empty cold searchable snapshot indices

As a safety precaution, a DELETE will be automatically created for **only** 5 through 9.  You probably don't want to delete current write indices.
Though a command to generate DELETEs for 1-4 IS provided in the summary file if you wish to run that separately. 


## Requirements:
- macOS or linux
- [jq](https://stedolan.github.io/jq/download/)
- An elasticsearch support diagnostic or these individual files:
  - indices_stats.json (`GET */_stats?level=shards&pretty&human&expand_wildcards=all`)
  - cat/cat_aliases.txt (`GET _cat/aliases?v`)
  - (optional)commercial/data_stream.json (`GET _data_stream?pretty&expand_wildcards=all`)
  - (optional)commercial/ilm_policies.json (`GET /_ilm/policy?human&pretty`

## Usage:
run the `es_index_empty_index_cleanup_1.sh` script from the main diagnostic folder (or same directory as `indices_stats.json` where `cat_aliases.txt` in a`cat` subdirectory and `data_stream.json` is in a `commercial` subdirectory)

```
$ pwd
/Users/rseldner/Downloads/a1-diagnostics/api-diagnostics-20230316-232543

$ /Users/rseldner/Documents/GitHub/empty-index-cleanup/es_index_empty_index_cleanup_1.sh
```

### Terminal output:

<details>
<summary>
Example 
</summary>

```
################ Empty Index Cleanup Summary [START] ################

1080 Total empty indices(1)
1066 Empty ILM rollover indices (3)
1035 Empty non-system indices (2)
1033 Empty non-system ILM rollover indices(4)
993 * Empty non-write ILM rollover indices(5)
966 * Empty non-system AND non-write ILM rollover indices(6)
6 * Empty frozen searchable snapshot indices(8)
0 * Empty non-write datastream backing indices(7)
0 * Empty cold searchable snapshot indices(9)

* = safest to remove (exclude write indices)

See es_empty_index_cleanup/0-es_index_cleanup_summary.txt and output files in es_empty_index_cleanup path for details

	 less es_empty_index_cleanup/0-es_index_cleanup_summary.txt

################ Empty Index Cleanup Summary [END] ################


##### 💰 Total Shards Savings (cluster wide) [START] 💰 #####

Shards | Group Filename
-------|---------------
2154  	 1-es_index_cleanup_all_empty.txt
2064  	 2-es_index_cleanup_all_empty_user.txt
2126  	 3-es_index_cleanup_all_empty_ilm.txt
2060  	 4-es_index_cleanup_all_empty_ilm_non_sys.txt
1986  	 5-es_index_cleanup_all_empty_ilm_non_write.txt
1932  	 6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt
0  	 7-es_index_cleanup_all_empty_non_write_datastreams.txt
6  	 8-all_empty_frozen_searchable_snapshots.txt
0  	 9-all_empty_cold_searchable_snapshots.txt

###### 💰 Total Shards Savings (cluster wide) [END] 💰 ######

################# ILM POLICY REVIEW [START] #################

The following ILM policies are associated with empty indices.
Consider adjusting the rollover max_age setting and/or the Delete phase min_age
In Elasticsearch 8.4 and above, you can add min_* settings
   Doc: https://www.elastic.co/guide/en/elasticsearch/reference/8.4/ilm-rollover.html
In Elasticsearch 8.5 and above, there is an indices.lifecycle.rollover.only_if_has_documents cluster level setting
   Doc: https://www.elastic.co/guide/en/elasticsearch/reference/8.5/ilm-settings.html

Policy                             empty count  rollover max_age  delete in_age
stage                              515          1d                13d
dev                                505          1d                8d
.siem-signals-default              12           30d               unset
.siem-signals-outside-development  11           30d               unset
apm-rollover-30-days               10           unset             2d
metricbeat                         8            30d               unset
slm-history-ilm-policy             4            30d               90d
ilm-history-ilm-policy             4            30d               90d
.siem-signals-admins               4            30d               unset
prod                               1            unset             unset
filebeat                           1            15d               7d
.lists-default                     1            unset             unset
.items-default                     1            unset             unset
```

</details>

### Summary file output:
<details>
<summary>
Example 
</summary>

```
################ Empty Index Cleanup Summary [START] ################

Use this to identify and quickly remove empty indices.

Particularly created this for when a large amount of indices are inadvertently created due to ILM max_age rollovers
https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices

⭐ My goto output is the Empty non-write ILM rollover indices file: ⭐ 5-es_index_cleanup_all_empty_ilm_non_write.txt ⭐

-----------------------------#1---------------------------------

1080 Total empty indices
🛑 Notes:  Recommended for general reference purposes.
File (list): es_empty_index_cleanup/1-es_index_cleanup_all_empty.txt

Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_empty_index_cleanup/1-es_index_cleanup_all_empty.txt| paste -s -d, -) > es_empty_index_cleanup/1-es_index_cleanup_all_empty.txt-DELETE.txt

-----------------------------#2---------------------------------

1035 Empty User indices
🟡 Notes: User/Custom Indices.  Excludes indices beggining with a "."
File (list): es_empty_index_cleanup/2-es_index_cleanup_all_empty_user.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_empty_index_cleanup/2-es_index_cleanup_all_empty_user.txt| paste -s -d, -) > es_empty_index_cleanup/2-es_index_cleanup_all_empty_user.txt-DELETE.txt

-----------------------------#3---------------------------------

1066 Empty ILM rollover indices
🟡 Notes: ❕Caution - This includes system and current write indices
File (list): es_empty_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_empty_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt| paste -s -d, -) > es_empty_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt-DELETE.txt

-----------------------------#4---------------------------------

1033 Empty non-system ILM rollover indices
🟡 Notes: ❕Caution - This includes the current write indices.
File (list): es_empty_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_empty_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt| paste -s -d, -) > es_empty_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt-DELETE.txt

-----------------------------#5---------------------------------

993 Empty non-write ILM rollover indices
🟢 Notes: Subset of #3.  Safer but note that it includes system/hidden indices (there *may* be a situation where a need a super "duper" user is needed 8.x.  Have not run into this yet though.)
File (list): es_empty_index_cleanup/5-es_index_cleanup_all_empty_ilm_non_write.txt

File containing DELETE was automatically created by script:
	less es_empty_index_cleanup/5-es_index_cleanup_all_empty_ilm_non_write.txt-DELETE.txt

-----------------------------#6---------------------------------

966 Empty non-system AND non-write ILM rollover indices
🟢 Notes: Subset of #4. Safest to remove
File (list): es_empty_index_cleanup/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt

File containing DELETE was automatically created by script:
	less es_empty_index_cleanup/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt-DELETE.txt

-----------------------------#7---------------------------------

0 Empty non-write datastream backing indices
🟢 Notes: Subset of #3. Safe to remove
File (list): es_empty_index_cleanup/7-es_index_cleanup_all_empty_non_write_datastreams.txt

File containing DELETE was automatically created by script:
	less es_empty_index_cleanup/7-es_index_cleanup_all_empty_non_write_datastreams.txt-DELETE.txt

-----------------------------#8---------------------------------

6 Empty frozen searchable snapshot indices
🟢 Notes: Subset of #1. Presumed safe as they would not be write indices and are in a snapshot
File (list): es_empty_index_cleanup/8-all_empty_frozen_searchable_snapshots.txt

File containing DELETE was automatically created by script:
	less es_empty_index_cleanup/8-all_empty_frozen_searchable_snapshots.txt-DELETE.txt

-----------------------------#9---------------------------------

0 Empty cold searchable snapshot indices
🟢 Notes: Subset of #1. Presumed safe as they would not be write indices and are in a snapshot
File (list): es_empty_index_cleanup/9-all_empty_cold_searchable_snapshots.txt

File containing DELETE was automatically created by script:
	less es_empty_index_cleanup/9-all_empty_cold_searchable_snapshots.txt-DELETE.txt

################ Empty Index Cleanup Summary [END] ################
```

</details>

### Output Files in `es_index_cleanup` directory
<details>
<summary>
Example: 
</summary>

```
$ ls -l es_empty_index_cleanup
total 616
-rw-r--r--@ 1 rseldner  staff   4649 Mar 27 13:46 0-es_index_cleanup_summary.txt
-rw-r--r--  1 rseldner  staff  35745 Mar 27 13:45 1-es_index_cleanup_all_empty.txt
-rw-r--r--  1 rseldner  staff  34172 Mar 27 13:45 2-es_index_cleanup_all_empty_user.txt
-rw-r--r--  1 rseldner  staff  35166 Mar 27 13:45 3-es_index_cleanup_all_empty_ilm.txt
-rw-r--r--  1 rseldner  staff  34123 Mar 27 13:45 4-es_index_cleanup_all_empty_ilm_non_sys.txt
-rw-r--r--  1 rseldner  staff  32810 Mar 27 13:45 5-es_index_cleanup_all_empty_ilm_non_write.txt
-rw-r--r--  1 rseldner  staff  32970 Mar 27 13:46 5-es_index_cleanup_all_empty_ilm_non_write.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff  31931 Mar 27 13:46 6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt
-rw-r--r--@ 1 rseldner  staff  32091 Mar 27 13:46 6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff      0 Mar 27 13:46 7-es_index_cleanup_all_empty_non_write_datastreams.txt
-rw-r--r--  1 rseldner  staff      8 Mar 27 13:46 7-es_index_cleanup_all_empty_non_write_datastreams.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff    242 Mar 27 13:46 8-all_empty_frozen_searchable_snapshots.txt
-rw-r--r--  1 rseldner  staff    249 Mar 27 13:46 8-all_empty_frozen_searchable_snapshots.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff      0 Mar 27 13:46 9-all_empty_cold_searchable_snapshots.txt
-rw-r--r--  1 rseldner  staff      8 Mar 27 13:46 9-all_empty_cold_searchable_snapshots.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff    413 Mar 27 13:50 es_empty_ilm_indices_policies.csv
```

</details>

### List file output:
<details>
<summary>
Example  
</summary>

```
$ cat 5-es_index_cleanup_all_empty_ilm_non_write.txt

.kibana-event-log-7.16.0-000005
.kibana-event-log-7.16.0-000006
.kibana-event-log-7.16.0-000007
.siem-signals-default-000001
.siem-signals-default-000002
apm-7.16.0-error-000001
apm-7.16.0-error-000002
apm-7.16.0-error-000003
apm-7.16.0-error-000004
apm-7.16.0-error-000005
...
```
</details>

### DELETE file output:
<details>
<summary>
Example
</summary>

```
$ cat 5-es_index_cleanup_all_empty_ilm_non_write.txt-DELETE.txt

DELETE .kibana-event-log-7.16.0-000005,.kibana-event-log-7.16.0-000006,.kibana-event-log-7.16.0-000007,.siem-signals-default-000001,....
```

</details>

# Next steps:
- [ ] split into separate <4KB DELETEs.  Done but can be improved with some creative math.
  - Reasoning: `http.max_initial_line_length` - https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html
  - [X] assuming index names < 100 chars for now
- [X] identify and rule out current write index for data streams. Related https://github.com/elastic/elasticsearch/issues/86633
  - [ ] account for datastreams that only have one backing index.  update logic to exclude these. This might already be fine, but need to specifically verify.
- [X] generate a list of ILM policies that may need to have `max_age` removed/adjusted and a DELETE phase added
- [X] produce a shard count for each grouping
  - came up with 3 possible count methods.  
  - [X] decide on a method.  cat indices seems good enough.
- [ ] validate ILM managed indices by checking actual ILM outputs rather than assuming based on an index name's numerical suffix.  though this might not be important.  Does it matter if an *empty* index is misinterpreted as being ILM managed?
- [ ] switch to checking alias.json for write indices instead of _cat/aliases as cat APIs are not recommended for programatic parsing.  risk of breaking in the future. This might be slower.
- [X] Mention new preventative settings
  - `min_*` settings for 8.4+ https://www.elastic.co/guide/en/elasticsearch/reference/8.4/indices-rollover-index.html
  - `indices.lifecycle.rollover.only_if_has_documents` for 8.5+
- [ ] simulated `_cat/allocation`.  Not sure if worth the effort.
- [ ] Clean it all up
