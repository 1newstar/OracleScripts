======================================
Using RMAN to Create Standby Databases
======================================


Abstract
========

The following outlines the steps followed in order to clone, using RMAN
active duplicate, the CFG database, to create a standby database for
use in a Data Guard environment on the Azure servers.

In this example, CFG will be cloned to a new database, CFGSB, but
the clone will have the same ``DB_NAME`` initialisation parameter and DBID
as the CFG database. This is standard for standby databases.

**Note:** To identify which database your session may be connected to,
do not use ``NAME`` from ``V$DATABASE``, use ``DB_UNIQUE_NAME`` instead. The
following shows that we are connected to the standby database, CFGSB
and that it has the same db_name as the primary, CFG:

..  code-block:: sql

    select name, db_unique_name from v$database;

    NAME     DB_UNIQUE_NAME
    -------- -----------------
    CFG      CFGSB


Terminology
===========

-  Primary database. The primary database - the one being cloned from.
   In RMAN, will be referred to as the ACTIVE DATABASE or the TARGET.

-  Primary server. Where the primary database runs.

-  Standby database. The standby database. The one being created by the
   clone process. In RMAN this is referred to as the CLONE or the
   AUXILIARY DATABASE.

-  Standby server. Where the standby database runs.


Prepare the Primary Database
============================


Amend the Primary Database Service
----------------------------------

The primary *could* be run as a standby at some point in time. If the service
starts automatically, then the database will ``OPEN``, regardless of its role, so
the services must be configured not to start automatically. For the
most efficient shutdowns, immediate is advised.

..  code-block:: batch

    oradim –edit –sid CFG -startmode manual –shutmode
    immediate

    
Amend the Primary Database Listener
-----------------------------------

The database will not register with the listener when it runs as a
standby. To ensure that the listener knows about the primary, when
running as a standby, we need a static identifier in the ``listener.ora``:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFG)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )


The listener should be stopped and restarted:

..  code-block:: batch

    lsnrctl stop
    lsnrctl start

    
Start the Primary database
--------------------------

Start, or ensure that the primary database was started, using an spfile.
This can be checked by:

..  code-block:: sql

    sqlplus sys/password as sysdba

    show parameter spfile

There *must* be a valid spfile name returned. If not, the database must
be restarted using an spfile. You may have to create one from the
current pfile, then restart. If necessary:

..  code-block:: sql

    create spfile='?\database\spfileCFG.ora' from
    pfile='?\database\initCFG.ora';

    shutdown
    startup

In the above, the '?' is valid and is shorthand for ``%ORACLE_HOME%``.


Enable Force Logging
--------------------

Ensure that the primary database is running with force logging enabled.
It must be ``MOUNT``\ ed or ``OPEN`` to allow this. There may be a delay while
this takes effect as all currently unlogged changes will be required to
complete.

..  code-block:: sql

    select force_logging from v$database;

Should return 'YES' if force logging is in force, if not, then run the
following:

..  code-block:: sql

    alter database force logging;
    select force_logging from v$database;

    
Update Tnsnames.ora
-------------------

Make sure that the ``tnsnames.ora`` has an entry for the new standby
database. This can be checked by running:

..  code-block:: batch

    tnsping standby_database

There should be an ok status returned at the end of the output. If not,
add the standby database to the primary server's ``tnsnames.ora`` file. If
it hangs, make sure that there is actually a listener configured and
running on the standby server.


Add Standby Redo Logs to Primary Database
-----------------------------------------

Add standby redo logs to the primary database. These will be used to
allow the current primary database to be run as a standby database
should the need ever occur to carry out a switchover.

There are required to be one standby log file group, with members, for
each existing log file group on the primary. There is also a requirement
for one extra standby log file group for each row in the ``V$THREAD`` view.

..  code-block:: sql

    select count(*) from v$thread;

Are there any existing standby logs?

..  code-block:: sql

    select distinct type from v$logfile;

If the response is 'ONLINE' only, then proceed, otherwise, drop any existing
standby logs:

..  code-block:: sql

    select distinct 'alter database drop logfile group ' ||
    to_char(group#)
    from v$logfile
    where type = 'STANDBY'
    order by 1;

The output from the above can be copied and pasted to remove the
unwanted standby logs.

The (new) standby log file groups can be created with the output from
the following command:

..  code-block:: sql

    set serveroutput on size unlimited

    declare
        -- Gap between top ONLINE and bottom STANDBY group#.
        -- CHANGE THIS to suit your requirements.
        vDesiredOffset constant number := 10;

        -- Current highest and lowest ONLINE group.
        vMaxOnlineGroup v$logfile.group#%type;
        vMinOnlineGroup v$logfile.group#%type;

        -- Current number of threads;**
        vThreadCount number;

        -- New desired GROUP# for the STANDBY logs
        vNewGroup v$logfile.group#%type;

        -- How big is a log file?
        vMaxBytes v$log.bytes%type;

        -- PATH to the 'a' redo log.
        vRedoAPath v$logfile.member%type;

        -- PATH to the 'b' redo log.
        vRedoBPath v$logfile.member%type;

        -- Allows me to grab the members of the highest
        -- ONLINE group of redo logs, to extract the paths.
        type tLogFileMembers is table of v$logfile.member%type
        index by binary_integer;

        vLogFileMembers tLogFileMembers;

    begin

        -- Get current maximum online group#.
        select min(group#), max(group#)
        into   vMinOnlineGroup, vMaxOnlineGroup
        from   v$logfile
        where  type = 'ONLINE';

        -- Get maximum size of a current logfile.
        select max(bytes)
        into   vMaxBytes
        from   v$log;

        -- Get the A and B paths. There could be more than 2 members.
        select member
        bulk   collect
        into   vLogFileMembers
        from   v$logfile
        where  group# = vMaxOnlineGroup;

        -- This assumes at least two members in each ONLINE group.
        -- Any less might/will be a problem.
        vRedoAPath := substr(vLogFileMembers(1), 1, instr(vLogFileMembers(1),
        '\', -1));

        vRedoBPath := substr(vLogFileMembers(2), 1, instr(vLogFileMembers(2),
        '\', -1));

        -- Get the thread count.
        select count(*)
        into   vThreadCount
        from   v$thread;

        -- Build the desired standby groups.
        for onlineLog in (select distinct group# as gn
                          from   v$logfile
                          where  type = 'ONLINE'
                          order  by 1)
        loop
            -- If current max is 13, we want the minimum standby group to
            -- be 23 + desired offset + 1. The minimum new group will be
            -- that number.

            vNewGroup := onlineLog.gn + vMaxOnlineGroup - vMinOnlineGroup +
            vDesiredOffset + 1;

            dbms_output.put('alter database add standby logfile group ');
            dbms_output.put_line(to_char(vNewGroup) || ' (');
            dbms_output.put_line('''' || vRedoAPath || 'stby' ||
            to_char(vNewGroup) || 'a.log'',');
            dbms_output.put_line('''' || vRedoBPath || 'stby' ||
            to_char(vNewGroup) || 'b.log''');
            dbms_output.put_line(') size ' || to_char(vMaxBytes) || ';');
            dbms_output.put_line(' ');
        end loop;

        -- We also need an extra standby for each entry in V$THREAD.
        dbms_output.put_line('-- We also need one extra standby for each entry
        in V$THREAD.');

        for extraLog in 1..vThreadCount
        loop
            vNewGroup := vNewGroup + 1;
            dbms_output.put('alter database add standby logfile group ');
            dbms_output.put_line (to_char(vNewGroup) || ' (');
            dbms_output.put_line ('''' || vRedoAPath || 'stby' ||
            to_char(vNewGroup) || 'a.log'',');
            dbms_output.put_line ('''' || vRedoBPath || 'stby' ||
            to_char(vNewGroup) || 'b.log'') ');
            dbms_output.put_line('size ' || to_char(vMaxBytes) || ';');
        end loop;
    end;
    /

The output will resemble the following (abridged) and should be copied
and executed to create the desired standby logfiles.

..  code-block:: sql

    alter database add standby logfile group 24 (
    'g:\mnt\oradata\cfg\stby24a.log',
    'g:\mnt\fast_recovery_area\cfg\stby24b.log'
    ) size 104857600;

    ...

    -- We also need one extra standby for each entry in V$THREAD.
    alter database add standby logfile group 34 (
    'g:\mnt\oradata\cfg\stby34a.log',
    'g:\mnt\fast_recovery_area\cfg\stby34b.log'
    ) size 104857600;

The group numbers leave a gap of 10 entries between the current maximum
online group number and the new lowest standby group number. This will
allow new online groups to be added if required with continuing sequence
numbers.

**Make sure that there are no existing STANDBY logfiles. If there are,
you may need to adjust ``vDesiredOffset`` in the code above to skip over
those. Alternatively, drop them.**

The size of the files in each standby log file group must be large
enough to receive any log file on the primary database, so they must be
sized according to the current maximum log file size.

The script also generates an additional redo log group addition, which
is what is normally required. However, if there are more than one row in
``V$THREAD``, then there needs to be one additional log group for each
thread in ``V$THREAD``


Prepare Primary Database to Send/Receive Redo Files
---------------------------------------------------

Although we are configuring CFG as the primary database, it can and
may be used as a standby database, so it has to be able to *receive*
redo log files. This configuration will be carried over to the standby
database when it is cloned.

The primary database will have its ``db_unique_name`` and ``db_name``
parameters set the same. On the standby, they will differ.

The following parameters will be in used when the database is running as
a primary database.

..  code-block:: sql

    alter system set db_unique_name='CFG' scope=spfile;

    alter system set log_archive_config='DG_CONFIG=(CFG,CFGSB)'
    scope=spfile;

    alter system set
    log_archive_dest_1='location=use_db_recovery_file_dest'
    scope=spfile;

    alter system set log_archive_dest_2='service=cfgsb async
    valid_for=(online_logfiles,primary_role) db_unique_name=CFGSB'
    scope=spfile;

    alter system set log_archive_dest_state_1=enable scope=spfile;

    alter system set log_archive_dest_state_2=enable scope=spfile;

    alter system set remote_login_passwordfile=exclusive scope=spfile;

    alter system set LOG_ARCHIVE_FORMAT='arc_%s_%r_%t.arc'
    scope=spfile;

The following parameters will be in used when the database is running as
a standby database.

..  code-block:: sql

    alter system set fal_server=CFGSB scope=spfile;

    alter system set db_file_name_convert=
    'g:\mnt\oradata\cfgsb',
    'g:\mnt\oradata\cfg',
    'g:\mnt\fast_recovery_area\cfgsb',
    'g:\mnt\fast_recovery_area\cfg' scope=spfile;

    alter system set log_file_name_convert=
    'g:\mnt\fast_recovery_area\cfgsb',
    'g:\mnt\fast_recovery_area\cfg' scope=spfile;

    alter system set standby_file_management=auto scope=spfile;


Enable Archive Logging and Flashback
------------------------------------

To determine if the database is in archive log mode and/or flashback
mode, the following SQL will suffice:

..  code-block:: sql

    select log_mode, flashback_on from v$database;

    LOG_MODE     FLASHBACK_ON
    ------------ ------------
    ARCHIVELOG   YES

If ``ARCHIVELOG`` and ``FLASHBACK`` are already enabled, shutdown and startup
the database to enable the new parameters above.

..  code-block:: sql

    shutdown
    startup

If the database is not yet in ``ARCHIVELOG`` mode (``FLASHBACK`` cannot
therefore be enabled) then the database must be put into ``ARCHIVELOG`` and
flashback mode as follows. Note that it must be in ``ARCHIVELOG`` mode
*before* ``FLASHBACK`` can be enabled.

..  code-block:: sql

    shutdown
    startup mount

    alter database archivelog;
    alter database open
    alter database flashback on;

If the database is in ``ARCHIVELOG`` but not ``FLASHBACK``, then simply enable
``FLASHBACK``:

..  code-block:: sql

    alter database flashback on;

    shutdown
    startup

The primary database is now ready to be cloned as a standby.

You must have restarted the database before continuing. The newly added
standby parameters will not take effect until you do. Also, log shipping
etc will not work either.


Prepare the Standby Server
==========================


Create a Password File for the Standby Database
-----------------------------------------------

Copy the password file from
``%ORACLE_HOME%\Database\pwdCFG.ora`` to the standby
server's location. Rename the file to suit the unique name of the
standby database - ``%ORACLE_HOME%\Database\pwdCFGSB.ora``.


Create a Service for the Standby Database
-----------------------------------------

Open a command session *as administrator* and set the oracle environment
appropriately, then enter the following command, all on one line:

..  code-block:: batch

    oraenv cfgsb
    oradim -new -sid cfgsb -startmode manual –shutmode
    immediate

    
Create a Pfile for the Standby Database
---------------------------------------

Create a pfile, in ``%oracle_home%\database``, named
``initCFGSB.ora`` - ``initCFGSB.ora`` in our example - and add
the following single line to it:

..  code-block::

    DB_NAME=CFGSB


Create the Standby Structure
----------------------------

Create the folder structure required by the standby database. For
example, run the following in a ``cmd`` session to easily create the full
paths:

..  code-block:: batch

    mkdir g:\mnt\oradata\CFGSB
    mkdir g:\mnt\fast_recovery_area\CFGSB

    
Update the Standby Listener
---------------------------

Add an entry to the ``listener.ora`` file on the standby server. There must
be an explicit entry for the standby database as it cannot auto-register
itself on startup, because we never get it past the nomount stage. The
following was added for our example:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFGSB)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )

The listener service will have to be restarted:

..  code-block:: batch

    lsnrctl stop
    lsntcrl start

If you are unable to do this from the command line then you can do it
from the Component Services utility off of the start menu.


Start the Standby Instance
--------------------------

Start the standby instance:

..  code-block:: batch

    oraenv cfgsb

    sqlplus / as sysdba

..  code-block:: sql

    -- It may have been started by oradim above, so …
    shutdown
    startup nomount pfile='?\database\initcfgsb.ora'
    exit

    
Update the Standby Tnsnames.ora
-------------------------------

The ``tnsnames.ora`` file on the standby server must have an entry for the
primary and the new standby databases added.

Test – you must be able to connect to the SYS user, as SYSDBA, from
*both* servers to *both* databases.


On Primary Server
~~~~~~~~~~~~~~~~~

..  code-block:: batch

    ping standby_server

    sqlplus sys/<password>@CFG as sysdba
    sqlplus sys/<password>@CFGSB as sysdba

    
On Standby Server
~~~~~~~~~~~~~~~~~

..  code-block:: batch

    ping primary_server

    sqlplus sys/<password>@CFG as sysdba
    sqlplus sys/<password>@CFGSB as sysdba

    
Create the Standby Database
---------------------------

Connect to ``RMAN`` using a password for both the target and auxiliary
databases. There must also be a ``tnsnames.ora`` alias used for the
auxiliary database. For best results, use one on both databases. You can
connect from either the primary or the standby servers, it makes no
difference.

..  code-block:: batch

    rman target sys/password@CFG auxiliary sys/password@CFGSB

Run the following command:

..  code-block::

    run {
        allocate auxiliary channel x1 device type DISK;
        allocate auxiliary channel x2 device type DISK;
        allocate auxiliary channel x3 device type DISK;

        allocate channel d1 device type DISK;
        allocate channel d2 device type DISK;
        allocate channel d3 device type DISK;
        allocate channel d4 device type DISK;
        allocate channel d5 device type DISK;

        duplicate target database
        for standby
        from active database
        dorecover
        spfile
        parameter_value_convert
            'G:\mnt\oradata\CFG',
            'G:\mnt\oradata\CFGSB',
            'G:\mnt\fast_recovery_area\CFG',
            'G:\mnt\fast_recovery_area\CFGSB'
        set control_files
            'G:\mnt\oradata\CFGSB\control01.ctl',
            'G:\mnt\fast_recovery_area\CFGSB\control02.ctl'
        set db_unique_name 'CFGSB'
        set db_file_name_convert
            'G:\mnt\oradata\CFG',
            'G:\mnt\oradata\CFGSB',
            'G:\mnt\fast_recovery_area\CFG',
            'G:\mnt\fast_recovery_area\CFGSB'
        set fal_server 'CFG'
        set instance_name 'CFGSB'
        set service_names 'CFGSB'
        set audit_file_dest 'C:\ORACLEDATABASE\ADMIN\CFGSB\ADUMP'
        set dispatchers '(PROTOCOL=TCP) (SERVICE=CFGSBXDB)'
        set db_recovery_file_dest 'G:\mnt\fast_recovery_area'
        set dg_broker_start=false
        set log_file_name_convert
            'G:\mnt\oradata\CFG',
            'G:\mnt\oradata\CFGSB',
            'G:\mnt\fast_recovery_area\CFG',
            'G:\mnt\fast_recovery_area\CFGSB'
        set log_archive_dest_1
            'location=use_db_recovery_file_dest
            valid_for=(all_logfiles,all_roles) db_unique_name=CFGSB'
        set log_archive_dest_2
            'service=cfg async valid_for=(online_logfiles,primary_role)
            db_unique_name=CFG'
        nofilenamecheck
        ;

        release channel x1;
        release channel x2;
        release channel x3;
        release channel d1;
        release channel d2;
        release channel d3;
        release channel d4;
        release channel d5;
    }

    exit

**Warning:**

The ``NOFILENAMECHECK`` parameter is required *only* when the clone is to a
standby database on a *different* server. If the clone is to the same
server, the parameter *must be removed*. However, it's not a good idea
to have your primary and standby databases on the same server. Asking for trouble?

The ``PARAMETER_VALUE_CONVERT`` is *supposed* to rename the settings for
the ``control_files`` etc, but appears not to work. By
specifying the ``control_files`` parameter above, this problem is worked
around.

It is possible, perhaps desirable, to increase the number of disk, but
not auxiliary, channels as this aids in the parallelism of the clone
process. However, don't allocate too many or you may swamp the network
reducing efficiency. Five disk channels would probably be about the
maximum advised.


Bugs & Foibles
--------------

During the creation of a standby in the above manner, you may find the
following errors at the end:

..  code-block::

    RMAN-05535: WARNING: All redo log files were not defined properly.

    ORACLE error from auxiliary database: ORA-01511: error in renaming
    log/data files

    ORA-01275: Operation RENAME is not allowed if standby file
    management is automatic.

These can be ignored. It's an Oracle "feature". There is a workaround,
but it is not necessary and may cause other problems in renaming files
with the possibility of overwriting the primary database log files as a
side effect, if we are running both databases on the same server - not a 
good idea at all.

..  code-block::

    RMAN-04014: startup failed: ORA-16024: parameter
    LOG_ARCHIVE_DEST_1 cannot be parsed

Check, carefully, your parameter setting. ``VALID_FOR`` is one word with an
underscore, not 2 separate words. There should be an '=' with no spaces
around it and brackets around the options, as in::

    valid_for=(yada,yada)
    
and so on.

Post Clone Checks
-----------------

..  code-block:: batch

    oraenv cfgsb

    sqlplus / as sysdba

..  code-block:: sql

    show parameter instance_name
    show parameter service_names
    show parameter audit_file_dest
    show parameter dispatchers
    show parameter db_recovery_file_dest

The output from the above should show the standby database name as
appropriate, and not the primary. If not, run the appropriate
command(s) below and bounce the database:

..  code-block:: sql

    alter system set instance_name='CFGSB' scope=spfile;

    alter system set service_names='CFGSB' scope=spfile;

    alter system set audit_file_dest =
    'C:\ORACLEDATABASE\ADMIN\CFGSB\ADUMP' scope = spfile;

    alter system set dispatchers=

    '(PROTOCOL=TCP) (SERVICE=CFGSBXDB)' scope=spfile;

    alter system set
    db_recovery_file_dest='G:\mnt\fast_recovery_area'
    scope=spfile;

    startup force mount;

    show parameter instance_name
    show parameter service_names
    show parameter audit_file_dest
    show parameter dispatchers
    show parameter db_recovery_file_dest

The output from the above should now show the standby database name
as appropriate, and not the primary.

..  code-block:: sql

    select d.name, d.db_unique_name, d.database_role,
    i.instance_name
    from v$database d, v$instance i;

    NAME      DB_UNIQUE_NAME DATABASE_ROLE    INSTANCE_NAME
    --------- -------------- ---------------- -------------
    CFG       CFGSB          PHYSICAL STANDBY cfgsb

    
Start Managed Recovery
======================

The database is not yet in managed recovery mode, so to start it off we
need to run the following command:

..  code-block:: sql

    alter database recover managed standby database
    using current logfile disconnect;

The database should now begin to apply any updates from the primary. You
can force a log switch, on the primary database, as follows:

..  code-block:: sql

    alter system archive log current;

    archive log list

    Database log mode Archive Mode
    Automatic archival Enabled
    Archive destination USE_DB_RECOVERY_FILE_DEST
    Oldest online log sequence 3321
    Next log sequence to archive 3330
    Current log sequence 3330

Then after a few seconds, maybe a couple of minutes,

..  code-block:: sql

    select gap_status
    from v$archive_dest_status
    where dest_id=2;

You should expect to see 'NO GAP' but if there's a delay, you may see
'RESOLVABLE GAP' if the standby hasn't quite caught up. Anything else
should be investigated before continuing.

On the standby, running ``ARCHIVE LOG LIST`` is a quick check that all is
well, the current log sequence should match that on the primary:

..  code-block:: sql

    archive log list

    Database log mode Archive Mode
    Automatic archival Enabled
    Archive destination USE_DB_RECOVERY_FILE_DEST
    Oldest online log sequence 0
    Next log sequence to archive 0
    Current log sequence 3330

    
Checking Managed Recovery
-------------------------


Am I the Primary or Standby?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Example on a primary database:

..  code-block:: sql

    select database_role from v$database;

    DATABASE_ROLE
    -------------
    PRIMARY

Example on a standby database:

..  code-block:: sql

    DATABASE_ROLE
    ----------------
    PHYSICAL STANDBY

The result will indicate the current role of this particular instance.


Is There an Apply Gap?
~~~~~~~~~~~~~~~~~~~~~~

The easiest method is to use ``dgmgrl`` after Data Guard has been configured
(see below) as this gives up to date details of any gaps etc:

..  code-block:: batch

    oraenv cfg
    dgmgrl /

    show configuration

    ...

    Databases:

    cfg - Primary database
    cfgsb - Physical standby database

    ...

    show database 'cfgsb'

    Database - cfgsb
    Role: PHYSICAL STANDBY
    Intended State: APPLY-ON
    Transport Lag: 0 seconds (computed 0 seconds ago)
    Apply Lag: 0 seconds (computed 0 seconds ago)
    Apply Rate: 137.00 KByte/s
    Real Time Query: OFF

    Instance(s):
    cfgsb

    Database Status:
    SUCCESS

Until Data Guard is configured, and running, you must query the
databases to find any gaps. To check on the Primary:

..  code-block:: sql

    select Dest_name, destination, archived_seq#, applied_seq#,
    error, db_unique_name, gap_status
    from   v$archive_dest_status
    where  status <> 'INACTIVE'
    and    dest_name = 'LOG_ARCHIVE_DEST_2';

Where 'n' is the ``dest_id``, usually 2, of the database parameter
that ships logs to the standby database.

..  code-block::

    DEST_NAME          ARCHIVED_SEQ# APPLIED_SEQ# ERROR GAP_STATUS
    ------------------ ------------- ------------ ----- ----------
    LOG_ARCHIVE_DEST_2         15975         15974      NO GAP

"NO GAP" is what you are hoping to see.

Or, alternatively, you can check on the standby:

..  code-block:: sql

    select Dest_name, destination, archived_seq#, applied_seq#,
    error, db_unique_name, gap_status
    from v$archive_dest_status
    where status <> 'INACTIVE'
    and dest_name = 'STANDBY_ARCHIVE_DEST';

    DEST_NAME            ARCHIVED_SEQ# APPLIED_SEQ# ERROR GAP_STATUS
    -------------------- ------------- ------------ ----- ----------
    STANDBY_ARCHIVE_DEST         15975         15975      NO GAP

On the primary database there will *usually* be a gap of 1 or 2 between the
``ARCHIVED_SEQ#`` and the ``APPLIED_SEQ#`` even if the standby shows that both
are the same, and match the primary's ``ARCHIVED_SEQ#``. You can check if
you wish:

..  code-block:: sql

    select sequence#, dest_id, applied
    from v$archived_log
    where sequence# >= 15974
    and dest_id = 2;

    SEQUENCE#  DEST_ID APPLIED
    ---------- ------- -------
    15974            2 YES
    15975            2 YES

As before, the ``dest_id`` matches the ``LOG_ARCHIVE_DEST_2`` database
parameter and usually refers to the standby database service. Adjust the
query as necessary.

You can see from the results that the log with sequence# of 15975 has
indeed been applied at the standby site, even though the above query
shows a "gap".

It is therefore best to run this particular query against the
``v$archive_dest_status`` on the standby, for the most accurate results!

Status of the last 10 archived logs?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Run on the Primary:

..  code-block:: sql

    select sequence#, dest_id, name, applied, backup_count, status
    from   v$archived_log
    where  sequence# > (  select -10 + max(sequence#) 
                          from v$archived_log
                       )
    and    lower(name) = 'cfgsb'
    order  by sequence#;

You should see that all of the listed logs are applied, with the
exception of the final one. Anything else needs to be investigated.
Obviously, the lower case standby database name should be specified
according to what that particular standby is actually named.

..  code-block::

    SEQUENCE# DEST_ID NAME  APPLIED BACKUP_COUNT STATUS
    --------- ------- ----- ------- ------------ ------
        15723       2 cfgsb YES                0 A
        15724       2 cfgsb YES                0 A
        15725       2 cfgsb YES                0 A
        15726       2 cfgsb YES                0 A
        15727       2 cfgsb YES                0 A
        15728       2 cfgsb YES                0 A
        15729       2 cfgsb YES                0 A
        15730       2 cfgsb YES                0 A
        15731       2 cfgsb YES                0 A
        15732       2 cfgsb NO                 0 A


What Point in Time Are the databases At? 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Run on the Primary:

..  code-block:: sql

    select scn_to_timestamp(current_scn) as PRIMARY_SCN 
    from   v$database;

    PRIMARY_SCN
    -------------------------------
    20-JUN-16 01.55.32.000000000 PM

Run on the Standby:

..  code-block:: sql

    select current_scn from v$database;

    CURRENT_SCN
    -----------
    54374184

Then, run on the Primary:

 ..  code-block:: sql

   select scn_to_timestamp(54374184) as STANDBY_SCN 
    from dual;

    STANDBY_SCN
    -------------------------------
    20-JUN-16 01.32.56.000000000 PM

This has to be run on the Primary as the open mode of the standby
prevents you from using it. Bear in mind that the standby database may
be some time behind the primary due to some logs not yet having been
archived and shipped to the standby database. It is unlikely that both 
timestamps will coincide.


Stopping Managed Recovery
=========================

*If it is necessary* to stop managed recovery, proceed as follows:

Login to the standby database as SYSDBA, and:

..  code-block:: sql

    alter database recover managed standby database cancel;

The database is no longer applying any updates from the primary.

If the stoppage is going to be for some considerable time, it may be
wise to DEFER archive log shipping on the *primary database* too. The
following assumes that ``log_archive_dest_2`` is the one pointing to the
standby database service:

..  code-block:: sql

    alter system set log_archive_dest_state_2='DEFER' 
    scope = memory;

If, of course, you wish to prevent the deferral from being rescinded
after a reboot of the primary database, you should replace 'memory' with
'both'.

Don't forget to enable the destination after you have finished working
on the standby again!


Create an Application Service
=============================

Now that a pair of databases are acting as one, the ``tnsnames.ora`` must be
changed to ensure that the application/user's connections connect to
whichever database is running as the primary, without having to make
changes to the application or the users' ``tnsnames.ora`` file every time
there is a switch over.


Amend Tnsnames.ora
------------------

Add the following entry, or a similar one, to the ``tnsnames.ora`` on *both*
servers, and in the centralised ``tnsnames.ora`` of one is in use. If not,
then the users will need an updated ``tnsnames.ora``, possibly.

..  code-block::

    CFGSVC =
        (DESCRIPTION =
            (ADDRESS_LIST =
                (ADDRESS = (PROTOCOL = TCP)(HOST = primary_server)(PORT = 1521))
                (ADDRESS = (PROTOCOL = TCP)(HOST = standby_server)(PORT = 1521))
            )
            (CONNECT_DATA =
                (SERVER = DEDICATED)
                (SERVICE_NAME = CFGSVC)
            )
        )

The alias has been configured to be the databases' name, without the
numeric suffix. The service is this alias with a ``_SERVICE`` suffix. This
way, DBAs and Data Guard can still directly access either CFG or
CFGSB, regardless of whether or not they are in primary or standby
configuration.

This ``tnsnames.ora`` points the CFGSRV alias at two separate servers, the
primary database server and the standby database server. However,
instead of connecting via a ``SID_NAME`` or a ``SERVICE_NAME`` that is the
same as the database name, CFG, we *must* now connect via a
``SERVICE_NAME`` that is *different* to the database name as the database
name is still used as the service name for the existing direct
connections to CFG and CFGSB.


Create a Service on the Current primary
---------------------------------------

Login to the primary database as SYSDBA and create a new service to
match the one used in the ``tnsnames.ora`` file above.

First, check the current ``service_names`` parameter:

..  code-block:: sql

    show parameter service_names

    NAME          TYPE   VALUE
    ------------- ------ -----
    service_names string CFG

We can see that only the existing service name, corresponding to the
database's ``DB_UNIQUE_NAME``, exists at present.

Next, create the new service:

..  code-block:: sql

    begin
        dbms_service.create_service(service_name => 'CFGSVC',
                                    network_name => 'CFGSVC');
    end;
    /

It is best to have both parameters the same and both should match that
used above in the new ``tnsnames.ora`` entry. The service will also be
created on the current standby database automatically.

If you check the ``service_names`` parameter again, nothing will have
changed. You need to start the service for any changes to take place.

Start the Service on the Current Primary
----------------------------------------

The service should now be started. As before, this must be carried out
on the primary database:

..  code-block:: sql

    begin
        dbms_service.start_service(service_name => 'CFGSVC');
    end;
    /

Then check the ``service_names`` parameter again to see which service names
are currently in use by the primary database:

..  code-block:: sql

    show parameter service_names

    NAME          TYPE   VALUE
    ------------- ------ -----------
    service_names string CFG, CFGSVC

The primary database is now running with two separate service names,
CFG and CFGSVC. This is as desired.

**Note**: It has been seen on a number of occasions that the CFG service 
name does not appear in the above output. This can be ignored as any TNS
alias set up to point at the CFG service will still work.


Ensure That the Service Only Runs on the Primary
------------------------------------------------

The CFGSVC defined and created above must only ever be running
on the primary database. This will ensure that all connections using the
CFGSVC alias, which connects via the CFGSVC service name, will connect to
either CFG or CFGSB regardless of which one is running as the
current primary database.

Create a new database trigger which will start or stop the service as
necessary, depending on whether the database started as a primary or a
standby. This must be executed as the SYS user:

..  code-block:: sql

    create or replace trigger CFGSVC_trigger
    after startup on database

    declare
        v_role V$DATABASE.DATABASE_ROLE%TYPE;

    begin

    --===================================================
    -- Make sure we only start the CFGSVC on this
    -- database if it is running as the primary database.
    --===================================================

    select database_role
    into   v_role
    from   v$database;

    if (v_role = 'PRIMARY') then
        dbms_service.start_service('CFGSVC');
    else
        dbms_service.stop_service('CFGSVC');
    end if;

    end;
    /

The naming convention used above is simply to append ``_TRIGGER`` to the
service name we are wishing to maintain.

If the database is started as a primary, then CFGSVC will be
started. Connections will automatically be directed to the running
primary database.

If the database is started as a standby, then the service will not be
started on this database. Connections will route to the CFGSB standby database
instead.

If both databases happen to be down, the service will not be started,
and connections will fail in the normal manner.


Update RMAN Configuration for Primary & Standby Databases
=========================================================

The primary and standby databases should have their ``archivelog deletion
policy`` updated to *applied on all standby backed up 2 times to device
type disk*. This will apply regardless of which instance is running as
the primary as both databases have the same DBID.

Non primary-standby pairs only have their archived logs deleted after
two successful backups. With a primary-standby pair, it is necessary to
ensure that the files have also been applied to the current standby.

There is no need to register the standby database with RMAN, as this
will create an error as the primary database's DBID is already
registered.

..  code-block::

    rman target sys/password@cfg catalog rman11g/password@CFGRMNSVC

If you run the following command, the current configuration will be
displayed:

..  code-block::

    show ARCHIVELOG DELETION POLICY;

    RMAN configuration parameters for database with db_unique_name
    CFG are:

    CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 2 TIMES TO DISK;

We need to adjust the setting now that we have a standby.

..  code-block::

    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY
    BACKED UP 2 TIMES TO DEVICE TYPE DISK;

    old RMAN configuration parameters:

    CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 2 TIMES TO DISK;

    new RMAN configuration parameters:

    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY
    BACKED UP 2 TIMES TO DISK;

    new RMAN configuration parameters are successfully stored

    exit;

Obviously, 'disk' in the above could very well be ``tape`` or ``sbt_tape``
according to what we are doing exactly to run our RMAN backups.


Configure Data Guard
====================

Once the standby has been shown to work correctly, and is shipping logs
etc, it is now in a position to be used to wait for some natural
disaster to occur which requires a *failover* or tested periodically by
carrying out a *switchover*.

In the current state, the switchover operation will require a large
number of checks and SQL commands to be carried out by the DBA before
the database can be considered ready to be switched over.

If we configure Data Guard then switching over is a simple matter of:

-  Running ``dgmgrl`` on either the primary or standby server.

-  Logging in as the SYS user, with a password. You need a password to
   create configurations, switchover or failover.

-  Executing the command switchover to cfgsb;

Having said that, Oracle advise that a number of checks are still
performed prior to switching over in order to reduce the possibility of
failures, and to speed up the actual switchover itself. These are
detailed in the separate ``SOP_DataGuardFailover`` document.

If the current primary database is completely lost, then the commands
should instead be:

..  code-block::

    Failover to cfgsb;

This latter case will usually require a rebuild of the old primary
database afterwards, but this can be done from within ``dgmgrl`` as well,
and uses flashback to bring the database back from the dead, using the
reinstate database command.


Configure the Listener
----------------------

There must be a static listener connection set up on both servers. The
``SID_NAME`` of the static connection must be ``DB_UNIQUE_NAME`` and the ``GLOBAL_NAME``
must be ``<DB_UNIQUE_NAME>_DGMGRL``. You must edit ``listener.ora``, on both
servers, and add an entry to each.

The entry on the primary server should be:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFG)
        (GLOBAL_DBNAME = CFG_DGMGRL)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )

While that on the standby server will be as follows:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFGSB)
        (GLOBAL_DBNAME = CFGSB_DGMGRL)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )

