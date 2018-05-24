==================================
Daily Statistics - Technical Guide
==================================

..  Author:     Norman Dunbar
..  Date:       23rd March 2018.
..  Changes:    13/03/2018: Added logging of start, end and errors as appropriate.
..              13/03/2018: Jobs now submitted for all databases.
..              13/03/2018: MISA jobs are "load balanced" in an effort to spread the load.
..              19/04/2018: Big tables get special handling. 
..              23/05/2018: Procedure ``emergencyAnalyse`` added for ETL3 overrun situations.
..                          Split into Installation, User and Technical guides.

..  -----------------------------------------------------------------------------------------------------------
..  NOTE:   To get a hyperlink in a docx/pdf output file that looks for something in the current document 
..          instead of a web page, do this:
..
..          ... `Rolling Back <#rolling-back>`_ ... 
..
..          Rolling Back' is the link text as it will appear in the document.
..          <#rolling-back> is the hyperlinked section heading, massaged for correct use.
..
..          Section headings are lower cased and all spaces and punctuation, except hyphens, are replaced
..          with hyphens.
..  -----------------------------------------------------------------------------------------------------------

    

Introduction
============

This document describes, in a mildly technical manner, the new Daily Statistics Gathering code.

All development work was carried out on the MISA development database, ``ukmisdev`` on server ``devora07.int.hlg.de``.


Installation & Usage
====================

The InstallGuide document holds all the details of installing the system. The UserGuide has details of using the system to analyse objects with stale statistics.


Brief System Overview
=====================

A new system has been built, which runs under the privileged user account ``DBA_USER``.  This user exists on all production databases and should have the installation scripts run to create the table and packages required prior to use.

After installation, there are a number new objects in the ``DBA_USER`` schema:

*   Table ``DAILY_STATS_EXCLUSIONS`` which holds a list of all the usernames which will *not* be considered for statistics gathering by the package.

*   Trigger ``DAILY_STATS_EXCLUSIONS_TRG`` which is used to ensure that the username is in upper case. 

*   Table ``DAILY_STATS_LOG`` which holds a log of everything analysed in the last 31 days (by default). This table can be house-kept on demand.

*   Trigger ``DAILY_STATS_LOG_TRG`` to make sure that the ``ID`` column is populated from the sequence ``DAILY_STATS_LOG_SEQ``.

*   Sequence ``DAILY_STATS_LOG_SEQ`` used by the above trigger to provide a primary key for the table.

*   Package ``PKG_DAILYSTATS`` which consists of the code required to carry out the statistics gathering. It consists of the following procedures:

    *   ``StatsControl`` which runs the processes necessary to generate statistics gathering SQL commands and to create procedures and scheduler jobs to execute them. This also will house-keep the ``DAILY_STATS_LOG`` table retaining, by default, only the last 31 days of data.

    *   ``StatsAnalyse`` which does the analysis of the objects and updates the ``DAILY_STATS_LOG`` logging table.

    *   ``EmergencyAnalyse`` which allows the DBA to manually execute statistics gathering for numerous objects when a scheduled job appears to be going to overrun the ETL3 start time.

    *   ``HousekeepStats`` which allows hose keeping of the old data in the logging table. This defaults to 31 days, but can be changed on the fly as necessary.

    *   ``ExcludeUsername`` which adds a new user to the exclusions table.

    *   ``IncludeUsername`` which removes a user from the exclusions table.

    *   ``ReportExcludedUsers`` which lists the contents of the exclusions table.

Externally to the database, three bash scripts are created in the ``/home/oracle/alain`` directory. These are the scripts that run the three methods of statistics gathering and are:

*   ``dailystats_auto`` which runs the statistics gathering in a fully automatic mode. The DBA simply needs to execute the script.

*   ``dailystats_semi`` which runs the statistics gathering in a semi-automatic mode. The DBA simply needs to execute the script, then, on completion, enable the required scheduled jobs by executing the commands listed on screen.

*   ``dailystats_manual`` which simply displays appropriate commands to gather statistics for objects with stale statistics. The DBA simply needs to execute the required commands.

    
DBA_USER Objects
----------------

The code runs under the ``DBA_USER`` schema and appropriate privileges will have been granted to all DBA users (in the HUK DBA Team) by the installation scripts. If new DBAs are added to the team, then these will need explicit grants to execute the package's code.


Table: DAILY_STATS_EXCLUSIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is a table consisting of one column, ``USERNAME``, which is also the primary key. It *should* contain all the Oracle supplied, or Hermes specific, usernames which *are not* to be considered for gathering of statistics no matter how stale. All the Oracle users such as SYS, SYSTEM, MDSYS etc will (or should) be found here as they should never have statistics gathered during the limited time we have available on a daily basis.

