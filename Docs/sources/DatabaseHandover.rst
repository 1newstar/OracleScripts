=======================
Azure Database Handover
=======================

Abstract
========

This document describes, hopefully, everything a Capita DBA will need to know, or be aware of, in order to maintain the production and pre-production databases on the Azure Platform. 

At the time of writing, this is based on the Windows Server 2012 Operating System, and Oracle 11.2.0.4 database software. All Oracle databases are at this version in Azure, and there is a single Oracle Home on each server.


Security Considerations
=======================

In Unix, for security and auditing purposes, the normal manner of operation would be to:

-	login to the server as "your name";
-	``su - oracle``
-	startup/stop/maintain databases.

In Windows, the ``su`` command is absent, so we have to do things in a slightly different manner:

-	login to the server as "your name";
-	SHIT + RIGHT-CLICK on the batch file you want to use;
-	Select "run as a different user";
-   Enter:
    -	Username: ``casfs\svc_oracleprod`` for production, or, ``casfs\svc_oracleppd`` for pre-production;
    -	Password: as appropriate for the username

It's a pain to work with, but is an apparent necessity for auditing purposes.

You should be aware that *all* the services for oracle database 'stuff' run under one or the other users, and any jobs or tasks that you may set up on the servers will have to run under those users too. RMAN, for example.

There are two folders, ``c:\scripts`` and ``c:\scripts\RMAN``, which are on the path for the above users. This is the best place to put scripts etc that need to be run.


Oracle Administration Assistant
===============================

This is a *hard to find* utility which allows you to configure how a database will start and stop, in a manner better than ``oradim`` does. We need to use this to:

-	Disable automatic startup of the database when the service is started. We need this as we do not want any database with a standby to ``OPEN`` when the server or service is restarted as this will seriously mess up the primary and standby if both are ``OPEN`` at the same time.
-	Enable the databases that do not have standbys to ``OPEN`` automatically when the server and/or service is restarted. This means that test, UAT etc databases are online with the server and the DBAs don't have to manually start them.

The process is:

-	Right-click the start button;
-	Select Search;
-	Type, on the far right, "Administration". The default selection will be "Administration Assistant for Windows".
-	Right-Click and select "Run as administrator". Confirm your desires.

When the utility starts:

-	Open "Oracle Managed Objects";
-	Open "Computers";
-	Open your computer name;
-	Open "Databases";

For each database you wish to amend:

-	Right-click the database name;
-	Select "Startup/Shutdown options";

-   On the "Oracle Instance" tab:
    -	Make sure that "Startup instance ..." is:    
        -	unchecked for standby enabled databases;
        -	checked for stand alone databases.        
    -	Make sure "shut down instance ..." is checked;
    -	Make sure "immediate" is checked.
    -	Click Apply.
   
-	On the "Oracle NT Service" tab:

    -	Set the service startup as desired. Automatic is fine for all databases.
    -	Make sure that "This account" is selected.
    -	Make sure that the credentials for ``svc_oracleprod`` or ``svc_oracleppd`` are entered.
    -	Click Apply.
    -	Click OK.

**Note** It appears that setting the service to automatic startup *does not stick*. The service appears to always remain in manual startup. You may have to use the ``services`` utility to make the services automatic.


Software Install Kits
=====================

**Where:**

Install kits can be found, all 7 of the 11g "discs", on ``c:\installs``. They are all zip files.

**Version:**

All databases are using Oracle version 11.2.0.4. Currently, no service packs etc have been applied. Everything is "as per release kit".

**Oracle Base:**

Oracle Base is defined in the registry as ``c:\OracleDatabase``. See ``HKLM\software\oracle\KEY_OraDb11g_home1\ORACLE_BASE``.

**Oracle Home:**

All databases currently use the same Oracle Home, ``c:\OracleDatabase\product\11.2.0\dbhome_1``.


Setting Oracle Environment
==========================

Oraenv
------

Windows has no concept of the ``oraenv`` utility, so we have to do it manually. (See below for a useful script that pretty much emulates ``oraenv`` as found on Unix systems.)

..	code-block:: batch

    set oracle_sid=whatever
    set oracle_home=c:\OracleDatabase\product\11.2.0\dbhome_1
    set path=%oracle_home%;%path%
    set nls_lang=american_america.we8iso8859p1
    set nls_date_format=dd/mm/yyyy hh24:mi:ss

