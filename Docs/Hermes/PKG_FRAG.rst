=======================================
Automated Defragmentation Code for MISA
=======================================

Introduction
============

Rhydian suggested that it would be nice to have the daily FRAGO system automated so that it would execute the desired SQL statements to reorganise tables and/or partitions as well as any local of global indexes that may have been affected.

I had a look at the existing code and wrote a new package in the MISA Development database to try to automate the process. This document describes the new features. After testing, the new package has been implemented in MISA and is in use on a daily basis.


Package Details
===============

The package is named ``PKG_FRAG`` and is owned by the ``HERMES_MI_ADMIN`` account, as is the present code.

The following procedures are publicly callable:

+----------------+-------------------------------------------------------------------------------------------+
| Procedure Name | Purpose & Description                                                                     |
+================+===========================================================================================+
| FRAG_REPORT    | Produces a report, similar to the one currently produced.                                 |
+----------------+-------------------------------------------------------------------------------------------+
| FRAG_CONTROL   | The control procedure which produces the report and the SQL to reorganise the tables etc. |
+----------------+-------------------------------------------------------------------------------------------+

The package relies on the existing procedure ``FRAG_ANALYSE`` to set up the system ready for reorganisation.

Existing Scripts
================

The current (manual) script as run by Alain et al is ``/home/oracle/alain/stats_chk`` and:

*   Executes the ``FRAG_ANALYSIS`` procedure under ``HERMES_MI_ADMIN`` to determine which tables or partitions need to be considered for reorganisation;
*   Lists the SQL commands that are required to carry out the reorganisation;
*   Optionally, list the commands to gather statistics for the reorganised objects.

The output is currently copied and pasted into a SQL*Plus session to be executed manually.


New Scripts
===========

Two new scripts have been added to the ``/home/oracle/alain`` directory. Both still call the ``FRAG_ANALYSIS`` procedure to analyse the fragmentation which is perceived to be a problem. The two new scripts are:

Stats_chk_noreorg
-----------------

This acts exactly the same as the existing script and does not automatically execute the generated SQL commands to facilitate the reorganisation. It is slightly different from the existing script in that it no longer calls the ``FRAG_REBUILD`` procedure to generate the SQL commands, but instead calls the new packaged procedure ``PKG_FRAG.FRAG_CONTROL``.

Progress reports are displayed on screen in the current manner, and resemble 'Done n out of nn.' messages.

Stats_chk_reorg
---------------

This script generates and executes the SQL commands to carry out the reorganisation and, additionally, gathers statistics for all affected objects after all reorganisation has taken place. Statistics are gathered at the table level for unpartitioned tables, or at the partition level for partitions.

To view progress, it is necessary to execute the query ``SELECT ACTION FROM V$SESSION WHERE MODULE='FRAGO'``, or, use the session monitor in Toad or SQLDeveloper. The ``ACTION`` column shows which table/partition is being analysed, reorganised or having its indexes rebuilt.


Procedure Details
=================

FRAG_REPORT
-----------

Unlike at present, the report section of the FRAGO process can be called as a standalone procedure to report on the analysis carried out by the existing, but still required, ``FRAG_ANALYSIS`` procedure. 

``FRAG_REPORT`` will display details of the contents of the ``FRAG_VIEW`` view, populated - or the underlying tables are populated - by the ``FRAG_ANALYSIS`` procedure. Obviously ``FRAG_ANALYSIS`` must still be executed to completion prior to attempting to produce a report - or the data will be out of date.

To execute the report as a standalone, run a script that contains the following SQL command:

..  code-block:: sql

    exec pkg_frag.frag_report
    
Alternatively:

..  code-block:: sql

    begin
        pkg_frag.frag_report;
    end;
    /

The code takes no parameters.    

An example report looks like the following:

..  code-block:: none

    -- Total number of fragmented tables (i.e. full blocks % <= 50): 29
    ------------ List of Tables ------------
    -- TABLE:      D_PCLSHP_DPOT_SERVICE             % Full Blocks:    8.33
    -- TABLE:      A_NETWORK_ENTRY                   
    -- PARTITION:  A_NETWORK_ENTRY_201603            % Full Blocks:   34.47
    -- TABLE:      A_LAST_MANIFEST                   
    -- PARTITION:  A_LAST_MANIFEST_201603            % Full Blocks:   45.21
    -- TABLE:      A_COURIER_POSTCODE                
    -- PARTITION:  A_COURIER_POSTCODE_201603         % Full Blocks:   39.23
    -- TABLE:      A_SOS_AGGR                        
    -- PARTITION:  A_SOS_AGGR_201603                 % Full Blocks:   46.03
    -- TABLE:      F_C2C_C2B_SOS                     
    -- PARTITION:  F_C2C_C2B_SOS_201603              % Full Blocks:   21.29
    -- TABLE:      A_PREADV_ENTRY_AGG                
    -- PARTITION:  A_PREADV_ENTRY_AGG_201603         % Full Blocks:   46.71
    -- TABLE:      F_DRVR_ETRY                       
    -- PARTITION:  F_DRVR_ETRY_201603                % Full Blocks:   32.99
    -- TABLE:      F_PCLSHP_ETRY                     
    -- PARTITION:  F_PCLSHP_ETRY_201603              % Full Blocks:   44.81
    -- TABLE:      F_PCLSHP_OVRALL_SOS_B2C           
    -- PARTITION:  F_PCLSHP_OVRALL_SOS_B2C_201603    % Full Blocks:   40.37
    -- TABLE:      A_CLN_PCL_SOS                     
    -- PARTITION:  A_CLN_PCL_SOS_201603              % Full Blocks:   48.15
    -- TABLE:      A_OSOS_FIRST_CR_COLLECT           
    -- PARTITION:  OSOS_FST_COU_COLL_201603          % Full Blocks:   47.09
    -- TABLE:      A_COURIER_TO_UPP_DEPOT            
    -- PARTITION:  A_COURIER_TO_UPP_DEPOT_201603     % Full Blocks:   36.08
    -- TABLE:      A_CLN_PCL_HERMES_CR_ENTRY         
    -- PARTITION:  A_CLN_PCL_HER_CR_ENTRY_201603     % Full Blocks:   47.02
    -- TABLE:      A_CLN_PCL_RND_CR_ENTRY            
    -- PARTITION:  A_CLN_PCL_RND_CR_ENTRY_201603     % Full Blocks:   47.10
    -- TABLE:      S_PCL_PROG_NO_PCL                 % Full Blocks:   30.93
    -- TABLE:      F_PCLSHP_DPOT_OUT_B2C             
    -- PARTITION:  F_PCLSHP_DPOT_OUT_B2C_201603      % Full Blocks:   41.80
    -- TABLE:      A_UPP_DEPOT_END_TO_END            
    -- PARTITION:  A_UPP_DEPOT_END_TO_END_201603     % Full Blocks:   34.18
    -- TABLE:      D_COURIER_RND_DETAILS             % Full Blocks:    7.92
    -- TABLE:      F_PCLSHP_MISSING_B2C              
    -- PARTITION:  F_PCLSHP_MISSING_B2C_201603       % Full Blocks:   44.11
    -- TABLE:      D_TRACK_POINT                     % Full Blocks:    8.33
    -- TABLE:      D_PARCELSHOP_HIERARCHY            % Full Blocks:   25.78
    -- TABLE:      D_DEPOT_VAN_ROUND                 % Full Blocks:    8.33
    -- TABLE:      A_CLT_INT_NTWRK                   
    -- PARTITION:  A_CLT_INT_NTWRK_201603            % Full Blocks:   20.38
    -- TABLE:      A_CLT_INT_PREADVICE               
    -- PARTITION:  A_CLT_INT_PREADVICE_201603        % Full Blocks:   19.75
    -- TABLE:      D_MANAGER                         % Full Blocks:    1.82
    -- TABLE:      D_ALL_CLIENT_SO_COLLECTION_SLA    % Full Blocks:    2.56
    -- TABLE:      D_ALL_ENQUIRY_SLA                 % Full Blocks:    1.82
    -- TABLE:      A_BUSINESS_VOL_DAILY              
    -- PARTITION:  A_BUSINESS_VOL_DAILY_201603       % Full Blocks:   32.08
    -----------------------------------------------------------------------

