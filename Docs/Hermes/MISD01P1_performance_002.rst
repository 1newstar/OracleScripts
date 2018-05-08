=====================================
Potential Performance Hit on MISD01P1
=====================================
   
Summary
=======

The following code was executed 3 times (and parsed 99 times!) in MISD01P1 - at the time of observation, which was 10:33 on 23/01/2018. 

..  code-block:: sql

    SELECT MAX ( DIM_CONTROL_BATCH_NUM ) FROM HEDW_MART.FACT_COLLECTION_EVENTS
    
The code spikes database I/O and runs for around 12 minutes per execution. The execution is assumed to be part of a larger ODI process, however, I have not yet tracked it down.

Given that it causes a spike in database I/O when executed and as it is executing in parallel ( with 32 instances) it is a good candidate for improvement and could save up to 12 minutes, on average, per execution. The spike is caused by the code having to scan the entire table looking for a single *high value* in one particular column, the ``DIM_CONTROL_BATCH_NUM`` column.

This column is not indexed, so the table has to be scanned in full. An index should be created to reduce the impact of the scan on the response time.


Observations & Assumptions
==========================

Statistics
----------

The following statistics have been extracted from the full statistics (see `Appendix A - Full Statistics`_ below) and relate to the 36 individual executions of the statement.

+-----------------+-----------------+----------------------------+
| Statistic       | Total           | Per Execution              |
+=================+=================+============================+
| Elapsed time    | 2,165.8s        | 240.65s (4.01m)            |
+-----------------+-----------------+----------------------------+
| CPU Time        | 38.19s          | 12.73s                     |
+-----------------+-----------------+----------------------------+
| Wait Time (I/O) | 696.84s         | 232.28s (3.87m)            |
+-----------------+-----------------+----------------------------+
| Data read       | 59.87Gb         | 19.96Gb                    |
+-----------------+-----------------+----------------------------+
| Read requests   | 74,800          | 24,933.33                  |
+-----------------+-----------------+----------------------------+


Observations
------------

1.  Each execution - there were 3 as of the time monitored - had been parsed 33 times. This is due to each of the parallel slaves and the parallel query coordinator parsing the statement on each execution. This is an overhead (and potential bottleneck for other processing) that cannot be *easily* avoided.

1.  Each execution is carrying out a full scan of the table in parallel with 32 instances. As of the last time statistics were gathered for this table - 5th January 2018 - there were 183.48 million rows. All of these rows are being scanned for the highest value in the ``DIM_CONTROL_BATCH_NUM`` column.

1.  Each execution spends the vast majority of its time, 96.52%, waiting for results from disk. 

1. Reducing the impact of this statement could reduce the average run time of the overall process by around 12 minutes - given the above average run time per execution.


Suggestions
===========

Indexed (non-unique) the column so that obtaining the highest value could be easily done with an index scan (or simple lookup) rather than scanning the entire table.


Appendix A - Full Statistics
============================

The full contents of V$SQLAREA for this SQL statement, are:

..  code-block:: none

    "sql_text":"SELECT MAX ( DIM_CONTROL_BATCH_NUM ) FROM HEDW_MART.FACT_COLLECTION_EVENTS",
    "sql_id":"6zp5rgdc17657",
    "sharable_mem":39219,
    "persistent_mem":34152,
    "runtime_mem":32944,
    "sorts":0,
    "version_count":9,
    "loaded_versions":1,
    "open_versions":0,
    "users_opening":0,
    "fetches":3,
    "executions":3,
    "px_servers_executions":95,
    "end_of_fetch_count":3,
    "users_executing":0,
    "loads":302,
    "first_load_time":"2017-10-27\/15:44:12",
    "invalidations":63,
    "parse_calls":99,
    "disk_reads":3935265,
    "direct_writes":0,
    "buffer_gets":4076768,
    "application_wait_time":39695,
    "concurrency_wait_time":0,
    "cluster_wait_time":0,
    "user_io_wait_time":2090513157,
    "plsql_exec_time":0,
    "java_exec_time":0,
    "rows_processed":3,
    "command_type":3,
    "optimizer_mode":"ALL_ROWS",
    "optimizer_cost":32309,    "optimizer_env":"E289FB891242B700DA011000AEF9C3E2CFFA331056414555519521105545551545545558591555449665851D5511058555555155515122555415A0EA0C55514542654554544490A9566E021696C6A355451545025415504416FD557151511555551001550A96295545D1C25444A101105559554049C0544D5555555554FA0705A42521740B500021000020000000000100001000000004002080007D0000000050088098A9011010000000030F40000040CCD400000028042021740B504646262040262320030020003020A0A05050A04001200000401F000040A6A02000A2A040863E00004006020C342000200000F0FF0F000002210304000400803E00000071020000000200A0E031E047860C008000800C710200304010A800688909803E0000B044F6FF0F00F0FF0F000000010000",
    "optimizer_env_hash_value":1915901742,
    "parsing_user_id":127,
    "parsing_schema_id":127,
    "parsing_schema_name":"HEDW_MART",
    "kept_versions":0,
    "address":"07000105A6EC9CA0",
    "hash_value":1477679271,
    "old_hash_value":392365885,
    "plan_hash_value":3832543627,
    "full_plan_hash_value":1651141686,
    "module":"ODI:1432139995400\/1\/770",
    "module_hash":-175181576,
    "action":"894614\/1\/1\/1",
    "action_hash":-1341877924,
    "serializable_aborts":0,
    "cpu_time":38191967,
    "elapsed_time":2165861245,
    "last_active_child_address":"07000105A540D630",
    "remote":"N",
    "object_status":"VALID",
    "literal_hash_value":0,
    "last_load_time":"23-JAN-18",
    "is_obsolete":"N",
    "is_bind_sensitive":"N",
    "is_bind_aware":"N",
    "child_latch":0,
    "program_id":159120,
    "program_line#":571,
    "exact_matching_signature":16179359325885773573,
    "force_matching_signature":16179359325885773573,
    "last_active_time":"23-JAN-18",
    "typecheck_mem":0,
    "io_cell_offload_eligible_bytes":0,
    "io_interconnect_bytes":64283639808,
    "physical_read_requests":74800,
    "physical_read_bytes":64290226176,
    "physical_write_requests":0,
    "physical_write_bytes":0,
    "optimized_phy_read_requests":0,
    "locked_total":21064,
    "pinned_total":21122,
    "io_cell_uncompressed_bytes":0,
    "io_cell_offload_returned_bytes":-6586368,
    "con_id":0,
    "is_reoptimizable":"N"