There is a trigger, ``DAILY_STATS_EXCLUSIONS_TRG``, attached to INSERT or UPDATE operations on this table, and this simply makes sure that the username is always in upper case when written to the table.

There are three procedures in the package ``PKG_DAILYSTATS`` which manipulate this table:

*   ``ExcludeUsername`` which adds a new username to the table, thus *excluding* its objects from any further statistics gathering by the system.

*   ``IncludeUsername`` which removes an existing username from the table, thus *including* its objects in statistics gathering by the system, when statistics are stale.

*   ``ReportExcludedUsers`` which reports on the username currently *excluded* from statistics gathering.


Trigger: DAILY_STATS_EXCLUSIONS_TRG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This trigger is associated with the above table, and on INSERT or UPDATE actions, will ensure that the data supplied are in upper case.


Table: DAILY_STATS_LOG
~~~~~~~~~~~~~~~~~~~~~~

This table is used to record the outcome of the statistics gathering exercise for the various objects involved. Any errors that occur will be logged here as well as the start and end date & time for the gathering.

There is a trigger associated with this table to ensure that the ID column is always populated by a number from a sequence. 

The table is automatically house-kept by the ``StatsControl`` procedure and by default, keeps 31 days worth of data. This means that the sequence used to populate the ``ID`` column can cycle, and will do so after reaching 999,999,999.

The table can be house-kept on demand by running the ``HousekeepStats`` procedure with a suitable value for the number of days to retain.

If any rows in the table have NULL for the ``ENDTIME`` and ``ERROR_MESSAGE`` columns, then the chances are that the object in question was having statistics gathered at the time the scheduler job was aborted. The user guide has details of some action that must be carried out after an abort to ensure that an error message is logged for the aborted objects.


Trigger: DAILY_STATS_LOG_TRG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This trigger is associated with the above table, and on INSERT actions, will ensure that the ``ID`` column has a valid value.


Sequence: DAILY_STATS_LOG_SEQ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Used by the above trigger to populate the ``ID`` column in the ``DAILY_STATS_LOG`` table.


Package: PKG_DAILYSTATS
~~~~~~~~~~~~~~~~~~~~~~~

This package holds all the code for the new system. There are procedures to:

*   Report on the statistics which need to be gathered;
*   To gather the required statistics;
*   Carry out emergency statistics gathering to (try to) prevent overruns with the ETL;
*   Carry out maintenance of the ``DAILY_STATS_EXCLUSIONS`` table;
*   Carry out maintenance of the ``DAILY_STATS_LOG`` table.

The DBA users have been granted execute access on this package, but *not* to any of the underlying objects, so using the package (ok, or logging in directly as DBA_USER, or SYS) is the only way to use the new system.

The code works on MISA (only) by building a list of objects that have stale statistics. The list is sorted into size order with the biggest first. The list is then 'dealt out' to each of the required procedures so that the biggest object goes to ``DAILYSTATSPROC_000``, the next biggest to ``DAILYSTATSPROC_001`` and so on down to the maximum allowed, currently 18 jobs are permitted. This leaves room for special jobs which deal with individual objects for those objects which have been noted as taking too much time to analyse.

For PNET/RTT and MYHERMES, the objects are simply allocated to a single procedure as these databases don't take as long as MISA, nor have as many stale objects on a daily basis. These will be executed in a correspondingly single scheduler job named ``DAILYSTATS000`` which calls the procedure ``DAILYSTATSPROC_000`` to do the actual work.

The source code generated for these procedures is then compiled and a DBMS_SCHEDULER job created to execute the code. It was done this way as there is a limit of 4,000 characters in the action for a scheduled job. MISA usually has around a thousand objects to analyse on a daily basis. Scheduled job named ``DAILYSTATS_000`` will execute procedure ``DAILYSTATSPROC_000`` and so on - this way, you can get back to the executing code from the job name. This also applies to special jobs created for the larger objects.

As mentioned, some objects have been noted as taking *far too long* to gather statistics, and these can hold up any following processing and might cause an ETL3 overrun. These objects will be separated out into a separate procedure and job as required, one single object per procedure and job. The procedures will be named ``DAILYSTATSSPECIALPROC_nnn`` and the jobs ``DAILYSTATSSPECIAL000``. These run with a parallel degree of 4 as opposed to the default degree of 2 for the normal jobs, in an effort to get them finished before the ETL starts.

Any database can have these large objects, so PNET/RTT and MYHERMES may also submit one or more special jobs, if a large object is defined in those databases.


