================================================
Refreshing AZSTG01/02 from Production Dump Files
================================================

Abstract
========

Refreshing the staging databases from production dump files carries out two significant DBA tasks in one exercise:

- It refreshes the staging databases;
- More importantly, it proves that the production backups are valid, readable and can be used to restore the database;

In addition, by using the daily dumps, we avoid the possibility of any impact on the production server as there will be around 7 RMAN sessions logged in and working to varying degrees of intensity, on the production database had we run a ``duplicate from active database``.


Process Outline
===============

The outline of the processes to be followed are:

- Drop the existing staging database & clean out its previous log files etc.
- Restore the CFG dumps to create a new ``CFG`` on the pre-production server.
- Rename, using ``nid``, the new ``CFG`` database to ``AZSTGnn`` as required.
- Create a new password file.
- Create a new spfile.
- Reset any production specific parameters and settings.
- Depersonalise the database, as required.
- Configure RMAN is required to perform backups of the database.
- Do some server clean up also.

The example described below restores the ``CFG`` database to the ``AZSTG02`` database.


Drop the Existing Staging Database
==================================

The existing staging database needs to vanish. We will be using  the same locations for data, FRA and redo files but we need to clear out any existing detritus first.

..  code-block:: sql

    oraenv azstg02
    sqlplus sys/password as sysdba
    
    -- Make sure we are on the correct database first!
    select name, db_unique_name from v$database;
    
    startup force restrict mount
    drop database;
    exit

In the Windows file explorer GUI, navigate to ``c:\oracledatabase\diag\rdbms`` and shift-delete the existing staging database diagnostics tree. ``Azstg02`` for this example.

Navigate to ``g:\mnt\oradata\azstg02`` and shift-delete the *contents*.

Navigate to ``h:\mnt\fast_recovery_area\azstg02`` and shift-delete the *contents*.

Check that the old spfile, ``spfileazstg02.ora``, has been deleted from ``%oracle_home%\database``.

If a password file exists, and it should, leave it alone as we will reuse this. The file will be named  ``pwdAZSTG02.ora``. Ditto a pfile named ``initAZSTG02.ora`` which should only contain the following contents:

..  code-block:: none

    db_name=azstg02

If the ``initAZSTG02.ora`` file contains more than the above, edit out everything except the above.
    
Finally, stop the existing Oracle service:

..  code-block:: none

    net stop OracleServiceazstg02
    
    
Restore the CFG Database Dumps
==============================

The following describes how to restore a database dump of the ``CFG`` database to a different server, but still named ``CFG``. This is normal for a restore test of a database backup.

However, we are restoring the ``CFG`` database dump to create a staging database, so as the restore progresses, we will divert some of the restored files etc to a *different location* that suits the desired staging database, which will be kept and used to create various testing, development and UAT databases.

There are other ways to do this - cloning the staging database from the dumps, for example, but the process differs from that which would be used to restore a ``CFG`` backup to the ``CFG`` database, so we use that process here - for education and familiarity purposes.

Brief Outline of the Restore Process
------------------------------------

The following steps will be discussed in full below, and are listed here for information as to what you are about to do.

-   Collect information about the backup you will be restoring.
-   Create a new ``CFG`` Oracle Service using ``oradim``.
-   Make sure that the ``tnsnames.ora`` alias for CFG is commented out on the server we are restoring to.
-   Nomount the instance and restore the spfile.
-   Edit the parameters.
-   Nomount the instance and restore the control files.
-   Mount the instance and restore & recover the database.

That's it, the database will then be ready for a post restore clean up and will be suitable for renaming.


Collect Required Information
----------------------------

The following information is required to be noted prior to restoring the ``CFG`` backup. The details can be found in the log files for the actual back, and these are located in ``\\Backman01\RMANBackup\backups\logs\cfg``. The log files are named ``RMAN_level_x.yyyymmdd_hhmm.log`` where 'x' is the level, zero or one, and yyyymmdd and hhmm indicate the date and time of the start of the backup.

You will need:

-   The ``CFG`` database identifier, DBID, this is usually : 2092933938 but check. (See below.)
-   The archive log sequence for the last archive log backed up.
-   The Control File/spfile autobackup location. 


