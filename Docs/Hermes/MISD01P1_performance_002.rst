=====================================
Potential Performance Hit on MISD01P1
=====================================
   
Summary
=======

The following code was executed 3 times (and parsed 99 times!) in MISD01P1 - at the time of observation. 

..  code-block:: sql

    SELECT MAX ( DIM_CONTROL_BATCH_NUM ) FROM HEDW_MART.FACT_COLLECTION_EVENTS
    
The code spikes database I/O and runs for around 12 minutes per execution. The execution is assumed to be part of a larger ODI process, however, I have not yet tracked it down.

Given that it causes a spike in database I/O when executed and as it is executing in parallel ( with 32 instances) it is a good candidate for improvement and could save up to 12 minutes, on average, per execution. The spike is caused by the code having to scan the entire table looking for a single *high value* in one particular column, the ``DIM_CONTROL_BATCH_NUM`` column.

This column is not indexed, so the table has to be scanned in full - there are currently 2902 million rows in the table. 


Observations & Assumptions
==========================

Statistics
----------

The following statistics relate to the 36 individual executions of the statement.

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

Execution Plan
--------------

..  code-block:: none

    Plan hash value: 3832543627
     
    -----------------------------------------------------------------------------------------------------------------------------------------------
    | Id  | Operation              | Name                   | E-Rows |E-Bytes| Cost (%CPU)| E-Time   | Pstart| Pstop |    TQ  |IN-OUT| PQ Distrib |
    -----------------------------------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT       |                        |      1 |     6 | 35961   (1)| 00:00:03 |       |       |        |      |            |
    |   1 |  SORT AGGREGATE        |                        |      1 |     6 |            |          |       |       |        |      |            |
    |   2 |   PX COORDINATOR       |                        |        |       |            |          |       |       |        |      |            |
    |   3 |    PX SEND QC (RANDOM) | :TQ10000               |      1 |     6 |            |          |       |       |  Q1,00 | P->S | QC (RAND)  |
    |   4 |     SORT AGGREGATE     |                        |      1 |     6 |            |          |       |       |  Q1,00 | PCWP |            |
    |   5 |      PX BLOCK ITERATOR |                        |    202M|  1157M| 35961   (1)| 00:00:03 |     1 |1048575|  Q1,00 | PCWC |            |
    |   6 |       TABLE ACCESS FULL| FACT_COLLECTION_EVENTS |    202M|  1157M| 35961   (1)| 00:00:03 |     1 |1048575|  Q1,00 | PCWP |            |
    -----------------------------------------------------------------------------------------------------------------------------------------------
     
    Note
    -----
       - automatic DOP: Computed Degree of Parallelism is 32 because of degree limit
       - Warning: basic plan statistics not available. These are only collected when:
           * hint 'gather_plan_statistics' is used for the statement or
           * parameter 'statistics_level' is set to 'ALL', at session or system level

Observations
------------

1.  Each execution - there were 3 as of the time monitored - had been parsed 33 times. This is due to each of the parallel slaves and the parallel query coordinator parsing the statement on each execution. This is an overhead (and potential bottleneck for other processing) that cannot be *easily* avoided.

1.  Each execution is carrying out a full scan of the table in parallel with 32 instances. As of the last time statistics were gathered for this table - 5th January 2018 - there were 183.48 million rows. All of these rows are being scanned for the highest value in the ``DIM_CONTROL_BATCH_NUM`` column.

1.  Each execution spends the vast majority of its time, 96.52%, waiting for results from disk. 

1. Reducing the impact of this statement could reduce the average run time of the overall process by around 12 minutes - given the above average run time per execution.


Suggestions
===========

Indexed (non-unique) the column so that obtaining the highest value could be easily done with an index scan (or simple lookup) rather than scanning the entire table.


