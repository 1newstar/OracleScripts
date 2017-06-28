=========================
Oracle For SQLServer DBAs
=========================

Database Summary
================

+----------+----------------+---------+------------------------+-------------------------------+
| Database | Estate         | Role    | Server                 | Purpose                       |
+==========+================+=========+========================+===============================+
| CFG      | Production     | Primary | uvorc01.casfs.co.uk    | Live database - do not kill   |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGAUDIT | Production     | Primary | uvorc01.casfs.co.uk    | Audit archiving database      |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGRMN   | Production     | Primary | uvorc01.casfs.co.uk    | Live RMAN catalogue           |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGSB    | Production     | Standby | uvorc02.casfs.co.uk    | Live standby                  |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGAUDSB | Production     | Standby | uvorc02.casfs.co.uk    | Audit standby                 |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGRMNSB | Production     | Standby | uvorc02.casfs.co.uk    | RMAN catalogue                |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGDR    | Production     | Standby | druvorc03.casfs.co.uk  | Live DR database              |
+----------+----------------+---------+------------------------+-------------------------------+
| CFGRMNDR | Production     | Standby | druvorc04.casfs.co.uk  | RMAN catalogue                |
+----------+----------------+---------+------------------------+-------------------------------+
| PPDCFG   | Pre-Production | Primary | ppduvorc01.casfs.co.uk | Pre-production database       | 
+----------+----------------+---------+------------------------+-------------------------------+
| PPDRMN   | Pre-Production | Primary | ppduvorc01.casfs.co.uk | Pre-Production RMAN catalogue |
+----------+----------------+---------+------------------------+-------------------------------+
| PPDCFGSB | Pre-Production | Standby | ppduvorc02.casfs.co.uk | Pre-production standby        |
+----------+----------------+---------+------------------------+-------------------------------+
| PPDRMNSB | Pre-Production | Standby | ppduvorc02.casfs.co.uk | Pre-Production RMAN standby   |
+----------+----------------+---------+------------------------+-------------------------------+
| AZSTG01  | DBA Staging    | Primary | ppduvorc01.casfs.co.uk | DBA Use Only                  | 
+----------+----------------+---------+------------------------+-------------------------------+
| AZSTG01  | DBA Staging    | Primary | ppduvorc01.casfs.co.uk | DBA Use Only (Depersonalised) | 
+----------+----------------+---------+------------------------+-------------------------------+
| AZFS1nn  | Development    | Primary | devorc01.casfs.co.uk   | Development Databases         |
+----------+----------------+---------+------------------------+-------------------------------+
| AZFS1nn  | Development    | Primary | devorc02.casfs.co.uk   | Development Databases         |
+----------+----------------+---------+------------------------+-------------------------------+
| AZFS2nn  | Release        | Primary | rel0rc01.casfs.co.uk   | Release database              |
+----------+----------------+---------+------------------------+-------------------------------+
| AZFS2nn  | Release        | Primary | rel0rc02.casfs.co.uk   | Release database              |
+----------+----------------+---------+------------------------+-------------------------------+


Introduction
============

Welcome to the *Dark Side* ;-)

This document is a brief overview of a real database system, provided to enable those of you unlucky enough to have to deal with a pretend database every day, to get an idea of how a proper system hangs together - at least until the developers get at it!

Only kidding!

Hopefully, this document will help you carry out various duties, as may be dumped on you from above, when all the Oracle DBAs have gone off somewhere relaxing, leaving *you* in charge.

Good luck. Don't mess up! ;-)

Windows Environment
-------------------

All of the following assumes that you have the following *mandatory* folders on your path:

-   ``c:\scripts``
-   ``c:\scripts\RMAN``

If you logon to a server and attempt to execute the command below, it should give you a clue as to whether or not the correct folders are on your ``%PATH%``:

..  code-block:: none

    mypath
    
There are a few utility scripts etc to make your life a whole lot easier in the above locations.

Server and Database Passwords
=============================

