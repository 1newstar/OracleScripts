==========================
Daily Statistics Gathering
==========================

..  Author:     Norman Dunbar
..  Date:       23rd March 2018.
..  Changes:    13/03/2018: Added logging of start, end and errors as appropriate.
..              13/03/2018: Jobs now submitted for all databases.
..              13/03/2018: MISA jobs are "load balanced" in an effort to spread the load.
..              19/04/2018: Big tables get special handling. 

Current Situation
=================

The current system, inherited from Alain and run by James daily, is to query ``DBA_TAB_STATISTICS`` for any  tables, partitions or subpartitions, where the ``STALE_STATS`` columns is 'YES'. (This is slightly different from how ``DBMS_STATS`` would gather stale statistics as that looks in ``DBA_TAB_MODIFICATIONS``.) To ensure consistency, the new system will continue to read from ``DBA_TAB_STATISTICS``.

As MISA is by far the biggest *problem* database, it is done first every day. Normally with up to 10 separate sessions open, each gathering statistics for a number of tables, partitions and/or subpartitions.

The process is quite simple, and very manual:

1.  Determine that ETL2 completed ok, at least one hour ago. Use `Dashboard <http://axukpremisddb02.int.hlg.de:8080/apex/f?p=106>`_ to determine this.
1.  Determine that we will not be executing any new statements after 08:10. Currently executing statements should be allowed to continue.
1.  Determine the objects that have stale statistics.
1.  Generate SQL statements for those objects.
1.  Execute said SQL, in as many simultaneous sessions as necessary. (MISA <= 10, RTT/MYHERMES = 1)
1.  Repeat again tomorrow.

It should also be noted that the script ``/home/oracle/alain/daily_fdp_stats.sh`` is executed by cron at 11:30 on a daily basis, 7 days a week. This script only gathers statistics for ``HERMES_MI_MART.F_DELIVERY_PARCEL`` on the MISA server.

MISA and MYHEREMS are identical, however, RTT (aka PNET) must not gather statistics on any tracking  tables - anything with 'TRKG' in the table name.

Appendices `A <#appendix-a---misa-current-system>`_, `B <#appendix-b---rttpnet-current-system>`_ and `C <#appendix-c---myhermes-current-system>`_ give details of the scripts currently in use on each of the three databases, to determine which, if any, objects require to be re-analysed.

New System - Installation Kit
=============================

All development work was carried out on the MISA development database, ukmisdev on server devora07.int.hlg.de.

An install kit exists, which is a zip file containing the following scripts:

*   ``dailystats_control.sql`` - The top level script which calls the others in order, to install the system and assigns any required privileges to the HUK DBA team members only, at present. The ``DBA_USER`` account is also granted the ``CREATE JOB`` privilege so that the required scheduler jobs can be created when processing the MISA database. The script creates a log file of everything that was carried out - ``dailystats_control.log`` - in the current directory.
*   ``dailystats_exclusions.sql`` - Creates the table ``DBA_USER.DAILY_STATS_EXCLUSIONS``, plus trigger ``DAILY_STATS_EXCLUSIONS_TRG``.
*   ``dailystats_logging.sql`` - Creates the table ``DBA_USER.DAILY_STATS_LOG``, trigger ``DAILY_STATS_LOG_TRG`` and a sequence ``DAILY_STATS_LOG_SEQ``. 
*   ``pkg_dailystats.pks`` - Creates the package ``DBA_USER.PKG_DAILYSTATS``.
*   ``pkg_dailystats.pkb`` - Creates the package body for ``DBA_USER.PKG_DAILYSTATS``.
*   ``load_exclusions.sql`` - Loads a number of default users which we wish to exclude from the gathering of statistics under the new system. This includes the standard Oracle supplied system type user accounts, the HUK DBA team's own accounts and a few other *obvious* accounts.

There is a rollback script to remove the new system, should this be necessary.

*   ``dailystats_rollback.sql`` - Rolls back the entire installation of the new system. Actions (and any errors) are recorded in the log file ``dailystats_rollback.log``.

There are also three shell scripts to be installed on the servers, and *edited as appropriate, to change the database names*:

*   ``dailystats_manual`` - Allows the statistics to be gathered manually as at present. Simply displays the SQL commands required.
*   ``dailystats_auto`` - Allows the statistics to be gathered automatically. Generates the SQL commands required and submits a number of DBMS_SCHEDULER jobs to execute the commands. The jobs are submitted in the *enabled* state, so will execute immediately. For MISA the number of jobs is configured within the package (default 18) while for other databases, the script submits a single scheduler job.
*   ``dailystats_semi`` - Allows the statistics to be gathered semi-automatically. Generates the SQL commands required and submits a number of DBMS_SCHEDULER jobs to execute the commands, however, the jobs are submitted *disabled* so do not execute until the DBA enables them. For MISA the number of jobs is configured within the package (default 18) while for other databases, the script submits a single scheduler jobs.


