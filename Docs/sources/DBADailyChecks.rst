================
DBA Daily Checks
================

Introduction
------------

The following is a *non-exclusive* list of the daily checks that must be carried out in Azure environments. This is required until such time as we get full access to OEM (Oracle Enterprise Manager) and can set up proper monitoring.

Please note that any scripts below can be found in the TFS area ``$TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation\Code\DBADailyChecks``. There is a top level script, ``00_DailyChecks.sql`` which will run all of the others. Output from each script will be found in a folder called ``logs`` - these logs must be checked daily.

Daily Check Scripts
-------------------

Various scripts to run the daily checks are to be found in TFS at location ``$TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\dba documentation\code\DBADailyChecks`` and these are:

00_DailyChecks.sql
    Control scripts which runs the others. Used for 11g databases.
    
00_DailyChecks_10g.sql
    Control scripts which runs the others. Used for 10g databases.

DataGuardChecks.sql
    Carries out checks to ensure that all configured destinations for standby databases, have no apply or transport lag.
    
DataGuardChecks_10g.sql
    Carries out checks to ensure that all configured destinations for standby databases, have no apply or transport lag. For 10g databases.

FRAChecks.sql
    Checks that the FRA is not filling up too much.
    
FRAChecks_10g.sql
    Checks that the FRA is not filling up too much. For 10g databases.
    
PasswordExpiryChecks.sql
    List all users with a profile which limits password life times and who are going to have to change their password in the next fortnight.
    
RestorePointChecks.sql
    List all restore points whihc are older than 7 days.
    
RestorePointChecks_10g.sql
    List all restore points whihc are older than 7 days. For 10g databases.
    
RMANBackupChecks.sql
    Lists all RMAN backups, and attempted backups, over the last 3 days.
    
RMANErrors.sql
    Lists errors in any reported failed backups in the output of the above script. This script is not called from the control scripts.

TablespaceFreeSpace.sql
    Lists all tablespaces and their percentages etc. Used to maintain any tablespace over 80% capacity. Capacity being  the absolute maximum size of autoextend tablespaces and/or data files.


Database Backups
----------------

**Backups are your top priority.**

The Backup Area
~~~~~~~~~~~~~~~

This *should* be being checked by the Windows gurus, however, it is always best to have an extra pair of eyes on the matter. In theory, the RMAN backups taken will be archived off to a separate, offline, storage area leaving plenty of space on the main backup discs. This has to be done as we are keeping 7 years of backups for legal reasons.

The properties of the backup disc should be checked, either on the production or pre-production servers, and the free space noted. The full size of the backup disc is 3 Tb and a full week's worth of backups requires *approximately* 100 Gb - depending on database usage.

If space does appear to be low, or getting that way, check with the Windows team in DevOps, to have older files archived off. If they are required for restoration, they can easily be restored as required.

Please note that the log files should be archived too. These contain important information that will be needed in the event of a restore.


Checking the Log Files
~~~~~~~~~~~~~~~~~~~~~~

The database backups logs must be checked on the servers as soon as possible each day, especially Mondays as there is a weekend's worth of backups to check.

The primary CFG database is backed up at 03:00 daily, with a level 0 (aka full) backup on Sundays. Other days perform a level 1 incremental backup.

Logs are found at ``\\Backman01\Rmanbackup\backups\logs\<database_name>`` and should be checked to ensure that:

- The database backup completed successfully;
- The archived logs backup completed successfully;
- The controlfile auto-backup completed successfully.


Using SQL*Plus
~~~~~~~~~~~~~~

On the database being backed up, which is normally the primary, but need not be - RMAN can backup the standby if necessary - run the script, ``RMANBackupChecks.sql``, to determine the state of the backups over the last few days - this covers the weekends:
   
Example output would resemble the following:

