=====================================
Potential Performance Hit on MISD01P1
=====================================

Summary
=======

The following code was executed 36 times (and parsed 1185 times!) in MISD01P1 - at the time of observation, which was 12:49 on 22/01/2018. 

..  code-block:: sql

    SELECT NVL(MAX(STG_PCL_VOLUMETRIC_ID),0) FROM HEDW_EDW.PARCEL_VOLUMETRIC
    
The code spikes database I/O and runs for around 25 minutes per execution. The execution is part of a larger data load process, assumed to be initiated by ODI.

The statement is part of the loading process for the ``HEDW_EDW.PARCEL_VOLUMETRIC`` table, called from the procedure ``HEDW_EDW.PR_LOAD_VOLUMETRIC_EDW``, and according to the comments in this procedure, is executed to *get the window*.

Given that it causes a spike in database I/O when executed and as it is executing in parallel ( with 32 instances) it is a good candidate for improvement and could save up to 25 minutes, on average, per execution of the ODI module which appears to be calling the code regularly. The spike is caused by the code having to scan the entire table looking for a single *high value* in one particular column, the ``STG_PCL_VOLUMETRIC_ID`` column.

This column is not indexed, so has to be scanned. Alternatively, the column's value *could* be extracted/copied to a separate (and small) table which would take little or no time to scan when looking for the current high value on the next, and subsequent, executions of the ODI load process.


Observations & Assumptions
==========================

Assumptions
-----------

The *window* mentioned above is thought to be a manner of reducing the amount of data scanned in order to facilitate the load. From an initial look at the code, it seems that the loading process is detecting the highest *staging* id and using that in subsequent queries and updates etc to limit the number of rows to be processed.

It is assumed that this value for the staging id could/can be obtained from the staging table itself prior to the data being deleted after loading.

It is assumed that the code is being executed by/from ODI as the ``MODULE_NAME`` column in ``V$SQLAREA`` is set to 'ODI:1432139995400/1/206' and the code is executed at intervals during the day.


Statistics
----------

The following statistics have been extracted from the full statistics (see `Appendix A - Full Statistics`_ below) and relate to the 36 individual executions of the statement.

+-----------------+-----------------+----------------------------+
| Statistic       | Total           | Per Execution              |
+=================+=================+============================+
| Elapsed time    | 51,389.2s       | 1,427.5s (23.8m)           |
+-----------------+-----------------+----------------------------+
| CPU Time        | 922.2s          | 25.6s                      |
+-----------------+-----------------+----------------------------+
| Wait Time (I/O) | 49,495.5s       | 1,374.88s (22.9m)          |
+-----------------+-----------------+----------------------------+
| Data read       | 1,683.2Gb       | 46.76Gb                    |
+-----------------+-----------------+----------------------------+
| Read requests   | 1,758,732       | 48,853.67                  |
+-----------------+-----------------+----------------------------+


Observations
------------

1.  Each execution - there were 36 as of the time monitored - had been parsed 33 times. This is due to each of the parallel slaves and the parallel query coordinator parsing the statement on each execution. This is an overhead (and potential bottleneck for other processing) that cannot be *easily* avoided.

1.  Each execution is carrying out a full scan of the table in parallel with 32 instances. As of the last time statistics were gathered for this table - 5th December 2017 - there were 420.6 million rows. All of these rows are being scanned for the highest value in the ``STG_PCL_VOLUMETRIC_ID`` column.

1.  Each execution spends the vast majority of its time, 96.3%, waiting for results from disk. 

1. Reducing the impact of this statement could reduce the average run time of the overall load process by around 25 minutes - given the above average run time per execution.


Suggestions
===========

The following suggestions could be used to improve performance and reduce the amount of I/O required in order to extract the highest ID for the processing window:

1.   Given the above assumption(s), it may be a better idea to separate that highest value into another table, or location, whereby a full scan is not required. This assumes that this value *can* be removed from the table and stored elsewhere.