Additionally, *if the listener is running on a port other than 1521*,
then the following entries need to be added, first to the primary
listener:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFG)
        (GLOBAL_DBNAME = CFG_DGB)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )

And to the standby listener:

..  code-block::

    (SID_DESC =
        (SID_NAME = CFGSB)
        (GLOBAL_DBNAME = CFGSB_DGB)
        (ORACLE_HOME = C:\OracleDatabase\product\11.2.0\dbhome_1)
    )

The ``_DGB`` entry is used by the Data Guard Broker Process, ``DMON``, to check
the heartbeat of the different nodes in the configuration.

Obviously, the listener will need to be restarted after any changes. You
should restart it as follows:

..  code-block::

    lsnrctl stop
    lsnrctl start
    
You need to be running in an administrator enabled command session to do the above. Failing that, use the "services" applet in Control Panel.


Tnsnames.ora
------------

Nothing needs to be changed in ``tnsnames.ora``. The static listener
connections and ``global_dbname`` settings are all that is required and
these are set up in ``listener.ora`` as per the instructions above.


Start the DG Broker
-------------------

On *both* databases, start the data guard broker as follows:

..  code-block:: sql

    alter system set dg_broker_start=true scope=both;
    exit;

    
Start DGMGRL
------------

On the primary server, start the ``dgmgrl`` utility as follows, and connect
to the SYS user:

..  code-block:: batch

    dgmgrl sys/password

    
Create a DG Configuration
-------------------------

..  code-block::

    DGMGRL> create configuration 'dgmgrl_configuration' as
    primary database is cfg
    connect identifier is cfg;

    Configuration "dgmgrl_configuration" created with primary database
    "cfg"

    
Add a Standby Database
----------------------

..  code-block::

    DGMGRL> add database cfgsb as
    connect identifier is cfgsb
    maintained as physical;

    Database "cfgsb" added

    
Display Current Configuration
-----------------------------

..  code-block::

    DGMGRL> show configuration

    Configuration - dgmgrl_configuration
    Protection Mode: MaxPerformance

    Databases:
    cfg - Primary database
    cfgsb - Physical standby database

    Fast-Start Failover: DISABLED

    Configuration Status:
    DISABLED

    
Display Brief Primary Database Details
--------------------------------------

..  code-block::

    DGMGRL> show database cfg
    Database - cfg
    Role: PRIMARY
    Intended State: OFFLINE
    Instance(s):
    cfg
    Database Status:
    DISABLED


Display Brief Standby Database Details
--------------------------------------

..  code-block::

    DGMGRL> show database cfgsb

    Database - cfgsb
    Role: PHYSICAL STANDBY
    Intended State: OFFLINE
    Transport Lag: (unknown)
    Apply Lag: (unknown)
    Apply Rate: (unknown)

    Real Time Query: OFF
    Instance(s):
    cfgsb

    Database Status:
    DISABLED

    