You should beware of the last one though, if you are importing the NOROWS import for a 9i database to 11g, or even from 11g to 11g using expdp/impdp then setting the date format to anything can lead to "invalid date" errors because a table has been set up with a default for a DATE column, and the default is a string which is incompatible with many of the valid settings for ``NLS_DATE_FORMAT``. (The developer didn't use ``TO_DATE()`` in the default, just the string literal.

If you are importing, it's best to:

..	code-block:: batch

    set nls_date_format=

To be sure that it's safe.


Oracle Inventory
----------------

The Oracle Inventory location is specified in the register, at ``HKLM\software\oracle\inst_loc`` and defaults to ``c:\Program Files\Oracle\Inventory``.

If you have administrator rights on the server, and you should have, use ``regedit`` to access the registry settings, if required.


Useful Scripts
==============

I've created a few potentially useful utility scripts to make life under Windows a little easier for the Unix aficionados among us. They are all to be found in ``c:\scripts`` and are as follows:


Oraenv script
-------------

This can be run, in batch files or shell sessions, as follows:

..	code-block:: batch

    oraenv <required_database>

For example:

..	code-block:: batch

    oraenv ppdcfg

This will set the required environment. Note that ``NLS_DATE_FORMAT`` will be set by this script. If you are importing into a UV database, best redefine it as above. There's a DATE column which has a default value defined as a VARCHAR2, and the format of that is incompatible with 'dd/mm/yy hh24:mi:ss'. They should have used a TO_DATE(), but sadly, didn't.

The ``oraenv.cmd`` is dependent on some helper programs:

-   DBHome.exe - Extracts the ``%ORACLE_HOME%`` for the supplied %ORACLE_SID% from the ``oratab`` file.
-   DBPath.exe - Removes the existing ``%ORACLE_HOME%\*`` folders from ``%PATH%`` prior to adding the new ``%ORACLE_HOME%\bin`` folder to the path - if the ``%ORACLE_HOME%`` has changed.
-   TidyPath.exe - Required as defining ``%PATH%`` in Control Panel, as opposed to on the command line, allows folder paths which have spaces or other special characters, to be defined without double quotes. This fails when setting ``%PATH%`` in a batch file! This utility makes sure that all paths that need to be, are quoted correctly.

And also on an ``oratab`` file, looked for in the following locations, in order of preference:

-   ``%ORATAB%`` - the full path and filename of the file to be used.
-   ``%ORACLE_BASE%\oratab.txt`` - If %ORACLE_BASE% is defined.
-   ``c:\scripts\oratab.txt`` - in the same folder as the ``oraenv.cmd`` executable. This is the default at the time of writing. (Although I would prefer defining an ``%ORATAB%`` environment variable pointing to a separate location myself!)

Running ``oraenv`` also looks for and uses the ``%ORAENV_ASK%`` environment variable, as follows:

-   ``%ORAENV_ASK%`` = YES:
    -	Will prompt for a valid ``%ORACLE_SID%`` if none supplied when calling ``oraenv``.
    
-   ``%ORAENV_ASK%`` = NO:
    -	Will not prompt for a valid ``%ORACLE_SID%`` if none supplied when calling ``oraenv`` but will simply display the current oracle environment.
    
    
    
OraRunning Script
-----------------

On Unix the command:

..  code-block:: bash

    ps -ef|grep -i pmon

is extremely handy for seeing which databases are up and which are missing. On Windows, we have similar usefulness. We have to do this:

..  code-block:: batch

    net start | find /i "OracleService" 

Which is far too much typing on a daily basis. I've created a script called ``OraRunning`` to do the above.

..	code-block:: batch

    @echo off
    rem Lists all the service that are for an Oracle database
    rem and which are currently running. 
    rem
    rem NOTE: This doesn't mean that the databases are up
    rem only that the services are. It is possible for a
    rem service to be running and the database not yet started.
    rem
    rem Norman Dunbar 1 September 2016.
    rem
    echo The following database services are running:
    echo.
    net start | find /i "OracleService" | sort
    echo.
    echo NOTE: The databases themselves might need to be started.
    echo.

    rem There's a pause in case someone double-clicks in Explorer.
    pause

Just call the script as follows:

..  code-block:: batch

    orarunning

And the list of running services will be displayed. You can also double-click the file in Windows File Explorer - as it pauses before exiting, to let you see what's on the screen.

Be aware, however, that just because a service is running, the database may still need to be started in the normal manner. For example:

..  code-block:: batch

    c:\> oraenv ppdcfg

    Environment set as follows:
    ORACLE_HOME=C:\OracleDatabase\product\11.2.0\dbhome_1
    ORACLE_SID=ppdcfg
    NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss
    nls_lang=AMERICAN_AMERICA.WE8ISO8859P1

    c:\> orarunning

    The following database services are running:

        OracleServicePPDCFG
        OracleServicePPDRMN

    NOTE: The databases themselves might need to be started.
    Press any key to continue . . .

    c:\> sqlplus sys/<password> as sysdba

    ...
    Connected to an idle instance.

    SQL> startup [mount]

And so on.


MyPath Utility
--------------

Handy utility to display the current setting of ``%PATH%`` but with each separate folder path on a new line, this makes it far easier to read, and helps identify duplicates.

..  code-block:: batch

    mypath
    
This would result is something resembling the following:

..  code-block:: none

    C:\OracleDatabase\product\11.2.0\dbhome_1\bin;
    C:\Windows\system32;
    C:\Windows;
    C:\Windows\System32\Wbem;
    C:\Windows\System32\WindowsPowerShell\v1.0\;
    c:\users\ndunbar\utilities;
    c:\scripts;
    c:\scripts\rman;


HexDump Utility
---------------	  

A somewhat useful utility to dump out a file in hex.

..  code-block:: batch

    hexdump file_name [start] [length]
    
-	 Start defaults to 0 and means the beginning of the file.
-	 Length defaults to the full length of the file, or from start until the end.

The output format is quite simple:

..  code-block:: none

    000040  BA10000E 1FB409CD 21B8014C CD219090  ........!..L.!..
    000050  54686973 2070726F 6772616D 206D7573  This program mus
    000060  74206265 2072756E 20756E64 65722057  t be run under W
    000070  696E3332 0D0A2437 00000000 00000000  in32..$7........

And so on.

    
RMAN Backup Scripts
-------------------

The following RMAN backup scripts are described below:

- BackupDatabase.cmd
- RMAN_backup.cmd
- RMAN_cold_backup.cmd


Listeners
=========

There is a single listener, named ``LISTENER``, per server. The port number is the default, 1521, and databases register dynamically with the listener on startup (``OPEN`` mode only though - beware).

Databases which *can be run* as a standby are given a static entry in the listener.ora as standby databases don't ``OPEN`` so will not auto-register with the listener, so basically cannot work as a standby because the primary won't be able to find it.

Databases which are under the control of Data Guard have an additional static entry, ``<DB_UNIQUE_NAME>_DGMGRL``, so that the Data Guard broker can access them in order to carry out switchover, failovers and to check log transport and apply gaps.

The usual ``lsnrctl`` commands work fine on windows but note that start, stop, reload etc require a DOS session with administrator rights. The only alternative is to search for "services" and run the commands form the services utility - which is a *monumental pain*.

The listeners run as a Windows service, and are configured to start automatically with the servers. The service name is ``OracleOraDb11g_home1TNSListener`` and can be started and stopped using the ``net stop`` and ``net start`` commands, as well as the ``lsnrctl start`` and ``lsnrctl stop`` ones.


Log Files
---------

Listener.log files can be found in ``%ORACLE_BASE%\diag\tnslsnr\<SERVER_NAME>\listener\trace``.


Servers
=======

Production Servers
------------------

-	uvorc01 - Primary production server.
-	uvorc02 - Standby production server.
-	druvorc03 - DR production server.

On the servers above, the oracle user is ``svc_oracleprod``.


Pre-Production Servers
----------------------

-	ppduvorc01 - Primary production server.
-	ppduvorc02 - Standby production server.

There isn't a DR server in the pre-production environment.

On the servers above, the oracle user is ``svc_oracleppd``.


Databases
=========


Alert Files
-----------

Alert.log files can be found in ``%ORACLE_BASE%\diag\rdbms\<DB_NAME>\<DB_UNIQUE_NAME>\trace``.


Diagnostic & Trace files
------------------------

Trace files can be found in ``%ORACLE_BASE%\diag\rdbms\<DB_NAME>\<DB_UNIQUE_NAME>\trace``.

Production Databases
--------------------

-	CFG - Primary production database.
-	CFGSB - Standby production database.
-	CFGDR - DR standby production database.
-	CFGAUDIT - Primary Audit database.
-	CFGAUDSB - Standby audit database.
-	CFGAUDDR - DR Audit database.
-	CFGRMN - Primary RMAN catalog database.
-	CFGRMNSB - Standby RMAN catalog database.
-	CFGRMNDR - DR standby RMAN catalog database.


Pre-Production Databases
------------------------

-	PPDCFG - Primary pre-production database.
-	PPDCFGSB - Standby pre-production database.
-	PPDRMN - Primary pre-production RMAN catalog database.
-	PPDRMNSB - Standby pre-production RMAN catalog database.

DevOps Databases
----------------

-	AZSTG01 - Partially depersonalised staging database used to create further UAT etc databases where full depersonalisation is not able to be utilised. This is also used as a destination database when testing the RMAN backups of the production database for restorability.
-	AZSTG01 - Fully depersonalised staging database used to create further DEV etc databases where access to personal data is not permitted.
-   CFGDEMO - Used by DevOps to test deployments.

Other Databases
---------------

-   AZFS1nn - Development Databases. Users have full control via the FCS account, which has full DBA rights granted. We are not responsible for these databases, other than making sure that they are up and running on request.
-   AZFS2nn - Release databases - whatever "release" is taken to mean. Used for UAT etc. We are responsible for these as the users do not have the FCS account credentials.
-   AZTRNnn - Training databases. Again, we are responsible for these as the users do not have the FCS account credentials.


Startup/Shutdown
----------------

Those databases that have a standby configured are set up, with ``oradim``, *not to start automatically* after a server reboot. This is a necessity (in the lack of Oracle Restart, Grid Infrastructure, HA and/or ``/etc/oratab``) to prevent the standby databases coming up in ``OPEN``, mode after a server restart, as there is no way to force a database to only come up to ``MOUNT`` after a restart.

We do not want the standby databases coming up in ``OPEN`` mode, as that would be a bad thing indeed, for two reasons, application connections could go to either of the ``OPEN`` databases rather than just the PRIMARY, but more expensively, ``OPEN``\ ing the standby activates Real Time Query which is an additional licence and involves extra costs!

This configuration applies to the primary, standby and DR servers - where present - as any one of these could run as primary or standby.


Starting Services
~~~~~~~~~~~~~~~~~

Services are started thus:

..	code-block:: batch

    net start OracleService<db_unique_name>

For example:

..	code-block:: batch

    net start OracleServicePPDCFG

Alternatively, you may use the Windows services utility to stop and start the Oracle services. This doesn't require administrator rights. Be aware that this method of starting will ``OPEN`` the database. The ``oradim`` utility can be used to start up the service and database with a different open mode if desired.


Stopping Services
~~~~~~~~~~~~~~~~~

Stopping a service will stop the database. The database will be closed in a manner that is configurable with ``oradim`` or the Administrative Assistant for Windows utility as supplied by Oracle. Our databases are configured to shutdown ``IMMEDIATE``. However, it is best practice to close the database before stopping it with the service, just in case.

Services are stopped thus:

..	code-block:: batch

    sqlplus sys/password@database as sysdba
    shutdown immediate
    exit

    net stop OracleService<db_unique_name>

For example:

..	code-block:: batch

    ...
    net stop OracleServicePPDCFG

Alternatively, you may use the Windows services utility to stop and start the Oracle services. This doesn't require administrator rights.


SQLNET.ORA
==========

Because of some foible in the application(s) it is not possible, on Windows, to have ``sqlnet.ora`` set up to allow DBAs to ``connect / as sysdba``. The connection has to be ``connect sys/password as sysdba`` when starting or stopping.

**Do not** use ``connect sys/password@database as sysdba`` when starting or restarting the database, it will not work. The shutdown will, but the startup won't be able to do anything as the database is no longer registered with the listener, so it cannot reconnect prior to starting the database.

The ``sqlnet.ora`` file must resemble the following in order for the applications to work correctly:

..	code-block:: none

    # This file is actually generated by netca. But if customers choose to 
    # install "Software Only", this file won't exist and without the native 
    # authentication, they will not be able to connect to the database on NT.

    ## This should prevent connections being dropped
    ## if not used for a while. It sends a probe
    ## to check for dead connections every 'n' minutes.
    ## Restart the listener if you change it.
    SQLNET.EXPIRE_TIME = 10

    ## You need this one to start the databases with "/ as sysdba"
    ## Or to run the dbRefresh.cmd script to refresh a database.
    ## Or to run an RMAN backup.
    #SQLNET.AUTHENTICATION_SERVICES = (NTS)

    ## You need this one for normal running.
    SQLNET.AUTHENTICATION_SERVICES = (NONE)
    
    
The final line is the required setting for normal running.

This of course, prevents DBAs from connecting to anything, or running RMAN with only the '/ [as sysdba]' option, which means that the various scripts to backup the databases etc, require a SYS password to be passed. This implies that when the SYS password is changed, scripts and scheduler tasks will need updating.


TNSNAMES.ORA
============

    **Note:** Any changes made to the ``tnsnames.ora`` file on a server, must be propagated to the others in that group of Production or Pre-production servers and to the central ``tnsnames.ora`` which is located at ``\CFSLDSFP01\Apps.Net\Aura\TNSNAMES_CENTRE\``.

    **Warning:** Do not copy the ``tnsnames.ora`` from production to pre-production, or vice versa, when changes are made. The ``rmancatsrv`` alias is *different* in production and pre-production. Do not get them confused.

Because there are standby and DR databases configured, there are changes in the ``tnsnames.ora`` file to cope with this, regardless of which actual instance is running the database at any given point in time.

All connections must now use the ``SERVICE_NAME`` clause in the ``CONNECT_DATA`` section, and not the old ``SID`` clause. The default service name for a database is the ``SID``, however, other service names can be added via the ``SERVICE_NAMES`` database initialisation parameter, or simply by starting a service on that particular database.

See "Data Guard Switchover/Failover" below for details.

In addition to the service names, however, you can still connect to the individual databases using their default service names, set up as tns aliases, as per the following example for the production database. The other databases are similar:

..	code-block:: none

    CFG =
      (DESCRIPTION =
        (ADDRESS = (PROTOCOL = TCP)(HOST = uvorc01.casfs.co.uk)(PORT = 1521))
        (CONNECT_DATA =
          (SERVER = DEDICATED)
          (SERVICE_NAME = CFG)
        )
      )


    CFGSB =
      (DESCRIPTION =
        (ADDRESS = (PROTOCOL = TCP)(HOST = uvorc02.casfs.co.uk)(PORT = 1521))
        (CONNECT_DATA =
          (SERVER = DEDICATED)
          (SERVICE_NAME = CFGSB)
        )
      )


    CFGDR =
      (DESCRIPTION =
        (ADDRESS = (PROTOCOL = TCP)(HOST = druvorc03.casfs.co.uk)(PORT = 1521))
        (CONNECT_DATA =
          (SERVER = DEDICATED)
          (SERVICE_NAME = CFGDR)
        )
      )


    CFGSRV =
      (DESCRIPTION =
        (ADDRESS_LIST =
          (ADDRESS = (PROTOCOL = TCP)(HOST = uvorc01.casfs.co.uk)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = uvorc02.casfs.co.uk)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = druvorc03.casfs.co.uk)(PORT = 1521))
        )
        (CONNECT_DATA =
          (SERVER = DEDICATED)
          (SERVICE_NAME = CFGSRV)
        )
      )