Keepass. That's all you need to know - or all that should be written down in a document anyway! ;-)

Oracle Environment Variables
============================

Running Oracle Database maintenance requires the following Oracle Environment variables:

ORACLE_SID
    This holds the name of the database you wish to work on. You can work on others, but the default for all commands is the one defined here.
    
ORACLE_BASE
    Not usually set, defaults to ``c:\OracleDatabase``. Considered the base folder for all the rest of the environment. Just ignore it!
    
ORACLE_HOME
    The folder, most often located somewhere beneath ``%ORACLE_BASE%`` where the RDBMS software for the database in question (see ``%ORACLE_SID%``) is located. Running a database with the wrong version leads to problems.
    
NLS_LANG
    Sets the database variables ``NLS_TERRITORY``, ``NLS_LANGUAGE`` and ``NLS_CHARACTERSET`` for the database in one go. We always use a setting of ``AMERICAN_AMERICA.WE8ISO8859P1``. The format is LANGUAGE_TERRITORY.CHARACTERSET and our default results in:
    
    -   NLS_TERRITORY = AMERICA
    -   NLS_LANGUAGE = AMERICAN
    -   NLS_CHARACTER_SET = WE8ISO8859P1    
    
    There's a synonym of ENGLISH_WITH_SPELLING_ERRORS for AMERICAN, if you wish\ [2]_\ .
    
    The database variables are not the same as Windows Environment Variables. They exist in the database only.
    
Database access utilities, such as ``SQL*Plus``, ``expdp``, ``impdp`` etc *must* match these settings or character conversion may result, leading to interesting corruptions. The default settings for an Oracle database are:
    
    -   NLS_TERRITORY = AMERICA
    -   NLS_LANGUAGE = AMERICAN
    -   NLS_CHARACTER_SET = US7ASCII
    
Because of the characterset that defaults, accented characters and other 8 bit glyphs are liable to be corrupted in a database with the default characterset, or, in a session where the client (you) has not correctly set the ``%NLS_LANG%`` environment variable to have the correct characterset.    
    
NLS_DATE_FORMAT
    Setting  this variable means that your default date and time format is ``yyyy/mm/dd hh24:mi:ss`` and is about the best format going. You can change it of course, but best not to - unless otherwise advised.
    
So, we have a script named `oraenv` that sets the above for you. It is called as follows:

..  code-block:: none

    oraenv XXXXXX
    
Which sets all of the above, apart from ``%ORACLE_BASE%`` as appropriate. The file ``c:\scripts\oratab.txt`` contains a list of valid database names (for ``XXXXX``) and the corresponding ``ORACLE_HOME`` for each.

If you type ``oraenv`` without a database SID, your current environment will be displayed:

..  code-block:: none

    oraenv
    
You may see something like the following:    

..  code-block:: none

    Current Environment details are:
    ORACLE_SID=ppdcfg
    ORACLE_HOME=c:\OracleDatabase\product\11.2.0\dbhome_1
    NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss
    NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1

Useful Scripts
==============

As mentioned, we have useful scripts in a couple of standard locations across all our database servers. There are also helpful README type documents for most, if not all of these.

Oraenv
------

As shown above, sets the oracle environment as necessary, given a database SID as a parameter. ``Oraenv`` uses the following utilities or files:

-   ``c:\scripts\oratab.txt`` - defines the valid database SIDs and ``%ORACLE_HOME%``s for this server.

-   ``DBHome`` - Extracts the correct ``%ORACLE_HOME%`` from ``c:\scripts\oratab.txt``, given a valid database SID.

-   ``DBPath`` - Removes any previous ``%ORACLE_HOME%`` folder(s) from ``%PATH%`` and adds on the newly requested database SID's ``%ORACLE_HOME%\bin`` folder to the front of the ``%PATH%``. You *must not* mix and match Oracle Homes or carnage results.

