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

Check that the old spfile, ``spfileazstg02.ora``, has gone from ``c:\oracledatabase\product\11.2.0\dbhome_1\database``.

If a password file exists, leave it alone as we will reuse this. The file will be named  ``pwdazstg02.ora``. Ditto a pfile named ``initazstg02.ora`` which should only contain the following contents:

..  code-block:: none

    db_name=azstg02
    
Finally, stop the existing Oracle service:

..  code-block:: none

    net stop OracleServiceazstg02
    
    
Restore the CFG Database Dumps
==============================

The production database backup files can now be restored to the pre-production server as a new database named ``CFG``, as per the instructions in the *RMANRestore.docx* document available from TFS, at *TA\\DEV\\Projects\\Oracle Upgrade 9i to 11g\\UKRegulated\\Database\\DBA Documentation*\ .

    **Note**\ : be aware that the example given in that document is a restore of the azdba01 database, which was indeed the database restored when the document was created. You should replace paths and database names to match the ``CFG`` database that you will be restoring.

Return to this document when you have completed the restore.



Rename the Database Using 'Nid'
===============================

If you did not rename the database as part of the restore, then you must do it now.

The database will be renamed using the ``nid`` utility as it currently has the same ``DBID`` as the database it was restored from, ``CFG``, and if you attempt to back it up, you may corrupt the backup details for the CFG database, in the ``RMAN`` catalogue.

..  code-block::

    oraenv cfg
    
    sqlplus sys/password as sysdba
    shutdown immediate
    startup mount
    
If you have a large number of data files, then:

..  code-block::

    alter system set open_cursors=1500 scope=memory;
    
Then exit from the database.

In a DOS (shell) session:

..  code-block::

    nid target=sys/password dbname=azstg02 setname=y logfile=nid_azstg02.log
    
The database will be left closed when the above command completes. You *must* check the logfile.

Post Rename Configuration
=========================

Once the database has been renamed, there's a little more work to do.

Create a New Password File
--------------------------

In ``%ORACLE_HOME%\database`` copy, or rename, the password file to suit the new staging database name. If there is no current password file, then create a new one:

..  code-block:: none

    cd %oracle_home%\database
    orapwd file=pwdAZSTG02.ora password=<SysPassword> entries=10

Create a New Spfile
-------------------

If no spfile exists for the new staging database, then create one in the normal manner, based on the ``CFG`` spfile:

..  code-block:: sql

    create pfile='?\database\initAZSTG02.ora'
    from spfile '?\database\spfileCFG.ora' ;
    
    host "notepad %oracle_home%\database\initAZSTG02.ora" ;
        
You will need to change the ``db_name`` parameter, at the very least, to reference ``AZSTG02`` rather than ``CFG``. Any other parameters will need similar adjusting where they currently contain ``CFG`` in their value.

Once complete, save the file and exit from notepad, back into SQL*Plus. Then:

..  code-block:: sql
       
    create spfile '?\database\spfileAZSTG02.ora' 
    from pfile '?\database\initAZSTG02.ora';
    
    shutdown immediate
    startup mount
    
        
You *may* get told that the database name in the controlfile is still the old one, especially if you *copied* the ``CFG`` spfile to the ``AZSTG02`` spfile, rather than creating a new one. This is easily fixed, however:

..  code-block:: sql

    alter system set db_name='AZSTG02' scope=spfile;
    
    shutdown immediate
    startup mount

    **Warning**\: you should also check for other parameters that reference ``CFG`` if you did copy the spfile. These will need correcting too.
    
Post Restore Clean Up
=====================

The database has now been restored, and should now be named ``AZSTG02`` - for this exercise. However, there are still services etc which exist purely for Data Guard, and for the production database, and these need to be removed.


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

Obviously, replace 'H' with the correct drive letter for the FRA disc. Some other parameters might also need to be changed from their ``CFG`` values:

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


For all non-production databases, there should be no jobs owned by FCS in the listing. If there are, they must be disabled:

..  code-block:: sql

    begin
        dbms_scheduler.disable(name => 'FCS.ALERTS_HEARTBEAT');
        dbms_scheduler.disable(name => 'FCS.CLEARLOGS');
        dbms_scheduler.disable(name => 'FCS.JISA_18BDAY_CONVERSION');
    end;

Check also that there are no PERFSTAT jobs active. If there are, the solution is a little more drastic:

..  code-block:: sql

    drop user perfstat cascade;

We tend to only be interested in PERFSTAT on production databases.


Depersonalisation
=================

Regardless of the database being restored, we must ensure that, at least, a partial depersonalisation is performed. The code can be obtained from TFS, from *TA\\MAIN\\Source\\UKRegulated\\Database\\Depersonalisation\\Depers & Shrink*\ .

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
    
    