Transparent Application failover is *not enabled* due to the minor fact that the application *probably* has not been written to cope with getting an error back from Oracle telling it to rollback and resubmit the last command.

In the event that the primary database is switched over, everyone will have to reconnect.

What is extremely annoying is the fact that any time the ``netca`` utility is used on a server, it mangles the ``tnsnames.ora`` file by reorganising the comments to the top of the file, and saving the file with the databases in a completely random order.


Data Guard Switchover/Failover
==============================

    **WARNING**: There appears to be a bug in Data Guard at 11.2.0.4. When a primary database with ``LOG_ARCHIVE_DEST_2`` and ``LOG_ARCHIVE_DEST_3`` is switched over to a standby, the settings for ``LOG_ARCHIVE_DEST_3`` are lost. These need to be reset after each switch over.
        
    We have logged an SR with Oracle on this matter.
    
    However, it turns out not to be a problem. We shouldn't really be setting up these parameters in the databases if we are using Data Guard. Data Guard knows which databases are the standby(s) at any time, and sets it's own parameters internally to suit.
    
    You can see those parameters with the command ``SHOW DATABASE whatever`` 

Only the primary running database starts the appropriate service, the standby database(s) physically stop it. This is done by way of the following trigger, owned by SYS:

..	code-block:: sql

    CREATE OR REPLACE TRIGGER SYS.cfgsrv_trigger
    after startup on database
    declare
        v_role V$DATABASE.DATABASE_ROLE%TYPE;

    begin
        --===================================================
        -- Make sure we only start the CFGSRV on this
        -- database if it is running as the primary database.
        --===================================================
        select  database_role
        into    v_role
        from    v$database;

        if (v_role = 'PRIMARY') then
            dbms_service.start_service('CFGSRV');
        else
            dbms_service.stop_service('CFGSRV');
        end if;
    end;
    /