Enable the Configuration
------------------------

..  code-block::

    DGMGRL> enable configuration

    Enabled.

    
Did it Work?
------------

..  code-block::

    DGMGRL> show configuration

    Configuration - dgmgrl_configuration
    Protection Mode: MaxPerformance

    Databases:
    cfg - Primary database
    cfgsb - Physical standby database

    Fast-Start Failover: DISABLED

    Configuration Status:
    SUCCESS

The configuration has been enabled, and is working correctly.


Stopping the DG Broker
----------------------

*If it should become necessary* to disable Data Guard, then:

on *both* databases, primary and standby, stop the data guard broker as
follows:

..  code-block:: sql

    alter system set dg_broker_start=false scope=both;
    exit;

    
Test Switchover
---------------

It is wise to test switchovers in both directions, to be certain that
all is working correctly.


Pre-Check Both Databases
~~~~~~~~~~~~~~~~~~~~~~~~

In SQL*Plus, check the primary database details as follows:

..  code-block:: sql

    select name, db_unique_name,database_role
    from v$database;

    NAME      DB_UNIQUE_NAME  DATABASE_ROLE
    --------- --------------- ----------------
    CFG       CFG             PRIMARY

And on the standby database, we get the following output:

..  code-block:: sql

    NAME      DB_UNIQUE_NAME  DATABASE_ROLE
    --------- --------------- ----------------
    CFG       CFGSB           PHYSICAL STANDBY

    