Technical Description
=====================

The installed package, ``DBA_USER.PKG_DAILYSTATS``, exposes:

*   A single control procedure, ``StatsControl`` to control the running of the statistics gathering;
*   An analysis procedure ``StatsAnalyse`` to do the actual object analysis and logging of details;
*   An "emergency"  procedure ``EmergencyAnalyse`` to assist the DBA in correcting scheduled jobs that may overrun the ETL start time;
*   Three user maintenance procedures, ``includeUsername``, ``excludeUsername`` and ``reportExcludedUsers`` to exclude or include certain schemas from the statistics gathering processes;
*   A house keeping procedure, ``HousekeepStats`` to tidy the ``DAILY_STATS_LOG`` table. 

Procedure: StatsControl
-----------------------

This is the top level procedure in the system. It can be used to produce a report which lists the commands required to bring statistics up to date, or to actually execute all the commands required. If the commands are to be executed, it will do this as a single "online" session for databases MYHERMES and RTT/PNET only. For MISA, the work is always done in "batch" mode by submitting scheduler jobs, as necessary. The number of jobs can be configured, but the default is 18.

The procedure requires three parameters:

*   ``piDatabase`` - the database name. Only MISA, RTT, PNET or MYHERMES are allowed. This should match up to the appropriate database on the server where you are running the code, otherwise some additional tables may have statistics gathered where they are not needed. RTT (aka PNET) does not analyse tables with 'TRKG' in their name, the others will.

*   ``piDisplayOnly`` - specifies whether the commands are to be generated & displayed only, or to be executed. Allowable values are true or false. The default, if not specified is false.

*   ``piEnableJobs`` - specified whether the collection of DBMS_SCHEDULER jobs are to be enabled - and therefore executed - or not. The default, if not specified, is false - meaning that jobs created will not be enabled and will therefore not execute until enabled by the DBA. Set this to true if you wish to have the jobs submitted and enabled, for immediate execution.


Gathering Statistics
~~~~~~~~~~~~~~~~~~~~

Fully Automatic Method
""""""""""""""""""""""

To generate the required SQL commands, and to execute them, proceed as follows, using MISA as an example database:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.statsControl(piDatabase = 'MISA', piDisplayOnly => false, piEnableJobs => true);
   
This is what the script ``dailystats_auto`` carries out on your behalf. All jobs created will be submitted, enabled and will execute on submission. The jobs thus created will remain present in the database until the next run of the new system. This allows the run logs to be checked for errors.

You may, if desired, leave out the ``piDisplayOnly => false`` parameter as this defaults to false anyway, but it's better to leave it in to be explicit.



Semi-Automatic Method
"""""""""""""""""""""
    
If, on the other hand, the DBA wishes to have the jobs created and submitted, but *not automatically* executed, then the commands to run are:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.statsControl(piDatabase = 'MISA', piDisplayOnly => false, piEnableJobs => false);

This is what the script ``dailystats_semi`` carries out on your behalf. All jobs created will be submitted, but disabled,  and will not execute on submission. The jobs thus created will remain present in the database until the DBA manually enables each one, whereupon it will execute. Once again, the jobs will remain in the scheduler until next run of the new system.

You may, if desired, leave out the ``piDisplayOnly => false`` parameter as this defaults to false anyway, but it's better to leave it in to be explicit.

As of 23/04/2018, large tables get special treatment in that they get a bigger parallelism and get submitted as a job by themselves. This was necessary as some of the bigger tables were causing overruns on the MISA and PNET databases. The job and procedure names will be ``DAILYSTATSSPECIALnnn`` and ``DAILYSTATSSPECIALPROC_nnn`` 
  

Manual Method
"""""""""""""

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.statsControl(piDatabase = 'MISA', piDisplayOnly => true, piEnableJobs => false);

This is what the script ``dailystats_manual`` carries out on your behalf. No jobs or procedures will be created and no commands will be executed. The various commands required to gather statistics manually, will simply be generated and displayed on screen. It is the responsibility of the DBA to ensure that they are subsequently executed, somehow.

You may, if desired, leave out the ``piEnableJobs => false`` parameter as this defaults to false anyway, but it's better to leave it in to be explicit.

In the old system, the commands generated were calls to ``DBMS_STATS.GATHER_TABLE_STATS``, but the new system makes calls similar to the following:

..  code-block:: sql

    BEGIN dba_user.pkg_dailystats.statsAnalyse(piOwner => 'MYHERMES', piTableName => 'RFND_PYMT', piObjectType => 'TABLE'); end;
  