We *attempt* to be consistent in the naming of services etc. In this example, the service is ``cfgsrv`` because the *primary database* is named CFG. So the service name is always, or at least, wherever possible, the primary database name plus 'srv'. The trigger name is therefore the service_name with '_trigger' tagged on.
    
    
The services currently in use are:

-	CFGSRV - Production database service.
-	CFGAUDSRV - Production Audit database service.
-	CFGRMNSRV - Production RMAN catalog database service.

And for pre-production, we have:

-	PPDCFGSRV - Pre-production database service.
-	PPDRMNSRV - Pre-production RMAN catalog database service.

And for the RMAN catalog use during backups, we have:

-   RMANCATSRV - In production, points to the CFGRMNSRV service.
-   RMANCATSRV - In pre-production, points to the PPDRMNSRV service.

The tns alias, *RMANCATSRV* in pre-production *and* production, as described, point to the appropriate RMAN catalog database service mentioned above, according to the server's production or otherwise status. For this reason, the ``TNSNAMES.ORA`` file is *different* in production and pre-production and they *should not* be mixed.

The *RMANCATSRV* service is used in the various RMAN backup scripts (found in ``c:\scripts\RMAN``) on both production and pre-production environments, and so the code in those scripts is identical regardless of the server it exists on. (And only one script is required in TFS too!)

Services are created and deleted by way of the DBMS\_SERVICE package.

**Note:** In the event of a switchover, it is required that the scheduled tasks, run under the Windows Task Scheduler, which carry out RMAN backups are:

-	Disabled on what was the *previously* running primary server; and
-	Enabled on the *currently* running primary server.


RMAN
====


Backup Drive
------------

The ``\\BACKMAN01\RMANBACKUP\`` drive has been setup as the main RMAN backup device. This is currently 3TB in size, but this will need to be monitored as normal running starts to take place. Especially as the retention period for the production database has been set to 7 years and a day! (2558).

    **Note** the backup location disc is not big enough to hold a full 7 years worth of backups, incremental or otherwise, so these will be archived off to tape from time to time (scheduled?). In the event that a really old database restore has to be done, they will need restoring to disc first. (Unless, the tape system has a library that RMAN can use of course!)

This drive is *not visible* in Windows File Explorer except to the various service users, it will not appear in Windows File Explorer unless you are logged in as the appropriate service user.

You can, however, map a network drive to ``Z:\``, for example, in your own user. The full path is ``\\BACKMAN01\RMANBACKUP``. This allows you to read and write to the drive, assuming Windows permissions allow of course.

RMAN *cannot* back up to the (mapped) ``Z:\`` drive for some reason. It can, however, backup to the full UNC path, so all format clauses in the RMAN backup scripts *must* use the full UNC path, rather than ``Z:\`` as the following example demonstrates:

..  code-block:: none

    RMAN> backup format '\\backman01\RMANBackup\backups\cfgrmn\test_%U%T' spfile;

    Starting backup at 2016/11/17 10:54:39
    ...
    channel ORA_DISK_1: starting piece 1 at 2016/11/17 10:54:40
    channel ORA_DISK_1: finished piece 1 at 2016/11/17 10:54:41
    piece handle=\\BACKMAN01\RMANBACKUP\BACKUPS\CFGRMN\TEST_3ERL4QJG_1_120161117 tag=TAG20161117T105440 comment=NONE
    channel ORA_DISK_1: backup set complete, elapsed time: 00:00:01
    Finished backup at 2016/11/17 10:54:41
    ...



    RMAN> backup format 'Z:\backups\cfgrmn\test_%U%T' spfile;

    Starting backup at 2016/11/17 10:55:05
    ...
    channel ORA_DISK_1: starting piece 1 at 2016/11/17 10:55:05
    RMAN-00571: ===========================================================
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00571: ===========================================================
    RMAN-03009: failure of backup command on ORA_DISK_1 channel at 11/17/2016 10:55:06
    ORA-19504: failed to create file "Z:\BACKUPS\CFGRMN\TEST_3GRL4QK9_1_120161117"
    ORA-27040: file create error, unable to create file
    OSD-04002: unable to open file
    O/S-Error: (OS 3) The system cannot find the path specified.
    ...

    
Configuration
-------------

