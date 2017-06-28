===========================
SOP - Data Guard Switchover
===========================

Abstract
========

The following outlines the steps followed in order to carry out a
database switchover from the current primary to the current standby.
While DGMGRL will carry out a switchover quite simply and easily, it is
always best to check that the procedure should succeed and not fail due
to some oversight.

For the purposes of this document, the primary database is CFG and
the standby database is CFGSB.


References
==========

The following MOS (My Oracle Support) notes are valuable sources of
information regarding this process:

-  1305019.1 - 11.2 Data Guard Physical Standby Switchover Best
   Practices using the Broker

-  1304939.1 - 11.2 Data Guard Physical Standby Switchover Best
   Practices using SQL\*Plus

Similar documents exists for Oracle 12c, should they be required.

-  1305019.1 - 11.2 Data Guard Physical Standby Switchover Best
   Practices using the Broker

-  1304939.1 - 11.2 Data Guard Physical Standby Switchover Best
   Practices using SQL\*Plus

   
Quick Version
=============

The following instructions are extracted from Oracle docs, as listed,
and are considered best practice.


Verify Configuration
--------------------

All of the following commands should return SUCCESS. If any do not, or
if any Oracle errors are displayed, you cannot continue until such time
as the problems have been resolved.

..  code-block:: batch

    oraenv cfg
    dgmgrl sys/password

    show configuration verbose;

    
Perform Switchover
------------------

..  code-block:: none

    switchover to <standby database name>;


Post Switchover Tasks
---------------------

First, amend the RMAN settings for ARCHIVELOG DELETION POLICY and crosscheck the archived logs,  as described in section *Check RMAN Archivelog Deletion Policy* below, then skip to section *Post Switchover Checks* and ensure all checks are carried out.


Explicit Version
================

The following instructions are extracted from Oracle docs, as listed,
and are considered best practice.


Verify Configuration
--------------------

On the current primary database server, run the following commands. All
of these should return SUCCESS. If any do not, or if any Oracle errors
are displayed, you cannot continue until such time as the problems have
been resolved.

..  code-block:: none

    oraenv cfg
    dgmgrl sys/password

    show configuration verbose;
    show database cfg;
    show instance cfg;
    show database cfgsb;
    show instance cfgsb;

You are expecting to see something similar to the following at the end
of each of the above commands:

..  code-block:: none

    Configuration Status:
    SUCCESS

    
Test Connections & Flashback
----------------------------

The broker uses the StaticConnectIdentifier to reach the other
database(s) in the configuration. You should check that they all work,
from both servers.

..  code-block:: none

    show database cfg StaticConnectIdentifier

    StaticConnectIdentifier =
    '(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=ORCDEVORC
    01)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=CFG_DGMGRL)(INSTANCE_NAME=CFG
    )(SERVER=DEDICATED)))'

You should now check that the connection string, everything within - but
excluding - the single quotes, can be contacted from SQL\*Plus on both
servers:

..  code-block:: batch

    sqlplus sys/password@"XXX" as sysdba

    select flashback_on, instance_name, host_name
    from v$instance, v$database;

'XXX' is the full static connect identifier from the above query,
wrapped in double quotes as opposed to single ones.

Ensure that the host\_name and instance\_name returned are correct for
each test.

Ensure that the primary database has flashback on. If the primary shows
up as having it turned off, enable it as follows:

..  code-block:: sql

    alter database flashback on;

Ensure that the standby database has flashback on. If the standby shows
up as having it turned off, enable it *after the switchover*:


Check RMAN Archivelog Deletion Policy
-------------------------------------

Both databases have the same DBID, so if RMAN is in use for daily
backups, then the archivelog deletion policy should be set to "APPLIED
ON ALL STANDBY BACKED UP 2 TIMES TO DISK" on the primary database:

..  code-block:: none

    rman target sys/password@CFG
    
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

and for the standby, it should be set to "APPLIED ON ALL STANDBY":

..  code-block:: none

    rman target sys/password@CFGSB
    
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;

Finally, because we have been backing up *another* database as the primary, we need to be sure that RMAN is aware that some archived logs are not going to be found on the new primary database server, so, on the primary database:

..  code-block:: none

    crosscheck archivelog all;
    exit;
    
The above may run for some time, do not abandon it. If an archived log cannot be found on *this* server, because it's on another one, then the archived logs backup will fail. We do not want that to happen.    
    
Verify Tempfiles match
----------------------

If any new Tempfiles have been added to the primary since the creation
of the standby, or the most recent switchover, then they will not be
present on the current standby. Run the following query on both
databases.

First on the primary:

..  code-block:: sql

    select tmp.name filename, bytes, ts.name tablespace
    from v$tempfile tmp, v$tablespace ts
    where tmp.ts# = ts.ts#;

    FILENAME                           BYTES TABLESPACE
    ----------------------------- ---------- ----------
    G:\MNT\ORADATA\CFG\TEMP01.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFG\TEMP02.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFG\TEMP03.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFG\TEMP04.DBF 1369440256 TEMP

Then on the standby:

..  code-block:: sql

    select tmp.name filename, bytes, ts.name tablespace
    from v$tempfile tmp, v$tablespace ts
    where tmp.ts# = ts.ts#;

    FILENAME                             BYTES TABLESPACE
    ------------------------------- ---------- ----------
    G:\MNT\ORADATA\CFGSB\TEMP01.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFGSB\TEMP02.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFGSB\TEMP03.DBF 1368391680 TEMP
    G:\MNT\ORADATA\CFGSB\TEMP04.DBF 1369440256 TEMP

