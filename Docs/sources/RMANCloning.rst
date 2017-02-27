============================
Cloning Databases using RMAN
============================

Abstract
========

The following outlines the steps followed in order to clone, using RMAN
active duplicate, a *staging* database, to another database either to create 
a new database, or, to refresh an existing database with the latest UV data. 
Either option is catered for, and the process is pretty much identical.

*You cannot clone a database to a new database, with the same
name, regardless of whether it is running on a different server or not.*


Terminology:
============

Target\_database.
    The source database. (Oracle refer to this as the target, go figure!) In the following example, this will be referred to as T_DB.

Target\_server. 
    Where the target database runs. In the following example, this will be referred to as T_SVR if the name is required.

Auxiliary\_database. 
    The destination database. (Oracle refer to this as the auxiliary database.) In the following example, this will be referred to as A_DB.

Auxiliary\_server. 
    Where the auxiliary database runs. In the following example, this will be referred to as A_SVR if the name is required.
    
Prepare the Target Server
=========================

Start database T_DB using an spfile. If the database is already running, an spfile can be checked for by:

..  code-block:: sql

    oraenv T_DB
    sqlplus sys/password as sysdba
    show parameter spfile

There *must* be a valid spfile name returned. If not, the database must
be restarted using an spfile.

..  code-block:: sql

    create spfile='?\database\spfileT_DB.ora' from pfile;
    startup force

This database must also be running in ``ARCHIVELOG`` mode. This can be checked by:

..  code-block:: sql

    select log_mode from v$database;

If the returned value is ``NOARCHIVELOG`` then run the following:

..  code-block:: sql

    shutdown immediate;
    startup mount;

    alter database archivelog;
    alter database flashback on;
    alter database open;
    alter system archive log current;

    select log_mode from v$database;

Make sure that the ``tnsnames.ora`` has an entry for A_DB. This can be checked by running:

..  code-block:: BATCH

    tnsping A_DB

There should be an ok status returned at the end of the output. If not,
add the A_DB to the target server's ``tnsnames.ora`` file.


Prepare the Auxiliary server
============================

Open an Administrator enabled command session. Run the following
command replacing "A_DB" as appropriate:

..  code-block:: batch

    oradim -new -sid A_DB -startmode manual -shutmode immediate

Create the folder structure required by the new database. For
example, run the following in a cmd session to easily create the full
paths:

..  code-block:: batch

    mkdir <drive>:\mnt\oradata\A_DB
    mkdir <drive>:\mnt\fast_recovery_area\A_DB

Copy the password file for T_DB, from ``%ORACLE_HOME%\database\pwdT_DB.ora`` on the
target server to ``%ORACLE_HOME%\database\pwdA_DB.ora`` on the auxiliary server.

Create a new pfile for the auxiliary database. It only needs to
contain the following:

..  code-block:: sql

    db_name=A_DB

Save the file in ``%ORACLE_HOME%\DATABASE\initA_DB.ora``.

Add an entry for A_DB to the auxiliary server's
``tnsnames.ora`` and also to the target server's ``tnsnames.ora``.

Add an entry for the database to the listener.ora on the auxiliary server:

..  code-block::

    SID_LIST_LISTENER =
            ...
        (SID_DESC =
            (SID_NAME = A_DB)
            (ORACLE_HOME = c:\OracleDatabase\product\11.2.0\dbhome_1)
        )
      )

This is required because when the database is not ``OPEN``, it is not registered with the listener and so cannot be reached from ``RMAN``.

Stop and start the listener service:

..  code-block:: batch

    lsnrctl stop
    lsnrctl start

Start A_DB in ``NOMOUNT`` mode. It must be started using a pfile, *not* an spfile:

..  code-block:: sql

    oraenv A_DB
    sqlplus sys/password as sysdba

    startup nomount pfile='?\database\initA_DB.ora'
    exit
    
   
Clone the Database
==================

The database is ready to be cloned. It can be initiated from the
target server or the auxiliary server as desired.

If you are cloning onto the *same* server, then read on. If, on the other hand, 
you are cloning onto different servers, see *Cloning a Staging Database to a 
Different Server*, below, *after* reading the following small section 
on certain foibles noticed when running the scripts to clone databases.

RMAN Foibles
------------

**Warning:** The ``PARAMETER_VALUE_CONVERT`` in the following is *supposed* to rename the
settings for the ``control_files`` etc, but appears not to work. 
To this end, it was necessary to recreate the target server's
tree structure - where the control files lived - onto the
auxiliary server. This also left the control files in the wrong
location after the clone.