The following configuration has been set up so far, you may reconfigure as desired after handover. Any parameters not mentioned below are currently left as per the default.


CFG
---

..	code-block:: none

    RMAN configuration parameters for database with db_unique_name CFG are:
    CONFIGURE RETENTION POLICY TO REDUNDANCY 2558;
    CONFIGURE BACKUP OPTIMIZATION ON;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO     '\\backman01\RMANBackup\backups\cfg\autobackup\%F';
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

    **Note** the location of the autobackup of the controlfile is subject to change as and when the backup devices, aka the ``Z:\`` drive, are fully up and working.

    **Note** *All* the primary databases have the archivelog deletion policy set as shown above, and *all* the standby databases have 'CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY' instead as we don't backup from the standby databases - unless they are running as primary of course. This parameter will require changing when we perform a switchover.


CFGAUDIT
--------

..	code-block:: none

    RMAN configuration parameters for database with db_unique_name CFGAUDIT are:
    CONFIGURE RETENTION POLICY TO REDUNDANCY 2558;
    CONFIGURE BACKUP OPTIMIZATION ON;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '\\backman01\RMANBackup\backups\cfgaudit\autobackup\%F';
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

    
CFGRMN
------

..	code-block:: none

    RMAN configuration parameters for database with db_unique_name CFGRMN are:
    CONFIGURE RETENTION POLICY TO REDUNDANCY 31;
    CONFIGURE BACKUP OPTIMIZATION ON;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
        CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '\\backman01\RMANBackup\backups\cfgrmn\autobackup\%F';
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

    
PPDCFG
------

..	code-block:: none

    RMAN configuration parameters for database with db_unique_name PPDCFG are:
    CONFIGURE RETENTION POLICY TO REDUNDANCY 10;
    CONFIGURE BACKUP OPTIMIZATION ON;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

    
PPDRMN
------

..	code-block:: none

    RMAN configuration parameters for database with db_unique_name PPDRMN are:
    CONFIGURE RETENTION POLICY TO REDUNDANCY 10;
    CONFIGURE BACKUP OPTIMIZATION ON;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY BACKED UP 2 TIMES TO DISK;

    
Catalogs
--------

As mentioned above, there are two main RMAN catalog databases. These are accessed via the following TNS alias names:

-	CFGRMNSRV & RMANCATSRV - the production RMAN catalog service;
-	PPDRMNSRV & RMANCATSRV - the pre-production RMAN catalog service.

There is an alias, as you will note from the above, ``RMANCATSRV``, on both production and pre-production servers which connects to the appropriate RMAN catalog on that server's type, regardless. This is used by the scripts to avoid having to have different scripts on each server type.

Both databases have the same catalog username - ``rman11g`` and the password is currently ``rman11gcatalog`` but this could/should/will be changed after handover - and the various backup scripts amended to suit. 

    **Note**\ :At present, there is also a separate ``RMAN`` catalog database on ``ORCDEVORC03``, named ``AZRMN01`` and this is only used for backups on the test/UAT servers, if applicable. This server is being decommissioned so this database may not exist when you read this document.


Daily Backups
-------------

    **Note**: Due to *foibles* in the way that the application needs certain settings within ``sqlnet.ora`` to be set, we must always login to the databases with a username and password. This includes running backups etc. To this end, the SYS password on the databases, if changed, **must be reflected** in the settings used to carry out a backup in the  Windows Task Scheduler.

Daily backups are configured to take place 7 days a week, with a level 0 incremental backup taking place on Sunday. Every other day of the week will carry out an incremental level 1 backup.

This is slightly different from the old 9i regime where levels 2 through 4 existed in RMAN, but as these are no longer provided at 11g, the choice is level 0 or level 1 only.

    **Beware**: The backup location is always to the supplied path with the oracle sid for the database being used in the path:  ``\\BACKMAN01\RMANBackup\backups\%ORACLE_SID%`` - this means that if we backup the standby database, the files will be written to the ``xxxSB`` folder as opposed to `xxx` according to the database name.

Craig has a diagram of the RMAN backup environment, but in summary:

-	RMAN backs up the database to a specific drive. This is mapped on all
   servers as the same disk, ``\\BACKMAN01\RMANBackup\``, but only within 
   the service user's account by
   default, so there's no problem if we switch from backing up the
   primary to backing up the standby, or the DR databases.
-	The backups are kept on disc for two months. (This may be subject to
   change).
-	Backups older than two months are copied to a backup vault. This
   takes place on a separate server so as to reduce impact on production
   servers.
-	They are not, *under any circumstances*, deleted or obsoleted in
   RMAN. RMAN continues to "think" that they are available.
-	These vaulted database backups, including archived logs, are kept for
   as long as is legally required. (Currently 7 years.)

   
Production Schedule
-------------------

The backups of production are taken from the currently running primary database. The database sid (aka db_unique_name) must be passed by the scheduled task's action parameters to the ``BackupDatabase`` script that is used to carry out the backups.

Backups will be located in a folder with the primary database name - ``cfg``, ``cfgsb``, ``cfgdr`` etc, on the backup drive.

**CFG**

Windows scheduler tasks exist to carry out the following schedule.

+-----------+-----------------------+------------------+
| Weekday   | Backup Type           | Scheduled Time   |
+===========+=======================+==================+
| Sunday    | Incremental Level 0   | 03:00            |
+-----------+-----------------------+------------------+
| Mon-Sat   | Incremental Level 1   | 03:00            |
+-----------+-----------------------+------------------+

**CFGAUDIT**

Windows scheduler tasks exist to carry out the following schedule.

+-----------+-----------------------+------------------+
| Weekday   | Backup Type           | Scheduled Time   |
+===========+=======================+==================+
| Sunday    | Incremental Level 0   | 22:00            |
+-----------+-----------------------+------------------+
| Mon-Sat   | Incremental Level 1   | 22:00            |
+-----------+-----------------------+------------------+

**CFGRMN**

Windows scheduler tasks exist to carry out the following schedule.

+-----------+-----------------------+------------------+
| Weekday   | Backup Type           | Scheduled Time   |
+===========+=======================+==================+
| Sunday    | Incremental Level 0   | 01:00            |
+-----------+-----------------------+------------------+
| Mon-Sat   | Incremental Level 1   | 01:00            |
+-----------+-----------------------+------------------+


Pre-Production Schedule
-----------------------

Currently, the pre-production databases are not actually backed up daily. However, the following scheduled tasks have been set up using the Windows scheduler, but only the Sunday level 0 incremental backups have been enabled. The preproduction environment therefore only carries out a weekly backup.

**PPDCFG**

