=============================
Daily Statistics - User Guide
=============================

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

    

Installation
============

For full details on installing the new Daily Statistics Gathering system, see the InstallGuide document.


Configuration
=============

After installation has been completed, and checked, it may be advisable to execute the following code in a SQL*Plus session (or Toad, SQLDeveloper etc):

..  code-block:: sql

    set serverout on size unlimited
    set lines 300 trimspool on trimout on pages 200
    exec dba_user.pkg_dailystats.reportExcludedUsers;
    
This will display all the users currently *excluded* from the checks for objects with stale statistics - this means that none of the users listed will have statistics gathered for any of their objects, unless done manually in an ad-hoc manner.

Depending on the database, you may need or wish to exclude other users, or to remove some of the usernames listed - the ``pkg_dailyStats`` package contains some user management procedures to carry out those tasks. See below for details.


Daily Statistics Gathering
==========================

Daily statistics is normally started around 06:00, Monday to Friday except bank holidays. However, it merely needs to have completed before the start of ETL3, which is normally around 08:15 to 08:20. In the event of an overrun, the statistics gathering job(s) should be aborted, the log table updated with the details, and the ETL allowed to run. Details on these actions are listed below.


Running Stats Jobs
------------------

*   Logon the the primary database server for MISA, PNET and MYHERMES as your own account, and become the oracle user:

    ..  code-block:: bash

        sudo -iu oracle    
        cd alain
        
    The scripts to run the daily tasks have been installed into the ``alain`` directory, under the ``oracle`` account.

*   Check the Dashboard (`http://axukpremisddb02.int.hlg.de:8080/apex/f?p=106:1:13359801905169::NO::: <http://axukpremisddb02.int.hlg.de:8080/apex/f?p=106:1:13359801905169::NO:::>`_) and make sure that ETL1 and ETL2 have finished "in the green", for today, if not, **do not** start the statistics gathering jobs.

    If the delay is in any way excessive, the daily tasks can be aborted for today, and started again, if all is well, tomorrow.

*   If the ETLs have successfully completed, start the jobs, on all three servers, by running  the following command on each:

    ..  code-block:: bash

        ./dailystats_auto
        
    This will analyse the objects that need statistics gathering, and spread them out over a number of separate DBMS_SCHEDULER jobs (MISA only, the other databases get a single job each) with any of the previously identified larger (and thus, long running) objects, getting a separate job to themselves - one large object per additional job. This attempts to spread the load (MISA in the main, but occasionally, PNET also) across the server.

    
Other job scripts are available as well, these are:

*   ``dailystats_semi`` which creates and submits the same jhobs as above, but does not enable them. At the end of the output from the script, will be a list of the required commands to activate the jobs, at the DBA's leisure.

*   ``dailystats_manual`` which simply lists the commands that are required to be executed, by the DBA, in order to analyse the objects requiring fresh statistics. This is somewhat equivalent to the old, now superceded, manual system.


Monitoring Running Jobs
-----------------------

You can monitor the jobs, which run under the Oracle Scheduler, by checking for any "Jnnn" session in SQLDeveloper's (or Toad's Monitor Sessions utility). The ACTION column will tell you what is being gathered at that point. The MODULE will, unfortunately, be "DBMS_SCHEDULER".

..  code-block:: sql

    select program, module, action
    from v$session
    where program like '%J___)';

The ACTION column will show you what is happening:

*   **T:ttttt** = Table ttttt is being analysed.
*   **P:ppppp** = Partition ppppp is being analysed. Unfortunately, there's no space to have the table name as well.
*   **S:sssss** = Sub-Partition sssss is being analysed. Unfortunately, there's no space to have the table name as well.


ETL3 OverRuns
-------------

Because the size of the objects being analysed varies from huge to very huge, there are occasions when a large object (these are analysed first) may take far too long and will probably overrun the ETL3 start time. This means that the job will need to be aborted, and this will leave all the other objects queued up behind the large one, unanalysed.