Installation
------------

1.  Login to the server as your own account, and become the oracle user in the normal manner. Set the appropriate Oracle environment, again in the normal manner.
1.  Create a new directory, for example, ``dailystats_install``, and change into it.
1.  Copy the installation kit into the new directory and unzip it.
1.  Check that the files listed above are all present.
1.  Connect to SQL*Plus as either your own DBA enabled user, or as a SYDBA enabled user.
1.  Execute the ``dailystats_control.sql`` script. This will install the system.
1.  If necessary:
    *   Copy the three (or two for non-MISA databases) ``dailystats_*`` scripts to the ``/home/oracle/alain`` directory. They must be owned by the oracle account.
    *   Edit the scripts to change one occurrence of 'XXXX' to the appropriate database name (MISA, RTT (or PNET) and MYHERMES only are permitted.)
    *   Ensure that the scripts are made executable by at least owner and group - ``chmod ug+x dailystats_*``.


Once this has completed, the ``dailystats_control.log`` file should be checked for any errors and anything untoward resolved before using the system.

The privilege, ``CREATE JOB`` will be granted to the DBA_USER account, however, some, but not all, databases already have this granted. This will not cause an error. This privilege *will not* be removed if the system is rolled back (see `Rolling Back <#rolling-back>`_ below.)

Configuration
-------------

After installation has been completed, and checked, it may be advisable to execute the following code in a SQL*Plus session (or Toad, SQLDeveloper etc):

..  code-block:: sql

    set serverout on size unlimited
    set lines 300 trimspool on trimout on pages 200
    exec dba_user.pkg_dailystats.reportExcludedUsers;
    
This will display all the users currently excluded from the checks for objects with stale statistics. depending on the database, you may need or wish to add others, or, remove some of the usernames listed. The package contains some user management procedures to carry out those tasks. See `New System - Brief Description <#new-system---brief-description>`_ for details.

..  -----------------------------------------------------------------------------------------------------------
..  NOTE:   The above '#' is how to get a hyperlink in a docx output file that looks for something in the
..          current document instead of a web page. 

..  NOTE:   Also, section headings are lower cased and all spaces and punctuation, except hyphens, are replaced
..          with hyphens.
..  -----------------------------------------------------------------------------------------------------------


Rolling Back
------------

Should it be necessary to rollback the new system, and remove it from the database, simply:

1.  Login to the server as your own account, and become the oracle user in the normal manner. Set the appropriate Oracle environment, again in the normal manner.
1.  Change to the new directory, ``dailystats_install``.
1.  Connect to SQL*Plus as either your own DBA enabled user or as a SYSDBA enabled user.
1.  Execute the ``dailystats_rollback.sql`` script. This will uninstall the system.
1.  Check the ``dailystats_rollback.log`` file for any errors.
1.  Remove the ``dailystats_*`` scripts from ``/home/oracle/alain``:
    
    ..  code-block:: sql
    
        rm dailystats_{auto,manual,semi}

Note that the script will not revoke ``CREATE JOB`` from the DBA_USER account as some database had this privilege granted prior to the system being installed.


New System - Brief Description
==============================

A new system has been built, which runs under the privileged user account ``DBA_USER``.  This user exists on all production databases and should have the installation scripts run to create the table and packages required prior to use.

There are a number new objects in the system:

*   Table ``DAILY_STATS_EXCLUSIONS`` which holds a list of all the usernames which will *not* be considered for statistics gathering by the package;
*   Trigger ``DAILY_STATS_EXCLUSIONS_TRG`` which is used to ensure that the username is in upper case. 
*   Table ``DAILY_STATS_LOG`` which holds a log of everything analysed in the last 31 days (by default). This table can be house-kept on demand.
*   Trigger ``DAILY_STATS_LOG_TRG`` to make sure that the ``ID`` column is populated from the sequence ``DAILY_STATS_LOG_SEQ``.
*   Sequence ``DAILY_STATS_LOG_SEQ`` used by the above trigger to provide a primary key for the table.
*   Package ``PKG_DAILYSTATS`` which consists of the code required to carry out the statistics gathering. It consists of the following procedures:
    *   ``StatsControl`` which runs the processes necessary to generate statistics gathering SQL commands and to create procedures and scheduler jobs to execute them. This also will house-keep the ``DAILY_STATS_LOG`` table retaining, by default, only the last 31 days of data.
    *   ``StatsAnalyse`` which does the analysis of the objects and updates the ``DAILY_STATS_LOG`` logging table.
    *   ``HousekeepStats`` which allows hose keeping of the old data in the logging table. This defaults to 31 days, but can be changed on the fly as necessary.
    *   ``ExcludeUsername`` which adds a new user to the exclusions table.
    *   ``IncludeUsername`` which removes a user from the exclusions table.
    *   ``ReportExcludedUsers`` which lists the contents of the exclusions table.

    
