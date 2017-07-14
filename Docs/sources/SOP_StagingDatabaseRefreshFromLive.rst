================================================
Refreshing AZSTG01/02 from Production Dump Files
================================================

Abstract
========

Refreshing the staging databases from production dump files carries out two significant DBA tasks in one exercise:

- It refreshes the staging databases;
- More importantly, it proves that the production backups are valid, readable and can be used to restore the database;

In addition, by using the daily dumps, we avoid the possibility of any impact on the production server as there would normally be around 7 RMAN sessions logged in and working to varying degrees of intensity, on the production database had we run a ``duplicate from active database``.

    **Warning**: You must be aware that during the copying of the data files, the auxiliary database must have block change tracking disabled. If you don't do this, a bug in Oracle will trash the auxiliary database.


Process Outline
===============

The outline of the processes to be followed are:

-   Drop the staging database.
-   Run a "non-target" RMAN ``duplicate`` while connected *only* to the auxiliary database, the staging database in other words.
-   Update the ``LEEDS_CONFIG.DATABASE_INFORMATION`` table with the date of the backup we used.
-   Clean up afterwards.


The example described below restores the ``CFG`` database to the ``AZSTG01`` database.


Drop the Existing Staging Database
==================================

The existing staging database needs to vanish. We will be using  the same locations for data, FRA and redo files but we need to clear out any existing detritus first.

..  code-block:: sql

    oraenv azstg01
    sqlplus sys/password as sysdba
    
    -- Make sure we are on the correct database first!
    select name, db_unique_name from v$database;
    
    startup force restrict mount
    drop database;
    exit

In the Windows file explorer GUI, navigate to ``c:\oracledatabase\diag\rdbms`` and shift-delete the existing staging database diagnostics tree. ``Azstg01`` for this example.

Navigate to ``g:\mnt\oradata\azstg01`` and shift-delete the *contents*.

Navigate to ``h:\mnt\fast_recovery_area\azstg01`` and shift-delete the *contents*.

Check that the old spfile, ``spfileazstg01.ora``, has been deleted from ``%oracle_home%\database``.

If a password file exists, and it should, leave it alone as we will reuse this. The file will be named  ``pwdAZSTG01.ora``. 

A pfile named ``initAZSTG01.ora`` may exist, it should contain *only* the following contents:

..  code-block:: none

    db_name=azstg01
    memory_target=4G
    memory_max_target=5G
    sga_target=2G
    sga_max_size=3G
    pga_aggregate_target=500M
    db_recovery_file_dest_size=200g

If the ``initAZSTG01.ora`` file contains more than the above, edit out everything except the above. The parameters specified are those we wish to propagate out to other databases that are refreshed (cloned) from this staging database.
   
    
Restore the CFG Database Dumps
==============================

**URGENT** There is a bug/feature in Oracle ``RMAN`` whereby when a database is being cloned from a dump of another database, and the source database is running with block change tracking enabled, then there is an intermittent possibility that the ``alter database open resetlogs`` of the clone will fail, and much manual work will require to be done to resolve the problem.

To clone the database you must:

-   Start the ``RMAN`` clone, and wait for it to complete restoring the control files, and then mounting the database;
-   Login to ``SQL*Plus`` as SYSDBA and disable block change tracking on the clone;
-   Allow the ``RMAN`` clone to continue.

Start the RMAN Clone
--------------------

To restore the database dumps as a new database, we simply run a ``DUPLICATE DATABASE ...`` command within ``RMAN``, while connected *only* to the ``AZSTG01`` database as the auxiliary database:

..  code-block:: none

    oraenv azstg01
    sqlplus sys/password as sysdba
    startup nomount pfile='?\database\initAZSTG01.ora'
    exit

    cd /d f:\builds\AZSTG01_REFRESH

    rman AUXILIARY sys/password@azstg01
        
    @refresh_azstg01.rman


Urgently Disable Block Change Tracking
--------------------------------------

If you monitor the execution of the ``RMAN`` script, you will see the following, shortly after it begins:

..  code-block:: none

    Starting restore at 2017/05/31 09:29:02
    ...
    channel x1: restoring control file
    channel x1: restore complete, elapsed time: 00:00:14
    output file name=G:\MNT\ORADATA\AZSTG02\CONTROL01.CTL
    output file name=H:\MNT\FAST_RECOVERY_AREA\AZSTG02\CONTROL02.CTL
    Finished restore at 2017/05/31 09:29:16

    database mounted

