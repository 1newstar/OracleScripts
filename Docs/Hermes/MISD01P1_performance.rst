=====================================
Potential Performance Hit on MISD01P1
=====================================

Summary
=======

The following code was executed 36 times (and parsed 1185 times!) in MISD01P1 - at the time of observation. 

..  code-block:: sql

    SELECT NVL(MAX(STG_PCL_VOLUMETRIC_ID),0) FROM HEDW_EDW.PARCEL_VOLUMETRIC
    
The code spikes database I/O and runs for around 25 minutes per execution. The execution is part of a larger data load process, assumed to be initiated by ODI.

The statement is part of the loading process for the ``HEDW_EDW.PARCEL_VOLUMETRIC`` table, called from the procedure ``HEDW_EDW.PR_LOAD_VOLUMETRIC_EDW``, and according to the comments in this procedure, is executed to *get the window*.

Given that it causes a spike in database I/O when executed and as it is executing in parallel ( with 32 instances) it is a good candidate for improvement and could save up to 25 minutes, on average, per execution of the ODI module which appears to be calling the code regularly. The spike is caused by the code having to scan the entire table looking for a single *high value* in one particular column, the ``STG_PCL_VOLUMETRIC_ID`` column.

This column is not indexed, so has to be scanned. There are 486 million rows in the table. 


Observations & Assumptions
==========================

Assumptions
-----------

The *window* mentioned above is thought to be a manner of reducing the amount of data scanned in order to facilitate the load. From an initial look at the code, it seems that the loading process is detecting the highest *staging* id and using that in subsequent queries and updates etc to limit the number of rows to be processed.

It is assumed that this value for the staging id could/can be obtained from the staging table itself prior to the data being deleted after loading.

It is assumed that the code is being executed by/from ODI as the ``MODULE_NAME`` column in ``V$SQLAREA`` is set to 'ODI:1432139995400/1/206' and the code is executed at intervals during the day.


Statistics
----------

The following statistics relate to the 36 individual executions of the statement.

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

Execution Plan
--------------

..  code-block:: none

    Plan hash value: 3722892853
     
    ------------------------------------------------------------------------------------------------------------------------------------------
    | Id  | Operation              | Name              | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
    ------------------------------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT       |                   |      1 |     7 | 79282   (1)| 00:00:06 |       |       |        |      |            |
    |   1 |  SORT AGGREGATE        |                   |      1 |     7 |            |          |       |       |        |      |            |
    |   2 |   PX COORDINATOR       |                   |        |       |            |          |       |       |        |      |            |
    |   3 |    PX SEND QC (RANDOM) | :TQ10000          |      1 |     7 |            |          |       |       |  Q1,00 | P->S | QC (RAND)  |
    |   4 |     SORT AGGREGATE     |                   |      1 |     7 |            |          |       |       |  Q1,00 | PCWP |            |
    |   5 |      PX BLOCK ITERATOR |                   |    486M|  3245M| 79282   (1)| 00:00:06 |     1 |1048575|  Q1,00 | PCWC |            |
    |   6 |       TABLE ACCESS FULL| PARCEL_VOLUMETRIC |    486M|  3245M| 79282   (1)| 00:00:06 |     1 |1048575|  Q1,00 | PCWP |            |
    ------------------------------------------------------------------------------------------------------------------------------------------
     
    Note
    -----
       - automatic DOP: Computed Degree of Parallelism is 32 because of degree limit
       - Warning: basic plan statistics not available. These are only collected when:
           * hint 'gather_plan_statistics' is used for the statement or
           * parameter 'statistics_level' is set to 'ALL', at session or system level

Observations
------------

1.  Each execution - there were 36 as of the time monitored - had been parsed 33 times. This is due to each of the parallel slaves and the parallel query coordinator parsing the statement on each execution. This is an overhead (and potential bottleneck for other processing) that cannot be *easily* avoided.

1.  Each execution is carrying out a full scan of the table in parallel with 32 instances. As of the last time statistics were gathered for this table there were 486 million rows. All of these rows are being scanned for the highest value in the ``STG_PCL_VOLUMETRIC_ID`` column.

1.  Each execution spends the vast majority of its time, 96.3%, waiting for results from disk. 

1. Reducing the impact of this statement could reduce the average run time of the overall load process by around 25 minutes - given the above average run time per execution.


Suggestions
===========

The following suggestions could be used to improve performance and reduce the amount of I/O required in order to extract the highest ID for the processing window:

1.   Given the above assumption(s), it may be a better idea to separate that highest value into another table, or location, whereby a full scan is not required. This assumes that this value *can* be removed from the table and stored elsewhere.

1.   If the value cannot be removed/extracted from the table to a separate location:

    *   It could be *copied* to a separate table, and that used to obtain the window for the processing.

    *   It could be indexed so that obtaining the highest value could be easily done with an index scan (or simple lookup) rather than scanning the entire table.


