====================================
Dimension - PGA Session Killer Patch
====================================

Introduction
============

Due to large numbers of 'stuck' sessions in Dimension in the 'SCPROD' database. These sessions hold on to allocated PGA memory, and when the PGA memory allocated exceeds a set value, then other *active* sessions are being killed by Oracle.

This patch installs a procedure named 'PGASessionKiller' to the SYS schema, where it can be executed by those with the appropriate permissions, or, scheduled to run automatically at specified intervals.

Patch Contents
==============

The following files are supplied in the patch kit:

-   **PGASessionKiller.sql** which is a script to create the procedure. This must be run as the SYS user, or by another SYSDBA enabled account, as it is necessary that it be created in the SYS schema.

-   **PGAKillerSchedule.sql** which is a script to create a scheduled job that runs every half hour, by default, to execute the above procedure to clear out stuck sessions. It uses all the default values for the parameters, so if necessary, these may be changed prior to running the script to schedule a job. The job name set up with this script will be **SYS.PGASESSIONKILLER**.

-   **PGAKillerRollback.sql** which is a script to remove all traces of the patch.


Installation
============

To install the patch, login to the database as a SYSDBA enabled user account, normally SYS, and execute the following scripts, in order:

-   **PGASessionKiller.sql**
-   **PGAKillerSchedule.sql**

Check the log files for errors, these will be:

-   **PGASessionKiller.log**
-   **PGAKillerSchedule.log**


The scheduled job set up by the latter script will start immediately, and will be enabled. It will run every 30 minutes.

Removal
=======

To remove the patch, login to the database as a SYSDBA enabled user account, normally SYS, and execute the following script:

-   **PGAKillerRollback.sql**

Check the log files for errors, these will be:

-   **PGAKillerRollback.log**

Any errors about the scheduled job not existing can be safely ignored.

Parameters
==========

Calling the procedure defaults to sensible values, and these are:

-   **piModule** is the name of the module being executed by the stuck sessions. This defaults to 'Report Execution', as this is the most prolific module name affected. This parameter is optional (in that the default will be used if omitted) and must be in the *exact letter case* to match the module in v$session. NULL is not permitted.

-   **piProgram** is the name of the program being executed by the stuck sessions. This defaults to 'dya141mr.exe', as this is the most prolific module name affected. This parameter is optional (in that the default will be used if omitted) and must be in the *exact letter case* to match the module in v$session. NULL is not permitted.

-   **piSeconds** is the number of seconds that the jobs to be killed must have been waiting already. The default is 1800 (30 minutes) and this will be applied if the parameter is not specified. NULL is not permitted. The valid range is from 500 upwards.

-   **piDoKill** is a flag that indicates whether you wish to list the sessions that will be killed, or to actually kill them. The default is FALSE which will list the session to the trace file and not kill them. You must set this to TRUE to actually kill the sessions.

It should be further noted that only those sessions with the following settings, will be listed and/or killed:

-   V$SESSION.MODULE = piModule
-   V$SESSION.PROGRAM = piProgram
-   V$SESSION.SECONDS_IN_WAIT > piSeconds
-   V$SESSION.STATE = 'WAITING'
-   V$SESSION.EVENT = 'SQL*Net message from client'

For every session that meets the above criteria, the procedure executes the command:

..  code-block:: sql

    alter system kill session 'SID,SERIAL#' immediate'

Where SID and SERIAL# are the values taken from V$SESSION.    

Scheduling a Task
=================

The default settings for the scheduled task, if implemented by running script **PGAKillerSchedule.sql** is to check every 30 minutes.

Checking Results
================

If the alert log for the database is checked, it will show the following for each session killed:

..  code-block:: none

    Immediate Kill Session#: 174, Serial#: 43354
    Immediate Kill Session: sess: 00000003489885C0  OS pid: 7104

In the trace file for the session that executed the procedure, the following will be found for killed sessions:

..  code-block:: none

    Killing stuck session: 1270 which is running dya141mr.exe, module Report Execution, and has been stuck for 11858 seconds.
    ----------------------------------------
    SO: 0x0000000349EA9190, type: 2, owner: 0x0000000000000000, flag: INIT/-/-/0x00 if: 0x3 c: 0x3
    proc=0x0000000349EA9190, name=process, file=ksu.h LINE:13979, pg=0 conuid=0
    (process) Oracle pid:229, ser:43, calls cur/top: 0x0000000000000000/0x00000002DA0FDA70
          flags : (0x0) -  icon_uid:0
          flags2: (0x0),  flags3: (0x10) 
          intr error: 0, call error: 0, sess error: 0, txn error 0
          intr queue: empty
          
    ...
    
    PSO child state object changes :
    Dump of memory from 0x0000000349D6E7B8 to 0x0000000349D6E9C0
    349D6E7B0                   00000000 00000000          [........]
    349D6E7C0 00000000 00000000 00000000 00000000  [................]
      Repeat 31 times

This is a process state dump of the killed session.

If the procedure is only listing the sessions, the following will be seen in the trace file, only, nothing is written to the alert log:

..  code-block:: none

    Listing stuck session: 174 which is running dya141mr.exe, module Report Execution, and has been stuck for 3957 seconds.
    Listing stuck session: 268 which is running dya141mr.exe, module Report Execution, and has been stuck for 11347 seconds.
    Listing stuck session: 341 which is running dya141mr.exe, module Report Execution, and has been stuck for 10457 seconds.
    Listing stuck session: 342 which is running dya141mr.exe, module Report Execution, and has been stuck for 10501 seconds.

The trace file name can be extracted from the database by running the following query, **in the same session, Toad Tab, SQLDeveloper Tab etc, as the command to execute the procedure**.

..  code-block:: sql

    select p.tracefile
    from v$session s, v$process p
    where p.addr = s.paddr
    and s.sid = SYS_CONTEXT('USERENV', 'SID');
      
Caveats
=======

By default, the code will only kill sessions that are running the module and program specified and these are 'Report Execution' and 'dya141mr.exe'. These have been seen to be the most numerous of the stuck sessions. Testing has covered these sessions *only*.

Other stuck sessions belong to module and program 'dya141mr.exe', however, these are far less frequent, and are *not yet tested*.


----

| Author: Norman Dunbar
| Email: Norman@dunbar-it.co.uk
| Date : 6th July 2017.