At this point, there is a useful delay while ``RMAN`` reads data from the restored controlfile to enable it to determine the correct backup(s) and files to use to clone the database. Now is the time to disable block change tracking. The delay can be quite extended in actual fact. It's because Oracle is running an internal scan of the backup files to locate the one(s) it needs. This has been seen to take over two hours! This gives you plenty of time to turn off block change tracking. The code being executed to run the scan is ``DBMS_BACKUP_RESTORE.processSearchFileTable`` and appears to be reading the controlfile, very, *very*, slowly!

In a separate session, Toad etc, login to the staging database as SYSDBA and:
    
..  code-block:: sql

    alter database disable block change tracking;
    select * from v$block_change_tracking;
    
You may get a hug session. Don't worry. Just CTRL-C twice and log back in again. You need to catch the database when it isn't looking. Leave a couple of minutes between attempts for best results. If you leave the hug session hung, it (so far anyway) will never return.

Once you get a response, which should be immediate when the command works, you will have disabled block change tracking on the staging database.
    
If you neglect to do this step, there is a 50-50 chance that the following will occur after everything has completed:

..  code-block:: none

    ORA-00283: recovery session cancelled due to errors
    ORA-19755: could not open change tracking file
    ORA-19750: change tracking file: 'F:\MNT\FAST_RECOVERY_AREA\CFG\BCT.DBF'
    ORA-27041: unable to open file
    OSD-04002: unable to open file
    O/S-Error: (OS 3) The system cannot find the path specified.
    RMAN-00571: ===========================================================
    RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
    RMAN-00571: ===========================================================
    RMAN-03002: failure of Duplicate Db command at 05/25/2017 14:33:46
    RMAN-05501: aborting duplication of target database

See the "Fix for Block Change Tracking Problems" section below, for a fix for this problem. The database will not be able to be opened if the above error has occurred. You will also note that the file name mentioned is the file name for the production database. This is the cause of the problem. Also, the error doesn't *always* occur!

As long as you disable block change tracking, on the staging database being refreshed, *before* ``RMAN`` attempts to ``alter database open resetlogs``, you will be safe.


Continue the RMAN Clone
-----------------------

The ``refresh_azstg01.rman`` script does the hard work, and (currently) contains the following contents:

..  code-block:: none

    #------------------------------------------------------------
    # Clone AZSTG01 from CFG Backups using RMAN.
    #------------------------------------------------------------

    run {
        #
        # As we don't connect to a TARGET, we can only have 
        # AUXILIARY channels.
        #

        allocate auxiliary channel x1 device type DISK;
        allocate auxiliary channel x2 device type DISK;
        allocate auxiliary channel x3 device type DISK;
        allocate auxiliary channel x4 device type DISK;
        allocate auxiliary channel x5 device type DISK;
        
        duplicate database CFG to AZSTG01
        spfile
            set instance_name 'azstg01'
            set service_names 'azstg01'
            set fal_server=''
            set log_archive_config=''
            set log_archive_dest_2=''
            set log_archive_dest_3=''
            set dispatchers '(PROTOCOL=TCP) (SERVICE=azstg01XDB)'
            set audit_file_dest 'C:\ORACLEDATABASE\ADMIN\azstg01\ADUMP'
            set db_recovery_file_dest 'h:\mnt\fast_recovery_area'
            set dg_broker_start 'false'
            set control_files
                'g:\mnt\oradata\azstg01\control01.ctl',
                'h:\mnt\fast_recovery_area\azstg01\control02.ctl'
            set db_file_name_convert
                'e:\mnt\oradata\cfg',
                'g:\mnt\oradata\azstg01',
                'f:\mnt\fast_recovery_area\cfg',
                'h:\mnt\fast_recovery_area\azstg01'
            set log_file_name_convert
                'e:\mnt\oradata\cfg',
                'g:\mnt\oradata\azstg01',
                'f:\mnt\fast_recovery_area\cfg',
                'h:\mnt\fast_recovery_area\azstg01'
        #
        # We must tell RMAN where to find the backups as we are
        # not connecting to the CATALOG either.
        #

        backup location '\\Backman01\RMANBackup\backups\cfg\'
        nofilenamecheck;

        release channel x1;
        release channel x2;
        release channel x3;
        release channel x4;
        release channel x5;
    }

As noted in the comments, running a ``DUPLICATE DATABASE`` command from dumps only requires that we:

-   Do not attempt to allocate any channels *except* AUXILIARY ones;
-   Tell RMAN what database to duplicate from;
-   Tell RMAN where to look for the dumps of the named database.

    
Post Restore Clean Up
=====================

The following housekeeping tasks require attention after a refresh.

Update Refresh Date Table
-------------------------

..  code-block:: sql

    truncate table leeds_config.database_information;
    insert into leeds_config.database_information values (to_date('some_date', 'yyyy/mm/dd'));
    commit;
    
In the above, ``some_date`` is a string showing the date of the backup that was used to restore the database. Normally, this is "yesterday" so you could use:

..  code-block:: sql

    insert into leeds_config.database_information values (trunc(sysdate)-1);
    commit;

However, if you restored from a specific database dump, please ensure you use that actual date instead.

Production Service & Trigger
----------------------------

Once the database is open, we need to drop the existing trigger and any services that relate to the source, ``CFG``, database. This is especially required when the source database was a member of a primary-standby pairing.

..  code-block:: sql

    show parameter service_names
    
The result will most likely be:

..  code-block:: none

    NAME           TYPE        VALUE
    -------------- ----------- ------
    service_names  string      CFGSRV
    
Although you may see the following at times:

..  code-block:: none

    NAME           TYPE        VALUE
    -------------- ----------- ------
    service_names  string      CFGSRV, AZSTG01
    

This is still using the production service name, and not the default service name of ``AZSTG01``. 

There will be a trigger, owned by SYS, which fires after the databases has been started up and opened, which enables the ``CFGSRV`` service listed above. The trigger name *should* be the service name plus a suffix of ``_trigger``, ``CFGSRV_trigger`` in this example. The trigger must be dropped and the service disabled and deleted.

..  code-block:: sql

    drop trigger sys.CFGSRV_trigger;
    
    exec dbms_service.stop_service('CFGSRV');
    exec dbms_service.delete_service('CFGSRV');
    
    show parameter service_names

The result should now be:

..  code-block:: none

    NAME           TYPE        VALUE
    -------------- ----------- ------
    service_names  string      AZSTG01

    
Other Parameters
----------------

..  code-block:: sql

    select status, filename 
    from v$block_change_tracking;

If the result shows 'disabled' then we need to enable it:

..  code-block:: sql

    alter database enable block change tracking
    using file 'H:\mnt\fast_recovery_area\AZSTG01\bct.dbf' reuse;

Obviously, replace 'H' with the correct drive letter for the FRA disc, and set the database name correctly. 

Some other parameters might also need to be changed from their ``CFG`` values:

..  code-block:: sql

    select name, value
    from v$parameter
    where upper(value) like '%CFG%'    
    and lower(name) not like '%file_name_convert';

'No rows selected' is a good result. If, on the other hand, there are some rows selected, they will most likely be one of the following, so apply the appropriate fix(es):

..  code-block:: sql

    alter system set instance_name='azstg01' scope=spfile;

    alter system set service_names='azstg01' scope=spfile;

    alter system set audit_file_dest =
    'C:\ORACLEDATABASE\ADMIN\azstg01\ADUMP' scope = spfile;

    alter system set dispatchers=
    '(PROTOCOL=TCP) (SERVICE=azstg01XDB)' scope=spfile;
    
    alter system set fal_server='' scope=both;
    
    alter system set log_archive_config='' scope=both;
    
    alter system set log_archive_dest_2 = '' scope=both;
    
    alter system set log_archive_dest_3 = '' scope=both;

If you had to make any changes with ``scope=spfile``, then restart the database:

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
        dbms_scheduler.drop_job(job_name => 'FCS.ALERTS_HEARTBEAT');

        dbms_scheduler.disable(name => 'FCS.CLEARLOGS',
                               force => true);
        dbms_scheduler.drop_job(job_name => 'FCS.CLEARLOGS');

        dbms_scheduler.disable(name => 'FCS.JISA_18BDAY_CONVERSION',
                               force => true);
        dbms_scheduler.drop_job(job_name => 'FCS.JISA_18BDAY_CONVERSION');

        dbms_scheduler.disable(name => 'PERFSTAT.PURGE_DAILY',
                               force => true);
        dbms_scheduler.drop_job(job_name => 'PERFSTAT.PURGE_DAILY');
        
        dbms_scheduler.disable(name => 'PERFSTAT.SNAPSHOT_EVERY_15MINS',
                               force => true);
        dbms_scheduler.drop_job(job_name => 'PERFSTAT.SNAPSHOT_EVERY_15MINS');
    end;
    /