DBID
~~~~

The ``DBID`` is obtained from the top of the ``RMAN`` log, or from the prompts when you connect to the database with ``RMAN``:

..  code-block:: none

    connected to target database: CFG (DBID=2092933938)

    
Archived Log Sequence
~~~~~~~~~~~~~~~~~~~~~

The archive sequence is the highest one in the ``RMAN`` log. It appears near the end, just above the details of the controlfile and spfile autobackup:

..  code-block:: none

    ...
    input archived log thread=1 sequence=73 RECID=73 STAMP=928589967
    
    Starting Control File and SPFILE Autobackup at 2016/11/22 13:39:54
    piece 
    ...

**Note:** The sequence number you note down will be incremented by 1 later, in order to ensure that the one you noted will be restored and recovered by ``RMAN``. Normally ``RMAN`` stops applying logs when it reaches the requested log sequence, but does not apply it. Beware of this.


Spfile and Controlfile Autobackup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The controlfile and Spfile backups are taken at the end of every ``RMAN`` backup, no matter what else was backed up. You can never have too many backups of these files. Close to the end of the ``RMAN`` log, you will find the required details:
    
..  code-block:: none

    Starting Control File and SPFILE Autobackup at 2016/11/22 13:39:54
    piece handle=\\BACKMAN01\RMANBACKUP\BACKUPS\CFG\AUTOBACKUP\C-2092933938-20161122-01 comment=NONE
    Finished Control File and SPFILE Autobackup at 2016/11/22 13:40:12

The filename mentioned will have copies of both the spfile and the controlfiles, and we will definitely require all of those on the destination server.

The filename contains the dbid and the data and time of the backup within its name too, if you look closely!


Create Oracle Service
---------------------

Normally, to avoid wasting resources on the server, the service for the ``CFG`` database, on the server we are restoring to, usually a preproduction server, has been cleaned up after the most recent restore exercise. To this end, we must recreate the service.

..  code-block:: none

    oradim -new -sid cfg -startmode manual -shutmode abort

This will create a new service and start it up. We will have to manually start the database ourselves, but this is as desired.
    

Check & Edit Tnsnames.ora
-------------------------

On the restoring server, we do not want connections to ``CFG`` to go to the *production* database, so we must comment out, for now, the appropriate entry.

Edit the tnsnames.ora file and locate the entry for ``CFG`` - this is not the same as ``CFGSRV``, leave that one alone. Comment out the entry as follows:

..  code-block:: none

    #CFG =
    #  (DESCRIPTION =
    #    (ADDRESS = (PROTOCOL = TCP)(HOST = uvorc01.casfs.co.uk)(PORT = 1521))
    #    (CONNECT_DATA =
    #      (SERVER = DEDICATED)
    #      (SERVICE_NAME = CFG)
    #    )
    #  )
    
Save the file and exit.

Test that all is well by running the following command:

..  code-block:: none

    tnsping cfg

You should not see a valid connection going to server ``uvorc01`` on port 1521, you should see something resembling the following instead:

..  code-block:: none

    ...
    TNS-03505: Failed to resolve name
       
    
Restore the Spfile
------------------

Nomount the database instance and restore the spfile as a pfile, as follows:

..  code-block:: none

    oraenv cfg
    cd %oracle_home%\database

Create, or edit, the file initCFG.ora and ensure that the entire contents match this:

..  code-block:: none

    db_name=cfg

Save the file and exit the editor.

Login to ``RMAN`` and start the instance in nomount mode:

..  code-block:: sql

    rman target sys/password nocatalog
    startup nomount pfile='?\database\initCFG.ora'
    
When the instance starts, restore the spfile as a text based pfile, as follows:

..  code-block:: none

    set dbid 2092933938;
    restore spfile to pfile '?\database\initCFG.ora' from 
    '\\BACKMAN01\RMANBACKUP\BACKUPS\CFG\AUTOBACKUP\C-2092933938-20161122-01';
    
Obviously the filename will be as you noted from the backup log.    


Edit the Parameters
-------------------