You will note that the columns now align and percentages are formatted correctly.

    
FRAG_CONTROL
------------

At present, the FRAGO processing simply displays a large number of SQL comments and commands on screen. It is up to the DBA to copy and paste said commands into an SQL*Plus session to have the code executed. In addition, although there is a parameter to generate ``GATHER_STATS`` commands, this appears unused in the existing scripts. This is possibly because the statistics are gathered after each table or partition is reorganised, and extends the time that the reorganisation takes.

    **WARNING:** *It has been noticed that when copying and pasting a large chunk of text into SQL\*Plus - or other programs, in a Putty or MobaXterm session, silently truncates the chunk of text leaving it incomplete.* 

The packaged version of ``FRAG_CONTROL`` will *always* generate SQL statements that will ``GATHER_STATS`` for tables and partitions and cascade these to the indexes that are affected. These, however, are generated at the end of all the reorganisation commands - so that reorganisation can be completed before any statistics are gathered, allowing for the statistics part to be aborted, if necessary, without affecting the reorganisation.

The ``FRAG_CONTROL`` procedure takes a single parameter, a boolean to indicate whether you wish to display the SQL only - as per the current FRAGO system, or, whether the generated SQL statements should be executed. If the statements are executed, all the reorganisation will take place first and statistics gathered on completion.

To execute the procedure in *display only* mode:

..  code-block:: sql

    exec PKG_FRAG.frag_control(piExecuteCommands => false)
    
Alternatively:

..  code-block:: sql

    begin
        PKG_FRAG.frag_control(piExecuteCommands => false);
    end;
    /
    
This will generate and *display*, but not execute, the SQL statements automatically. The output will show details similar to the following:

..  code-block:: sql

    -----------------------------------------------------------------------
    -- TABLE: D_PARCELSHOP_HIERARCHY
    -----------------------------------------------------------------------
    -- TABLE: D_PARCELSHOP_HIERARCHY -- Size (MB): 5
    -- Partially used blocks: 95
    -- Percentage of highly fragmented blocks: 76.05%
    -- Formatted Blocks: 128
    -- Full Blocks: 33 -- %Full Blocks: 25.78
    -----------------------------------------------------------------------
    ALTER TABLE HERMES_MI_MART.D_PARCELSHOP_HIERARCHY MOVE PARALLEL;
    -- 
    alter index HERMES_MI_MART.DPSHFK1 rebuild parallel ;
    alter index HERMES_MI_MART.DPSHFK3 rebuild parallel ;
    alter index HERMES_MI_MART.DPSHFK2 rebuild parallel ;
    alter index HERMES_MI_MART.DPSHPKI rebuild parallel ;
    alter index HERMES_MI_MART.DPH_PCLSHP_TYP rebuild parallel ;
    exec dbms_output.put_line('Done 22 out of 29');
    
The displayed output can be copied and pasted in the current manner by the DBA.

To execute the procedure in *auto execute* mode:

..  code-block:: sql

    exec PKG_FRAG.frag_control(piExecuteCommands => true)
    
Alternatively:

..  code-block:: sql

    begin
        PKG_FRAG.frag_control(piExecuteCommands => true);
    end;
    /
    
This will generate, display, and *execute*, the SQL statements automatically. The output will show details similar to the following:

..  code-block:: sql

    -----------------------------------------------------------------------
    -- TABLE: D_PARCELSHOP_HIERARCHY
    -----------------------------------------------------------------------
    -- TABLE: D_PARCELSHOP_HIERARCHY -- Size (MB): 5
    -- Partially used blocks: 95
    -- Percentage of highly fragmented blocks: 76.05%
    -- Formatted Blocks: 128
    -- Full Blocks: 33 -- %Full Blocks: 25.78
    -----------------------------------------------------------------------
    EXECUTING: ALTER TABLE HERMES_MI_MART.D_PARCELSHOP_HIERARCHY MOVE PARALLEL;
    -- 
    EXECUTING: alter index HERMES_MI_MART.DPSHFK1 rebuild parallel ;
    EXECUTING: alter index HERMES_MI_MART.DPSHFK3 rebuild parallel ;
    EXECUTING: alter index HERMES_MI_MART.DPSHFK2 rebuild parallel ;
    EXECUTING: alter index HERMES_MI_MART.DPSHPKI rebuild parallel ;
    EXECUTING: alter index HERMES_MI_MART.DPH_PCLSHP_TYP rebuild parallel ;
    EXECUTING: exec dbms_output.put_line('Done 22 out of 29');

You should note that ``DBMS_OUTPUT`` messages cannot be seen when executing, until the PL/SQL procedure has completed.
    
Monitoring Progress
===================

There are thee separate phases to the reorganisation:

Analysis
--------

While the ``FRAG_ANALYSE`` procedure is running, progress can be monitored by:

..  code-block:: sql

    select sid, module, action
    from   v$session
    where  module = 'FRAGO';
    
You will see a list of tables, or tables and their affected partition, with an 'A:' prefix. This indicates that the analysis phase is taking place. For example:

..  code-block:: none

    A: F_PCLSHP_OVERALL_SOS F_PCLSHP_OVERALL_SOS_201802
    
Which shows that partition ``F_PCLSHP_OVERALL_SOS_201802`` of table ``F_PCLSHP_OVERALL_SOS`` is being analysed.

SQL Generation
--------------

During the generation of SQL commands to reorganise tables or partitions, indexes and gathering statistics, the messages are simply:

..  code-block:: none

    Done n out of nnnn.

This shows that in the list of nnnn tables or partitions to be reorganised, the SQL commands for table or partition n have now been generated and the procedure is currently processing table n+1.  


SQL Execution
-------------

There are two methods of SQL execution.

Manual Processing
~~~~~~~~~~~~~~~~~

While the reorganisation is taking place, the script will generate progress reports after each and every table, or partition, has been reorganised, and its indexes rebuilt. These messages will simply be ``Done n of nnnn.`` where 'n' is the current table number, and 'nnnn' is the total number of tables/partitions being defragmented.   

Automatic Processing
~~~~~~~~~~~~~~~~~~~~

When running automatically, the progress can be monitored using the SQL command:

..  code-block:: sql

    select sid, module, action
    from   v$session
    where  module = 'FRAGO';
    
If the procedure is currently reorganising the table, partition or rebuilding indexes, the result will be similar to:

..  code-block:: none

    R: F_PCLSHP_OVERALL_SOS

The 'R:' prefix shows that the procedure is reorganising as opposed to analysing the table, or partition.

If, on the other hand, indexes are being rebuilt, the same message as above will be displayed, but there will be numerous rows returned, rather than just one. This is because the indexes are rebuilt in parallel.

Progress Messages
-----------------

The following ``ACTION`` values will indicate progress:

Analysis Phase
~~~~~~~~~~~~~~

+-------------------------------------+--------------------------------------------------------------------------+
| Action                              | Description                                                              |
+=====================================+==========================================================================+
| Archiving and Housekeeping          | The analysis is running some housekeeping.                               |
+-------------------------------------+--------------------------------------------------------------------------+
| Housekeeping complete               | The analysis phase have completed its housekeeping.                      |
+-------------------------------------+--------------------------------------------------------------------------+
| A: <table name> <Partition name>    | The named table, or partition, is being analysed.                        |
+-------------------------------------+--------------------------------------------------------------------------+

Reorganisation Phase
~~~~~~~~~~~~~~~~~~~~

