# empty-index-cleanup
 tool to help identify empty indices that can be removed; particularly those that have resulted from [max_age ILM rollovers](https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices).
 The tool will organize the empty indices into groups, and will provide a separate output for each subset.

Currently creates serparate outputs for:
1. ALL Empty Indices
2. Empty User indices (aka indices that don't begin with "."; including datastreams)
3. Empty ILM rollover indices
4. Empty ILM rollover non-system/hidden indices
5. Empty ILM rollover and non write indices
6. Empty ILM rollover non-system/hidden and not current write indices

As a safety precaution, a DELETE will be automatically created for **only** 5 and 6.  
Though a command to generate DELETEs for 1-4 IS provided in the summary file if you wish to run that separately. 

### Example Terminal output:
```
################ Index Cleanup Summary [START] ################

32 Total empty indices
0 Empty User indices
29 Empty ILM rollover indices
17 Empty non-system ILM rollover indices
17 Empty non-write ILM rollover indices
11 Empty non-system AND non-write ILM rollover indices

See es_index_cleanup/0-es_index_cleanup_summary.txt and output files in es_index_cleanup path for details

	 less es_index_cleanup/0-es_index_cleanup_summary.txt

################ Index Cleanup Summary [END] ################
```
### Example Summary file output:
```
################ Index Cleanup Summary [START] ################

Use this to identify and quickly remove empty indices.

Particularly created this for when a large amount of indices are inadvertently created due to ILM max_age rollovers
https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html#delete-empty-indices

⭐ My goto output is the Empty non-write ILM rollover indices file: ⭐ 5-es_index_cleanup_all_empty_ilm_non_write.txt ⭐

-----------------------------#1---------------------------------

32 Total empty indices
🛑 Notes:  Caution - manual review recommended
File (list): es_index_cleanup/1-es_index_cleanup_all_empty.txt

Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_index_cleanup/1-es_index_cleanup_all_empty.txt| paste -s -d, -) > es_index_cleanup/1-es_index_cleanup_all_empty.txt-DELETE.txt

-----------------------------#2---------------------------------

0 Empty User indices
🟡 Notes: User/Custom Indices.  Excludes indices beggining with a "."
File (list): es_index_cleanup/2-es_index_cleanup_all_empty_user.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_index_cleanup/2-es_index_cleanup_all_empty_user.txt| paste -s -d, -) > es_index_cleanup/2-es_index_cleanup_all_empty_user.txt-DELETE.txt

-----------------------------#3---------------------------------

29 Empty ILM rollover indices
🟡 Notes: ❕Caution - This includes current write indices, which can result in annoying errors when removed
File (list): es_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt| paste -s -d, -) > es_index_cleanup/3-es_index_cleanup_all_empty_ilm.txt-DELETE.txt

-----------------------------#4---------------------------------

17 Empty non-system ILM rollover indices
🟡 Notes: Caution - This includes the current write indices. Probably not recommended 
File (list): es_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt
Terminal Command to generate a DELETE file (copy/paste to run):

echo DELETE $(cat es_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt| paste -s -d, -) > es_index_cleanup/4-es_index_cleanup_all_empty_ilm_non_sys.txt-DELETE.txt

-----------------------------#5---------------------------------

17 Empty non-write ILM rollover indices
🟢 Notes: Subset of #3.  Safer but note that it includes system/hidden indices (usually fine - haven't tested if a super "duper" user is needed for 8.x)
File (list): es_index_cleanup/5-es_index_cleanup_all_empty_ilm_non_write.txt

File containing DELETE was automatically created by script:
	less es_index_cleanup/5-es_index_cleanup_all_empty_ilm_non_write.txt-DELETE.txt

-----------------------------#6---------------------------------

11 Empty non-system AND non-write ILM rollover indices
🟢 Notes: Subset of #4. Safest to remove
File (list): es_index_cleanup/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt

File containing DELETE was automatically created by script:
	less es_index_cleanup/6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt-DELETE.txt

################ Index Cleanup Summary [END] ################

```
### Output Files in `es_index_cleanup` directory
```
$ ls -l es_index_cleanup 
total 64
-rw-r--r--  1 rseldner  staff  3284 Apr  6 11:33 0-es_index_cleanup_summary.txt
-rw-r--r--  1 rseldner  staff   970 Apr  6 11:33 1-es_index_cleanup_all_empty.txt
-rw-r--r--  1 rseldner  staff     0 Apr  6 11:33 2-es_index_cleanup_all_empty_user.txt
-rw-r--r--@ 1 rseldner  staff   914 Apr  6 11:33 3-es_index_cleanup_all_empty_ilm.txt
-rw-r--r--@ 1 rseldner  staff   440 Apr  6 11:33 4-es_index_cleanup_all_empty_ilm_non_sys.txt
-rw-r--r--@ 1 rseldner  staff   477 Apr  6 11:33 5-es_index_cleanup_all_empty_ilm_non_write.txt
-rw-r--r--@ 1 rseldner  staff   484 Apr  6 11:33 5-es_index_cleanup_all_empty_ilm_non_write.txt-DELETE.txt
-rw-r--r--  1 rseldner  staff   285 Apr  6 11:33 6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt
-rw-r--r--@ 1 rseldner  staff   292 Apr  6 11:33 6-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt-DELETE.txt
```
### Example list file output:
```
apm-7.15.2-profile-000001
apm-7.15.2-profile-000002
apm-7.15.2-profile-000003
apm-7.16.1-error-000003
apm-7.16.1-profile-000001
...
```
### Example DELETE file output:
```
DELETE apm-7.15.2-profile-000001,apm-7.15.2-profile-000002,apm-7.15.2-profile-000003,apm-7.16.1-error-000003,apm-7.16.1-profile-000001,apm-7.16.1-...
```

## Currently testing getting a shard count for these indices as well as their ILM policies

<details>
<summary> **Example Outputs**</summary>
	
```
##### 💰 Total Shards Savings (cluster wide) [START] 💰 #####

1 - Shard count Method 1 (total_count in indices_stats.json) - might take several seconds.  This will count total assigned shards. Unfortunately, this might be empty depending on the diag and cluster version
100

#########

2 - Shard count Method 2 (calculation of P & R columns cat_indices) - This will count total configured shards; so unassigned shards will be included in the count
100

#########

3 - Used shard count Method 3 (count of index name in shards.json - 1 instance = 1 shard). This will count total configured shards; so unassigned shards will be included in the count
100


###### 💰 Total Shards Savings (cluster wide) [END] 💰 ######



################# ILM POLICY REVIEW [START] #################

Consider adjusting the rollover max_age or Delete phase min_age in the following ILM Policies

.siem-signals-default
(1 empty rollover indices found)
	 Rollover max_age: 	 30d
	 Delete min_age: 	


apm-rollover-30-days
(110 empty rollover indices found)
	 Rollover max_age: 	 30d
	 Delete min_age: 	

################# ILM POLICY REVIEW [END] #################
```
	
</details>

## Requirements:
- macOS or linux
- [jq](https://stedolan.github.io/jq/download/)
- An elasticsearch support diagnostic or these files:
  - indices_stats.json (`GET */_stats?level=shards&pretty&human&expand_wildcards=all`)
  - cat/cat_aliases.txt (`GET _cat/aliases?v`)

## Usage:
run the `es_index_empty_index_cleanup.sh` script in the main diagnostic folder (or same directory as `indices_stats.json` where `cat_aliases.txt` in a`cat` subdirectory)

# Next steps:
- [ ] produce a shard count for each grouping
  - came up with 3 count methods.  need to decide where to put that info
- [ ] split into separate DELETEs every ~4000 characters (<4KB)
- [ ] validate ILM managed indices by checking actual ILM outputs rather than assuming based on an index name's numerical suffix.  though this might not be important.  Does it matter if an *empty* index is misinterpreted as being ILM managed?
- [ ] switch to checking alias.json for write indices instead of _cat/aliases as cat APIs are not recommended for programatic parsing.  risk of breaking in the future.
- [ ] identify and rule out current write index for data streams
- [X] generate a list of ILM policies that may need to have `max_age` removed/adjusted and a DELETE phase added
- [ ] Clean it all up