The restored parameter file references a number of parameters that are specific to the ``CFG`` database in production, sets up Data Guard requirements and so on. These need to be changed or removed/disabled to suit the restored ``CFG`` database.

Always Edit the Following
~~~~~~~~~~~~~~~~~~~~~~~~~
    
Open the file ``%oracle_home%\database\initCFG.ora`` and edit the following, *non-exclusive* list of parameters:

- Anything that *does not* begin with an asterisk ('*') should be deleted;
- Make sure that the CONTROL_FILES setting is correct for this new database. There should be one in ORADATA and one in the FRA. Make sure that the names specify the disc drives for the staging database (which are usually ``G:\`` and ``H:\``) and that the folder names reflects that of the staging database, not ``CFG``.
- Delete DB_FILE_NAME_CONVERT if present.
- Make sure that the DB_RECOVERY_FILE_DEST setting is correct for this new database.
- Ensure DG_BROKER_START is set to FALSE.
- Delete FAL_SERVER and FAL_CLIENT if present.
- Delete LOCAL_LISTENER if present.
- Delete LOG_ARCHIVE_CONFIG if present.
- Delete LOG_ARCHIVE_DEST_2 upwards. Keep only dest 1.
- Delete LOG_ARCHIVE_DEST_STATE_2 upwards. Keep only state 1.
- Delete LOG_FILE_NAME_CONVERT if present.
- Set PGA_AGGREGATE_TARGET to 100m.
- Delete REMOTE_LISTENER if present.
- Set SGA_TARGET to 2g. (Or adjust as appropriate for the database.)
- Set SGA_MAX_SIZE to 3g. (Or adjust as appropriate for the database.)

If the Source Database was Data Guarded
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Additionally, if the restore is taken from a Data Guarded database, and ``CFG`` is usually Data Guarded, remove anything to do with the standby. Should have been done above, but check:

- Ensure DG_BROKER_START is set to FALSE.
- Delete LOG_ARCHIVE_CONFIG if present.


If the Source Database was RAC Clustered
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section can be ignored, we do not use RAC clustered databases as yet.

If the restore is taken from an RAC database, then ensure that all RAC specific parameters are removed:

- Delete CLUSTER_DATABASE.
- Delete INSTANCE_NAME.
- Delete INSTANCE_NUMBER.


Edit to Suit the Staging Database
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Locate all parameters that reference ``CFG`` and replace ``CFG`` with the name of the staging database that we are restoring. However, **do not** change the ``db_name`` parameter, it must continue to reference ``CFG``.

Save the file and exit from the editor.


Restore the Control Files
-------------------------

Log back into ``RMAN``, restart the database using the new pfile and restore the control files:

..  code-block:: none

    startup force nomount pfile='?\database\initCFG.ora';

    set dbid 2092933938;
    restore controlfile from 
    '\\BACKMAN01\RMANBACKUP\BACKUPS\CFG\AUTOBACKUP\C-2092933938-20161122-01';
    
Obviously the filename will be as you noted from the backup log and will be the same as for the spfile restore above. 


Restore & Recover the Database
------------------------------

..  code-block:: none

    startup force mount pfile='?\database\initCFG.ora';

Because we are running a restore and recover, there is an unfortunate problem, the various ``_FILE_NAME_CONVERT`` parameters *do not work*, so we have to do things manually. 

Additionally, the TEMP tablespace's files do not get renamed by default. We need to do that manually as well. 

Currently, the production database has two files in the TEMP tablespace, however, it may be best to check this by running  the following script against the *production* ``CFG`` database:

..  code-block:: none

    select file_id
    from dba_temp_files
    order by 1;
    
Whatever numbers you get out are the ones we need to rename in the following script.    

Create the following file in an editor and note that the value for 'nnnn' below is one higher than the sequence number you noted fown from the backup log.

