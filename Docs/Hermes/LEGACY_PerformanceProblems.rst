=====================================
Legacy Systems - Observed Performance 
=====================================


..  Copy the following template when required, as the desired format
..  for each issue. Then tab is one place backwards after getting rid
..  of the two dots that make it a comment here. (Or use ALT!)

..  ------------------------------------------------------------------
..  SQL_ID: ''
    ----------

    SQL Text
    ~~~~~~~~

    ..  code-block:: sql

        null;

    Observations
    ~~~~~~~~~~~~

    Problems
    ~~~~~~~~

    Proposal
    ~~~~~~~~
    
    Rollback
    ~~~~~~~~

    If it is necessary to rollback the proposed solution, then:

    ..  code-block:: sql
   
..  ------------------------------------------------------------------




..  ===================================================================================================================
Database: MISA01P1
==================




    
..  ===================================================================================================================
Database: MISD01P1
==================

SQL_ID: '6zp5rgdc17657'
-----------------------

SQL Text
~~~~~~~~

..  code-block:: sql

    SELECT MAX ( DIM_CONTROL_BATCH_NUM )
    FROM HEDW_MART.FACT_COLLECTION_EVENTS;

Observations
~~~~~~~~~~~~

This query is executed mostly 1, but occasionally, 2 times per hour and runs for anything between 20 and 40 seconds each time. The reason for this is a full table scan on the ``HEDW_MART.FACT_COLLECTION_EVENTS`` table which is (currently) 183.49 million rows over 1,371,182 blocks.

The cost of a full table scan is around 32,310 and involves the set up, use and breakdown of 32 parallel slaves plus one query controller.

97% of the time spent is waiting on I/O. This is where we can gain the most performance.


Problems
~~~~~~~~

*   Approx 20-40 seconds per execution. (OEM and manually in SQLDeveloper).
*   32 parallel slaves involved.
*   Runs 1 or 2 times per hour.
*   Module: ODI:1432139995400/1/770
*   FTS: Cost 32K
*   Num_rows: 183,481,198
*   Blocks: 1,371,182


Proposal
~~~~~~~~

*   Create an, initially, invisible index, locally partitioned to match the table. Gather required statistics prior to use.

    ..  code-block:: sql
    
        create /* non-unique */ index hedw_mart.dim_control_batch_num_ix
        on hedw_mart.fact_collection_events(dim_control_batch_num)
        invisible
        tablespace "hedw_mart"  
        local
        online;
        
        exec dbms_stats.gather_index_stats('HEDW_MART', 'DIM_CONTROL_BATCH_NUM_IX');

*   To test, enable the optimiser to use invisible indexes.

    ..  code-block:: sql
    
        alter session set optimizer_use_invisible_indexes = true;
        
*   Test the optimiser's proposed plan.

    ..  code-block:: sql
    
        explain plan for
            select max ( dim_control_batch_num )
            from hedw_mart.fact_collection_events;
        
        select * from table(dbms_xplan.display);
        
    You are looking for the new index to be used and a small cost for the query.
    
*   Test the new index.

    Assuming that the optimiser shows the new index being used over a full table scan, test the query.
    
    ..  code-block:: sql
    
        select max ( dim_control_batch_num )
        from hedw_mart.fact_collection_events;

    The query should return the answer in a couple of seconds as opposed to the full scan's 20-40 second response time.
    
*   Make Production Ready.

    ..  code-block:: sql
    
        alter index hedw_mart.dim_control_batch_num_ix visible;
    
Rollback
~~~~~~~~

If it is necesary to rollback the proposed solution, then:

..  code-block:: sql

    drop index hedw_mart.dim_control_batch_num_ix;
    

SQL_ID: '66n01fv1v1nzk'    
-----------------------
    
SQL Text    
~~~~~~~~    
    
..  code-block:: sql    
    
    SELECT NVL(MAX(STG_PCL_VOLUMETRIC_ID),0) 
    FROM HEDW_EDW.PARCEL_VOLUMETRIC;    
    
Observations    
~~~~~~~~~~~~

96.3% of the total response is waiting for I/O.

There are currently 466.3 million rows in the table.

*   Execution takes approximately 46 seconds.

*   The query is executed frequently - 91 times currently (13:30 on 21/02) since 11:05 on 20/02. (V$SQLAREA.LAST_LOAD_TIME)

*   Total CPU time is 2414s. (Average 26.5s per execution)

*   Total Elapsed Time is 131,723s. (Average 1,447.5s per execution)

*   Total I/O Wait Time is 127,024s. (Average 1,395.8s per execution)

*   Disk Reads is 287,853,705. (Average 3,163,227.5 per execution)

*   Buffer Gets is 288,740,018. (Average 3,172,967.2 per execution)
    
Problems    
~~~~~~~~    

*   Approx 40-50 seconds per execution. (OEM and manually in SQLDeveloper).
*   32 parallel slaves involved.
*   Runs 1 or two times per hour, over a 24 hour period. (From ASH history).
*   Module: ODI:1432139995400/1/206
*   FTS: Cost 32K
*   Num_rows: 183481198
*   Blocks: 1371182
    
Proposal    
~~~~~~~~    
    
Rollback    
~~~~~~~~    
    
If it is necessary to rollback the proposed solution, then:   



 
    
..  code-block:: sql    
..  ===================================================================================================================
Database: MOD01P1
=================

SQL_ID: ''
----------

SQL Text
~~~~~~~~

..  code-block:: sql

    null;

Observations
~~~~~~~~~~~~

Problems
~~~~~~~~

Proposal
~~~~~~~~





..  ===================================================================================================================
Database: UKMHPRDDB
===================

SQL_ID: ''
----------

SQL Text
~~~~~~~~

..  code-block:: sql

    null;

Observations
~~~~~~~~~~~~

Problems
~~~~~~~~

Proposal
~~~~~~~~





..  ===================================================================================================================
Database: PNET01P1
==================

SQL_ID: ''
----------

SQL Text
~~~~~~~~

..  code-block:: sql

    null;

Observations
~~~~~~~~~~~~

Problems
~~~~~~~~

Proposal
~~~~~~~~


    