DBA_USER Objects
----------------

The code runs under the ``DBA_USER`` schema and appropriate privileges have been granted to all DBA users (in the HUK DBA Team) by the installation scripts.


Table: DAILY_STATS_EXCLUSIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is a table consisting of one column, ``USERNAME``, which is also the primary key. It *should* contain all the Oracle supplied, or Hermes specific, usernames which are not to be considered for gathering of statistics no matter how stale. All the Oracle users such as SYS, SYSTEM, MDSYS etc will (or should) be found here as they should never have statistics gathered during the limited time we have available on a daily basis.

There is a trigger attached to INSERT or UPDATE operations on the table, and this simply makes sure that the username is always in upper case when written to the table.

There are three procedures in the package ``PKG_DAILYSTATS`` which manipulate this table:

*   ``ExcludeUsername`` which adds a new username to the table, thus excluding it from any further statistics gathering by the system.
*   ``IncludeUsername`` which removes an existing username from the table, thus including it in statistics gathering by the system.
*   ``ReportExcludedUsers`` which reports on the username currently excluded.


Trigger: DAILY_STATS_EXCLUSIONS_TRG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This trigger is associated with the above table, and on INSERT or UPDATE actions, will ensure that the data supplied are in upper case.


Table: DAILY_STATS_LOG
~~~~~~~~~~~~~~~~~~~~~~

This table is used to record the outcome of the statistics gathering exercise for the various objects involved. Any errors that occur will be logged here as well as the start and end date & time for the gathering.

There is a trigger associated with this table to ensure that the ID column is always populated by a number from a sequence. 

The table is house-kept by the ``StatsControl`` procedure and by default, keeps 31 days worth of data. This means that the sequence used to populate the ``ID`` column can cycle, and does so after reaching 999,999,999.

The table can be house-kept on demand by running the ``HousekeepStats`` procedure with a suitable value for the number of days to retain.


Trigger: DAILY_STATS_LOG_TRG
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This trigger is associated with the above table, and on INSERT actions, will ensure that the ``ID`` columns has a valid value.


Sequence: DAILY_STATS_LOG_SEQ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Used by the above trigger to populate the ``ID`` column in the ``DAILY_STATS_LOG`` table.


Package: PKG_DAILYSTATS
~~~~~~~~~~~~~~~~~~~~~~~

This package holds all the code for the new system. There are procedures to:

*   Report on the statistics which need to be gathered;
*   To gather the required statistics;
*   Carry out maintenance of the ``DAILY_STATS_EXCLUSIONS`` table.
*   Carry out maintenance of the ``DAILY_STATS_LOG`` table.

The DBA users have been granted execute access on this package, but *not* to any of the underlying objects, so using the package (ok, or logging in directly as DBA_USER, or SYS) is the only way to use the new system.

If the system is processing MISA, then the package (specification) defines the maximum number of jobs that can be submitted concurrently to gather statistics. If there are more objects that the defined maximum number of jobs, then the objects will be spread over the requisite number of jobs, otherwise, a single job will be created and submitted. Jobs will be named ``DailyStats_000`` through ``DailyStats_nnn`` where 'nnn' is one less than the configured setting for the maximum number of allowed jobs. Each job executes a single procedure named ``DailyStatsProc_nnn`` where 'nnn' corresponds to the job number.

In an effort to spread the load across all the jobs, the selected objects are sorted into descending order of the number of blocks in the objects (table, partition or subpartition). Once the full list is known, the various tasks (ie, one object requiring analysis) are 'load balanced' by 'dealing' one task to each of the jobs in turn until all tasks have been 'dealt' and all the jobs have a 'hand' of tasks. (Card game analogy sort of works!). 

If the system is processing MYHERMES or RTT (aka PNET) databases, then all the commands will be executed in a single scheduler job named ``DailyStats_000`` which calls a procedure ``DailyStatsProc_000`` to do the actual work.


New System - Usage
==================

To use the new system to gather statistics, follow the following instructions.