PERFSTAT is not required on the staging databases:

..  code-block:: sql

    drop user perfstat cascade;

If there is an error that *you cannot drop a user that is connected* then the above running job(s) for PERFSTAT are still running in the background. The database should be restarted.

..  code-block:: sql

    shutdown abort;
    startup 
    drop user perfstat cascade;

For all non-production databases, disable the SYS owned jobs that should only be running on production:

..  code-block:: sql

    begin
        dbms_scheduler.disable(name => 'SYS.AUDIT_ARCHIVING', force => true);
        dbms_scheduler.drop_job(job_name => 'SYS.AUDIT_ARCHIVING');        

        dbms_scheduler.disable(name => 'SYS.EXPIRE_PASSWORDS', force => true);       
        dbms_scheduler.drop_job(job_name => 'SYS.EXPIRE_PASSWORDS');

        dbms_scheduler.disable(name => 'SYS.UTMSODRM', force => true);
        dbms_scheduler.drop_job(job_name => 'SYS.UTMSODRM');
    end;
    /
    

Change Passwords
----------------

Certain users will require to have their password changed as they now reflect production. At the *very least* you must change the FCS password to that found in ``Keepass`` for the staging database. In addition, change any other passwords found for the staging database in ``Keepass`` to suit.

..  code-block:: sql

    alter user FCS identified by <kepass_password>;

    
Drop Database Links
-------------------

We do not want, or need the production database links in a staging database used to refresh other databases, so:

..  code-block:: sql

    drop public database link CFGTRAIN_LINK;
    drop public database link CFGSB_LINK;
    drop public database link CFGAUDIT_LINK;

   

Depersonalisation
=================

Regardless of the database being restored, we must ensure that, at least, a partial depersonalisation is performed. The code can be obtained from TFS, from *TA\\MAIN\\Source\\UKRegulated\\Database\\Depersonalisation\\Depers & Shrink*\ .

- AZSTG01 is *normally* a partially depersonalised database.
- AZSTG02 is normally a fully depersonalised database.

Choose the correct script to run as appropriate.

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

You must check with ``RMAN`` as to the settings of the parameters for the newly restored database. It will currently reflect the ``CFG`` database and will need changing to match ``AZSTG01`` - even though this database is not normally backed up, we don't want it to impinge on production if we do decide to take an adhoc backup.

..  code-block:: none

    oraenv azstg01
    rman target sys/password@azstg01 nocatalog
    
    configure archivelog deletion policy to none;
    configure backup optimization on;
    configure controlfile autobackup on;
    configure controlfile autobackup format for device type disk clear;
    configure retention policy to redundancy 1;
    show all;
    
    # Check and adjust as appropriate, the remaining parameters.
    
    exit;

We have reset the location for the controlfile autobackups, as shown above. The default is to send them to the FRA for the database, into the ``autobackup`` folder.

You will also need to register the database with the ``RMAN`` catalog [sic] if it is to be backed up.

..  code-block:: none

    rman target sys/password catalog rman11g/password@rmancatsrv
    
    register database;
    exit;
    
    
..  _FIX_BCT:
    
Fix for Block Change Tracking Problems
======================================

As noted above, if the block change tracking is not turned off, Oracle *sometimes* fails in setting up block change tracking on the cloned database, as it attempts to use the source database's path for the BCT file, and that fails on the destination server if the path doesn't exist. The process is as follows:

-   Recreate the controlfiles;
-   Recover the database;
-   Open the database & reset the logs;
-   Add the temporary tablespace files;
-   Create an spfile;
-   Restart the database.

Recreate the Controlfiles
-------------------------

If you look at the various "name" parameters for the cloned database, you will see that ``DB_NAME`` is still set to the CFG database name, plus, the control file will also have CFG recorded as the database name. We cannot open the database in this state, so, we need to recreate the control files. Login to the database, which is most likely MOUNTed, and should be, as SYSDBA and:

..  code-block:: sql

    alter database
    backup controlfile to trace
    as '?\database\controlfile.sql'
    resetlogs;
    
This creates a SQL script to recreate the control files. The file is located in ``%ORACLE_HOME%\database`` and needs to be edited.

-   Delete all the text - comments - down to the ``CREATE CONTROLFILE REUSE...`` command. 
-   Delete, or comment out, all the commands after the closing ';' for the above command, however, keep any commands relating to the temporary tablespace(s) near the end. We need these later.
-   Make sure that all redo-log paths are correct for the staging database, they may still relate to the production database.
-   Make sure that all the data file paths are correct for the staging database.
-   Save the file.