However, by specifying the ``set control_files`` parameter, this problem was
worked around. See *Control_Files_Workaround*, below, for a
workaround for when this parameter wasn't originally used - just in case!

It is possible, perhaps desirable, to increase the number of disk, but
not auxiliary, channels as this aids in the parallelism of the clone
process. However, don't allocate too many or you may swamp the network
reducing efficiency. Five disk channels would probably be about the
maximum advised.

**Warning:** When cloning between two databases on the same server, 
the ``nofilenamecheck`` parameter *must* be *omitted*. This
prevents the clone process from inadvertently overwriting
target database files with auxiliary database files - if yo somehow managed to mess up the various ``xxx_file_name_convert`` parameters. 

This parameter *must never* be specified when cloning to the *same* server.

Pre-Cloning Script Edits
------------------------

The code shown below to clone a database must be edited to replace the target and auxiliary database drive letters, and paths, for the following:

- ``PARAMETER_VALUE_CONVERT``
- ``DB_FILE_NAME_CONVERT``
- ``LOG_FILE_NAME_CONVERT``.

To avoid any omissions that *will* cause later problems when opening the auxiliary database, 
and to avoid having the auxiliary database have parameter settings that refer to the target database name, the script below may be helpful.

It will list the "from" values required for any or all of the parameters listed above, depending on the T_DB configuration. If a parameter is missing from the output, then it is not required in the clone commands file.

Run the following on the target database to extract the settings. The script runs happily on Windows or flavours of Unix without change:

..  code-block:: sql

    -- Check for DATA FILES...
    -- Uses '\' for Windows and '/' for UNIX.
    -- Use the output to set up DB_FILE_NAME_CONVERT's "from" values.
    --
    with db as (
    --
        select distinct  
               substr(file_name, 0, instr(file_name, '\', -1)) as value
        from dba_data_files 
        union all
        select distinct substr(file_name, 0, instr(file_name, '/', -1)) 
        from dba_data_files 
    ),
    --
    redo as (
    --
        -- Check for REDO LOG FILES...
        -- Uses '\' for Windows and '/' for UNIX.
        -- Use the output to set up LOG_FILE_NAME_CONVERT's "from" values.
        select distinct  
               substr(member, 0, instr(member, '\', -1)) as value
        from v$logfile
        union all
        select distinct substr(member, 0, instr(member, '/', -1)) 
        from v$logfile 
    ),
    --
    param as (
    --
        -- Check for database parameters.
        -- Uses '\' for Windows and '/' for UNIX.
        -- Use the output to set up PARAMETER_VALUE_CONVERT's "from" values.
        select distinct  
               stuff.value as value
        from (    
            select name, value
            from v$parameter
            where value like '%\%'
            union all
            select name, value
            from v$parameter
            where value like '%/%'
        ) stuff
        where upper(name) not in (
            'AUDIT_FILE_DEST',
            'CONTROL_FILES',
            'DB_RECOVERY_FILE_DEST',
            'BACKGROUND_DUMP_DEST',
            'CORE_DUMP_DEST',
            'DG_BROKER_CONFIG_FILE1',
            'DG_BROKER_CONFIG_FILE2',
            'DIAGNOSTIC_DEST',
            'SPFILE',
            'STANDBY_ARCHIVE_DEST',
            'USER_DUMP_DEST',
            'NLS_DATE_FORMAT'
        )
    )
    --
    select 'DB_FILE_NAME_CONVERT' as parameter, value from db
    where value is not null
    union all
    select 'LOG_FILE_NAME_CONVERT' as parameter, value from redo
    where value is not null
    union all
    select 'PARAMETER_VALUE_CONVERT' as parameter, value from param
    where value is not null
    order by 1,2;

We can ignore any of the following parameters:

- ``AUDIT_FILE_DEST``
- ``CONTROL_FILES``
- ``DB_RECOVERY_FILE_DEST``
-   Anything that lives in ``%ORACLE_BASE%`` or ``%ORACLE_HOME%``. These usually include:

    - ``BACKGROUND_DUMP_DEST``
    - ``CORE_DUMP_DEST``
    - ``DG_BROKER_CONFIG_FILE%``
    - ``DIAGNOSTIC_DEST``
    - ``SPFILE``
    - ``STANDBY_ARCHIVE_DEST``
    - ``USER_DUMP_DEST``

- ``NLS_DATE_FORMAT`` :-)  

These are explicitly set by the ``RMAN`` commands to create the clone database 
or default to acceptable values when the database is created and/or opened.

The output from the above will resemble the following:

..  code-block::

    PARAMETER               VALUE
    ----------------------- -----------------------------------
    DB_FILE_NAME_CONVERT    G:\MNT\ORADATA\AZSTG02\
    LOG_FILE_NAME_CONVERT   G:\MNT\ORADATA\AZSTG02\
    LOG_FILE_NAME_CONVERT   H:\MNT\FAST_RECOVERY_AREA\AZSTG02\


Cloning A Staging Database to the Same Server
=============================================

The following outlines the steps followed in order to clone, using RMAN
active duplicate, the T_DB database, to a new database, A_DB, on the *same*
server.

Run the following command in ``RMAN``, replacing the T_DB and A_DB's names
as appropriate. In addition, the drive letter for the target database is listed as ``t:\`` and that of the auxiliary database is listed as ``a:\`` - change these too.

You may find it helpful to copy the following and paste it into a text file, named something
like ``clone_A_DB.rman``, then open the file in your favourite editor (alternatively, use ``notepad``) and:

- Replace all occurrences of 'a:' with the correct drive on the auxiliary server.
- Replace all occurrences of 't:' with the correct drive on the target server.
- Replace all occurrences of 'A_DB' with the name of the auxiliary database.
- Replace all occurrences of 'T_DB' with the name of the target database.


Once the code shown below has been edited accordingly, connect to ``RMAN`` using 
a password for both the target and auxiliary databases. There must also be 
a ``tnsnames.ora`` alias used for the auxiliary database. For best results, 
use one on both databases:

..  code-block:: batch

    rman target sys/password@T_DB auxiliary sys/password@A_DB

..  code-block::

    # Clone A_DB from T_DB using RMAN.

    run {
        allocate auxiliary channel x1 device type DISK;
        allocate auxiliary channel x2 device type DISK;
        allocate auxiliary channel x3 device type DISK;
        allocate channel d1 device type DISK;
        allocate channel d2 device type DISK;
        allocate channel d3 device type DISK;
        allocate channel d4 device type DISK;
        allocate channel d5 device type DISK;

        duplicate target database to A_DB
        from active database
        spfile
        parameter_value_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
        set instance_name 'A_DB'
        set service_names 'A_DB'
        set dispatchers '(PROTOCOL=TCP) (SERVICE=A_DBXDB)'
        set audit_file_dest ' C:\ORACLEDATABASE\ADMIN\A_DB\ADUMP'
        set db_recovery_file_dest 'a:\mnt\fast_recovery_area'
        set dg_broker_start 'false'
        set control_files
            'a:\mnt\oradata\A_DB\control01.ctl',
            'a:\mnt\fast_recovery_area\A_DB\control02.ctl'
        set db_file_name_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
        set log_file_name_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
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

When complete, skip the next section and continue from 
*Post Clone Tidy-up and Checks* below.


Cloning A Staging Database to a Different Server
================================================

The following outlines the steps followed in order to clone, using RMAN
active duplicate, the T_DB database, to a new database named A_DB.

Exactly the same directory structure was used on the auxiliary server 
as on the target server. This need not always be the case, however.

You may find it helpful to copy the following and paste it into a text file, named something
like ``clone_A_DB.rman``, then open the file in your favourite editor (alternatively, use ``notepad``) and:

- Replace all occurrences of 'a:' with the correct drive on the auxiliary server.
- Replace all occurrences of 't:' with the correct drive on the target server.
- Replace all occurrences of 'A_DB' with the name of the auxiliary database.
- Replace all occurrences of 'T_DB' with the name of the target database.

Connect to ``RMAN`` using a password for both the target and auxiliary
databases. There must also be a ``tnsnames.ora`` alias used for the
auxiliary database. For best results, use one on both databases:

..  code-block:: batch

    rman target sys/password@T_DB auxiliary sys/password@A_DB

..  code-block::

    # Clone A_DB from T_DB using RMAN.

    run {
        allocate auxiliary channel x1 device type DISK;
        allocate auxiliary channel x2 device type DISK;
        allocate auxiliary channel x3 device type DISK;
        allocate channel d1 device type DISK;
        allocate channel d2 device type DISK;
        allocate channel d3 device type DISK;
        allocate channel d4 device type DISK;
        allocate channel d5 device type DISK;

        duplicate target database to A_DB
        from active database
        spfile
        parameter_value_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
        set instance_name 'A_DB'
        set service_names 'A_DB'
        set dispatchers '(PROTOCOL=TCP) (SERVICE=A_DBXDB)'
        set audit_file_dest 'C:\ORACLEDATABASE\ADMIN\A_DB\ADUMP'
        set db_recovery_file_dest 'a:\mnt\fast_recovery_area'
        set dg_broker_start 'false'
        set control_files
            'a:\mnt\oradata\A_DB\control01.ctl',
            'a:\mnt\fast_recovery_area\A_DB\control02.ctl'
        set db_file_name_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
        set log_file_name_convert
            't:\mnt\oradata\T_DB',
            'a:\mnt\oradata\A_DB',
            't:\mnt\fast_recovery_area\T_DB',
            'a:\mnt\fast_recovery_area\A_DB'
        nofilenamecheck;

        release channel x1;
        release channel x2;
        release channel x3;
        release channel d1;
        release channel d2;
        release channel d3;
        release channel d4;
        release channel d5;
    }


Post Clone Tidy Up and Checks
=============================

After the clone has finished it is wise to make sure everything is in
order. Cloning a database in this manner will, *can* sometimes leave parameters 
with their T_DB settings as opposed to the desired A_DB settings.

Block Change Tracking
---------------------

The first step is to fix the block change tracking problem. You *may* have
seen a message similar to the following:

..  code-block:: sql

    ORA-19750: change tracking file:
    'a:\mnt\fast_recovery_area\A_DB\bct.dbf'

    ORA-27040: file create error, unable to create file
    OSD-04002: unable to open file
    O/S-Error: (OS 3) The system cannot find the path specified.

However, it is not always the case that a message is produced, so, execute the following on A_DB, replacing 'a:\\' with the correct drive letter:

..  code-block:: sql

    select status, filename 
    from v$block_change_tracking;

If the filename and status show the correct paths - to the FRA for A_DB, and ``ENABLED``, then all is well. Otherwise:    

..  code-block:: sql

    alter database enable block change tracking
    using file 'a:\mnt\fast_recovery_area\A_DB\bct.dbf';

    
Database Parameters
-------------------

The following SQL can be used on the clone database to identify
initialisation parameters that may need adjusting. Replace T_DB 
with the target database name in upper case, before running the 
query:

..  code-block:: sql

    select name, value
    from v$parameter
    where upper(value) like '%T_DB%'
    and lower(name) not like '%file_name_convert';

The results *might* look as follows:

..  code-block::

    dispatchers
    (PROTOCOL=TCP) (SERVICE=T_DBXDB)

    instance_name
    T_DB

    service_names
    T_DB

To resolve the issues identified above, run the appropriate SQL from the following
depending on which parameter(s) need amending, Replace all occurrences of A_DB as necessary:

..  code-block:: sql

    alter system set instance_name='A_DB' scope=spfile;
    
    alter system set service_names='A_DB' scope=spfile;

    alter system set audit_file_dest =
    'C:\ORACLEDATABASE\ADMIN\A_DB\ADUMP' scope = spfile;

    alter system set dispatchers=
    '(PROTOCOL=TCP) (SERVICE=A_DBXDB)' scope=spfile;

If there were any changes made, the database must be restarted. However, before restarting it, consider 
if the database is to continue to run in ARCHIVELOG mode or not. 

If the database *is* to continue in ``ARCHIVELOG`` mode, then simply restart it to fix the amended parameters:

..  code-block:: sql

    alter database flashback on;
    startup force

If, on the other hand, the database is to be run in ``NOARCHIVELOG`` mode, then:

..  code-block:: sql

    startup force mount
    alter database flashback off;
    alter database noarchivelog;
    alter database open;

Then check the parameters again with the above query, until there are ``no rows
selected``.


Database Roles
--------------

For *non-production databases only*, two roles will now require to be updated as their password is dependent on the database name, so they currently have the password of the originating database:

..  code-block:: sql

    column db_name new_value my_dbname noprint;
    select name as db_name from v$database;
    
    alter role NORMAL_USER identified by &&my_dbname.123;
    alter role SVC_AURA_SERV_ROLE identified by &&my_dbname.123;

Scheduler Jobs
--------------

Check that all FCS jobs running under dba\_scheduler\_jobs are disabled:

..  code-block:: sql

    select owner, enabled, job_name
    from dba_scheduler_jobs
    where enabled = 'TRUE'
    and owner not in ('SYS','SYSTEM','SYSMAN','ORACLE_OCM','EXFSYS')
    order by owner,job_name;

For all non-production databases, there should be no jobs owned by FCS in
the listing. If there are, they must be disabled:

..  code-block:: sql

    dbms_scheduler.disable(name => 'whatever');
    
Where ``whatever`` is the enabled job name that you wish to disable.    


Clone Configuration
-------------------

After cloning any non-production *depersonalised* databases, we must run
the following script – you may ignore any errors relating to dropping of
objects. The script in question *must be run as the FCS user*, and is
located in TFS at:

$/TA/MAIN/Source/UKRegulated/Database/Depersonalisation/Depers & Shrink/8\_uat\_config.sql

..  code-block:: sql

    connect fcs/password
    @8_uat_config.sql

There are also various user creation scripts which can be found in TFS
at location:

$/TA/MAIN/Non Source/Dev DBA/Database Release/control\_script/Create\_UV\_Users/Main

The controlling script is named execute.sql and this *must* be edited
prior to *running as the FCS user*. Only one line needs to be changed:

..  code-block:: sql

    PK_ACCESS_SETUP.UPDATE_ACCESS('???');

Replace '???' in the above with one of the other values listed in the file
itself. The value depends on the "type" of the database. Currently, valid values are:

+----+---------------------------+
|Code|Database Type              |
+====+===========================+
|TRG |Training                   |
+----+---------------------------+
|DEV |Development                |
+----+---------------------------+
|ST  |System Test or Integration |
+----+---------------------------+
|SIT |UAT                        |
+----+---------------------------+

Save the file, and run the code:

..  code-block:: sql

    sqlplus fcs/password 
    @execute.sql

If you mistakenly run the code as SYS, then the fix is to carry out the 
following while logged in as SYS:

..  code-block:: sql

    drop package pk_access_setup;

    connect FCS/password

    @pk_access_setup_pks.sql
    @pk_access_setup_pkb.sql

    declare
        vout varchar2(100);

    begin
        -- CHANGE '???' to a valid option as above.
        PK_ACCESS_SETUP.UPDATE_ACCESS('???');
    end;
    /

    DROP PACKAGE pk_access_setup;


Register Database for RMAN Backups
==================================

If the databases are to be backed up using RMAN, then they must be
registered with the RMAN catalog.

**Note**: The alias ``rmancatsrv`` should be defined in the ``tnsnames.ora`` file on this server
to connect to the appropriate RMAN catalog database. This alias is common across (Azure) servers
but obviously points to a different database on production, from that on pre-production etc.

..  code-block:: batch

    oraenv A_DB
    rman target sys/password catalog rman11g/password@rmancatsrv

..  code-block::
    
    register database;

    run {
        configure controlfile autobackup on;
        configure backup optimization on;
        configure retention policy to recovery window of 7 days;
        configure archivelog deletion policy to backed up 2 times to disk;
    }

    show all;

    exit

Obviously, you would set the appropriate retention periods etc and not just
blindly follow the values used above!


Control Files Workaround
========================

As mentioned above, the ``PARAMETER_VALUE_CONVERT`` parameter in the
duplicate command *should* have renamed the control files appropriately
for the cloned database, however, it does not. 

Without using the
``set control_files`` parameter in the rman cloning commands, the target database's
directory structure was cloned onto the auxiliary server, using the target database's name 
in the paths. Not good.

This meant that there needed to exist, a structure as follows, on the auxiliary server:

..  code-block::

    t:\mnt\oradata\T_DB
    t:\mnt\fast_recover_area\T_DB

When what we really wanted was the following:

..  code-block::

    a:\mnt\oradata\A_DB
    a:\mnt\fast_recover_area\A_DB

To fix the database and put the controlfiles into the correct location,
follow the following steps, replacing 'a:\\' and 'A_DB' as appropriate
for the auxiliary server and database:


..  code-block:: sql

    oraenv A_DB
    
    sqlplus sys/password as sysdba
    
    shutdown immediate
    startup nomount
    
    alter system set control_files=
    'a:\mnt\oradata\A_DB\control01.ctl'.
    'a:\mnt\fast_recover_area\A_DB\control02.ctl' 
    scope = spfile;

    shutdown;

-  In the operating system, after the database *has fully shutdown*,
   copy the current control files to the locations and names noted
   above.

-  STARTUP

The control files should now be in the correct place as desired and the
ones named after the target database's locations can be deleted from
the *auxiliary server*\ !