1.  Login to the database server as your own user, as normal.
1.  Become the Oracle user in the normal manner.
1.  Set the Oracle environment as per the required database. (Only MISA, RTT/PNET or MYHERMES at present.
1.  Change to the 'alain' directory (``/home/oracle/alain``)
1.  You now have three options in running scripts:
    1.  ``./dailystats_manual`` will act as the old system and simply display the commands that you should execute.
    1.  ``./dailystats_auto`` will generate the various tasks to be executed, and execute them automatically for you.
    1.  ``./dailystats_semi`` will generate the various tasks, and will submit a number of jobs under the DBMS_SCHEDULER, as user DBA_USER, but the jobs will not be enabled. The DBA can enable them in turn and have them execute.
    

Technical Description
=====================

The installed package, ``DBA_USER.PKG_DAILYSTATS``, exposes a single control procedure, ``statsControl``, an analysis procedure ``StatsAnalyse`` to do the actual analysis and logging of details, three user maintenance procedures, ``includeUsername``, ``excludeUsername`` and ``reportExcludedUsers``, and one house keeping procedure, ``HousekeepStats`` to tidy the ``DAILY_STATS_LOG`` table. 

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

As of 23/04/2018, large tables get special treatment in that they get a bigger parallelism and get submitted as a job by themselves. This was necessary as some of the bigger tables were causing overruns on the MISA and PNET databases. The job and procedure names will be ``DAILYSTATSSPECIALnnn`` and ``DAILYSTATSSPECIALPROC_nnn`` 


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

This is what the script ``dailystats_manual`` carries out on your behalf. No jobs will be created created and no commands will be executed. The various commands required to gather statistics manually, will be generated and displayed on screen. It is the responsibility of the DBA to ensure that they are subsequently executed, somehow.

You may, if desired, leave out the ``piEnableJobs => false`` parameter as this defaults to false anyway, but it's better to leave it in to be explicit.

In the old system, the commands generated were calls to ``DBMS_STATS.GATHER_TABLE_STATS``, but the new system makes calls similar to the following:

..  code-block:: sql

    BEGIN dba_user.pkg_dailystats.statsAnalyse(piOwner => 'MYHERMES', piTableName => 'RFND_PYMT', piObjectType => 'TABLE'); end;
  
By calling the named package, details of the start time, end time and any errors that occurred can be logged to the ``DAILY_STATS_LOG`` table.

As of 23/04/2018, large tables get special treatment in that they get a bigger parallelism. This was necessary as some of the bigger tables were causing overruns on the MISA and PNET databases when running in automatic or semi-automatic mode.
    
    
User Maintenance
----------------

Certain user accounts should not be considered for statistics gathering. These include, but are not limited to, the various accounts supplied by Oracle and the Hermes DBAs, BO users etc.

The ``PKG_DAILYSTATS`` package, has a number of procedures built in to allow these users to be included or excluded from the daily statistics gathering. These are described below.

In the following examples, the usernames supplied to the packaged procedures can be in upper, lower or mixed case. They will be converted to uppercase for processing.

ExcludeUsername
~~~~~~~~~~~~~~~

This procedure adds a username to the exclusions table so that it's tables etc *will not* be considered for statistics gathering by the new system. A user is added thus:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.excludeUsername('some user');
    
The procedure will report back whether or not the username has been added to the table. If the username already existed in the table, no errors will be raised.

Example
"""""""

..  code-block:: sql

    set serverout on size unlimited

    -- FRED is not in the table yet.
    exec dba_user.pkg_dailystats.excludeUsername('FRED');

    FRED has been added to the exclusions table.
    
    
    -- FRED is already in the table.
    exec dba_user.pkg_dailystats.excludeUsername('fred');
    
    FRED already existed in the exclusions table.
    
    
IncludeUsername
~~~~~~~~~~~~~~~

This procedure removes a username from the exclusions table so that its tables etc *will* now be considered for statistics gathering by the new system. A user is removed as follows:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.includeUsername('some user');
    
The procedure will report back whether or not the username has been removed from the table. If the username didn't already exist on the table, no errors will be raised.

Example
"""""""

..  code-block:: sql

    set serverout on size unlimited

    -- FRED currently exists in the exclusions table.
    exec dba_user.pkg_dailystats.includeUsername('fred');

    FRED has been removed from the exclusions table.
  
    
    -- FRED is not in the exclusions table.
    exec dba_user.pkg_dailystats.includeUsername('FRED');
    
    FRED was not found in the exclusions table.
    

ReportExcludedUsers
~~~~~~~~~~~~~~~~~~~

This procedure lists the contents of the exclusions table.

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.reportExcludedUsers;
    
Example
"""""""

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.reportExcludedUsers;

    ANONYMOUS is excluded from the dba_users.pkg_dailyStats processing.
    APEX_030300 is excluded from the dba_users.pkg_dailyStats processing.
    APEX_PUBLIC_USER is excluded from the dba_users.pkg_dailyStats processing.
    ...
    WILLIAMSRHY is excluded from the dba_users.pkg_dailyStats processing.
    WMSYS is excluded from the dba_users.pkg_dailyStats processing.
    XDB is excluded from the dba_users.pkg_dailyStats processing.
    XS$NULL is excluded from the dba_users.pkg_dailyStats processing.
    
   

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
|                                    | failed with error EEEE.           |
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


Appendix A - MISA: Current System
=================================

Because of the size of MISA and the large number of tables, partitions and subpartitions that normally require a refresh of their statistics, the processing for MISA is normally done in 10 separate database sessions.

Groups of commands are collected from the following scripts' output, and pasted into each of the 10 sessions. Once one (or more) have finished processing, then another group of commands is pasted in for processing.

Tables
------

The following SQL statement will identify those tables which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- recycle stuff
    -- and owner = 'HERMES_MI_STAGE'
    -- and owner = 'ECHO_EDW'
    -- and owner = 'ECHO_DW_STAGE'
    -- and owner = 'C2C'
    -- and last_analyzed < sysdate -4
       and stale_stats <> 'NO'
       and object_type = 'TABLE'
    -- and table_name = 'A_NETWORK_ENTRY'
       and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    -- order by 1,2,3, last_analyzed desc
       order by owner, table_name;

Partitions
----------

The following SQL statement will identify those partitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||partition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'PARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'PARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    order by owner,
             table_name,
             partition_name;

SubPartitions
-------------

The following SQL statement will identify those subpartitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||SUBpartition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'SUBPARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'SUBPARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    order by owner,
             table_name,
             partition_name;


Appendix B - RTT/PNET: Current System
=====================================


Tables
------

The following SQL statement will identify those tables which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- recycle stuff
    and table_name not like '%TRKG%'
    -- and owner = 'HERMES_MI_STAGE'
    -- and owner = 'ECHO_EDW'
    -- and owner = 'ECHO_DW_STAGE'
    -- and owner = 'C2C'
    -- and last_analyzed < sysdate -4
    and stale_stats <> 'NO'
    and object_type = 'TABLE'
    -- and table_name = 'A_NETWORK_ENTRY'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    -- order by 1,2,3, last_analyzed desc
    order by owner, table_name;

Partitions
----------

The following SQL statement will identify those partitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||partition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'PARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and table_name not like '%TRKG%'
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'PARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    order by owner,
             table_name,
             partition_name;

SubPartitions
-------------

The following SQL statement will identify those subpartitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||SUBpartition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'SUBPARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and table_name not like '%TRKG%'
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'SUBPARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN','CTXSYS','MDSYS','OLAPSYS','ORDSYS','SYSADMIN')
    order by owner,
             table_name,
             partition_name;