-   ``TidyPath`` - When setting ``%PATH%`` using a command line session, any folder with spaces or, other 'reserved' characters, must be wrapped in double quotes.

    When setting from Control Panel, they don't. This utility makes sure that all folders in the current ``%PATH%`` are indeed, correctly wrapped. Consistency? In Windows? Pah!
    

MyPath
------

Displays the ``%PATH%`` environment variable in an *easy to read* format where each separate folder is on a separate line. This makes life a whole lot easier when trying to find out if a particular folder is on or not on the ``%PATH%``..


HexDump
-------

Might be useful, does what it says! It dumps a file, or part of one, in hex.

..  code-block:: none

    hexdump file_name [start address] [length to dump]

TraceAdjust
-----------

It's unlikely that you will need this. It's massages an Oracle trace dump to convert time values in microSeconds into seconds, deltas and local timestamps. 

TraceMiner2
-----------

It's unlikely that you will need this either. It's read an Oracle trace dump and extracts an HTML report of all the SQL executed with any bind variables replaced by the actual data values used by that particular execution.


Oracle Databases
================

An Oracle Database consists of:

-   An Instance.
-   A Database.
-   A text based parameter file (PFile) or a binary parameter file (SPfile).
-   At least two control files.
-   Online redo log files.
-   Data files.
-   Temporary files.
-   Archived log files.
-   And only on Windows, a Service.

Instances
---------
The instance is nothing more than a shared memory segment plus some background processes. 

Database
--------
The database is the instance, plus the various data files etc.

    **Note**: It is considered impolite to confuse these two, but to be honest, nobody cares! Don't worry about it.

Pfile and SPfile
----------------

In days of old, a text based parameter file was used to start the database with an initial set of parameters. For some time we've had the choice of a pfile or an spfile. 

Oracle looks first in ``%ORACLE_HOME%\database`` for an spfile named ``spfile%ORACLE_SID%.ora`` and uses it if it finds it. Otherwise it looks for a pfile named ``init%ORACLE_SID%.ora`` and uses that. Otherwise it barfs.

Pfiles can only be updated by editing with a text editor, or alternatively, ``notepad.exe``. The database must be restrated to pick up the new parameters.

Spfiles can be updated, only, by the database. They are binary files and have checksums everywhere! You update a parameter as follows:

..  code-block:: sql

    alter system set something = new_value scope = spfile;
    
This changes the setting in the spfile only, and it will be implemented on the next database startup. No validation is done on the new value, so be careful - a broken spfile will stop a database from starting.

..  code-block:: sql

    alter system set something = new_value scope = memory;
    
Not all parameters can be changed this way. Some are only changed within the spfile. This method does not update the spfile, it simply changes the setting in the current running instance. When the next startup happens, the setting will revert back to the spfile setting.

..  code-block:: sql

    alter system set something = new_value scope = both;
    
Not all parameters can be changed this way. This method updates the spfile and changes the setting in the current running instance. When the next startup happens, the setting will also persist as the spfile was changed too.


Running a ``startup nomount`` of a database will start the instance using the spfile, or pfile as necessary.

Control Files
-------------

The control file is highly important. The pfile or spfile tells Oracle where to find the control files for the database. The control file holds a lot of data about the database, but importantly, where all the database files live.

Normally, we have a pairs of control files - one of the pair lives with the data files, and the other in the FRA (Fast Recovery Area).

Running a ``startup mount`` of a database will start the instance using the spfile, or pfile as necessary and bring the control files online.

Control files are documented in the ``V$CONTROLFILE`` view.

Online & Archived log files
---------------------------

Production and pre-production databases *always* run in ``archivelog`` mode.

The online redo log files are used to hold details of transactions executed on the database. In ``archivelog`` mode, these are archived off when full. If the database is in ``noarchivelog`` mode, they are not archived.

Normally, we have pairs of redo logs - one of the pair lives with the data files, and the other in the FRA.

When the current online log file is full up, Oracle seals it and starts using the next one. Three sets are considered normal - UV uses about 13!