There should be the same number of files, and they should match in size,
on both databases. If any are missing or incorrectly sized, you can
resolve this now or after opening the new primary.


Verify Datafiles
----------------

Prior to switching over, check that all data files on the current
standby database, are online:

..  code-block:: sql

    select file# from v$datafile where status='OFFLINE';

If any are offline,

..  code-block:: sql

    alter database datafile <file#> online;

    
Check For Running Jobs
----------------------

There should be no jobs running on the primary database as these can
interfere with the switchover. To check, run the following commands on
the primary database:

..  code-block:: sql

    select owner, job_name, session_id, running_instance, elapsed_time
    from dba_scheduler_running_jobs;

    no rows selected

    select job, sid, instance, this_date
    from dba_jobs_running;

    no rows selected

The expected result for both is "no rows selected". Any running jobs
should be allowed to finish, or be aborted as necessary before switching
over.


Check for Running Transactions with RollBack
--------------------------------------------

Any transaction with any existing UNDO will be rolled back as part of
the switchover. Large transactions may take a long time to rollback.
Check for these as follows:

..  code-block:: sql

    set lines 3000 trimspool on pages 200
    col username format a15
    col machine format a20
    col tablespace_name format a15

    SELECT s.username, r.tablespace_name, t.used_ublk, t.start_time
    "START_TIME mm/dd/yyyy"
    FROM sys.v_$transaction t, dba_rollback_segs r, v$session s
    WHERE (t.xidusn = r.segment_id)
    and S.TADDR = t.addr
    ORDER BY t.start_time;

The output will resemble the following (slightly contrived) example:

..  code-block:: none

    USERNAME        TABLESPACE_NAME USED_UBLK  START_TIME mm/dd/yy
    --------------- --------------- ---------- -------------------
    FRED            UNDOTBS1                50 06/23/16 08:30:20
    BARNEY          UNDOTBS1                 1 06/23/16 11:50:18

    
Perform Switchover
------------------

The databases are now ready to switchover. Depending on the number of
uncommitted transactions, and the size of these, there may well be quite
a delay in the switchover process.


Check Switchover Status
-----------------------

On both databases, make sure that the database will permit a switchover:

..  code-block:: sql

    select switchover_status from v$database;

-  NOT ALLOWED - There are no standby databases, or, this is the standby
   and the primary has not been switched yet.

-  SESSION ACTIVE - There are active SQL sessions connected to the
   database. These need to be disconnected first, although they will be
   disconnected by the switchover.

-  SWITCHOVER PENDING - This is the standby database. The request to
   switchover has been received and is in progress, but not yet
   completed.

-  SWITCHOVER LATENT - The switchover *was* pending, but did not
   complete.

-  TO PRIMARY - This is a standby database, with no active sessions,
   that is allowed to switch over to a primary database.

-  TO STANDBY - This is a primary database, with no active sessions,
   that is allowed to switch over to a standby database.

-  RECOVERY NEEDED - This is a standby database that has not received
   the switchover request.

   
Switch Over
-----------

In dgmgrl, on either server, run the following command:

..  code-block:: none

    connect sys/password
    switchover to <standby database name>;

You *must* connect with the SYS username and password to actually carry
out a switchover.

After the switchover completes, *and it may take some time*, check the
configuration to ensure that the two databases have swapped roles.

If the standby doesn't come up correctly for any particular reason,
simply login as SYSDBA and startup mount it in the normal manner. It
will then come up and start processing redo in the normal manner.

Check the drc<database\_name>.log & the database alert.log file for the
failure details.


Post Switchover Checks
======================

After a successful switchover, some additional checks are required to be
carried out.


Verify Configuration
--------------------

In dgmgrl run the same commands as you did in the pre-switchover checks.

..  code-block:: none

    show configuration verbose
    show database <primary database>
    show database <standby database>
    show instance <primary instance>
    show instance <standby instance>

They should all show a 'SUCCESS' result, similar to the following:

..  code-block:: none

    ...
    Configuration Status:
    SUCCESS

    
Check Apply Gaps
----------------

Dgmgrl's show database <standby database name> command will quickly
indicate if there's a gap or not. You should see 'NO GAP' reported.

Alternatively, run the following on the new primary database in
SQL\*Plus:

..  code-block:: sql

    set pages 300 lines 300 trimspool on
    col destination format a30
    col error format a30
    col db_unique_name format a10

    select destination, archived_seq#, applied_seq#, error,
    db_unique_name, gap_status
    from v$archive_dest_status
    where status <> 'INACTIVE'
    and dest_name = 'LOG_ARCHIVE_DEST_2';

    
Confirm Flashback
-----------------

Both databases should be running with flashback on. As per the
preliminary checks above, the now current standby should be in this mode
as the old primary was checked and enabled before the switch over.
However, the old standby may not have been set and so the new primary
now needs to be confirmed:

..  code-block:: sql

    select flashback_on from v$database;

If this returns "NO", then enable it as follows:

..  code-block:: sql

    alter database flashback on;

    
Amend any Backup Scripts
------------------------

If any scripts are configured to run backups against the old primary,
these will now require amending to run against the new primary database
instead.


Important – RMAN Backup Tasks
=============================

When patching is in progress, or has completed, the database server,
whichever one it happens to be, running as the primary server, must have
the Windows Task Scheduler's RMAN Backup Tasks enabled. These will run
at pre-determined times of the day to carry out RMAN backups of the
various databases.

The servers running as standby or DR during and after patching, must
have their task scheduler backup tasks disabled. We only run the backups
on the primary servers in production and pre-production.