Appendix C - MYHERMES: Current System
=====================================


Tables
------

The following SQL statement will identify those tables which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- recycle stuff
    -- and owner = 'HERMES_MI_STAGE'
    -- and owner = 'ECHO_EDW'
    -- and owner = 'ECHO_DW_STAGE'
    -- and owner = 'C2C'
    -- and last_analyzed < sysdate -4
       and stale_stats <> 'NO'
       and object_type = 'TABLE'
    -- and table_name = 'A_NETWORK_ENTRY'
       and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN')
    -- order by 1,2,3, last_analyzed desc
       order by owner, table_name;

Partitions
----------

The following SQL statement will identify those partitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||partition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'PARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'PARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN')
    order by owner,
             table_name,
             partition_name;

SubPartitions
-------------

The following SQL statement will identify those subpartitions which require statistics gathering, and, will generate the necessary SQL:

..  code-block:: sql

    select 'EXEC DBMS_STATS.GATHER_TABLE_STATS ('''||owner
                                                   ||''','''
                                                   ||table_name
                                                   ||''','''
                                                   ||SUBpartition_name
                                                   ||''',GRANULARITY => '''
                                                   ||'SUBPARTITION'
                                                   ||''');' cmd
    from dba_tab_statistics
    where table_name not like 'BIN$%' -- remove recyclebin stuff
    and stale_stats = 'YES'
    and partition_name <> 'NO'
    and object_type = 'SUBPARTITION'
    and owner not in ('SYS','SYSTEM','SYSMAN','DBSNMP','OLAPSYS','XDB','WMSYS','OWBSYS','OWF_MGR','EXFSYS','OUTLN')
    order by owner,
             table_name,
             partition_name;