In ``archivelog`` mode, sealing the file kicks off a process that copies the sealed file to an archive location for safety, it may also pass the archived file to any standby databases configured. The data in the archived log will be used there to bring the database up to the state of the primary.

In ``noarchivelog`` mode, no archiving is done.

When the final online log file is sealed, the first one is used again. However, if we are running in ``archivelog`` mode, and the first one has not yet been archived, Oracle will stop all processing to prevent data loss. The DBA needs to either:

-   Find some space in the FRA (Fast Recover Area) for more archived logs; or
-   Fix whatever problem is causing the files not to be archived.

Online log files are documented in the ``V$LOG`` and ``V$LOGFILE`` views. Archived logs are documented in ``V$ARCHIVED_LOG``. (It's big!)

Data & Temporary files
----------------------

Data files and Temp files live in the data area. This is usually ``X:\mnt\oradata\%ORACLE_SID%\`` which is the standard for our databases. Obviously, ``X:\`` varies from database to database.

These days, the drive letter represents a virtual drive, made up of slices of an array, so there's no problem having all the database files together, in one place, unlike the old days, when I was a lad\ [1]_\ .

Data files are used to hold permanent data while Temp files hold sort buffers, index building work areas and so on.

You can see the list of data files by querying ``DBA_DATA_FILES``, and temp files by querying ``DBA_TEMP_FILES``.

Oracle Database Services
------------------------

Windows needs a database service, usually named ``OracleServiceXXXXX``, where `XXXXX`` is the database name, or ``SID`` (System IDentifier).

A new database has to have a service, on Windows only, created as follows:

..  code-block:: none

    oradim -new -sid XXXXXX -startmode automatic -shutmode immediate
    
Once created, Windows doesn't *exactly* follow the instructions, so you have to manually fix it. Login to the ``services`` control panel utility and locate the service name. Change it to automatic startup, *unless* the database is a standby database - see later on for details - as we do not want standby databases to start by them selves!

You will also need to locate and execute the ``Administration Assistant for Windows`` - normally located on the task bar - to set the proper startup/shutdown options.

-   Right-click the database name and select *Startup/Shutdown options*.
-   Set the instance to start with the service.
-   Set the instance to stop with the service.
-   Set the shutdown mode to immediate. 

Most database services run as the local SYSTEM account, however, production services *must* be run as the ``casfs\svc_oraclePROD`` account and pre-production as the ``casfs\svc_oraclePPD`` account.

This utility can be used to set the service to automatic, but guess what, it doesn't work!

Starting Databases
------------------

-   Start the service, for production or pre-production listeners, use the ``services`` utility to start the database service as it runs as a specific user. For other systems, ``net start OracleServiceXXXXX`` will suffice.
-   Make sure that the listener is running, you can check it in the ``services`` utility, and start it from there too if we are on production or pre-production.
-   Open a command session as administrator (don't be afraid of the command line - it won't bite).
-   Set the environment with ``oraenv``.
-   Run ``sqlplus sys/password as sysdba``
-   execute one of the following:

    -   ``startup nomount`` - to start the instance only.
    -   ``startup mount`` - to start the instance and bring the control file(s) online.
    -   ``startup [open]`` - to start the instance and bring the database online. The parameter is optional, the default for a startup command is to open the database for use.
    
-   Exit from ``sqlplus``.
    
Stopping databases
------------------

-   Open a command session as adminstrator.
-   Set the environment with ``oraenv``.
-   Run ``sqlplus sys/password as sysdba``
-   execute one of the following:

    -   ``shutdown`` - to wait for all sessions to logout, and then shut down the database and instance. This almost never works as we have services that are automatic and will never logout. :-(
    -   ``shutdown immediate`` - no new transactions will be started, any uncommitted ones in progress will be rolled back - which may take a while - and then the database and instance will be closed.
    -   ``shutdown abort`` - dangerous! Kills everything *now*. Very user unfriendly, but sometimes you have no choice. On startup, there will be a modicum of transaction recovery carried out to clean up any uncommitted transactions that got binned.
    
-   Exit from ``sqlplus``.

Oracle Listeners
================

The listener, is a process that runs as a service, which allows users to (remotely) connect to a database. The default listener is named ``LISTENER`` and listens on port 1521 for connections to *any* of the databases that it is listening for.

When a user attempts a connection using a command  which runs a TCP network connection to the database server, the listener:

-   Waits for a connection on port 1521.
-   Checks that the requested session wants to connect to a database it knows about.
-   Passes the request over on a randomly assigned port number, where it continues to speak directly to the database.
-   Goes back to listening on port 1521.

Normally, Oracle databases auto-register with the listener (provided that it is named LISTENER, and running on port 1521) on startup. If the listener is not running when the database starts, the PMON background process of the database, will keep trying to register at intervals until the listener finally starts.

The listener service is named after the ``%ORACLE_HOME%`` name that it is installed into. The name is defaulted when installing the RDBMS software on the server initially, for our Azure Servers, the name is ``OracleOraDb11g_home1`` giving the listener a name of ``OracleOraDb11g_home1TNSListener``.

Starting the Listener
---------------------

If the server is production or pre-production, you must start the listener service using the ``services`` utility as it must run under a specific user account, not local SYSTEM (the default).

For other systems, the following command will work, provided you have set a valid oracle environment with ``oraenv``:

-   ``lsnrctl start``

Stopping the Listener
---------------------

If the server is production or pre-production, you must stop the listener service using the ``services`` utility as it must be shutdown by a specific user account, not local SYSTEM.

For other systems, the following command will work, provided you have set a valid oracle environment with ``oraenv``:

-   ``lsnrctl stop``

Listener Status
---------------

Regardless of the server's production status, the following command will work, provided you have set a valid oracle environment with ``oraenv``:

-   ``lsnrctl status``

The output will resemble the following mess:

..  code-block:: none

    LSNRCTL for 64-bit Windows: Version 11.2.0.4.0 - Production on 28-JUN-2017 12:43:42

    Copyright (c) 1991, 2013, Oracle.  All rights reserved.

    Connecting to (ADDRESS=(PROTOCOL=tcp)(HOST=)(PORT=1521))
    STATUS of the LISTENER
    ------------------------
    Alias                     LISTENER
    Version                   TNSLSNR for 64-bit Windows: Version 11.2.0.4.0 - Production
    Start Date                07-JUN-2017 16:24:53
    Uptime                    20 days 20 hr. 18 min. 49 sec
    Trace Level               off
    Security                  ON: Local OS Authentication
    SNMP                      OFF
    Listener Parameter File   c:\OracleDatabase\product\11.2.0\dbhome_1\network\admin\listener.ora
    Listener Log File         c:\OracleDatabase\diag\tnslsnr\ppduvorc01\listener\alert\log.xml
    Listening Endpoints Summary...
      (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=ppduvorc01.casfs.co.uk)(PORT=1521)))
    Services Summary...
    Service "AZSTG01" has 1 instance(s).
      Instance "AZSTG01", status UNKNOWN, has 1 handler(s) for this service...

      ... yada yada yada ...
      
    Service "cfgdemoXDB" has 1 instance(s).
      Instance "cfgdemo", status READY, has 1 handler(s) for this service...
    Service "prduatXDB" has 1 instance(s).
      Instance "prduat", status READY, has 1 handler(s) for this service...
    The command completed successfully

If you see the desired database in the above list, then the listener is listening for it. That's not to say that it will work, but at least you know it's being listened for!

Oracle Backups
==============

Database backups are run daily - for production primary databases - with a full backup taken on a Sunday plus incremental backups of anything that has changed taken on the rest of the week.

Pre-production databases are backed up fully, every Sunday only. These will be recreated from production in the event of a problem, if necessary.

Backups on production and preproduction go to:

    ``\\Backman01\RMANBackup\backups\%ORACLE_SID%\`` 
 
with the logs being written to:

    ``\\Backman01\RMANBackup\backups\logs\%ORACLE_SID%\RMAN_level_n.yyyymmdd_hhmm.log``. 
    
    The level (n) will be zero for a full backup and one for an incremental backup.

If you have to check on a backup, the log file is the place to be. Good luck, but you will be looking for a lack of errors. Errors look something like the following:

..  code-block:: none

    RMAN-00571: ===========================================================
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00571: ===========================================================
    RMAN-03002: failure of backup command at 06/25/2017 22:43:01
    RMAN-06059: expected archived log not found, loss of archived log compromises recoverability
    ORA-19625: error identifying file F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2017_03_07\O1_MF_1_1_DCXGLL1C_.ARC
    ORA-27041: unable to open file
    OSD-04002: unable to open file
    O/S-Error: (OS 3) The system cannot find the path specified.

Hopefully, you will see "successful backup" messages for the following:

-   The database backup;
-   The controlfile and spfile auto-backup;
-   Crosschecking the archived logs;
-   The archived logs backup;
-   The controlfile and spfile auto-backup again;

As follows:

..  code-block:: none

    Recovery Manager: Release 11.2.0.4.0 - Production on Sun Jun 25 03:00:00 2017

    Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

    connected to target database: CFG (DBID=2092933938)
    connected to recovery catalog database

    Starting backup at 2017/06/25 03:00:16

        # Lots of output here ...
        
    Finished backup at 2017/06/25 03:44:29

    Starting Control File and SPFILE Autobackup at 2017/06/25 03:44:30
    piece handle=\\BACKMAN01\RMANBACKUP\BACKUPS\CFG\AUTOBACKUP\C-2092933938-20170625-00 comment=NONE
    Finished Control File and SPFILE Autobackup at 2017/06/25 03:44:40

    sql statement: alter system archive log current

    validation succeeded for archived log
    archived log file name=F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2017_06_23\O1_MF_1_18062_DNS0CFW4_.ARC RECID=42498 STAMP=947389694

        # Lots of output here ...

    Crosschecked 258 objects


    Starting backup at 2017/06/25 03:45:12
    current log archived

        # Lots of output here ...

    Finished backup at 2017/06/25 03:49:38

    Starting Control File and SPFILE Autobackup at 2017/06/25 03:49:38
    piece handle=\\BACKMAN01\RMANBACKUP\BACKUPS\CFG\AUTOBACKUP\C-2092933938-20170625-01 comment=NONE
    Finished Control File and SPFILE Autobackup at 2017/06/25 03:49:49

    released channel: disk_1

    released channel: disk_2

    released channel: disk_3

    released channel: disk_4

    released channel: disk_5

    Recovery Manager complete.


All backup information for production and preproduction databases are stored in the RMAN catalog database (Services ``CFGRMNSRV`` or ``PPDRMNSRV`` as appropriate) *except* for the backups of the catalog databases themselves which keep their details in the control file.

We do not (normally) backup the release or development databases. However, we can do if requested. There are no RMAN catalog databases on the release or development database servers, we would use the controlfile if necessary.

Primary Databases
=================

We have the following *primary* databases. These are the ones that we normally run the applications against. 

These databases are located in a Dublin data centre used by Azure.

Production
----------
The server in use is:

-   ``uvorc01.casfs.co.uk``

The databases are:

-   CFG. The main UV database. The users have access to this one for normal duties.
-   CFGAUDIT. The main audit database where auditing data is archived to on a daily basis.
-   CFGRMN. The RMAN catalog database for the production databases.

Pre-Production
--------------
The server in use is:

-   ``ppduvorc01.casfs.co.uk``

The databases are:

-   PPDCFG. The main UV database in pre-production. This is not used by the users normally.
-   PPDRMN. The RMAN catalog database for the pre-production databases.

Standby Databases
=================

We have the following *standby* databases. These databases are always started in ``MOUNT`` mode, never ``OPEN`` as the cannot be opened without hugely expensive licensing costs. Do not ever startup a standby database in anything other than ``MOUNT`` mode.

Databases created with names ending in 'SB' are considered to be the standby database, however, on a switchover (or failover) they can be running as the primary. Just beware!

Normal users cannot login to a standby database, only SYSDBA enabled users can do this and that means SYS only in our environment.

These databases are located in a separate Dublin data centre used by Azure.

Production
----------

The server in use is:

-   ``uvorc02.casfs.co.uk``

The databases are:

-   CFGSB. The main UV standby database.
-   CFGAUDSB. The main audit standby database.
-   CFGRMNSB. The RMAN catalog standby database for the production estate.

Pre-Production
--------------

The server in use is:

-   ``ppduvorc02.casfs.co.uk``

The databases are:

-   PPDCFGSB. The main UV standby database in pre-production.
-   PPDRMNSB. The RMAN catalog standby database for the pre-production estate.

Disaster Recovery Databases
===========================

Production
----------
The server in use is:

-   ``druvorc03.casfs.co.uk``

We only have Disaster Recovery databases for production. These are:

-   CFGDR. The main UV DR database.
-   CFGAUDDR. The main audit DR database.
-   CFGRMNDR. The RMAN catalog DR database for the production estate.

Normal users cannot login to a standby database, only SYSDBA enabled users can do this and that means SYS only in our environment.

These databases are located in an Amsterdam data centre used by Azure.

Staging Databases
=================

There are two of these and they are used by the DBAs only. They both are hosted on the pre-production server ``ppduvorc01.casfs.co.uk`` and there are no standby or DR databases.

-   AZSTG01 is built by restoring the production (CFG) database backup from `last night` which serves to:

    -   Ensure that the database dump files are usable; and
    -   Gives the staging database up to date data.
    
    AZSTG01 is a non-depersonalised database, so any customer data within is still personal and **must be kept safe** or we are in breach of the Data Protection Act. We do not want to go there!

-   AZSTG02 is a clone of AZSTG01 which has been *fully* depersonalised to obfuscate any and all personal data. This is the database mostly used to create or refresh release and development databases. 

Release Databases
=================

These are used by Developers, Tester etc. They are not used by the users at all. Various databases exist but they all have the names ``AZFS2nn``. There are currently two servers hosting these databases:

-   ``relorc01.casfs.co.uk``
-   ``relorc02.casfs.co.uk``

These databases are created or refreshed by cloning the AZSTG02 staging database used (only) by the DBAs. Under certain, restricted conditions, the AZSTG01 database might be used to create or refresh a release database. In those limited cases, access is highly restricted as anyone not permitted access has their account deleted prior to handover.

Only the DBAs have full DBA access to these, so we support them.

Development Databases
=====================

These are used mainly by Developers. They are not used by the users at all. Various databases exist but they all have the names ``AZFS1nn``. There are currently two servers hosting these databases:

-   ``devorc01.casfs.co.uk``
-   ``devorc02.casfs.co.uk``

These databases are created or refreshed by cloning the AZSTG02 staging database used (only) by the DBAs. 

The DBAs do not normally support these databases as the developers have full DBA access to them, and are able to do anything with them. In the event of problems, *c'est la vie*, as they say in Wales. Refresh!


Daily Checks
============

Only on production databases. A separate document exists explaining what and why we check.


Useful Documents in TFS
=======================

The following is a list of potentially useful documents that can be found in TFS at the location given. It is assumed that you are aware of how to connect to the TFS system and extract files that you may need to view.

-   Anything in the Standard Operating Procedures folder. ``$TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation\Standard Operating Procedures``.
-   The Database Handover document (for my successor) at ``$TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation``.
-   The Daily Checks document at ``$TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation``.


-----

| Author: Norman Dunbar
| Email: norman@dunbar-it.co.uk
| Last Updated: 28th June 2017.


..  [1] Old git!
..  [2] Only kidding, there isn't!