Switch Over
~~~~~~~~~~~

In ``dgmgrl``, on either server, switch over to the current standby
database:

..  code-block::

    DGMGRL> show configuration

    Configuration - dgmgrl_configuration
    Protection Mode: MaxPerformance

    Databases:
    cfg - Primary database
    cfgsb - Physical standby database

    ...

..  code-block::

    DGMGRL> switchover to cfgsb

    Performing switchover NOW, please wait...

    Operation requires a connection to instance "cfgsb" on database
    "cfgsb"

    Connecting to instance "cfgsb"...
    Connected.

    New primary database "cfgsb" is opening...

    Operation requires startup of instance "cfg" on database
    "cfg"

    Starting instance "cfg"...
    ORACLE instance started.
    Database mounted.

    Switchover succeeded, new primary is "cfgsb"

    
Check for Correct Switch Over
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In SQL*Plus, check the primary database details as follows:

..  code-block:: sql

    select name, db_unique_name,database_role
    from v$database;

    NAME      DB_UNIQUE_NAME  DATABASE_ROLE
    --------- --------------- ----------------
    CFG       CFG             PHYSICAL STANDBY

And on the standby database, we get the following output:

..  code-block:: sql

    NAME      DB_UNIQUE_NAME  DATABASE_ROLE
    --------- --------------- ----------------
    CFG       CFGSB           PRIMARY

