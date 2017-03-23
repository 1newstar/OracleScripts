.. pandoc -f rst -t docx -o RMANRestore.docx --reference-docx=pandoc_reference.docx --table-of-contents --toc-depth=3 RMANRestore.rst
   is the command that will convert this document to a Word docx file.
   
.. pandoc -f rst -t pdf -o RMANRestore.pdf --listings -H listings_setup.tex --table-of-contents --toc-depth=3 RMANRestore.rst
   -- variable tocolor="Cool Grey" -- variable urlcolor="Cool Grey" -- variable linkcolor="Cool Grey" 
   is the command that will convert this document to a PDF file.
   
.. Norman Dunbar
   November 2016..March 2017.   

======================================================
RMAN Restores & Backup Validation to Different Servers
======================================================

Abstract
========

This document shows how the AZDBA01 database was copied from server ORCDEVORC01 to server DEVORC01 using a previously taken ``RMAN`` incremental level 0 backup. As this restore is simply a backup verification and not a restore back to the same place exercise, we must be careful when using the ``RMAN`` catalog.

If, on the other hand, this was an *actual restore*, to the *same location* on the *same server*, life is much easier - we simply connect to the target database and the catalog and issue the following commands:

..  code-block:: sql

    set until .... ;  # SCN, sequence or time ...
    restore database ;
    recover database ;
    alter database open resetlogs;
    exit;

For backup proving or ad-hoc restores to check/extract older data, and where the restore is to a *different* location or *server*, we must *avoid using the catalog* as any commands executed that affect the *restored database* will update the recorded details of the *source database* in the catalog, and may/will affect or fail future backups.

    
Two different backup proving exercises were carried out, and are described fully below:

- **A *point in time* restore** which proved that the dump files created by RMAN were actually *usable* in the event that a restore & recover to a given point in time was ever required. This exercise proved that all the required database backups, level 0 and subsequent level 1s, *and* the archived logs, were available, readable and could be restored.

- **A *validation* restore** which proved that the dump files **for the most recent level 0 backup prior to the desired restore point** were at the very least readable. It did not (and indeed can not) prove anything about any subsequently taken incremental level 1 backups, or, any of the archived logs that would be required to be used to physically restore and recover the database to any given point in time.


Server Preparation
==================

Points to note
--------------

- You *cannot* restore a backup of a database to a differently named database, even on a different server.

- The server where the database is being restored, in full or just for validation, must have the appropriate version of Oracle Software installed. At present, this is 11.2.0.4 for all databases on all servers so that's currently ok. The versions must match exactly on source and destination servers, you cannot restore a dump taken on an 11.2.0.4 server to an 11.2.0.3 server, for example.

- You need to collect certain information about the source database in order to replicate it on the destination server. This information is usually found in the RMAN backup log, but if that's not available, see the section *Collecting Required Information*, below, for helpful details. 

- There must be an Oracle Service created for the database being restored. The ``oradim`` command will set one up for you, as follows::

        oradim -new -sid azdba01 -startmode auto -shutmode immediate

  This service will start with the server - after a reboot - and will shut the database down in immediate mode, if the service is stopped. 

  **Warning:** Normally we would not configure a service to start the database automatically after a shutdown (or crash) as this can mess up primary and standby databases as Windows will start the database in ``OPEN`` mode, even if it is a standby database!

- There must be a location on the destination server which can see the files created by the source server's ``RMAN`` backups. This can be using a mapped drive (``Z:\`` for example) or simply the full UNC name of the source server's share (``\\orcdevorc01\h$\backups\azdba01``). 

  **Note:** ``RMAN`` has been known to not see mapped drives while it can see the full UNC name, but in this exercise, this has not been tested, so it has been left here as a possibility. These exercises used local discs and copied the data between servers.
  
  In this exercise, we are creating a dedicated folder on the ``e:\`` drive, and simply copying files into it from the source server.
  
- **The catalog must not be used**. If the catalog is connected at any time, the locations used in the restores will be logged against the source database as they will, for the duration of the exercise, have the same DBID. This will mess up the subsequent backups as, for example, archived logs are searched for on non-existent locations on the source server.

- The source database must be configured, in ``RMAN``, to have controlfile autobackups on.

    **You should be aware that the backups for the production and/or preproduction databases are owned by the appropriate service users -  casfs\svc_oracleprod for production, casfs\svc_oracleppd for pre-production - and in order to use them for a restore operation, you must be running as one of these service users. 
    
    Files owned by the production user can be read by the pre-production user, as this can facilitate testing that production restores work, if you are running the test on the pre-production servers.


Collecting Required Information
-------------------------------

Regardless of the type of restore to be done, using the backups and archived logs for a database on one server, to restore to another, requires at least the following information which can be obtained from the ``RMAN`` log for the appropriate backup being tested/restored:

- DBID: 692009496
- Archive Log sequence: 73
- CF/SPFILE Autobackup location: g:\\mnt\\oradata\\azdba01\\....


DBID
~~~~

The ``DBID`` is obtained from the top of the ``RMAN`` log, or from the prompts when you connect to the database with ``RMAN``::

    connected to target database: AZDBA01 (DBID=692009496)

    
