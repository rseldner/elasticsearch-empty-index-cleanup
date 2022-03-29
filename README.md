# empty-index-cleanup
 tool to help identify empty indices that can be removed; particularly those that have resulted from max_age ILM rollovers.
 The tool will break down the different types of empty indices, and will provide a separate output for each subset.

Currently creates serparate outputs for:
1. Empty Indices
2. Empty ILM rollover indices
3. Empty ILM rollover non-system/hidden indices
4. Empty ILM rollover and non write indices
5. Empty ILM rollover non-system/hidden and not current write indices


### Example script output:
```
################ Index Cleanup Summary [START] ################
-----------------------------#1---------------------------------
81 Empty Indices
Notes: Caution - manual review recommended
Output File: 1-es_index_cleanup_all_empty.txt

-----------------------------#2---------------------------------
55 Empty ILM rollover indices
Notes: Caution - This includes current write indices
Output File: 2-es_index_cleanup_all_empty_ilm.txt

-----------------------------#3---------------------------------
35 Empty ILM rollover non-system/hidden indices
Notes: Caution - This includes current write indices, which can result in annoying errors when removed
Output File: 3-es_index_cleanup_all_empty_ilm_non_sys.txt

-----------------------------#4---------------------------------
45 Empty ILM rollover and non write indices
Notes: Subset of #2.  Safer but note that it includes system/hidden indices (usually fine - might require super "duper" user if 8.x)
Output File: 4-es_index_cleanup_all_empty_ilm_non_write.txt

-----------------------------#5---------------------------------
30 Empty ILM rollover non-system/hidden and not current write indices
Notes: Subset of #3. Safest to remove
Output File: 5-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt

----------------------------------------------------------------
################ Index Cleanup Summary [END] ################
```
### Output Files in `es_index_cleanup` directory
```
$ ls -l es_index_cleanup 
total 48
-rw-r--r--  1 rseldner  staff  1383 Mar 28 16:33 0-es_index_cleanup_summary.txt
-rw-r--r--  1 rseldner  staff  3670 Mar 28 16:33 1-es_index_cleanup_all_empty.txt
-rw-r--r--  1 rseldner  staff  2327 Mar 28 16:33 2-es_index_cleanup_all_empty_ilm.txt
-rw-r--r--  1 rseldner  staff   896 Mar 28 16:33 3-es_index_cleanup_all_empty_ilm_non_sys.txt
-rw-r--r--  1 rseldner  staff  1896 Mar 28 16:33 4-es_index_cleanup_all_empty_ilm_non_write.txt
-rw-r--r--  1 rseldner  staff   768 Mar 28 16:33 5-es_index_cleanup_all_empty_ilm_non_sys_non_write.txt
```

## Requirements:
- [jq](https://stedolan.github.io/jq/download/)
- An elasticsearch support diagnostic or these files:
  - indices_stats.json
  - cat/cat_aliases.txt

# Next steps:
- Add a command in output that will provide the DELETEs for #4 and #5.  Not sure if I will provide this #1,#2,#3 to force the user to make the decision.
- split into separate DELETEs every ~4000 characters
- change to checking alias.json for write indices instead of _cat/aliases as cat APIs are not recommended for programatic parsing.  Potential of breaking in the future.