We can see that the roles have been correctly reversed, cfgsb is now
running as the primary with cfg as the new standby database.


Switch Back
~~~~~~~~~~~

You must test that the switchover works both ways. This will prevent
problems where it is possible to switch from cfg to cfgsb but a
configuration problem prevents switching from cfgsb to cfg.

..  code-block::

    DGMGRL> switchover to cfg

    Performing switchover NOW, please wait...
    New primary database "cfg" is opening...

    Operation requires startup of instance "cfgsb" on database
    "cfgsb"

    Starting instance "cfgsb"...
    ORACLE instance started.
    Database mounted.

    Switchover succeeded, new primary is "cfg"

    
Disabling the Standby Database
==============================

In order to disable the standby database, you need to:

-  Cancel managed recovery and DEFER the primary database's
   ``log_archive_dest_2`` – see *Stopping Managed
   Recovery*.

-  Turn off Data Guard, if in use – see *Stopping the DG
   Broker*.

   
Data Guard Troubleshooting
==========================


Switch over
~~~~~~~~~~~

It takes a few minutes to perform a switchover. Bringing up the standby
to a mount state seems to be the longest part. Be aware that during the
mounting, running show configuration in a separate ``dgmgrl`` session will
show spurious errors regarding log archive transport and/or mismatched
``DB_UNIQUE_NAME``. Just wait and it should come up happily.