..  code-block:: none

    PARENT_ START_TIME          END_TIME            OBJECT_TYPE STATUS      OPERATION
    ------- ------------------- ------------------- ----------- ---------   ----------------
        104	2017/03/13 08:55:11		                DB INCR	    FAILED	    BACKUP
        102	2017/03/13 03:03:39	2017/03/13 03:03:46		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        99	2017/03/13 03:02:08	2017/03/13 03:03:48	ARCHIVELOG	COMPLETED	BACKUP
        100	2017/03/13 03:01:10	2017/03/13 03:01:16		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        99	2017/03/13 03:00:19	2017/03/13 03:01:19	DB INCR	    COMPLETED	BACKUP
        97	2017/03/11 03:03:30	2017/03/11 03:03:36		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        94	2017/03/11 03:01:32	2017/03/11 03:03:39	ARCHIVELOG	COMPLETED	BACKUP
        95	2017/03/11 03:00:41	2017/03/11 03:00:48		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        94	2017/03/11 03:00:07	2017/03/11 03:00:51	DB INCR	    COMPLETED	BACKUP
        92	2017/03/10 17:05:42	2017/03/10 17:05:49		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        89	2017/03/10 17:03:11	2017/03/10 17:05:51	ARCHIVELOG	COMPLETED	BACKUP
        90	2017/03/10 17:02:22	2017/03/10 17:02:28		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        89	2017/03/10 17:01:09	2017/03/10 17:02:31	DB INCR	    COMPLETED	BACKUP
        87	2017/03/10 03:04:15	2017/03/10 03:04:21		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        84	2017/03/10 03:01:50	2017/03/10 03:04:24	ARCHIVELOG	COMPLETED	BACKUP
        85	2017/03/10 03:01:07	2017/03/10 03:01:13		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        84	2017/03/10 03:00:11	2017/03/10 03:01:16	DB INCR	    COMPLETED	BACKUP

In the event of a problem, for example, the first line of output above, use the ``PARENT_RECID`` to query ``V$RMAN_OUTPUT``, as per the script, ``RMANErrors.sql``:

The output will show what would have been found in the RMAN log for that particular failed backup. If no errors are listed, then you can be certain that either:

- A DBA abandoned the backup; or
- The server crashed during the backup.

as any other errors from RMAN will be shown.


Data Guard Time Lag
-------------------

Using SQL*Plus
~~~~~~~~~~~~~~

Run the script, ``DataGuardChecks.sql``, or ``DataGuardChecks_10g`` on the *primary database*\ :

The results will resemble the following:

..  code-block:: none

    DEST_ID DEST_NAME          DESTINATION ARCHIVED_SEQ# APPLIED_SEQ# ERROR DB_UNIQUE_NAME GAP_STATUS
    ------- ------------------ ----------- ------------- ------------ ----- -------------- ----------
          2 LOG_ARCHIVE_DEST_2 cfgsb               15975         15974      cfgsb          NO GAP
          3 LOG_ARCHIVE_DEST_2 CFGDR               15975         15974      CFGDR          NO GAP

"NO GAP" is what you are hoping to see in the ``GAP_STATUS`` column. Other values that may appears here are:

+---------------------------+-------------------------------------------------------------------------------------------------------------+
| Status                    | Description                                                                                                 |
+===========================+=============================================================================================================+
| NO GAP                    | The desired result. There is not an apply gap.                                                              |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| LOG SWITCH GAP            | The destination has not yet received all of the redo information from the most recently archived log file.  |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| RESOLVABLE GAP            | The destination has a redo gap but it can be resolved by fetching, automatically, the missing archived log  |
|                           | files from  *this* database. No action is required, unless ``FAL_SERVER`` for this database does not point  |
|                           | at the *this* database.                                                                                     |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| UNRESOLVABLE GAP          | The destination has a redo gap which can not be resolved by fetching, automatically, the missing archived   |
|                           | log files from *this* database, and there are no other destinations (standbys) where the missing            |
|                           | information can be obtained. Action is required in this case as the standby database is not up to date, and |
|                           | cannot be brought up to date. (Someone deleted an archive log or two perhaps?)                              |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| LOCALLY UNRESOLVABLE GAP  | The destination has a redo gap which can not be resolved by fetching, automatically, the missing archived   |
|                           | log files from *this* database, however, other destinations (standbys) *may* be able to assist in resolving |
|                           | the missing data. Action is required in this case, but only to monitor that the standby doesn't get further |
|                           | and further out of date.                                                                                    |
+---------------------------+-------------------------------------------------------------------------------------------------------------+