By calling the named package, details of the start time, end time and any errors that occurred can be logged to the ``DAILY_STATS_LOG`` table.

    

Emergency Analysis
~~~~~~~~~~~~~~~~~~

If the scheduled job(s), submitted by  the system, appear to be taking far too long, then it is necessary to abort those jobs (just) prior to the ETL3 starting its processing. Because the largest objects are analysed first, then it is normally the case that it will be one of the first objects in the job that is taking the most time. If the job is aborted, all the other objects in that scheduled job will not have statistics gathered - which might cause problems.

The procedure ``EmergencyAnalysis`` will accept a scheduled job name - but not one of the special job's names as these only ever analyse a single object - and from that job name, will extract the name of the procedure being executed, and from the source code of that procedure, will list an ``EXEC`` statement that will carry out the analysis for the objects in the procedure. The objects will be listed in increasing size order and the object that has caused the hold up *will also be listed*. It is the DBA's responsibility to ensure that the latter doesn't get executed again!

Once the list is displayed, it can be copied and pasted into a SQL*Plus session (or more than one if necessary) logged in as the ``DBA_USER`` account, and executed. As the order is from smallest to biggest, the executions will take an increasing time, normally, to run.

Running these commands will assist in getting as many objects analysed as possible, even given the large object that is holding things up.


    
User Maintenance
----------------

Certain user accounts should not be considered for statistics gathering. These include, but are not limited to, the various accounts supplied by Oracle and the Hermes DBAs, Business Objects users etc.

The ``PKG_DAILYSTATS`` package, has a number of procedures built in to allow these users to be included or excluded from the daily statistics gathering. These are described below.

ExcludeUsername
~~~~~~~~~~~~~~~

This procedure adds a username to the ``DAILY_STATS_EXCLUSIONS`` table so that it's tables etc *will not* be considered for statistics gathering by the new system. The procedure will report back whether or not the username has been added to, or already existed in, the table. If the username already existed in the table, no errors will be raised.

    
IncludeUsername
~~~~~~~~~~~~~~~

This procedure removes a username from the ``DAILY_STATS_EXCLUSIONS`` table so that its tables etc *will* now be considered for statistics gathering by the new system. The procedure will report back whether or not the username has been removed from the table. If the username didn't already exist on the table, no errors will be raised.
   

ReportExcludedUsers
~~~~~~~~~~~~~~~~~~~

This procedure lists the contents of the ``DAILY_STATS_EXCLUSIONS`` table.


System Messages
===============

In the table of messages below, these abbreviations are used:

+-----------+-------------------+
| Abbrev    | Description       |
+===========+===================+
| PPPP      | Procedure name    |
+-----------+-------------------+
| JJJJ      | Job name          |
+-----------+-------------------+
| DDDD      | Database Name     |
+-----------+-------------------+
| UUUU      | User/account name |
+-----------+-------------------+
| EEEE      | Oracle error text |
+-----------+-------------------+

..  NORM:   You need a paragraph between tables to prevent them merging.

Error Messages
--------------

In addition to the specific messages in the tables below, the SQL error which caused the problem, and a back trace of the PL/SQL call stack showing how the system got to the error, will normally be displayed where appropriate..

+------------------------------------+-----------------------------------+
| Message                            | Reason, description etc           |
+====================================+===================================+
| MisaProcBuilder(): EEEE            | The MisaProcBuilder procedure     |
|                                    | failed with error EEEE. Previous  |
|                                    | messages will detail exactly what |
|                                    | happened.                         |
+------------------------------------+-----------------------------------+
| HousekeepStats(): EEEE             | The HousekeepStats procedure      |
|                                    | failed with error message EEEE.   |
+------------------------------------+-----------------------------------+
| EXECUTING: SQL Statement           | The statistics are being gathered |
|                                    | for an object as per the SQL      |
|                                    | Statement listed.                 |
+------------------------------------+-----------------------------------+
|| StatsAnalyse(): EEEE              | The StatsAnalyse procedure failed |
|| FAILED: SQL Statement             | with error EEEE while analysing   |
|                                    | an object using the SQL listed.   |
+------------------------------------+-----------------------------------+
| StatsControl(): EEEE               | The StatsControl procedure failed |
|                                    | with error EEEE. This will be     |
|                                    | followed by a stack trace.        |
+------------------------------------+-----------------------------------+
| LOGSTATS(INSERT) : EEEE            | The LogStats procedure failed     |
|                                    | with error EEEE while inserting a |
|                                    | new row.                          |
+------------------------------------+-----------------------------------+
| LOGSTATS(UPDATE ID = NNN) : EEEE   | The LogStats procedure failed     |
|                                    | with error EEEE while updating a  |
|                                    | row with the ID shown.            |
+------------------------------------+-----------------------------------+
| CreateProcedure(): EEEE            | The CreateProcedure procedure     |
|                                    | failed with error EEEE while      |
|                                    | creating a new procedure.         |
+------------------------------------+-----------------------------------+
| ProcedureBuilder(): EEEE           | The ProcedureBuilder procedure    |
|                                    | failed with error EEEE while      |
|                                    | creating a new procedure's source |
|                                    | code.                             |
+------------------------------------+-----------------------------------+
| Failed to create one or more       | Self explanatory message. Follows |
| procedures.                        | the procedureBuilder one above.   |
+------------------------------------+-----------------------------------+
| MISA: Creating nnn procedures      | Self explanatory message.         |
| and jobs.                          |                                   |
+------------------------------------+-----------------------------------+
| MISA: Creating 1 (only) procedure  | Self explanatory message.         |
| and job.                           |                                   |
+------------------------------------+-----------------------------------+
|| Creating Procedure/Job: PPPP/JJJJ | The creation worked.              |
|| Created.                          |                                   |
+------------------------------------+-----------------------------------+
|| Creating Procedure/Job: PPPP/JJJJ | The creation failed.              |
|| FAILED.                           |                                   |
+------------------------------------+-----------------------------------+