Log Files
~~~~~~~~~

The log files for each database in a Data Guard configuration can be
found in::

    %ORACLE_HOME%\diag\rdbms\<database>\<database>\trace\drc<database>.log

which equates to the following for our two example databases above::

    %ORACLE_HOME%\diag\rdbms\cfg\cfg\trace\drccfg.log
    %ORACLE_HOME%\diag\rdbms\cfgsb\cfgsb\trace\drccfgsb.log


What's Happening?
~~~~~~~~~~~~~~~~~

On the standby database, run this command:

..  code-block:: sql

    select process,status,thread#,sequence#,block#,blocks
    from v$managed_standby;

The output will resemble this:

..  code-block::

    PROCESS   STATUS          THREAD#  SEQUENCE#     BLOCK#     BLOCKS
    --------- ------------ ---------- ---------- ---------- ----------
    ARCH      CLOSING               1      15933       2048       2004
    ARCH      CONNECTED             0          0          0          0
    ARCH      CLOSING               1      15936          1        561
    ARCH      CLOSING               1      15934          1        953
    RFS       IDLE                  0          0          0          0
    RFS       IDLE                  1      15937        315          1
    RFS       IDLE                  0          0          0          0
    MRP0      APPLYING_LOG          1      15937        314     204800

The ``MRPn`` process is the one that carries out managed recovery. In the
above, it is applying log sequence 15937. ``MRP0`` in use means that the
recovery was initiated with ``alter database ... disconnect from session``
as above. If the process is called ``MR(fg)`` then no disconnect was
requested.

The ``RFS`` processes fetch logs from the primary as and when required. They
are idle here, so nothing is coming across at the moment.


Switch Over Works, One Way Only
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you find that you can switchover to one database ok, but cannot
switch back, check the configuration and the following database parameters:

- ``instance_name``
- ``db_unique_name``
- ``log_archive_dest_2``
- ``service_names``
- ``dispatcher``
- ``audit_file_dest``

The ``listener.log`` may also be of use, as it could be showing the
following:

..  code-block::

    TNS-12514: TNS:listener does not currently know of service requested in
    connect descriptor
    
    22-JUN-2016 11:37:17 *
    (CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=CFGSB)
    (CID=(PROGRAM=c:\oracledatabase\product\11.2.0\dbhome_1\bin\ORACLE.EXE)
    (HOST=ORCDEVORC01)(USER=SYSTEM)))
    * (ADDRESS=(PROTOCOL=tcp)(HOST=172.21.42.11)(PORT=64261)) 
    * establish
    * CFGSB * 12514

These messages will be shown if the standby database did not start for
some reason, because the primary is still trying to connect to it
regardless. Check database CFGSB, in this case, to see what the
``SERVICE_NAMES`` parameter is set to. You may have to run the following to
correct things:

..  code-block:: sql

    sqlplus / as sysdba

    startup nomount (if the database didn't start)

    show parameter service_names

    ...

    alter system set service_names='CFGSB' scope=both;
    alter database mount;


Next, update the ``StaticConnectIdentifier`` in ``dgmgrl``:

..  code-block::

    DGMGRL> edit database cfgsb 
    set property StaticConnectIdentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)
    (HOST=ORCDEVORC01)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=CFGSB_DGMGRL)
    (INSTANCE_NAME=CFGSB)(SERVER=DEDICATED)))';

    Property "staticconnectidentifier" updated

**Warning**: The command shown above may have wrapped onto a number of lines, 
everything after the '=' sign must be all on the same line.    
    
The standby should now begin applying logs etc, however, your ``dgmgrl``
session is probably hung. You can leave it for a while (10 minutes
should suffice) to see if it returns, or CTRL-C your way out if
necessary.