Archived Log Sequence
~~~~~~~~~~~~~~~~~~~~~

The archive sequence is the highest one in the ``RMAN`` log. It appears near the end, just above the details of the controlfile and spfile autobackup::

    ...
    input archived log thread=1 sequence=73 RECID=73 STAMP=928589967
    
    Starting Control File and SPFILE Autobackup at 2016/11/22 13:39:54
    piece 
    ...

If you are unable to extract the required sequence, you should use a date and time instead.
    

Spfile and Controlfile Autobackup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The controlfile and Spfile backups are taken at the end of every ``RMAN`` backup, no matter what else was backed up. You can never have too many backups of these files. Close to the end of the ``RMAN`` log, you will find the required details::
    
    Starting Control File and SPFILE Autobackup at 2016/11/22 13:39:54
    piece handle=G:\MNT\FAST_RECOVERY_AREA\AZDBA01\AUTOBACKUP\2016_11_22\O1_MF_S_928589997_D38LOL9P_.BKP comment=NONE
    Finished Control File and SPFILE Autobackup at 2016/11/22 13:40:12

The filename mentioned will have copies of the spfile and controlfiles, and we will definitely require those on the destination server.

Again, if you do not have the logfile for the backup, you should be able to extract a suitable filename from the following ``RMAN`` commands, while connected to the source database (and possibly the catalog, but remember to disconnect from the catalog prior to running any restores etc)::

    list backup of spfile summary;

The output will list the various backups, and their tags. The tag format defaults to "YYYYMMDDHHMMSS". Once you find a suitable tag, you can determine the filename required by::

    list backup tag "tag from the above";

Look for the details of the *Piece Name* which will indicate the required backup file. Also, check for the presence of the following line in the output::

    Control File Included ...

This indicates that the file is an autobackup and that the spfile and controlfiles can be restored from the same file. If the controlfile is not present, repeat the above using::

    list backup of controlfile summary;

Then, select a suitable backup of the controlfile that is as close as possible to the required data and time you wish to restore back to.

You need the appropriate file for both the controlfiles and the spfile backups.


Scripts to Rename Data and Redo Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  

If the database is merely being *validated*, skip this section.

If the database is being *physically* restored to a set of paths on the destination server, that are *identical* to those on the source server, then skip this section.
  
The restore and recover will normally attempt to write the data files back to the same location as the source database. If we are intending to restore to different paths, we need an ``RMAN`` script to be generated to rename the data files prior to the restore of the database on the new server. There are two ways (at least) to do this, a hard way and an easy way if we are using Oracle 11gR2 onwards. Both are described below, pick one.

This is required because the database parameters ``DB_FILE_NAME_CONVERT`` and ``LOG_FILE_NAME_CONVERT`` *do not work* in an ``RMAN`` restore operation.

We also require a ``SQL*Plus`` script to rename the online redo logs.

The Hard Way
""""""""""""

Run the following query, against the source database, as the SYSDBA user, to generate the scripts to carry out the data file renaming, *the hard way*, the easy way follows below:

..  code-block:: sql

    set lines 2000 trimspool on
    set pages 3000 head off feed off
    set echo off verify off
    
    spool rename_dbfiles.rman

    -- Script to rename data files using RMAN...
    -- MAKE SURE that you change the DEFINE to 
    -- suit your new database locations.
    define DEST_PATH=e:\mnt\oradata\AZDBA01\
    
    -- The following will use the define above.
    select 'set newname for datafile '|| file# || 
    ' to ''&DEST_PATH' || 
    substr(name, instr(name, '\', -1) +1) || ''';' 
    from v$datafile
    --
    union all
    --
    select 'set newname for tempfile '|| file# || 
    ' to ''&DEST_PATH' || 
    substr(name, instr(name, '\', -1) +1) || ''';' 
    from v$tempfile;

    spool off

    -- Clean up, to avoid surprises later!
    undefine DEST_PATH


The Easy Way
""""""""""""

The *easy way* is to get RMAN to do all that for you. If, and only if, *all* the data files are located in the same folder, then adding the following line to the RMAN command to restore the database, will rename the data files correctly. **Beware** that it will not rename the temp files though, contrary to what the manual states.

..  code_block:: none

    set newname for database to '?:\mnt\oradata\%d\%b';
    
In the code above, the '?' should be replaced by the drive letter where the data files are desired to be located on the destination server.


Renaming Redo Logs
""""""""""""""""""

The following snippet will tell you the replacements that might be needed for the log file renaming:

..  code-block:: sql

    select distinct substr(member, 1, 1) 
    from   v$logfile;    
    
The result(s) can be used as the 'from' defines below - ``LOG_A_DRIVE`` and ``LOG_B_DRIVE``.

The redo logs are assumed to be found on two separate drives - the ORADATA for the 'a' variants of the logs, and the FRA for the 'b' variants. If these are to remain unchanged as drive letters after the rename, then simply set the appropriate drive letters accordingly below.

Likewise, the database name in the path might be desired to be changed, in which case set those defines accordingly too, otherwise, set them to be the same, or something t hat cannot occur.

..  code-block:: sql

    spool rename_logs.sql
    
    -- Script to rename REDO logs using SQL*Plus...
    -- Note: REPLACE() is case sensitive. Use correct locations!
    --       AND use UPPERCASE for drive letters and DB Names!
    --
    -- Change the following to suit your source and destination drives.
    -- LOG_A_DRIVE is the drive where REDOnA logs live. Usually ORADATA drive.
    define LOG_A_DRIVE=E

    -- LOG_B_DRIVE is the drive where REDOnB logs live. Usually FRA drive.
    define LOG_B_DRIVE=F

    -- LOG_A_DEST is where the REDOnA logs will be after the restore. ORADATA again.?
    define LOG_A_DEST=G

    -- LOG_B_DEST is where the REDOnB logs will be after the restore. FRA again?
    define LOG_B_DEST=H

    -- SRC_DB is part of the path to ORADATA for the source database.
    define SRC_DB=AZDBA01
    
    -- DEST_DB is part of the path to ORADATA for the destination database.
    -- Can be the same as above.
    define DEST_DB=AZDBA01  
    
    select 'alter database rename file '''|| member || ''' to ''' ||
            replace(
                replace(
                    replace(upper(member),
                           '&LOG_A_DRIVE:','&LOG_A_DEST:'),
                    '&LOG_B_DRIVE:','&LOG_B_DEST:'), 
                '&SRC_DB', '&DEST_DB'
            ) || ''';'
    from v$logfile
    order by 1;
    
    spool off
    
    -- Clean up, to avoid surprises later!
    undefine LOG_A_DRIVE
    undefine LOG_B_DRIVE
    undefine LOG_A_DEST
    undefine LOG_B_DEST
    undefine SRC_DB
    undefine DEST_DB  

The two scripts generated, ``rename_dbfiles.rman`` and ``rename_logs.sql`` will need copying to a suitable location on the destination server. 

**Note:** On Windows, filenames are not case sensitive, however, in the database, comparing their names with ``replace()`` *is* case sensitive. That is the reason why the logfile names were upper-cased before replacing the appropriate drive letters with those of the new server.


Determining Which Backup Files are Required
===========================================

If the backup location can be seen from both servers, then skip this section.

Once we have an idea of the date and time of the end of the backup we wish to restore/test, we need to ensure that the files are available on the destination server. This can be done by using the full UNC path to the backup location on the source server - provided it can be seen from the destination server.

If, on the other hand, the source backup files cannot be seen from the destination server, then they need to be identified and physically coped to the destination server into a temporary location. The remainder of this example assumes the latter case.

If we need to physically copy the files to the destination server, we need to be able to identify them. ``RMAN`` can help, especially if you have the backup log:

..  code-block:: batch

    find /i "Piece Handle" <logfile_name> | sort

The output will be something like the following::

    ---------- RMAN_TEST_BACKUP.LOG
    Piece Handle=``J:\BACKUPS\CFG\C-2081680004-20161103-01`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\C-2081680004-20161103-01`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\2VRJT781_1_1`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\32RJT7GC_1_1`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\31RJT7B6_1_1`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\30RJT794_1_1`` tag=TAGyadayadayada comment=NONE
    Piece Handle=``J:\BACKUPS\CFG\2URJT720_1_1`` tag=TAGyadayadayada comment=NONE

The list of files output by the command are the database dump files that are required on the destination server.

If, on the other hand, the log for the appropriate dump is no longer available, execute the following code in a shell session, on the *source* server:

..  code-block:: batch

    oraenv <source_database>
    rman target sys/<password> catalog rman11g/<password>@rmancatsrv

Once connected with the target database and the catalogue, execute the following commands:

..  code-block:: sql

    spool log to restore_preview.log
    run {
        set until time 'yyyy/mm/dd hh24:mi:ss';
        restore spfile preview;
        restore controlfile preview;
        restore database preview;
    }    
    spool log off;
    exit;
    
Now the backup piece names can be extracted from the logfile, as follows:

..  code-block:: batch

    Rem Find the backup pieces required:
    find /i "Piece Name:" restore_preview.log | sort

The output will resemble this::

    ---------- RESTORE_PREVIEW.LOG
    Piece Name: ``J:\BACKUPS\CFG\C-2081680004-20161103-01``
    Piece Name: ``J:\BACKUPS\CFG\C-2081680004-20161103-01``
    Piece Name: ``J:\BACKUPS\CFG\2VRJT781_1_1``
    Piece Name: ``J:\BACKUPS\CFG\32RJT7GC_1_1``
    Piece Name: ``J:\BACKUPS\CFG\31RJT7B6_1_1``
    Piece Name: ``J:\BACKUPS\CFG\30RJT794_1_1``
    Piece Name: ``J:\BACKUPS\CFG\2URJT720_1_1``
    
The first two files have the same name as these will be the spfile and controlfile backups, and in this restore exercise, they are found in the same file.

Now the free standing archived logs can be extracted from the logfile, as follows:

..  code-block:: batch

    Rem Find the archived logs required:
    find /i "Name:" restore_preview.log | find /v /i "Piece Name:" | find /v /i "spfile" | sort

The output will resemble the following abridged listing::

    ---------- RESTORE_PREVIEW.LOG
    ...
    Name: ``F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3791_D1RX3HSS_.ARC``
    Name: ``F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3792_D1RXZMXZ_.ARC``
    Name: ``F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3792_D1RXZMXZ_.ARC``
    Name: ``F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3793_D1RYVR2M_.ARC``
    Name: ``F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3793_D1RYVR2M_.ARC``
    ...

The backup pieces and archived logs listed above are *all* required to restore and recover the database to the requested date and time.

The backup pieces should be copied to the location on the destination server where you are temporarily having ``RMAN`` think of as the backup area. The archived logs should be copied to the same backup area.

**Please Note:** Make sure that when you come to run the ``catalog start ...`` command in ``RMAN`` that you are *not* connected to the catalog database or future archived logs backups for the source database will try to backup any archived logs in the destination backup location!

** Please Also Note:** The end of the logfile above may indicate that your chosen date and time is not recent enough to restore and recover the database to a non-fuzzy (Oracle's choice of words!) state. Check the end of the log file for details as to whether or not you need to adjust your date and time.


Initialisation of Destination Server
====================================

The preliminary work on the destination server is identical regardless of the type of restore being carried out.

- Create backups folders to hold the backups, if it is required to physically copy the files from the source to the destination server;
- Copy the required backup pieces, and any required archived logs to the backup folder, if the physical backups are required on the destination server;
- If necessary, create an Oracle Service for the destination instance using ``oradim``.
- Create a PFILE for the instance containing only ``DB_NAME=azdba01``, in this example.
- Using ``RMAN``, start the instance in NOMOUNT mode using the above PFILE;
- Recover the SPFILE as a PFILE, overwriting the one created above;
- Edit the PFILE to ensure that parameters are correct for this server & database, and to remove any signs of Data Guard, RAC etc;
- Start the instance again, in NOMOUNT mode, using the restored and edited PFILE;
- Restore the controlfiles;
- Start the instance yet again, this time in MOUNT mode, so that it picks up the restored controlfiles;
- If the dump files were copied to the destination server, or are in a different location to where they were backed up originally, they must be catalogued into the control files. If, on the other hand, they are still in exactly the same location as they were backed up to, the control files already know about them, and they do not need to be catalogued.


You can now restore or validate the database itself by carrying out a Point in time Restore, or a Validation restore as described below. First however, the preparation work.

Create a folder to hold the backups::

    mkdir e:\backups\azdba01

Create a folder for the datafiles, and redo logs::

    mkdir e:\mnt\oradata\azdba01
    mkdir e:\mnt\fast_recovery_area\azdba01
    
Are these locations different from the database we are restoring? If so, we need the two scripts generated above - one to set a newname for the datafiles, and one to rename the redo logs. Copy the scripts into a location visible to the ``RMAN`` and ``SQL*Plus`` sessions that will be in use. In this example, they were copied to the above backup location ``e:\backups\azdba01``.

Create a new service for the database to be restored, if not already created as part of the server preliminary work detailed above::

    oradim -new -sid azdba01 -startmode auto -shutmode immediate

Create a PFILE for this database in ``%oracle_home%\database\`` named ``initAZDBA01.ora``. It will contain only the following::

    db_name=azdba01
    

Mount the Instance
------------------

Set the Oracle environment accordingly, to the new SID::

    set oracle_sid=azdba01
    set oracle_home=c:\OracleDatabase\product\11.2.0\dbhome_1
    set nls_date_format=yyyy/mm/dd hh24:mi:ss
    set nls_lang=american_america.we8iso8859p1
    
Start the instance from RMAN, as follows, without a catalog connection::

    rman target sys/password
    startup nomount pfile='?\database\initazdba01.ora'
    

It is assumed that the appropriate backup files are (now) available on the destination server, either copied across (as in this example) or via a full UNC path specification. See *Determining Which Backup Files are Required*, above, for details on how to extract the names of the backup pieces etc that require to be copied from the source server.
    
    
Restore the SPFILE
------------------

Enter the following commands in ``RMAN`` to restore the SPFILE for azdba01 as a text based PFILE. The DBID in use is that recorded earlier when we collected the required data about the ``RMAN`` backup we are restoring.

..  code-block:: sql

    set dbid 692009496;
    restore spfile 
    to pfile '?\database\initAZDBA01.ora' 
    from 'e:\backups\azdba01\<file_name>';
    
When the restore has finished, open the file in a separate session and edit the following, *non-exclusive* list of parameters:

- Anything that *does not* begin with an asterisk ('*') should be deleted;
- Delete DB_FILE_NAME_CONVERT if present;
- Make sure that the DB_RECOVERY_FILE_DEST setting is correct for this new database.
- Make sure that the CONTROL_FILES setting is correct for this new database. There should be one in ``ORADATA`` and one in the FRA.
- Delete FAL_SERVER and FAL_CLIENT if present;
- Delete LOCAL_LISTENER if present;
- Delete LOG_ARCHIVE_CONFIG if present;
- Delete LOG_ARCHIVE_DEST_2 upwards. Keep only dest 1.
- Delete LOG_ARCHIVE_DEST_STATE_2 upwards. Keep only state 1.
- Delete LOG_FILE_NAME_CONVERT if present;
- Set PGA_AGGREGATE_TARGET to 100m;
- Delete REMOTE_LISTENER if present;
- Set SGA_TARGET to 2g; (Or adjust as appropriate for the database.)
- Set SGA_MAX_SIZE to 3g; (Or adjust as appropriate for the database.)

Additionally, if the restore is taken from a Data Guarded database, then remove anything to do with the standby:

- Ensure DG_BROKER_START is set to FALSE;

If the restore is taken from an RAC database, then ensure that all RAC specific parameters are removed:

- Ensure CLUSTER_DATABASE, if present, is set to FALSE;
- Ensure INSTANCE_NAME, if present, matches DB_BNAME;
- Ensure INSTANCE_NUMBER, if present, is set to 0;

Finally, was the dump taken from a *standby* database? Fix these parameters, and any others you may find, to be those of the desired *primary* database:

- Ensure that AUDIT_FILE_DEST refers to the primary database, not the standby;
- Ensure that the CONTROL_FILES refer to the primary database and not the standby;
- Ensure DB_UNIQUE_NAME, if present, matches DB_NAME and is correct for the primary database in question;
- Ensure that DISPATCHERS refers to the primary database, not the standby;
- Ensure that LOG_ARCHIVE_DEST_1 is set to 'LOCATION=USE_RECOVERY_FILE_DEST';

Save the edited file.


Mount the Instance & Restore the Controlfiles
---------------------------------------------

Still in ``RMAN``, restart the database with the new pfile and restore the control files::

    startup force nomount pfile='?\database\initazdba01.ora';
    set dbid 692009496;
    restore controlfile from 'e:\backups\azdba01\<file_name>';
    
The from location is the same as for the spfile restore above. Once the restore is complete, mount the database:


Mount The instance
------------------

Use the following ``RMAN`` command to mount the instance, ready for the remainder of the restore or validation exercise::

    startup force mount pfile='?\database\initazdba01.ora';
    
At this point, you should note that the ``DBID`` reported by ``RMAN`` for the database, is now set as per the one we have been using. The database is ready to be restored to a given point in time, or used to validate the backup files.

**Please note:** Because the source database and the restored one now have the same ``DBID``, *any* catalog updates that get carried out on the restored one, or in preparation for the restore, will affect the source database. For example, if archived logs get restored to a new location, different from that on the source server, these details are written to the catalog. Future backups of the source database will attempt to backup the (non-existent) archived logs from this phantom location, and the backups may fail.


Catalog the Dump Files
----------------------

*This step can be omitted if the location of the backup files is exactly where RMAN put them. The restored controlfiles will/should still contain details of the backup locations and those will be used, provided the backups were taken 'recently'.*

    *Recently* in this case means that as long as the backups took place within the previous ``CONTROL_FILE_RECORD_KEEP_TIME`` days, then the control files we restored *should* still know about them.

The control files do not keep a never ending list of backups - they are restricted to ``CONTROL_FILE_RECORD_KEEP_TIME`` days only. If the dumps are older they may have aged out of the control files and will need to be re-catalogued. If the dump files are not in exactly the same location that they were backed up to, they will definitely need to be re-catalogued.

You may skip to the next section if the dumps were indeed recent *and* are being restored from the exact location that they were backed up to. The control files already 'know' where they are.

If the files had to be copied over from the source server, or are now located in a different place from where they were backed up to, or if they are not recent enough, then they must be re-catalogued. This *does not* affect the ``RMAN`` catalog, which we are not using, only the control files themselves.

The dump files can be catalogued as follows::

    catalog start with 'e:\backups\azdba01' noprompt;
    
After a while, the copy of the dump files will be recorded in the control file.

The above assumes that the source files have been physically copied to the destination server, into the location given above. If the files are on a UNC path, simply specify it in the command::

    catalog start with '\\some_server_name\backups\azdba01' noprompt;    


Point In Time Restore
=====================

If the exercise being carried out is a validation restore only and not a physical restore, then skip to the section *Validation Restore* below. 

The database is now ready to be restored to a desired point in time. A *point in time* restore will:

- Restore the database files, *optionally* to a different path to that on the source database, and;
- Recover from various archived logs to bring the database up to a given point in time, and;
- *Optionally* rename the online and standy REDO logs to use a different path to that originally backed up, and;
- Open the database using the ``resetlogs`` option.

In this exercise, we are restoring to the point in time of the last archived log backed up on the source server, sequence 73. 

    **Beware:** As we want sequence 73 to be applied to the restored database as part of the recovery, we must ensure that we use 74 as the ``until sequence`` in the RMAN restore and recover. ``RMAN`` restores, and recovers, *up to, but not including*, the specified sequence!


On the Source Server
--------------------

Backups files for the appropriate ``RMAN`` backup of the database, and archived logs, need to be found and made available to the destination server. See the section *Determining Which Backup Files are Required*, above, for full details.

You can determine the required backup files by scanning the appropriate backup logfile for the "piece handle" lines, similar to this for the database::

    piece handle=``H:\BACKUPS\AZDBA01\04RLI3KG_1_120161122`` tag=TAG20161122T114821 comment=NONE
    
And this for the archived logs::

    piece handle=``H:\BACKUPS\AZDBA01\0FRLIA4N_1_120161122`` tag=TAG20161122T133930 comment=NONE
    
There will, of course be numerous piece handles and all of them will be required to be accessed from, or copied to, the destination server. You will note that the database and archived logs have different tags.

    
On the Destination Server
-------------------------

Because we are running a restore and recover, there is an unfortunate problem, the various ``_FILE_NAME_CONVERT`` parameters *do not work*. We have to do things manually *if we are changing the location of the various data files*\ . 

In addition, the TEMP tablespace (and any other TEMPORARY tablespaces) do not get renamed by anything other than ``set newname for tempfile n to 'new\path\to\%b'``, which is a bit of a bind. (%b = the tempfile name, without the path part.) 

Most of our UV databases only have a single tempfile, so the following should be ok for those. If there are more tempfiles, then adjust accordingly.

Execute the following commands in ``RMAN``:

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

        set until sequence 74;  # One more than required!
        
        #=============================================================
        # ONLY if changing the data file paths.
        # Leave out if restoring to the same path as was dumped from.
        #=============================================================
        # This is the hard way - we rename all data and temp files.
        # UNCOMMENT to use this method, 
        # or leave commented to use the easy way below.
        #-------------------------------------------------------------
        
        # @rename_dbfiles.rman
        #
        #-------------------------------------------------------------
        # This is the easy (and recommended) way. 
        # COMMENT out to use the hard way above.
        # EDIT to use the correct drive letter. 
        # %d, lowercase = (new) database name.
        # %b, lowercase = filename stripped of the path.        
        #-------------------------------------------------------------

        set newname for database to '?:\mnt\oradata\%d\%b';
        #        
        #-------------------------------------------------------------
        # TEMP files are a right pain and have to be done manually.
        # COMMENT out to use the hard way above.
        # EDIT to use the correct drive letter here too.
        # %d, lowercase = (new) database name.
        # %b, lowercase = filename stripped of the path.        
        #-------------------------------------------------------------

        set newname for tempfile 1 to '?:\mnt\oradata\%d\%b';
        #=============================================================

        restore database;
        switch datafile all;
        switch tempfile all;
        recover database; 

        release channel d5;
        release channel d4;
        release channel d3;
        release channel d2;
        release channel d1;
    }
At this point, the database is restored and recovered, but is not yet open, it remains mounted.
    
    **Note**: TEMP files are never backed up. So they cannot be restored either. What will happen is that they will be recreated when you open the database.

At the end of the recovery phase, you should see a message showing that your chosen sequence of archived log, 73 in this exercise, was applied to the database. If you forgot to add one, and sequence 73 has not been applied, simply run the following in your ``RMAN`` session::

    recover database until sequence 74;

And the desired log will be applied to bring the database up to where it needed to be - assuming that archived log sequence 73 is available in the appropriate backup location of course!

If there is an error about some archived logs being missing but being required to bring the database up to your chosen sequence, these will need to be restored - preferably to their original location - and made available to the running ``RMAN`` session. See the *Missing Archived Logs* section for details *before* proceeding. The error will resemble the following::

    RMAN-06025: no backup of archived log for thread 1 with sequence 70 and starting SCN of 928588642 found to restore

In this case we need to restore sequences 70 through 73 from a backup, and make these available to the destination server. See *Missing Archived Logs* below, for details on how to restore the missing log files before proceeding.
    
Once all the archived logs have been applied, up to and including the desired sequence of 73, in this case, exit from RMAN. 

Start sqlplus::

    sqlplus sys/password as sysdba
    
    -- ONLY if changing the data file paths.
    -- Leave out if restoring to the same path as was dumped from.
    @e:\backups\azdba01\rename_logs.sql
    
    -- Always do this. The wrong filename could be in use.
    alter database disable block change tracking;

    -- Do the following always after a SET UNTIL ... restore and recover.
    alter database open resetlogs;
    
If you see the following error, or one very similar, after the above command is executed, you have a slight problem::

    alter database open resetlogs
    *
    ERROR at line 1:
    ORA-00392: log 9 of thread 1 is being cleared, operation not allowed
    ORA-00312: online log 9 thread 1: 'G:\MNT\ORADATA\AZSTG02\REDO9A.LOG'
    ORA-00312: online log 9 thread 1:
    'H:\MNT\FAST_RECOVERY_AREA\AZSTG02\REDO9B.LOG'

As the log files don't actually exist yet, we can safely clear them out, which simply initialises them, which is what we are trying to do anyway! First we need to determine which logfile group the logfile belongs to:

..  code-block:: sql

    select group# from v$logfile where member = 'H:\MNT\FAST_RECOVERY_AREA\AZSTG02\REDO9B.LOG';

        GROUP#
    ----------
             9

And once we know the group, we can clear it and open the database:

..  code-block:: sql

    alter database clear logfile group 9;
    Database altered.

    alter database open resetlogs;
    Database altered.    
    
That's it. The database has been restored onto a new server. 

If this was simply a backup test restore, then it seems to have worked.

See the section below, *Tidying Up*, for details of any possible tidying up that may be required, regardless of whether the database restore was an exercise or if the database just restored will be kept and used.


Validation Restore
==================

Once the SPFILE and Controlfiles have been restored and as above, we carry out a validation restore by performing the following steps:

- MOUNT the instance. The instance will already be MOUNTed after the restoration of the controlfiles;
- Execute a ``RESTORE VALIDATE`` command in ``RMAN``.


On the Source Server
--------------------

Backups files for the appropriate ``RMAN`` backup of the database, and archived logs, need to be found and made available to the destination server. See the section *Determining Which Backup Files are Required*, above, for full details.

You can determine the required backup files by scanning the backup logfile for the "piece handle" lines, similar to this for the database::

    piece handle=``H:\BACKUPS\AZDBA01\04RLI3KG_1_120161122`` tag=TAG20161122T114821 comment=NONE
    
And this for the archived logs:

    piece handle=``H:\BACKUPS\AZDBA01\0FRLIA4N_1_120161122`` tag=TAG20161122T133930 comment=NONE
    
There will, of course be numerous piece handles and all of them will be required to be accessed from, or copied to, the destination server. You will note that the database and archived logs have different tags.


On the Destination Server
-------------------------

Execute the following commands in ``RMAN``::

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

        set until sequence 74;  # One more than required!
        restore validate database;

        release channel d5;
        release channel d4;
        release channel d3;
        release channel d2;
        release channel d1;
    }

That's it. The most recent incremental level 0 database backup has been validated on a new server. 

    **You are warned**\ , again, that any level 1 backups taken since the newly validated level zero, have *not* been applied nor validated. This is a risk as it means that the level 1 backup files have not been validated. Equally, none of the required archived logs have been validated either.

See the section, *Tidying Up*, below for details of what might be required next, even after a validation restore.


Tidying Up
==========

Keeping the Database
--------------------

If the database is being kept, for any reason, we need to be running with an spfile.

..  code-block:: sql

    create spfile=`?\database\spfileAZDBA01.ora`
    from pfile=`?\database\initAZDBA01.ora`;
    
    shutdown
    startup -- MOUNT or OPEN etc. Depending on other work to follow.


For PreProduction or Similar
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Drop Standby Logs
"""""""""""""""""

If the database just restored is to be kept, perhaps as a pre-production database, then you may wish to drop all the standby redologs. If the database is to be used in a standby pairing, then these will be recreated. Otherwise, they simply waste disc space.

..  code-block:: sql

    select distinct 'alter database drop standby logfile group ' || to_char(group#) || ';'
    from v$logfile 
    where type = 'STANDBY' 
    order by 1;

You may copy & paste the resulting output to drop the standby logfile groups.    

Rename the Database
"""""""""""""""""""

In addition, the database *must* be renamed using the ``nid`` utility as it currently has the same ``DBID`` as the database it was restored from and if you attempt to back it up, you may corrupt the backup details for the source database, in the catalogue.

..  code-block::

    sqlplus sys/password as sysdba
    shutdown immediate
    startup mount
    
If you have a large number of data files, then:

..  code-block::

    alter system set open_cursors=1500 scope=memory;
    
Then exit from the database.

In a DOS (shell) session:

..  code-block::

    nid target=sys/password dbname="new name" setname=y logfile=nid.log
    
The database will be left closed when the above command completes. You *must* check the logfile.

If the logfile shows something like the following, then attention is required:

..  code-block:: none

    ORA-20000: File E:\MNT\ORADATA\CFG\TEMP01.DBF has wrong dbid or dbname, 
               remove or restore the offending file.
    ORA-06512: at "SYS.X$DBMS_BACKUP_RESTORE", line 6972
    ORA-06512: at line 1

The RMAN restore doesn't rename the temporary files. These need to be dropped and recreated.

..  code-block:: sql

    alter database tempfile 'E:\MNT\ORADATA\CFG\TEMP01.DBF' drop;
    Database altered.    

You should check for other temp files before continuing:

..  code-block:: sql

    select name from v$tempfile;
    no rows selected   
    
Then exit from the database.

In a DOS (shell) session:

..  code-block::

    nid target=sys/password dbname="new name" setname=y logfile=nid.log
    
The database will be left closed when the above command completes. You *must* check the logfile again.

Once the database has been renamed, there's a little more work to do.

- In %ORACLE_HOME%\database, rename the password file to the new database name.
- In %ORACLE_HOME%\database, copy the spfile to one with the new database name.
- startup MOUNT the database. You may get told that the database name in the controlfile is still the old one.

..  code-block:: sql

    alter system set db_name='AZDBA01' scope=spfile;
    shutdown
    startup mount


You will need to register the database in ``RMAN`` if it is to be backed up.

Depersonalise the Data
""""""""""""""""""""""

You must ensure that all depersonalisation scripts are executed after the database has been restored. 

Scripts are available in TFS, at ``TA\MAIN\Source\UKRegulated\Database\Depersonalisation\Depers & Shrink``, which will:

- Carry out a full depersonalisation of the email addresses, table data and UAT account setup - ``full_depers.sql``; or
- Carry out a partial depersonalisation of only the emails and UAT setup. Table data are not touched. The script is ``partial_depers.sql``.

The latter is for times when the users request a 'non-depersonalised' database refresh, usually, from ``AZSTG01``, the former is for 'depersonalised' database refreshes.


Other Requirements
""""""""""""""""""

You may also need to carry out some or all of the steps below. This is as appropriate to the purpose of the restored database.    

For Migration Purposes
~~~~~~~~~~~~~~~~~~~~~~

If this was a required restore onto a new server, perhaps to migrate a database, and the new database is to be retained for future use, then the following tasks remain to be carried out in ``SQL*Plus``:

..  code-block:: sql

    -- Reapply block change tracking.
    alter database enable block change tracking
    using file 'e:\mnt\fast_recovery_area\azdba01\bct.dbf' reuse;
    
    -- Make sure we are in force logging mode.
    select force_logging from v$database;
    alter database force logging; -- If 'NO' from the above.
    
    -- Make sure we are in archive log mode;
    select log_mode from v$database;
    
    -- If required...
    shutdown immediate;
    startup mount
    alter database archivelog;
    alter database open;
    
    -- Make sure we are in flashback mode.
    select flashback_on from v$database;
    alter database flashback on; -- If 'NO' from the above.
    
The source and restored database have the same ``DBID`` and this means that the backups of the source database may be used to restore the new database. 

The source database can now be shutdown if the newly restored database is to be used in its place.

The ``tnsnames.ora`` file(s) spread throughout the estate may now require updating to point the azdba01 alias at the new host.

A standby database and Data Guard configuration may now be set up as required for the database.


Backup Test Only
----------------

If, on the other hand, this restore was simply an exercise in testing the backups, then it's time to tidy up. Some of the following will not be required for a validation only restore. Errors can be ignored.

- First, drop the database:

..  code-block:: sql

    startup force restrict mount;
    select name, db_unique_name, instance_name from v$database, v$instance; -- Just to be sure!
    drop database;
    exit
    
- Delete all the files in ``%ORACLE_BASE%%\diag\rdbms\azdba01\azdba01``.
- Delete the ``e:\mnt\oradata\azdba01`` folder.
- Delete the ``e:\mnt\fast_recovery_area\azdba01`` folder.
- Delete ``%ORACLE_HOME%\database\initAZDBA01.ora``.
- Delete ``%ORACLE_HOME%\database\pwdAZDBA01.ora``.
- Delete ``%ORACLE_HOME%\database\hc_azdba01.dat`` if present.
- Delete ``%ORACLE_HOME%\database\sncfAZDBA01.ora`` if present.

The temporary service we created with ``oradim`` should have been deleted when we dropped the database, but sometimes not, so in an administrator enabled command session::

    net stop OracleServiceAZDBA01
    oradim -delete -sid azdba01 


If, and only if, you physically copied the backup files from the source server to the destination server, you may now wish to remove said files from the backup area, ``e:\backups\azdba01`` in this exercise, as they are no longer required. 


Missing Archived Logs
=====================

If the database restored and recovered, without complaining about missing archived logs, then you may skip this section.

It is *occasionally* possible that some of the archived logs required for the above (physical) recovery of the database are not present on disc. They may have been archived off to a backup vault, for example. They must be restored to the location visible to the database being recovered.

    **Warning:** You will be using the catalog here and so, any restores of archived logs *will affect the source database* as future backups will attempt to backup the archived logs in the location you are about to restore into.

During the recovery phase, ``RMAN`` complained about the following::

    RMAN-06025: no backup of archived log for thread 1 with sequence 70 and starting SCN of 928588642 found to restore

As we require up to and including sequence 73, we will probably need to restore sequences 70 through 73. We do this in a *separate ``RMAN`` session* to the one running the recovery.

To restore to the *same location* that the archived logs were backed up from::

    run {
        allocate channel d1 device type disk;
        restore archivelog from sequence 70 until sequence 73;
        release channel d1;
    }

On the other hand, to restore to a *different location*\ ::

    run {
        allocate channel d1 device type disk;
        
        set archivelog destination to 'e:\backups\azdba01';
        
        restore archivelog from sequence 70 until sequence 73;
        release channel d1;
    }

If you use the latter, to restore the archived logs directly to the *destination* server, and you intend to keep the *source* database, then you *must* run the following commands on the *source server* against the *source database*\ ::

    rman target sys/password catalog rman11g/<password>@rmancatsrv
    crosscheck archivelog all;
    exit
    
**Do not** run a ``delete obsolete`` command afterwards as that will get rid of more than just the obsolete archived logs on the non-existent ``e:\backups\\azdba01`` location! In addition, because the database backups are kept for 7 years - for legal reasons - any that have been archived off of the online backup discs will appear as obsolete. So, you might just have deleted them from the catalog. Luckily, they can be copied back from the vault and re-catalogued if required, but it's best to avoid the problem in the first place.
    
    