+-------------------------------------+--------------------------------------------------------------------------+
| Action                              | Description                                                              |
+=====================================+==========================================================================+
| FRAG_REPORT                         | The report section is running.                                           |
+-------------------------------------+--------------------------------------------------------------------------+
| FRAG_REPORT Complete                | The report is done.                                                      |
+-------------------------------------+--------------------------------------------------------------------------+
| SQL Generation                      | Starting SQL command generation for the various tables etc.              |
+-------------------------------------+--------------------------------------------------------------------------+
| Done n out of nnnn                  | The nth table has finished generating SQL commands. (Not execution!)     |
+-------------------------------------+--------------------------------------------------------------------------+
| SQL Generation Complete             | SQL Generation has finished.                                             |
+-------------------------------------+--------------------------------------------------------------------------+
| R: <table name>                     | The named table, is being reorganised, or its indexes are being rebuilt. |
+-------------------------------------+--------------------------------------------------------------------------+
| Reorg Complete. Now Gathering Stats | All tables have completed reorganisation. Statistics are being gathered. |
+-------------------------------------+--------------------------------------------------------------------------+

If there are no rows in ``V$SESSION`` where the ``MODULE`` column contains 'FRAGO', then the reorganisation has completed. (Or has yet to start!)


Error Handling
--------------

The package has error handling built in to the *execution* process so that if a table or partition fails to move, or an index fails to rebuild for example, then *only* that particular SQL command will fail. This problem will not prevent the remainder of the process being aborted as any subsequent SQL commands will still be attempted.

At the end of all processing, a warning is written to the output if any such errors were detected during the run any suitable error messages and call stacks are displayed beneath the offending SQL statement in the processes output.

For (a contrived) example:

..  code-block:: sql

    EXECUTING: ALTER TABLE HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE MOVE PARALLEL TABLESPACE THIS_DOES_NOT_EXIST; 
    ORA-00959: tablespace 'THIS_DOES_NOT_EXIST' does not exist
    
    ORA-06512: at line 1
    ORA-06512: at "HERMES_MI_ADMIN.PKG_FRAG", line 67

    ORA-00959: tablespace 'THIS_DOES_NOT_EXIST' does not exist

    -----------------------------------------------------------------------
    ERRORS DETECTED: Please check output log for details.
    -----------------------------------------------------------------------
    Process exited.
    Disconnecting from the database ukmisdev MIS A Development.

The line of code marked 'EXECUTING' which is listed prior to the error stack, is the code that caused the error.

**NOTE:** *When running the code manually, error trapping is as per the SQL\*Plus default - it may report errors and carry on, or it may just stop at that point.*
    
Statistics Gathering
====================

Currently, statistics are not gathered by the FRAGO system, although they can be, most likely because the ``DBMS_STATS.GATHER_xxxx_STATS`` commands are interspersed throughout the reorganising commands - leading to potential delays in the reorganisation.

The new package always generates statistics gathering commands and will either display or execute these, as requested, after all the reorganising commands have completed. This allows for the DBA to abort the FRAGO tasks after running the reorganisations, leaving statistics to be gathered later.

Statistics gathered are identical to those currently (not) gathered in that tables and partitions will have statistics gathered at the global level cascaded to all indexes. All statistics are gathered with parallel degree 2. 

The package will also check to see if statistics are locked for each table or partition, as appropriate, and if so, will no longer attempt to gather statistics for that table or partition. Instead, you will see that the SQL command to gather statistics has been modified into a comment, so will not be executed. As the following snippet displays:

..  code-block:: sql

    begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_NETWORK_ENTRY', partname => 'A_NETWORK_ENTRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
    
    -- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_PCLSHP_DPOT_SERVICE', cascade => true, degree => 2); end;
    
    begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_LAST_MANIFEST', partname => 'A_LAST_MANIFEST_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
    ...

This may be of some use top the DBA running  the code as it will inform him that statistics are locked for some reason - which may be accidental.


FRAGO Automation
================

At present the FRAGO code is executed manually. The new code can be scheduled using DBMS_SCHEDULER, (or cron) for example, however, as running the defragmentation depends on the successful completion of daily report production, there is no easy manner to determine a suitable starting time. The code should be continued to be run manually by the DBAs as at present.

It may be possible to build some sort of check to ensure that the BO Reporting has completed thus allowing the reorganisations to be submitted via the scheduler. This needs more investigation.