+-----------+-----------------------+------------------+
| Weekday   | Backup Type           | Scheduled Time   |
+===========+=======================+==================+
| Sunday    | Incremental Level 0   | 21:00            |
+-----------+-----------------------+------------------+
| Mon-Sat   | Incremental Level 1   | 21:00            |
+-----------+-----------------------+------------------+

**PPDRMN**

+-----------+-----------------------+------------------+
| Weekday   | Backup Type           | Scheduled Time   |
+===========+=======================+==================+
| Sunday    | Incremental Level 0   | 02:00            |
+-----------+-----------------------+------------------+
| Mon-Sat   | Incremental Level 1   | 02:00            |
+-----------+-----------------------+------------------+


Backup Scripts
--------------

As mentioned above, there are a number of useful backup scripts, located in the ``c:\scripts\RMAN`` folder, which can be used to backup databases.


BackupDatabase.cmd
^^^^^^^^^^^^^^^^^^

This script can be used to backup any database on the server. It is used by the Windows task scheduler to backup each and every database that is configured for regular scheduled backups. It is the command line for this script, that is called from within the Task Scheduler, that needs to have the SYS password changed if the database user's password is changed.

The script takes up to 4 parameters:

-	Database name - *mandatory*. The SID of the database to be backed up. For standby or DR databases, this must be the actual SID of the database, and not that of the (normal) primary database. So, ``cfgsb`` for example.
-	SYS password - *mandatory*. The SYS password for the database being
   backed up.
-	RMAN Level - *optional*. The incremental level for an RMAN backup.
   Defaults to 0. Allowed values are 0 or 1 only.
-	Backup Location - *optional*. Where the backups will be written to.
   Defaults to ``\\Backman01\RMANBackup\backups``. A folder for the
   database name will be created if necessary.

The script calls out to the ``oraenv.cmd`` script to set the required oracle environment and to the ``RMAN_backup.cmd`` (see below) to do the actual incremental backups, so the passed SID must exists in the ``oratab.txt`` file that is used by ``oraenv.cmd``.

This script is called from the Windows Task Scheduler and runs as the appropriate service user account, however, it can be run in your account if desired, to take a one-off backup.

**Note:** If you request a backup of any of the databases running under Data Guard, then the current primary will be backed up - regardless of which database is running as primary. For example, if a CFG backup is requested, but for some reason, we are running the CFGSB as the primary, then CFGSB will be backed up, not CFG.

If the database requested is not under Data Guard, then the specific database requested will be backed up.


RMAN\_backup.cmd
^^^^^^^^^^^^^^^^

This script backs up any database using an RMAN incremental level 0 or 1 backup. The level is passed on the command line as the only parameter. Some environment variables must be configured first and these are described below. For best and easiest usage, just use the BackupDatabase script above!

The environment variables that must be configured are:

-	ORACLE\_SID - the database to be backed up.
-	ORACLE\_HOME - The usual Oracle Home location.
-	BACKUP\_LOCATION - Where the backups will be written to. Need not
   exist.

The RMAN catalogue in use is ``rman11g@cfgrmnsrv`` on pre-production servers and ``rman11g@cfgrmnsrv`` on production servers. It was considered wise to set up a common RMAN alias in the tnsnames, on each server, to point at the appropriate catalog database to avoid problems of having to edit the script differently on each server – hence the two different catalog databases have the same service name in ``tns_names.ora``.

This script can also be used to backup the RMAN catalog database itself - it checks to see if this *is* a catalog backup, and if so, doesn't use a catalog.

Dump files are written to ``%BACKUP_LOCATION%\%ORACLE_SID%\`` and the output folder will be created if it doesn't already exist.

Logs for the backup are written to a folder named ``%BACKUP_LOCATION%\logs\%ORACLE_SID%`` and are date and time stamped to prevent overwriting of older, perhaps required, logs. Obviously this location will require regular housekeeping.

The script requires two mandatory parameters:

-	Level - which must be 0 or 1;
-	SYS\_PASSWORD - which is the SYS password for the database being
   backed up.

An example of its use is:

..	code-block:: batch

    c:\> cd c:\scripts\RMAN

    c:\> oraenv ppdcfg

    Environment set as follows:
    ORACLE_HOME=C:\OracleDatabase\product\11.2.0\dbhome_1
    ORACLE_SID=ppdcfg
    NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss
    nls_lang=AMERICAN_AMERICA.WE8ISO8859P1

    c:\> set backup_location=h:\backups

    c:\> rman_backup 0 <sys password>

    Logging RMAN output to logfile - h:\backups\logs\ppdcfg\RMAN_level_0.20170214-0923.log.
    Running level 0 script - scripts\RMAN_level_0.rman.
    Backup files will be written to - h:\backups\ppdcfg
    rman target sys/******* catalog rman11g\*******@ppdrmnsrv log h:\backups\logs\ppdcfg\RMAN_level_0. 20170214-0923.log cmdfile scripts\RMAN_level_0.rman 'h:\backups'

The RMAN log, located at ``h:\backups\logs\ppdcfg\RMAN_level_0.YYYYMMDD-HHMM.log`` has the output from the RMAN backup commands.


RMAN\_Cold\_backup.cmd
^^^^^^^^^^^^^^^^^^^^^^

This is similar to the ``RMAN_backup.cmd`` script, and requires the same parameters and/or environment variables setting. This script will shutdown the database cleanly, bring it back up in a ``MOUNT`` state, back it up and then, ``OPEN`` it for business use again after the backup is complete.


Test Restores
-------------

It is assumed that to prove the readability of the numerous backups that exist, that a DBA will regularly carry out a test restore onto a separate server, using the on-disc RMAN backups. This can be a RESTORE DATABASE & RECOVER DATABASE or a RESTORE VALIDATE from RMAN.

There is little point in taking regular backups if it is discovered that they are unusable when they are required - it's best to iron out problems prior to the emergency need for the backups.

A separate document exists in TFS, which outlines and explains the process of testing backups in this manner. The file is named ``RMANRestore.docx`` and can be found in TFS at: ``$TFS\TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation``.


CronJobs
========


What's now Running
------------------

Four definite "keepers" were determined on examination of the current cronjobs list from the Solaris server. These are:

-	Statsgen
-	Expire\_passwords
-	Endofday\_audit
-	Endofday\_utmsdrm

These have been rewritten as a package, owned by the SYS schema, named ``SOLARIS_CRONJOBS``.

Two schedules have been set up to run these at the desired times:

-	SUNDAY\_1800 - Used by statsgen.
-	DAILY\_2020 - Used by the remainder.

The names should indicate when the jobs are expected to run.


Where Are the Logs
------------------

The tasks above are run under the database scheduler. This means that they will be controlled by the database and will be backed up etc by RMAN as and when backups are taken.

Unfortunately, ``DBMS_OUTPUT`` data are lost when the jobs run under the scheduler, so logging tables have been created in SYS to log errors and/or messages from the most recent run of these jobs. The tables are truncated at the start of each job.

The tables in use are:

-	sys.statsgen\_errors
-	sys.expire\_password\_log
-	sys.utmsodrm\_errors

The table names should indicate which job they are used by. Any desired reports can be easily generated from these tables, perhaps using OEM to do so?


Password Changes
================

After handover, there will be a need for stronger security measures in the database. Some passwords have been set to a working password, and will require changing after handover. Obviously, existing processes for changing passwords of affected database links etc will need to be followed.

Password Vault
--------------

Passwords are (currently) stored, encrypted, in the KeePassX system. The master database lives at ``\\downloads\mnt\keepass\devopssecure.kdbx`` as well as locally on everyone's PC. Always remember to resynchronise KeePassX with this file to pick up other people's changes, and to make yours available too.

An Oracle Database Password Profile has been created within KeePassX to generate legal Oracle passwords of 20 characters, but it can create passwords with leading digits, which Oracle doesn't like. You can use this to generate new passwords. (Tools->Generate Password, choose the Oracle Database Password Format profile, click OK.)


SYS & SYSTEM
------------

The SYS and SYSTEM passwords on all databases will need changing on a regular basis.

**Note 1:** If you change the SYS password for a primary database, it is not propagated to the standby database(s). In this case, you *must* copy the password file from the primary to the standby database(s) and rename the file accordingly. That will carry out the necessary password change on the standby database(s).

**Note:** Any changes to the SYS password will require an edit of the various RMAN backup jobs configured in the Windows Task Scheduler. From Oracle 12c, however, there is a dedicated role set up to allow a user, not SYS, to be configured to run backups with RMAN. This is not yet possible in 11g.

Oracle Enterprise Manager
~~~~~~~~~~~~~~~~~~~~~~~~~

In OEM as the ``fs_dba`` account, change the ``monitoring credentials`` for the database(s) whenever the SYS password changes on the database - if the database is part of a primary-standby setup. If the database is standalone, the ``dbsnmp`` account will be used for monitoring.

-	 Go to ``setup``->``security``->``monitoring credentials``
-	 Select target type of ``Database Instance``
-	 Click ``Manage monitoring credentials``
-	 Select ``Monitoring Database Credentials`` in the drop down & click ``search``.
-	 Select the correct database and click ``set credentials``.
-	 Enter the new password twice and click ``test and save``.

DBSNMP
------

If the database is to be monitored by OEM, and if the database is a standalone one, then the DBSNMP account will need to be unlocked and have a secure password set. See above for details on setting up a monitoring password in OEM, change ``SYS`` to ``DBSNMP`` as appropriate.

CFGAUDIT
--------

The users in this database are:

- AUDITU. If this password is changed, change the database link CFGAUDIT_LINK@CFG to match.
- FCS. Unlikely to be connected to. Owns the tables, but updates are done via AUDITU and public synonyms.
- FCS_READ_ONLY.
- SYS - When this password is changed, the Windows Task Scheduler jobs that run the backups will need changing too.


CFG
---

The users in this database are:

- CMTEMP.
- FCS. When this password is changed, the database link CFGLIVE_LINK@CFSAUDIT will need changing to match.
- ITOPS.
- ONLOAD. (I suspect this is no longer required.)
- OEIC_RECALC.
- UVSCHEDULER. If this password is changed, the scheduler application, amongst others? will need to be changed to match.
- SYS - When this password is changed, the Windows Task Scheduler jobs that run the backups will need changing too.


CFGRMN
------

The users in this database are:

- RMAN11G. The catalog user. When the password is changed then the various RMAN backup scripts and ``dbClone.cmd``, in ``c:\scripts`` and ``c:\scripts\RMAN`` will require changing to suit.
- SYS - When this password is changed, the Windows Task Scheduler jobs that run the backups will need changing too.


PPDCFG
------

The users in this database are:

- CMTEMP.
- FCS.
- ITOPS.
- ONLOAD. (I suspect this is no longer required.)
- OEIC_RECALC.
- UVSCHEDULER. If this password is changed, the scheduler application, amongst others? will need to be changed to match.
- SYS - When this password is changed, the Windows Task Scheduler jobs that run the backups will need changing too.


PPDCFGRMN
---------

The users in this database are:

- RMAN11G. The catalog user. When the password is changed then the various RMAN backup scripts and ``dbClone.cmd``, in ``c:\scripts`` and ``c:\scripts\RMAN`` will require changing to suit.
- SYS - When this password is changed, the Windows Task Scheduler jobs that run the backups will need changing too.


Database Links
==============

There are a number of database links in various databases. At the time of migration to Azure, the following were known about:

CFG/CFGSB/CFGDR
---------------

- CFGAUDIT_LINK - connects to AUDITU@CFGAUDIT and is in use by the scheduled jobs to copy audit data from the production database to the audit database.
- CFGSB_LINK - connects to FCS@CFGSB, so it will not work. Currently has the incorrect password which was taken directly from 9i live, so it never worked there either. FCS cannot be used to connect to the standby database as it can only be connected to by SYSDBA users.
- CFGTRAIN_LINK - connects to FCS@CFGTRAIN. As there is no CFGTRAIN database, this link is going nowhere.


CFGAUDIT/CFGAUDSB/CFGAUDDR
--------------------------

CFGLIVE_LINK. Connects to FCS@CFG. Not working as it has the wrong password. It is not known what this link is for.


Windows Scheduler Tasks
=======================

A number of tasks have been created to allow regular scheduled backups of the various databases running in production and Pre-Production environments.


Production
----------

The following tasks have been set up in production.

-	**CFG\_Level\_0\_Sunday.xml** – backs up the production CFG database
   at 03:00 every Sunday by running a level 0 RMAN backup.
-	**CFG\_Level\_1\_Mon\_to\_Sat** – backs up the CFG production
   database at 03:00 every Monday through Saturday by running a level 1
   RMAN backup.
-	**CFGAUDIT\_Level\_0\_Sunday** – backs up the production CFGAUDIT
   database at 22:00 every Sunday by running a level 0 RMAN backup.
-	**CFGAUDIT\_Level\_1\_Mon\_to\_Sat** – backs up the production
   CFGAUDIT database at 22:00 every Monday through Saturday by running a
   level 1 RMAN backup.
-	**CFGRMN\_Level\_0\_Sunday** – backs up the production RMAN catalog
   database at 01:00 every Sunday by running a level 0 RMAN backup.
-	**CFGRMN\_Level\_1\_Mon\_to\_Sat** – backs up the production RMAN
   catalog database at 01:00 every Monday through Saturday by running a
   level 1 RMAN backup.

   
Pre-Production
--------------

The following tasks have been set up in production.

-	**PPDCFG\_Level\_0\_Sunday** - backs up the pre-production PPDCFG
   database at 21:00 every Sunday by running a level 0 RMAN backup.
-	**PPDCFG\_Level\_1\_Mon\_to\_Sat** - backs up the pre-production
   PPDCFG database at 21:00 every Monday through Saturday by running a
   level 1 RMAN backup.
-	**PPDRMN\_Level\_0\_Sunday** - backs up the pre-production RMAN
   catalog database at 02:00 every Sunday by running a level 0 RMAN
   backup.
-	**PPDRMN\_Level\_1\_Mon\_to\_Sat** - backs up the pre-production RMAN
   catalog database at 21:00 every Monday through Saturday by running a
   level 1 RMAN backup.

   
Killing Database Sessions
=========================

When a connection is made to the database, there are two sessions running, the first is the user process,
the other is a server process. You can find the process ID of the server process for a given
user process as follows:

..  code-block:: sql

    select  spid
    from    v$process
    where   addr = (select  paddr
                    from    v$session
                    where   sid = <your_sid>);
                    
The ``SID`` number is obviously the SID of the user session that is having difficulties. The returned value
on a Unix server, where things work properly, is the actual process ID of the server process. Sadly, on
Azure under Windows, the returned value is a *thread* id, not a process id.

If you kill a process id on Windows, you kill every thread running under it. Also, Task manager only shows
process ids, not thread ids, which is what we want.

To this end, in ``c:\scripts\ProcessExplorer``, on the database server, you will find a file named ``procexp64.exe`` 
which you should run as administrator. (Right-click, run as administrator).

Once running:

- Select view->show Process Tree, if necessary.
- Click on the ``process`` header in the tree that appears. You are sorting by the process name.
- Scroll down to ``oracle.exe`` there will be at least three, one for each database running.
- Hover over each in turn and check the hint that pops up, it will show the database name. Find the correct ``oracle.exe`` for the problem database.
- Double-click the correct ``oracle.exe`` process name.

In the pop-up that appears, go to the ``Threads`` tab. Click OK if you get a pop-up telling
you that something isn't as fully featured as it might need to be. Now:

- Click the ``TID`` column, to sort by thread id. You might need to do this twice to get the list in the order that you want. 
- Scroll down till you find the thread with the id identified by the SQL statement above.
- Click the thread to select it.
- Click the ``Kill`` button. The thread should vanish from the list.

That's the server process killed. The user process will still exist, possibly, in the database. So, back in the database:

- Find the session (in Toad I presume) in the Session Browser, and kill it there too.
- After a short delay, the session should vanish from the session list.
- Click refresh a couple of times to be sure.

If the database session does not vanish, even after a while, it could be a runaway session. We have seen these on 9i production and on 
11g production. The only solution is to bounce the database in this case, especially if the session is burning CPU etc.


Finding Rogue Database Sessions
===============================

It is possible that a rogue, or otherwise, session in the database can kill performance. How to determine the culprit? This is after you have determined that the problem isn't with locking of course.

-	 On the database server, open Task Manager.
-	 On the performance tab, click to open the Resource Monitor.
-	 Go to the Overview tab, and look at the "mini indicators" to see if the problem is CPU, Memory, Disc or Network - look for high percentages or similar. CPU is easiest to track down - information regarding the others is harder to come by.
-	 Click the appropriate tab, depending on the problem, and ensure that the Processes list is at the top.
-	 Sort the list by the appropriate column. ``Oracle.exe`` will no doubt appear at the top. Note the ``PID`` column for that process.

The ``oracle.exe`` process is the main database process, and all Windows connections are done via threads of this process. To get a database SID from a thread involves a little more work. Performance Monitor is no longer of any use. Move on ...

    **Note**: You *can* miss out the above if you open process explorer first. The mini performance graphs at the top of the screen will highlight the top user of the particular resource being graphed. That will give you the ``oracle.exe`` process name and its ``PID`` for the highest user of the particular resource.

Open ``c:\scripts\ProcessExplorer``, on the database server, in file explorer and you will find a file named ``procexp64.exe`` which you should run as administrator. (Right-click, run as administrator).

Once running:

-	 Select view->show Process Tree, if necessary.
-	 Select view->update speed and set it to 5 seconds, or longer, otherwise it refreshes too quickly and makes finding things difficult.
-	 Click on the ``process`` header in the tree that appears. You are sorting by the process name.
-	 Scroll down to the ``oracle.exe`` entries. There will be one for each database running on the server.
-	 Find the correct ``oracle.exe`` for the problem PID that you noted above.
-	 Double-click the correct ``oracle.exe`` process name.

In the pop-up that appears, go to the ``Threads`` tab. Click OK if you get a pop-up telling
you that something isn't as fully featured as it might need to be.

-	 Click the ``CPU`` column, to sort by thread id. You might need to do this twice to get the list in the order that you want - highest at the top. This assumes the problem in CPU of course. Sadly, for Disk and Network problems, there's not much other useful information to be gained. It may take a few seconds for the list to refresh.
-	 Note the ``TID`` of the thread with the highest CPU usage. However, watch for a few refreshes to see if it is the only one, or if others are also affecting performance. Note the ``TID``s for all, if necessary.

Now you have the thread IDs for the affecting sessions, we need to use Toad or SQL*Plus to find the culprits in the database.

-	 In the editor, run the following query:

    ..  code-block:: sql
    
        select  p.spid as TID, s.sid
        from    v$session s, v$process p
        where   s.paddr = p.addr
        and     s.paddr in (select  addr
                            from    v$process
                            where   spid in (3476,6564));

The list of threads and SIDs will identify the sessions you are interested in within the database.


Old DBMS_JOBS
=============

Anything under FCS that was once seen in DBA_JOBS will no longer be present in 11g. These jobs have been converted to use the
new (since 10g) DBMS_SCHEDULER.

You should look in DBA_SCHEDULER_JOBS to see details of the jobs, and DBA_SCHEDULER_JOB_LOG to see details of the jobs recent runs, status of same, etc.
For example:

..  code-block:: sql

    select * from dba_scheduler_job_log
    where owner = 'FCS'
    and job_name = 'ALERTS_HEARTBEAT'
    order by log_date desc;

The above will show the most recent output for the FCS.ALERTS_HEARTBEAT job. With the most recent information at the top.

  