1.   If the value cannot be removed/extracted from the table to a separate location:

    *   It could be *copied* to a separate table, and that used to obtain the window for the processing.

    *   It could be indexed so that obtaining the highest value could be easily done with an index scan (or simple lookup) rather than scanning the entire table.


Appendix A - Full Statistics
============================

The full contents of V$SQLAREA for this SQL statement, are:

..  code-block:: none

    "sql_text":"SELECT NVL(MAX(STG_PCL_VOLUMETRIC_ID),0) FROM HEDW_EDW.PARCEL_VOLUMETRIC ",
    "sql_id":"66n01fv1v1nzk",
    "sharable_mem":8714,
    "persistent_mem":34208,
    "runtime_mem":33000,
    "sorts":0,
    "version_count":3,
    "loaded_versions":0,
    "open_versions":0,
    "users_opening":0,
    "fetches":36,
    "executions":36,
    "px_servers_executions":1152,
    "end_of_fetch_count":36,
    "users_executing":0,
    "loads":4,
    "first_load_time":"2018-01-20\/23:38:10",
    "invalidations":0,
    "parse_calls":1185,
    "disk_reads":110462445,
    "direct_writes":0,
    "buffer_gets":110801074,
    "application_wait_time":39799,
    "concurrency_wait_time":12733,
    "cluster_wait_time":0,
    "user_io_wait_time":49495540483,
    "plsql_exec_time":0,
    "java_exec_time":0,
    "rows_processed":36,
    "command_type":3,
    "optimizer_mode":"ALL_ROWS",
    "optimizer_env":"E289FB891242B700DA011000AEF9C3E2CFFA331056414555519521105545551545545558591555449665851D5511058555555155515122555415A0EA0C55514542654554544490A9566E021696C6A355451545025415504416FD557151511555551001550A96295545D1C25444A101105559554049C0544D5555555554FA0705A42521740B500021000020000000000100001000000004002080007D0000000050088098A9011010000000030F40000040CCD400000028042021740B504646262040262320030020003020A0A05050A04001200000401F000040A6A02000A2A040863E00004006020C342000200000F0FF0F000002210304000400803E00000071020000000200A0E031E047860C008000800C710200304010A800688909803E0000B044F6FF0F00F0FF0F000000010000",
    "optimizer_env_hash_value":1915901742,
    "parsing_user_id":126,
    "parsing_schema_id":126,
    "parsing_schema_name":"HEDW_EDW",
    "kept_versions":0,
    "address":"07000105C069F220",
    "hash_value":3283145714,
    "old_hash_value":2636440104,
    "plan_hash_value":3722892853,
    "full_plan_hash_value":3147537283,
    "module":"ODI:1432139995400\/1\/206",
    "module_hash":-553249171,
    "action":"1019428\/1\/1\/1",
    "action_hash":-1876011914,
    "serializable_aborts":0,
    "cpu_time":922193187,
    "elapsed_time":51389173396,
    "last_active_child_address":"070001059F3BA620",
    "remote":"N",
    "object_status":"VALID",
    "literal_hash_value":0,
    "last_load_time":"22-JAN-18",
    "is_obsolete":"N",
    "is_bind_sensitive":"N",
    "is_bind_aware":"N",
    "child_latch":0,
    "program_id":106892,
    "program_line#":174,
    "exact_matching_signature":3511357499006103709,
    "force_matching_signature":12907428311064934633,
    "last_active_time":"22-JAN-18",
    "typecheck_mem":0,
    "io_cell_offload_eligible_bytes":0,
    "io_interconnect_bytes":1806337359872,
    "physical_read_requests":1758732,
    "physical_read_bytes":1807302574080,
    "physical_write_requests":0,
    "physical_write_bytes":0,
    "optimized_phy_read_requests":0,
    "locked_total":1221,
    "pinned_total":1223,
    "io_cell_uncompressed_bytes":0,
    "io_cell_offload_returned_bytes":-965214208,
    "con_id":0,
    "is_reoptimizable":"N"