The spfile is also incorrect, so we need a pfile to be generated so that we can correct it:

..  code-block:: sql

    create pfile='?\database\initTEMP.ora' from spfile='?\database\spfileAZSTG01.ora';
    
Edit the generated pfile and correct the ``DB_NAME`` parameter, and any others that still indicate the production database. You can ignore the various file_name_convert parameters though.

Now we need to start the database in ``NOMOUNT`` mode, using the *current, incorrect, spfile*, and recreate the controlfiles:

..  code-block:: sql

    shutdown abort
    startup nomount
    @?\databasecontrolfile.sql
    
If the script errors out, fix the problems and rerun the script.    

    
Recover the Database
--------------------

The database should now be mounted:

..  code-block:: sql

    alter database mount;

If Oracle says it is already mounted, you can ignore the error. Usually a database is mounted after recreating the controlfiles, but it's best to be absolutely sure. Try opening the database:
    
..  code-block:: sql

    alter database open resetlogs;
    
If this works, then we will not need to recover the database. Proceed to the next section - adding back the temporary tablespace files.

The database needs some further recovery, so for this we will need at least one archived log from the production server. To find out which one, we should attempt a recovery:

..  code-block:: sql

    recover database using backup controlfile until cancel;
    
Oracle will suggest an archived log to use to begin the recovery. Make a note of the date, and the sequence number from the filename, for example:

..  code-block:: none

    ORA-00279: change 297591712 generated at 05/25/2017 03:39:27 needed for thread 1
    ORA-00289: suggestion : H:\MNT\FAST_RECOVERY_AREA\AZSTG01\ARCHIVELOG\2017_05_25\O1_MF_1_13770_%U_.ARC
    
In the suggested file, Oracle wants sequence 13770 which was created on 25th may 2017. Cancel the recovery now.

..  code-block:: sql

    CANCEL

It should be in upper case.

We now need to exit from ``SQL*Plus`` and use ``RMAN`` to do the recovery. It is easier this way because the files we copy from production will not match exactly the randomly generated names given in the suggestion. ``SQL*Plus`` cannot cope with this, but ``RMAN`` can.

On the *production* server, locate the FRA for the database, and the ``archivelog`` folder that matches the date suggested by the previous recover attempt that we cancelled. Find the appropriate archived log file with the desired sequence number - 13770 in this example - and copy that, plus the next 4 sequential logs (13771 - 13774) from production to the FRA for the staging database, into a folder on the staging server, with the same name as that on the suggested filename mentioned above - usually yyyy-mm-dd.

In ``RMAN`` attempt a recovery. You will not need to rename the 5 copied archived logs. RMAN will find the correct ones, note the file names as they are, and apply them.

..  code-block:: none

    rman target sys/password@azstg01
    
    run {
        set until sequence = nnnn;
        recover database using backup controlfile;
    }
    
In the above, 'nnnn' is *one higher* than the highest sequence of the archived logs you copied from the production server - 13775 in this example. Once the recovery is done, attempt to open the database:
    
..  code-block:: none

    alter database open resetlogs;

If the attempt fails, further recovery is needed. Copy the next 5 archived logs from production to the staging server and repeat the above commands with the appropriate change to the until sequence specified.

Exit from ``RMAN`` when the database opens.


Add Temporary Tablespace Files
------------------------------

In ``SQL*Plus`` as the SYSDBA user again, we need to add the TEMP tablespace's files.

..  code-block:: sql

    alter tablespace temp add tempfile
    'h:\mnt\oradata\AZSTG01\temp01.dbf' size 20m
    autoextend on next 20m maxsize unlimited;
    
    alter tablespace temp add tempfile
    'h:\mnt\oradata\AZSTG01\temp02.dbf' size 20m
    autoextend on next 20m maxsize unlimited;
    


Create the Spfile
-----------------

The database is currently running with an incorrect spfile. We need to create a new spfile from the temporary pfile we created earlier:

..  code-block:: sql

    create spfile='?\database\spfileAZSTG01.ora' from pfile='?\database\initTEMP.ora';
    

Restart the Database
--------------------

The database should now be able to be restarted with the newly created spfile:
    
..  code-block:: sql

    startup force;
    
The temporary pfile can be deleted:

..  code-block:: none

    del %oracle_home%\database\initTEMP.ora;
    
The database is now ready for use, and for the post clone tidy up to be carried out. See above for details. 