To alleviate this, a procedure exists named `emergencyAnalyse`` which will, if given the name of the long running job, list all the commands that are within that job. These can be executed by the DBA manually, in order that as many objects as possible get analysed before the long running job is aborted.

To execute this, proceed as follows:

..  code-block:: sql

    begin
        dbms_output.enable(9e6);
        dba_user.pkg_dailystats.emergencyAnalyse('DailyStats001');
    end;
    
The output will resemble the following:

..  code-block:: sql

    exec dba_user.pkg_dailystats.statsAnalyse(piOwner => 'HERMES_MI_STAGE', piTableName => 'S_PCL_PROG_MIS_HOLD_TMP', piObjectType => 'TABLE');
    exec dba_user.pkg_dailystats.statsAnalyse(piOwner => 'HERMES_MI_STAGE', piTableName => 'S_BVDR_TOTAL_DIRECT', piObjectType => 'TABLE');
    exec dba_user.pkg_dailystats.statsAnalyse(piOwner => 'HERMES_MI_STAGE', piTableName => 'S_C2C_ORDER_NO_PCL', piObjectType => 'TABLE');
    exec dba_user.pkg_dailystats.statsAnalyse(piOwner => 'HERMES_MI_STAGE', piTableName => 'S_PCLSHP_RET_EVT', piObjectType => 'TABLE');
    ...

The commands are listed in order of increasing object size, so the top ones should run quicker than the bottom ones, so running the commands in order (in batches perhaps?) will get a larger number of objects analysed while the large object is hogging all the resources in the actual scheduler job.

**NOTE**: The large object that is currently taking too much time is also listed, and the DBA should avoid starting another analysis of that object, or any that appear after it in the listing, as those are all already completed. (Except for the running  one of course!)

On Statistics Job Completion
----------------------------

After all the jobs have completed, let everyone know that the statistics job has completed, or been aborted - see below, as necessary. Send an email to *huk.dba* to inform them that the jobs have finished, and the time of the latest database to finish running its jobs. (This will usually always be PNET or MISA as MYHERMES only ever runs for about a minute or three!)


Some Useful Scripts
===================

The DBA may find the following scripts useful.


Checking End Time
-----------------

The time at which the final object completed it statistics gathering can be ascertained by running:

..  code-block:: sql

    select max(endtime) from dba_user.daily_stats_log;


Checking For Errors
-------------------

If you look at  the status of the scheduled jobs, they all show SUCCEEDED. This is true *even* if errors were detected. So:

..  code-block:: sql

    select t.*,(t.endtime - t.starttime) * 60*60*24 as seconds
    from dba_user.daily_stats_log t
    where error_message is not null
    and starttime > trunc(sysdate)
    order by table_name;

Will list any objects that had errors during the analysis.


Checking Results
----------------

The following query will list all of today's work, and the length of time taken to analyse that particular object.

..  code-block:: sql

    select t.*,(t.endtime - t.starttime) * 60*60*24 as seconds
    from dba_user.daily_stats_log t
    where starttime > trunc(sysdate)
    order by table_name;

    

Abort All Running Statistics Jobs
---------------------------------

Find the running jobs that are gathering stats, and create SQL statements to abort them:

..  code-block:: sql

    select 'exec dbms_scheduler.stop_job(''DBA_USER.' || job_name || ''', force => true);'
    from dba_scheduler_jobs
    where owner = 'DBA_USER'
    and state = 'RUNNING'
    and job_name like 'DAILYSTATS%'
    order by job_name;

Whatever SQL is generated will need to be executed to force stop *all* the running jobs.

This will leave the stats for the tables being analysed in an "unknown" state. It appears that the first thing Oracle does when analysing a table, is to delete the current stats. This is probably not an ideal situation to be in, so aborting stats gathering jobs should be considered an action of last resort.

  
After Aborting
--------------

Regardless of which abort method you use, you will need to update the logging table with details of the abort. Every object that gets analysed has a start time, end time and error message columns in the logging table. If the job is aborted, there is no error message and no end time.

Run the following script to add an error message:

..  code-block:: sql

    update dba_user.daily_stats_log
    set error_message = 'ABORTED' 
    where endtime is null;

    commit;

    
User Maintenance
================

Certain user accounts should not be considered for statistics gathering. These include, but are not limited to, the various accounts supplied by Oracle and the Hermes DBAs, BO users etc.

The ``pkg_dailystats`` package, has a number of procedures built in to allow these users to be included or excluded from the daily statistics gathering. These are described below.

In the following examples, the usernames supplied to the packaged procedures can be in upper, lower or mixed case. They will be converted to uppercase for processing.

ExcludeUsername
---------------

This procedure adds a username to the exclusions table so that it's tables etc *will not* be considered for statistics gathering by the new system. A user is added thus:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.excludeUsername('some user');
    
The procedure will report back whether or not the username has been added to the table. If the username already existed in the table, no errors will be raised.

Example
~~~~~~~

..  code-block:: sql

    set serverout on size unlimited

    -- FRED is not in the table yet.
    exec dba_user.pkg_dailystats.excludeUsername('FRED');

    FRED has been added to the exclusions table.
    
    
    -- FRED is already in the table.
    exec dba_user.pkg_dailystats.excludeUsername('fred');
    
    FRED already existed in the exclusions table.
    
    
IncludeUsername
---------------

This procedure removes a username from the exclusions table so that its tables etc *will* now be considered for statistics gathering by the new system. A user is removed as follows:

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.includeUsername('some user');
    
The procedure will report back whether or not the username has been removed from the table. If the username didn't already exist on the table, no errors will be raised.

Example
~~~~~~~

..  code-block:: sql

    set serverout on size unlimited

    -- FRED currently exists in the exclusions table.
    exec dba_user.pkg_dailystats.includeUsername('fred');

    FRED has been removed from the exclusions table.
  
    
    -- FRED is not in the exclusions table.
    exec dba_user.pkg_dailystats.includeUsername('FRED');
    
    FRED was not found in the exclusions table.
    

ReportExcludedUsers
-------------------

This procedure lists the contents of the exclusions table.

..  code-block:: sql

    set serverout on size unlimited
    exec dba_user.pkg_dailystats.reportExcludedUsers;
    
Example
~~~~~~~

..  code-block:: none

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
    
   