Informational Messages
----------------------

+-----------------------------------+-----------------------------------+
| Message                           | Reason, description etc           |
+===================================+===================================+
| There is/are nnn objects(s) with  | Output when it is known how many  |
| stale statistics.                 | objects have state statistics.    |
+-----------------------------------+-----------------------------------+
| JJJJ - old job successfully       | Yesterday's scheduler job JJJJ    |
| dropped from scheduler.           | has been removed prior to         |
|                                   | creating today's scheduler job.   |
|                                   | MISA only.                        |
+-----------------------------------+-----------------------------------+
| JJJJ created and submitted for    | Today's scheduler job, JJJJ, has  |
| immediate execution.              | been created and submitted.       |
|                                   |                                   |
+-----------------------------------+-----------------------------------+
| JJJJ created and submitted but    | Today's scheduler job, JJJJ, has  |
| execution is suspended until      | been created and submitted but not|
| enabled.                          | enabled.                          |
+-----------------------------------+-----------------------------------+
| ``exec DBMS_SCHEDULER.ENABLE(     | This command will enable the new  |
|      'DBA_USER.JJJJ');``          | job that is currently disabled.   |
+-----------------------------------+-----------------------------------+
| Database name 'DDDD' is           | Database name is incorrect or not |
| incorrect. MISA, MYHERMES, RTT or | supplied.                         |
| PNET only.                        |                                   |
+-----------------------------------+-----------------------------------+
| DDDD nothing to do today.         | Output when there are no SQL      |
|                                   | statements generated to analyse   |
|                                   | objects.                          |
+-----------------------------------+-----------------------------------+
| DDDD: Ignoring partition          | A partition named 'NO' is being   |
| owner.table_name.NO.              | ignored on the named table.       |
+-----------------------------------+-----------------------------------+
| DDDD: Ignoring owner.tablename.   | RTT/PNET table name has 'TRKG' in |
|                                   | it's name and is being ignored.   |
+-----------------------------------+-----------------------------------+
| Submitting an additional nn       | 'nn' large object(s) are being    |
| special job(s) for large tables.  | analysed as a special jobs.       |
|                                   | For debugging and monitoring      |
|                                   | purposes, the command *may* also  |
|                                   | be listed.                        |
+-----------------------------------+-----------------------------------+


User Maintenance Messages
-------------------------

+-----------------------------------+-----------------------------------+
| Message                           | Reason, description etc           |
+===================================+===================================+
| UUUU has been added to the        | User UUUU will no longer be       |
| exclusions table.                 | considered for statistics         |
|                                   | gathering.                        |
+-----------------------------------+-----------------------------------+
| UUUU already existed on the       | Self explanatory, informational   |
| exclusions table.                 | message.                          |
+-----------------------------------+-----------------------------------+
| UUUU was not found on the         | Self explanatory, informational   |
| exclusions table.                 | message.                          |
+-----------------------------------+-----------------------------------+
| UUUU has been removed from the    | User UUUU will be considered for  |
| exclusions table.                 | statistics gathering.             |
+-----------------------------------+-----------------------------------+
| UUUU is excluded from the         | Message output by the procedure   |
| dba_user.pkg_dailyStats           | ``reportExcludedUsers``.          |
| processing.                       |                                   |
+-----------------------------------+-----------------------------------+