..  code-block:: none

    run {
    	allocate channel d1
        device type DISK;

    	allocate channel d2
        device type DISK;

    	allocate channel d3
        device type DISK;

    	allocate channel d4
        device type DISK;

    	allocate channel d5
        device type DISK;

    	allocate channel d6
        device type DISK;

        #----------------------------------------------------------------
        # 'nnnn' in the following must be one more than the sequence that
        # you noted down from the production ``CFG`` backup log.
        #----------------------------------------------------------------
        set until sequence nnnn;
       
        #----------------------------------------------------------------
        # Fix the database name, and check the drive letter here...
        #----------------------------------------------------------------
        set newname for database to 'G:\mnt\oradata\AZSTGnn\%b';
        
        #----------------------------------------------------------------
        # Add a line for each of the temp files in the source database
        # the fix the database name, and check the drive letter here too.
        #----------------------------------------------------------------
        set newname for tempfile 1 to 'G:\mnt\oradata\AZSTGnn\%b';
        set newname for tempfile 2 to 'G:\mnt\oradata\AZSTGnn\%b';

        restore database;
        switch datafile all;
        switch tempfile all;
        recover database; 

        release channel d6;
        release channel d5;
        release channel d4;
        release channel d3;
        release channel d2;
        release channel d1;
    }
    
Save the file as something like ``restore_cfg.rman`` and execute it in ``RMAN``:

..  code-block:: none

    @restore_cfg.rman
    
You may need to add in the full path to the file, depending on where you saved it.    
    
When completed, the database will be restored and recovered, but not yet open, it remains mounted.
    
    **Note**: Because the TEMP files are never backed up, they cannot be restored. What will happen is that they will be recreated when you open the database.

At the end of the recovery phase, you should see a message showing that your chosen sequence of archived log was applied to the database. 

The database has all it's files in the locations required by the staging database, but is still named ``CFG``. Before we rename it, we need to do a little housekeeping.

You should now exit from RMAN. The remainder of the work needs to be done in ``SQL*Plus``.

We need a script to create a rename script for the redo logs. Open an editor and save the following as ``create_rename_redo.sql``:

..  code-block:: sql

    set lines 2000 pages 2000 trimspool on
    set echo off feed off verify off head off

    spool rename_logs.sql
    
    -- Script to rename REDO logs using SQL*Plus...
    -- Note: REPLACE() is case sensitive. Use correct locations!
    --       AND use UPPERCASE for drive letters and DB Names!
    --
    -- Change the following to suit your source and destination drives.
    -- LOG_A_DRIVE is the drive where CFG REDOnA logs live. Usually ORADATA drive.
    -- LOG_B_DRIVE is the drive where CFG REDOnB logs live. Usually FRA drive.
    -- Currently, these are E and F drives.
    define LOG_A_DRIVE=E
    define LOG_B_DRIVE=F

    -- LOG_A_DEST is where the AZSTGnn REDOnA logs will be after the restore.
    -- LOG_B_DEST is where the AZSTGnn REDOnB logs will be after the restore.
    -- Currently, these are G and H drives.
    define LOG_A_DEST=G
    define LOG_B_DEST=H
    
    -- DEST_DB is AZSTG01 or AZSTG02 as appropriate.
    define DEST_DB=AZSTGnn

    select 'alter database rename file '''|| member || ''' to ''' ||
            replace(
                replace(
                    replace(upper(member),
                           '&LOG_A_DRIVE:','&LOG_A_DEST:'),
                    '&LOG_B_DRIVE:','&LOG_B_DEST:'), 
                '\CFG\', '\' || '&DEST_DB' || '\'
            ) || ''';'
    from v$logfile
    order by 1;
    
    spool off
    
Save the file and exit. The settings for the source and destination drives should be correct, however, it is best to check. You will need to set the correct value for the staging database being restored. Log in to the database using ``SQL*Plus`` as the SYSDBA user and:

..  code-block:: sql

    -- Create a script to rename the redo logs.
    @create_rename_redo.sql
    
    
    -- AFTER checking that it is ok, execute the generated script.
    @rename_logs.sql    
    
    
    -- Rename the redo logs.
    @rename_logs.sql
    
    
    -- Always do this. The CFG filename is still in use.
    alter database disable block change tracking;
    
    -- Do the following always after a SET UNTIL ... restore and recover.
    alter database open resetlogs;
    
You might see the following error, or one very similar:

..  code-block:: none

    alter database open resetlogs
    *
    ERROR at line 1:
    ORA-00392: log 9 of thread 1 is being cleared, operation not allowed
    ORA-00312: online log 9 thread 1: 'G:\MNT\ORADATA\AZSTG02\REDO9A.LOG'
    ORA-00312: online log 9 thread 1:
    'H:\MNT\FAST_RECOVERY_AREA\AZSTG02\REDO9B.LOG'

As the log files don't actually exist yet, we can safely clear them out, which simply initialises them, which is what we are trying to do anyway! First we need to determine which logfile group the logfile belongs to:

..  code-block:: sql

    select group# from v$logfile 
    where member = 'H:\MNT\FAST_RECOVERY_AREA\AZSTG02\REDO9B.LOG';

        GROUP#
    ----------
             9

And once we know the group, we can clear it and open the database:

..  code-block:: sql

    alter database clear logfile group 9;
    Database altered.

    alter database open resetlogs;
    Database altered.    
    

Post Restore Clean Up
=====================

The following housekeeping requires attention before the database can be renamed.

Production Service & Trigger
----------------------------

Once the database is open, we need to drop the existing trigger and any services that relate to the source, ``CFG``, database. This is especially required when the source database was a member of a primary-standby pairing.

..  code-block:: sql

    alter database open;
    
    show parameter service_names
    
The result will most likely be:

..  code-block:: none

    NAME           TYPE        VALUE
    -------------- ----------- ------
    service_names  string      CFGSRV
    
This is still using the production service name, and not the default service name of ``AZSTG02``. There will be a trigger, owned by SYS, which fires after the databases has been started up and opened, which enables the service named above. The trigger name *should* be the service name plus a suffix of ``_trigger``, ``CFGSRV_trigger`` in this example. The trigger must be dropped and the service disabled and deleted.

..  code-block:: sql

    drop trigger sys.CFGSRV_trigger;
    
    exec dbms_service.stop_service('CFGSRV');
    exec dbms_service.delete_service('CFGSRV');
    
    show parameter service_names

The result should now be:

..  code-block:: none

    NAME           TYPE        VALUE
    -------------- ----------- ------
    service_names  string      AZSTG02

    
Other Parameters
----------------

..  code-block:: sql

    select status, filename 
    from v$block_change_tracking;

If the result shows 'disabled' then we need to enable it:

..  code-block:: sql

    alter database enable block change tracking
    using file 'H:\mnt\fast_recovery_area\AZSTG02\bct.dbf';

Obviously, replace 'H' with the correct drive letter for the FRA disc, and set the database name correctly. 

Some other parameters might also need to be changed from their ``CFG`` values:

..  code-block:: sql

    select name, value
    from v$parameter
    where upper(value) like '%CFG%'    
    and lower(name) not like '%file_name_convert';

'No rows selected' is a good result. If, on the other hand, there are some rows selected, they will most likely be one of the following, so apply the appropriate fix(es):

..  code-block:: sql

    alter system set instance_name='azstg02' scope=spfile;

    alter system set service_names='azstg02' scope=spfile;

    alter system set audit_file_dest =
    'C:\ORACLEDATABASE\ADMIN\azstg02\ADUMP' scope = spfile;

    alter system set dispatchers=
    '(PROTOCOL=TCP) (SERVICE=azstg02XDB)' scope=spfile;

If you make any changes then restart the database:

..  code-block:: sql
       
    shutdown immediate
    startup

    
Scheduler Jobs
--------------

Check that all FCS jobs running under dba_scheduler_jobs are disabled:

..  code-block:: sql

    select owner, enabled, job_name
    from dba_scheduler_jobs
    where enabled = 'TRUE'
    and owner not in ('SYS','SYSTEM','SYSMAN','ORACLE_OCM','EXFSYS')
    order by owner,job_name;

    
The results will be similar, not necessarily identical, to the following:

..  code-block:: none

    OWNER                          ENABL JOB_NAME
    ------------------------------ ----- ----------------------
    FCS                            TRUE  ALERTS_HEARTBEAT
    FCS                            TRUE  CLEARLOGS
    FCS                            TRUE  JISA_18BDAY_CONVERSION
    PERFSTAT                       TRUE  PURGE_DAILY
    PERFSTAT                       TRUE  SNAPSHOT_EVERY_15MINS


If there are any jobs listed, they must be disabled:

..  code-block:: sql

    begin
        dbms_scheduler.disable(name => 'FCS.ALERTS_HEARTBEAT', 
                               force => true);
        dbms_scheduler.disable(name => 'FCS.CLEARLOGS',
                               force => true);
        dbms_scheduler.disable(name => 'FCS.JISA_18BDAY_CONVERSION',
                               force => true);
        dbms_scheduler.disable(name => 'PERFSTAT.PURGE_DAILY',
                               force => true);
        dbms_scheduler.disable(name => 'PERFSTAT.SNAPSHOT_EVERY_15MINS',
                               force => true);
    end;

PERFSTAT is not required on the staging databases:

..  code-block:: sql

    drop user perfstat cascade;

If there is an error that *you cannot drop a user that is connected* then the above running job(s) for PERFSTAT are still running in the background. The database should be restarted.

..  code-block:: sql

    shutdown abort;
    startup 
    drop user perfstat cascade;


Change Passwords
----------------

Certain users will require to have their password changed as they now reflect production. At the *very least* you must change the FCS password to that found in ``Keepass`` for the staging database. In addition, change any other passwords found for the staging database in ``Keepass`` to suit.

..  code-block:: sql

    alter user FCS identified by <kepass_password>;
    


Rename the Database Using 'Nid'
===============================

If you did not rename the database as part of the restore, then you must do it now.

The database will be renamed using the ``nid`` utility as it currently has the same ``DBID`` as the database it was restored from, ``CFG``, and if you attempt to back it up, you may corrupt the backup details for the CFG database, in the ``RMAN`` catalogue.

..  code-block:: none

    oraenv cfg
    
    sqlplus sys/password as sysdba
    shutdown immediate
    startup mount
    
If you have a large number of data files, then:

..  code-block:: sql

    alter system set open_cursors=1500 scope=memory;
    
Then exit from the database.

In a DOS (shell) session:

..  code-block:: none

    nid target=sys/password logfile=nid_azstg02.log
    
The *database will be left closed* when the above command completes. You *must* check the logfile.

If you see an error similar to the following, when you check the log file:

..  code-block:: none

    NID-00135: There are 1 active threads

Then the database has not been renamed and is still mounted. The usual cause is a background scheduled job running - you did drop all the scheduled jobs for FCS and PERFSTAT didn't you - or, the database was not shut down cleanly and has some instance recovery to carry out before ``nid`` will work.   



Post Rename Configuration
=========================

Create a New Password File
--------------------------

In ``%ORACLE_HOME%\database`` copy, or rename, the password file to suit the new staging database name. If an existing password file for the staging database exists, then *unless* you have changed the SYS password, it can continue to be used. If, on the other hand it doesn't exist, then rename the one for the CFG database to suit the staging database:

..  code-block:: none

    cd %oracle_home%\database
    copy pwdCFG.ora pwdAZSTG02.ora

If there is no existing ``pwdCFG.ora`` password file, then create a new one for the staging database:

..  code-block:: none

    cd %oracle_home%\database
    orapwd file=pwdAZSTG02.ora password=<SysPassword> entries=10

    
Create a New Spfile
-------------------

Once the database has been renamed, there's a little more work to do. After the ``nid``, the database was left in a closed state. We *don't* need it running for the following commands.

If no spfile exists for the new staging database, then create one in the normal manner, based on the ``CFG`` pfile. We can edit the file we restored earlier to match the staging database.

..  code-block:: none

    cd %oracle_home%\database
    copy initCFG.ora initAZSTGnn.ora
    
Now, edit the ``initAZSTGnn.ora`` file and change the ``db_name`` parameter from ``CFG`` to `AZSTGnn`` according to the database you are building.
   
Once complete, save the file and exit from the editor, then you must change the Oracle environment from ``CFG`` to ``AZSTG02`` - in this example.:

..  code-block:: sql
       
    oraenv azstg02
    
You have to change the environment to avoid errors when you start the database. If Oracle tells you that *the name of the database 'CFG' is not the same as in the control file 'AZSTG02'* then you forgot!

Use the Windows ``Services`` application to restart the ``OracleServiceAZSTG02`` service.
    
Log back into ``SQL*Plus`` as the SYSDBA user, and:

..  code-block:: sql
       
    create spfile '?\database\spfileAZSTG02.ora' 
    from pfile '?\database\initAZSTG02.ora';
    
    shutdown immediate
    startup mount
    

Depersonalisation
=================

Regardless of the database being restored, we must ensure that, at least, a partial depersonalisation is performed. The code can be obtained from TFS, from *TA\\MAIN\\Source\\UKRegulated\\Database\\Depersonalisation\\Depers & Shrink*\ .

- AZSTG01 is *normally* a partially depersonalised database.
- AZSTG02 is normally a fully depersonalised database.

Choose one of the following as appropriate, and note that while the depersonalisation is continuing, the 

Partial Depersonalisation
-------------------------

..  code-block:: sql

    connect fcs/password
    @partial_depers
    
This will run for some time, a few hours in fact, depending on the speed of the server and/or the type of discs in use for the data and FRA.


Full Depersonalisation
----------------------

For a fully depersonalised database, instead of the above, execute a full depersonalisation:

..  code-block:: sql

    connect fcs/password
    @full_depers
    
This will execute the above partial depersonalisation first, then will depersonalise all the data tables determined to contain personal data. This will obviously run for a bit longer than the partial script.

    **Note**\ : ``AZSTG02`` is always a *fully* depersonalised database. If you are restoring a dump of ``CFG`` to ``AZSTG01``, then only a partial depersonalisation is required.

    
RMAN Backups
============

You must check with ``RMAN`` as to the settings of the parameters for the newly restored database. It will currently reflect the ``CFG`` database and will need changing to match ``AZSTG02``.

..  code-block:: none

    oraenv azstg02
    rman target sys/password@azstg02 nocatalog
    
    configure backup optimization on;
    configure controlfile autobackup on;
    configure archivelog deletion policy to backed up 2 times to disk;
    configure controlfile autobackup format for device type disk
    to '\\Backman01\rmanbackup\backups\AZSTG02\autobackup\%F';

    show all;
    
    # Check and adjust as appropriate, the remaining parameters.
    
    exit;

You may wish to set a different location for the controlfile autobackups, as shown above. The default is to send them to the FRA for the database, into the ``autobackup`` folder.

You will also need to register the database with the ``RMAN`` catalog [sic] if it is to be backed up.

..  code-block:: none

    rman target sys/password catalog rman11g/password@rmancatsrv
    
    register database;
    exit;
    
    

Server Clean Up
===============

After all the above has been completed, the server still contains remnants of the ``CFG`` database that we originally restored. We should get rid of this now.

Remove Parameter Files
----------------------

There will most likely still be an spfile and password file for the ``CFG`` database, if so, these should be deleted from ``%oracle_home%\database`` as should the pfile, if one exists:

..  code-block:: none

    del %oracle_home%\database\initCFG.ora
    del %oracle_home%\database\spfileCFG.ora
    del %oracle_home%\database\pwdCFG.ora
    
Remove Diagnostic Files
-----------------------

Every database creates a huge amount of detritus and this is not automatically cleaned out when the database is removed. Usually this is found in ``%oracle_base%\diag\rdbms\%oracle_sid%`` but ``%oracle_base%`` is not usually defined. (Potential update to the ``oraenv`` script perhaps required?)

Using the Windows File Explorer GUI, navigate to ``c:\OracleDatabase\diag\rdbms`` and delete the entire file tree for the ``CFG`` database.

Remove the Oracle Service
-------------------------

Run the following ``oradim`` command to stop and remove all services related to the ``CFG`` database:

..  code-block:: none

    oradim -delete -sid cfg
    
If that throws an error about the service not existing, it is because it was created in upper case, try the following instead:

..  code-block:: none

    oradim -delete -sid CFG
    
    