In the above, where you see "*this* database", *this* refers to the database that the query was executed on - in our case, the *primary* database.


Using DGMGRL
~~~~~~~~~~~~

Run the following in ``dgmgrl`` on any of the servers, primary, standby or DR. You need to be logged in as the SYS user. The first command, ``show configuration``\ , simply displays the names of the various databases configured:

..  code-block:: none

    show configuration

    Configuration - dgmgrl_configuration

      Protection Mode: MaxPerformance
      Databases:
        cfg   - Primary database
        cfgsb - Physical standby database
        cfgdr - Physical standby database

    Fast-Start Failover: DISABLED

    Configuration Status:
    SUCCESS
    
The database names shown above are in lower case. This means that we can use them as-is. If they were in upper case, we would need to wrap them in double quotes, and in upper case too. ``Show database "CFGSB"`` for example.

The next commands display the two, in this case, standby databases:

..  code-block:: none

    DGMGRL> show database cfgsb

    Database - cfgsb

      Role:            PHYSICAL STANDBY
      Intended State:  APPLY-ON
      Transport Lag:   0 seconds (computed 0 seconds ago)
      Apply Lag:       0 seconds (computed 0 seconds ago)
      Apply Rate:      230.00 KByte/s
      Real Time Query: OFF
      Instance(s):
        cfgsb

    Database Status:
    SUCCESS

and:

..  code-block:: none

    DGMGRL> show database cfgdr

    Database - cfgdr

      Role:            PHYSICAL STANDBY
      Intended State:  APPLY-ON
      Transport Lag:   0 seconds (computed 0 seconds ago)
      Apply Lag:       1 second (computed 0 seconds ago)
      Apply Rate:      211.00 KByte/s
      Real Time Query: OFF
      Instance(s):
        cfgdr

    Database Status:
    SUCCESS

In either case we are looking to see that there isn't a (large) transport or apply lag and that the "computed" time is not excessive.

Various checks that can be applied when the status is not as desired are:

- Has the standby database just been started up after a while? If so, there will be potentially a large amount of un-applied redo to be obtained from the primary. Monitor the status and ensure that the lags do not simply keep increasing.
- Has the standby lost its managed apply? Check the alert log for details, stop and restart managed apply as per the document on building standby databases using RMAN.
- Has the network failed between the primary and standby? Try using ``tnsping standby`` to determine if this is the case. Once the network problems are alleviated, the standby should automatically start catching up.
- Has the primary database been run in NOACHIVELOG for a while? If so, the standby databases must be recreated.


Tablespace Usage
----------------

Any tablespace which has used 80% or more of its allocated *maximum size* - for ``AUTOEXTEND`` tablespaces and data files - should be considered for investigation and extension. This will need to be done under a service or change request when it involves CFG production (and pre-production?).


Using SQL*Plus
~~~~~~~~~~~~~~

The script ``TablespaceFreeSpace.sql``  will determine the correct usage figures for all tablespaces, including temporary ones.
              
The output is sorted in descending order of the tablespaces with the most used space, as a percentage of their maximum. (The final column in the listing.) The topmost tablespaces should be investigated if the figures are 80% or higher. 

You should note, that where there is a data file in in ``AUTOEXEND`` mode, that the maximum size of *unlimited* actually correlates to 30Gb.


FRA Usage
---------

The FRA should be self-cleaning, but only for Oracle managed files and only when the files in question have passed their retention criteria. If the FRA fills up during daily running of the database, then the database will hang until the FRA is cleared out of unnecessary files.

You can clean out the FRA in a number of ways:

- Use RMAN to backup the archived logs. They will normally be deleted after two backups and when they have been applied to all standby databases. But only when Oracle needs space in the FRA.
- If you have no restore points, but there appear to be flashback logs in the FRA, you can turn off flashback for the database and Oracle should delete the flashback logs for you. You can manually delete the flashback logs *carefully* but only after you have no restore points and have turned off flashback mode on the database. However, this is *not recommended* by Oracle.
- On the primary database, ``alter system set db_recovery_file_dest_size=NNNN scope=memory;`` can be used to *gradually* reduce the size of the FRA quota. If you then run ``alter system archive log current;`` or another command that will cause space to be used in the FRA, You should see the FRA being cleared out by watching the tail end of the alert log. You must be gradual about this as if you go too low, the database will hang. When done, reset the FRA quota back to what it was originally.

The script ``FRAChecks.sql``, or ``FRAChecks_10g.sql``, will show the usage of the FRA and how much space can be reclaimed from its various component parts.


Password Expiry
---------------

Where password changes are forced, using profiles, it is advisable to know which users accounts will expire within the next fortnight. The script ``PasswordExpiryChecks.sql`` will list those affected users. 

    **Note**: only users who have a profile that limits password life times will be selected.

    
Restore Points
--------------

Restore points are useful when performing upgrades and releases etc, but leaving them lying around causes the FRA to fill up as flashback logs and archived redo logs remain, online, ready to be used to flashback the database. The script ``RestorePointChecks.sql``, or ``RestorePointChecks_10g.sql``, will identify any restore points that have been in place for 7 or more days.

When a restore point is identified, it should be deleted *after* checking with the team/person/manager/business user who requested it be created. 


Scheduler Jobs
--------------

In the production database only, the following jobs should be checked for problems. It is probably best to login using Toad, then go to the schema browser.

In the schema browser, select scheduled jobs first, then the appropriate username (see below). You can then simply click on the "run log" tab on the far right, to see details of the most recent runs.

In non-production databases, the jobs etc may exist, but are disabled if so.


SYS Jobs
~~~~~~~~

AUDIT_ARCHIVING
"""""""""""""""

This job runs daily at 20:20 and copies today's audit details up to the ``CFGAUDIT`` database over a database link pointing at the ``CFGAUDSRV`` service. If the job fails, and is subsequently fixed, any unarchived data will be copied across on the next run.

EXPIRE_PASSWORDS
""""""""""""""""

This job runs daily at 20:20 and expires and locks various account passwords under conditions copied directly from the 9i Solaris production database of old.

STATSGEN
""""""""

This job runs weekly, on a Sunday at 18:00 to gather updated statistics on all application tables and indexes so that the Cost Based Optimiser is better able to create an efficient execution plan for SQL statements accessing the appropriate tables.

UTMSODRM
""""""""

This job runs daily at 20:20 and clears ouot one or more application tables for reuse next day.


FCS Jobs
~~~~~~~~

In the event of problems with FCS jobs, I would suggest a quick look to determine if the problem was caused by the database or server, and if not, pass the problem to a developer as it is unlikely to be something we can fix ourselves without detailed knowledge of the application.

ALERTS_HEARTBEAT
""""""""""""""""

This job runs every minute. Luckily you don't have to check every minute - OEM will do that for us, eventually! There's not much can go wrong here, but it will need fixing according to the error(s) if it does have problems.

CLEARLOGS
"""""""""

This job runs daily at 20:00.

JISA_18DAY_CONVERSION
"""""""""""""""""""""

This job runs daily at 23:00.


PERFSTAT Jobs
-------------

Any problems with ``PERFSTAT`` jobs should be resolved as quickly as possible to prevent potential UNDO tablespace problems on restarting them. This applies mainly to the ``PURGE_DAILY`` job.

SNAPSHOT_EVERY_15MINS
"""""""""""""""""""""

This job runs every 15 minutes, and takes a statspack snapshot of the system for later analysis in the event of performance problems.

PURGE_DAILY
"""""""""""

This job runs daily, at 05:00, to clear out old statspack snapshots. 'Old', by default, means anything that is older than 10 days of age. If the job fails, the next run will clear out the missed snapshot data, but **beware** that leaving this job in a failed state for too long could result in UNDO tablespace errors if there is a large amount of data to clear down when the job is restarted.