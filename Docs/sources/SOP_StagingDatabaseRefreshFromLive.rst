================================================
Refreshing AZSTG01/02 from Production Dump Files
================================================

Abstract
========

Refreshing the staging databases from production dump files carries out two significant DBA tasks in one exercise:

- It refreshes the staging databases;
- More importantly, it proves that the production backups are valid, readable and can be used to restore the database;

In addition, by using the daily dumps, we avoid the possibility of any impact on the production server as there would normally be around 7 RMAN sessions logged in and working to varying degrees of intensity, on the production database had we run a ``duplicate from active database``.


Process Outline
===============

The outline of the processes to be followed are:

-   Drop the staging database.
-   Run a "non-target" RMAN ``duplicate`` while connected *only* to the auxiliary database, the staging database in other words.
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

If the ``initAZSTG01.ora`` file contains more than the above, edit out everything except the above.
   
    
Restore the CFG Database Dumps
==============================

To restore the database dumps as a new database, we simply run a ``DUPLICATE DATABASE ...`` command within RMAN, while conneted *only* to the ``AZSTG01`` database as the auxiliary database:

..  code-block:: none

    oraenv azstg01
    sqlplus sys/password as sysdba
    startup nomount pfile='?\database\initAZSTG01.ora'
    exit

    cd f:\builds\AZSTG01_REFRESH

    rman AUXILIARY sys/password@azstg01
        
    @refresh_azstg01.rman

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
        dbms_scheduler.disable(name => 'FCS.CLEARLOGS',
                               force => true);
        dbms_scheduler.disable(name => 'FCS.JISA_18BDAY_CONVERSION',
                               force => true);
        dbms_scheduler.disable(name => 'PERFSTAT.PURGE_DAILY',
                               force => true);
        dbms_scheduler.disable(name => 'PERFSTAT.SNAPSHOT_EVERY_15MINS',
                               force => true);
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

You must check with ``RMAN`` as to the settings of the parameters for the newly restored database. It will currently reflect the ``CFG`` database and will need changing to match ``AZSTG01`` - even though this database is not normally backed up, we don't want it to impinge on production if we do decide to take an adhoc backup..

..  code-block:: none

    oraenv azstg01
    rman target sys/password@azstg01 nocatalog
    
    configure backup optimization on;
    configure controlfile autobackup on;
    configure archivelog deletion policy to backed up 2 times to disk;
    configure controlfile autobackup format for device type disk
    to '\\Backman01\rmanbackup\backups\AZSTG01\autobackup\%F';

    show all;
    
    # Check and adjust as appropriate, the remaining parameters.
    
    exit;

You may wish to set a different location for the controlfile autobackups, as shown above. The default is to send them to the FRA for the database, into the ``autobackup`` folder.

You will also need to register the database with the ``RMAN`` catalog [sic] if it is to be backed up.

..  code-block:: none

    rman target sys/password catalog rman11g/password@rmancatsrv
    
    register database;
    exit;
    
    

