.. pandoc -f rst -t docx -o RMANRestore.docx --reference-docx=pandoc_reference.docx --table-of-contents --toc-depth=3 RMANRestore.rst
   is the command that will convert this document to a Word docx file.
   
.. Norman Dunbar
   November 2016..January 2017.   

======================================================
RMAN Restores & Backup Validation to Different Servers
======================================================

Abstract
========

This document shows how the AZDBA01 database was copied from server ORCDEVORC01 to server DEVORC01 using a previously taken ``RMAN`` incremental level 0 backup. As this restore is simply a backup verification and not a restore back to the same place exercise, we must be careful when using the ``RMAN`` catalog.

If, on the other hand, this was an *actual restore*, to the *same location* on the *same server*, life is much easier - we simply connect to the target database and the catalog and issue the following commands::

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

If the database is being *physically* restored to a set of paths on the destination server, that are identical to those on the source server, then skip this section.
  
The restore and recover will normally attempt to write the data files back to the same path location as per the source database. If we are intending to restore to different paths, we need an ``RMAN`` script to be generated to rename the data files prior to the restore of the database on the new server. 

This is required because the parameters ``DB_FILE_NAME_CONVERT`` and ``LOG_FILE_NAME_CONVERT`` *do not work* in an ``RMAN`` restore operation.  

We also require a ``SQL*Plus`` script to rename the online redo logs.

A validation restore doesn't require these scripts and nor does a physical restore to the same locations, even if they are on a different server.

Run the following script, against the source database, as the SYSDBA user, to generate the two separate scripts to carry out the renaming exercise::

    set lines 2000 trimspool on
    set pages 3000 head off feed off
    set echo off verify off
    spool rename_dbfiles.rman

    -- Script to rename data files using RMAN...
    select 'set newname for datafile '|| file# || 
    ' to ''e:\mnt\oradata\azdba01\' || 
    substr(name, instr(name, '\', -1) +1) || ''';' 
    from v$datafile;

    spool off

    spool rename_logs.sql
    
    -- Script to rename REDO logs using SQL*Plus...
    -- Note: REPLACE() is case sensitive. Use correct locations!
    select 'alter database rename file '''|| member || ''' to ''' ||
    replace(replace(upper(member), 'F:','E:'),'G:','E:') || ''';'
    from v$logfile
    order by 1;
    
    spool off

**Note:** In the script above, the current location(s) of the various data files are all "don't care" while the redo logs are currently found on both the ``F:\`` and ``G:\`` drives. The scripts generated by the above, assume everything will eventually be located on the ``E:\`` drive only.  You will need to amend the above if a different source or destination location is desired.


The two scripts generated, ``rename_dbfiles.rman`` and ``rename_logs.sql`` will need copying to a suitable location on the destination server. 

**Note:** On Windows, filenames are not case sensitive, however, in the database, comparing their names with ``replace()`` *is* case sensitive. That is the reason why the logfile names were upper-cased before replacing the appropriate drive letters with those of the new server.


Determining Which Backup Files are Required
===========================================

Once we have an idea of the date and time of the end of the backup we wish to restore/test, we need to ensure that the files are available on the destination server. This can be done by using the full UNC path to the backup location on the source server - provided it can be seen from the destination server.

If, on the other hand, the source backup files cannot be seen from the destination server, then they need to be identified and physically coped to the destination server into a temporary location. The remainder of this example assumes the latter case.

If we need to physically copy the files to the destination server, we need to be able to identify them. ``RMAN`` can help, especially if you have the backup log::

    find /i "Piece Handle" <logfile_name> | sort

The output will be something like the following::

    ---------- RMAN_TEST_BACKUP.LOG
        Piece Handle=J:\BACKUPS\CFG\C-2081680004-20161103-01 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\C-2081680004-20161103-01 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\2VRJT781_1_1 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\32RJT7GC_1_1 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\31RJT7B6_1_1 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\30RJT794_1_1 tag=TAGyadayadayada comment=NONE
        Piece Handle=J:\BACKUPS\CFG\2URJT720_1_1 tag=TAGyadayadayada comment=NONE

The list of files output by the command are the database dump files that are required on the destination server.

If, on the other hand, the log for the appropriate dump is no longer available, execute the following code in a shell session, on the *source* server::

    oraenv <source_database>
    rman target sys/<password> catalog rman11g/<password>@rmancatsrv

Once connected with the target database and the catalogue, execute the following commands::

    spool log to restore_preview.log
    run {
        set until time 'yyyy/mm/dd hh24:mi:ss';
        restore spfile preview;
        restore controlfile preview;
        restore database preview;
    }    
    spool log off;
    exit;
    
Now the backup piece names can be extracted from the logfile, as follows::

    Rem Find the backup pieces required:
    find /i "Piece Name:" restore_preview.log | sort

The output will resemble this::

    ---------- RESTORE_PREVIEW.LOG
        Piece Name: J:\BACKUPS\CFG\C-2081680004-20161103-01
        Piece Name: J:\BACKUPS\CFG\C-2081680004-20161103-01
        Piece Name: J:\BACKUPS\CFG\2VRJT781_1_1
        Piece Name: J:\BACKUPS\CFG\32RJT7GC_1_1
        Piece Name: J:\BACKUPS\CFG\31RJT7B6_1_1
        Piece Name: J:\BACKUPS\CFG\30RJT794_1_1
        Piece Name: J:\BACKUPS\CFG\2URJT720_1_1
    
The first two files have the same name as these will be the spfile and controlfile backups, and in this restore exercise, they are found in the same file.

Now the free standing archived logs can be extracted from the logfile, as follows::

    Rem Find the archived logs required:
    find /i "Name:" restore_preview.log | find /v /i "Piece Name:" | find /v /i "spfile" | sort

The output will resemble the following abridged listing::

    ---------- RESTORE_PREVIEW.LOG
        ...
        Name: F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3791_D1RX3HSS_.ARC
        Name: F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3792_D1RXZMXZ_.ARC
        Name: F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3792_D1RXZMXZ_.ARC
        Name: F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3793_D1RYVR2M_.ARC
        Name: F:\MNT\FAST_RECOVERY_AREA\CFG\ARCHIVELOG\2016_11_04\O1_MF_1_3793_D1RYVR2M_.ARC
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
- Create an Oracle Service for the destination instance using ``oradim``.
- Using ``RMAN``, start the instance in NOMOUNT mode;
- Recover the SPFILE as a PFILE;
- Edit the PFILE to ensure that parameters are correct for this server & database, and to remove any signs of Data Guard, RAC etc;
- Start the instance again, in NOMOUNT mode, using the restored and edited PFILE;
- Restore the controlfiles;
- Start the instance yet again, this time in MOUNT mode, so that it picks up the restored controlfiles;
- Catalog the [copied] dump files.

You can now restore or validate the database itself by carrying out a Point in time Restore, or a Validation restore as described below. First however, the preparation work.

Create a folder to hold the backups::

    mkdir e:\backups\azdba01

Create a folder for the datafiles, and redo logs::

    mkdir e:\mnt\oradata\azdba01
    mkdir e:\mnt\fast_recovery_area\azdba01
    
Are these locations different from the database we are restoring? If so, we need the two scripts generated above - one to set a newname for the datafiles, and one to rename the redo logs. Copy the scripts into a location visible to the ``RMAN`` and ``SQL*Plus`` sessions that will be in use. In this example, they were copied to the above backup location ``e:\backups\azdba01``.

Create a new service for the database to be restored, if not already created as part of the server preliminary work detailed above::

    oradim -new -sid azdba01 -startmode auto -shutmode immediate
    

Mount the Instance
------------------

Set the Oracle environment accordingly, to the new SID::

    set oracle_sid=azdba01
    set oracle_home=c:\OracleDatabase\product\11.2.0\dbhome_1
    set nls_date_format=yyyy/mm/dd hh24:mi:ss
    set nls_lang=american_america.we8iso8859p1
    
Start RMAN and the instance as follows::

    rman target sys/password
    startup force nomount;

It is assumed that the appropriate backup files are (now) available on the destination server, either copied across (as in this example) or via a full UNC path specification. See *Determining Which Backup Files are Required*, above, for details on how to extract the names of the backup pieces etc that require to be copied from the source server.
    
    
Restore the SPFILE
------------------

Enter the following commands in ``RMAN`` to restore the SPFILE for azdba01 as a text based PFILE. The DBID in use is that recorded earlier when we collected the required data about the ``RMAN`` backup we are restoring.

::

    set dbid 692009496;
    restore spfile 
    to pfile 'c:\oracledatabase\product\11.2.0\dbhome_1\database\initAZDBA01.ora' 
    from 'e:\backups\azdba01\<file_name>';
    
When the restore has finished, open the file in a separate session and edit the following, *non-exclusive* list of parameters:

- Anything that *does not* begin with an asterisk ('*') should be deleted;
- Delete DB_FILE_NAME_CONVERT if present;
- Delete FAL_SERVER and FAL_CLIENT if present;
- Delete LOCAL_LISTENER if present;
- Delete LOG_ARCHIVE_CONFIG if present;
- Delete REMOTE_LISTENER if present;
- Delete LOG_ARCHIVE_DEST_2 upwards. Keep only dest 1.
- Delete LOG_ARCHIVE_DEST_STATE_2 upwards. Keep only state 1.
- Delete LOG_FILE_NAME_CONVERT if present;
- Set SGA_TARGET to 2g; (Or adjust as appropriate for the database.)
- Set SGA_MAX_SIZE to 3g; (Or adjust as appropriate for the database.)
- Set PGA_AGGREGATE_TARGET to 100m;

Additionally, if the restore is taken from a Data Guarded database, then remove anything to do with the standby:

- Ensure DG_BROKER_START is set to FALSE;

If the restore is taken from an RAC database, then ensure that all RAC specific parameters are removed:

- Ensure CLUSTER_DATABASE is set to FALSE;
- Ensure INSTANCE_NAME matches DB_BNAME;
- Ensure INSTANCE_NUMBER is set to 1;

Finally, was the dump taken from a *standby*) database? Fix these parameters, and any others you may find, to be those of the desired *primary* database:

- Ensure DB_UNIQUE_NAME matches DB_NAME and is correct for the primary database in question;
- Ensure that AUDIT_FILE_DEST refers to the primary database, not the standby;
- Ensure that the CONTROL_FILES refer to the primary database and not the standby;
- Ensure that DISPATCHERS refers to the primary database, not the standby;
- Ensure that LOG_ARCHIVE_DEST_1 is set to 'LOCATION=USE_RECOVERY_FILE_DEST';

Save the edited file.


Mount the Instance & Restore the Controlfiles
---------------------------------------------

Still in ``RMAN``, restart the database with the new pfile and restore the control files::

    startup force nomount;
    set dbid 692009496;
    restore controlfile from 'e:\backups\azdba01\<file_name>';
    
The from location is the same as for the spfile restore above. Once the restore is complete, mount the database:


Mount The instance
------------------

Use the following ``RMAN`` command to mount the instance, ready for the remainder of the restore or validation exercise::

    startup force mount;
    
At this point, you should note that the ``DBID`` reported by ``RMAN`` for the database, is now set as per the one we have been using. The database is ready to be restored to a given point in time, or used to validate the backup files.

**Please note:** Because the source database and the restored one now have the same ``DBID``, *any* catalog updates that get carried out on the restored one, or in preparation for the restore, will affect the source database. For example, if archived logs get restored to a new location, different from that on the source server, these details are written to the catalog. Future backups of the source database will attempt to backup the (non-existent) archived logs from this phantom location, and the backups may fail.


Catalog the Dump Files
----------------------

The dump files can be catalogued as follows::

    catalog start with 'e:\backups\azdba01' noprompt;
    
After a while, the copy of the dump files will be recorded in the control file.

The above assumes that the source files have been physically copied to the destination server, into the location given above. If the files are on a UNC path, simply specify it in the command above.


Point In Time Restore
=====================

Once the SPFILE and Controlfiles have been restored and edited as required, and the dump files from the source server have been [copied over to the destination server, and] catalogued in the control file, a point in time restore will:

- Restore the database files, *possibly* to a different location (path) to that on the source database, and;
- Recover from various archived logs to bring the database up to a given point in time.
- Open the database using the ``resetlogs`` option.

In this exercise, we are restoring to the point in time of the last archived log backed up on the source server, sequence 73. 

**Beware:** As we want sequence 73 to be applied to the restored database as part of the recovery, we must ensure that we use 74 as the ``until sequence`` in the RMAN restore and recover. ``RMAN`` restores, and recovers, *up to, but not including*, the specified sequence!


Server ORCDEVORC01
------------------

Backups files for the appropriate ``RMAN`` backup of the database, and archived logs, need to be found and made available to the destination server. See the section *Determining Which Backup Files are Required*, above, for full details.

You can determine the required backup files by scanning the appropriate backup logfile for the "piece handle" lines, similar to this for the database::

    piece handle=H:\BACKUPS\AZDBA01\04RLI3KG_1_120161122 tag=TAG20161122T114821 comment=NONE
    
And this for the archived logs:

    piece handle=H:\BACKUPS\AZDBA01\0FRLIA4N_1_120161122 tag=TAG20161122T133930 comment=NONE
    
There will, of course be numerous piece handles and all of them will be required to be accessed from, or copied to, the destination server. You will note that the database and archived logs have different tags.

    
Server DEVORC01
---------------

Because we are running a restore and recover, there is an unfortunate problem, the various ``_FILE_NAME_CONVERT`` parameters *do not work*. We have to do things manually if we are changing the location of the various data files. Execute the following commands in ``RMAN``::

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
        @e:\backups\azdba01\rename_dbfiles.rman

        restore database;
        switch datafile all;
        recover database; 

        release channel d5;
        release channel d4;
        release channel d3;
        release channel d2;
        release channel d1;
    }

At the end of the recovery phase, you should note that the desired a message showing that your chosen sequence of archived log, 73 in this exercise, was applied to the database. If you forgot to add one, and sequence 73 has not been applied, simply run the following in your ``RMAN`` session::

    recover database until sequence 74;

And the desired log will be applied to bring the database up to where it needed to be - assuming that archived log sequence 73 is available in the appropriate backup location of course!

If there is an error about archived logs missing and required to bring the database up to your chosen sequence, these will need to be restored - preferably to their original location - and made available to the running ``RMAN`` session. See below for details *before* proceeding. The error will resemble the following::

    RMAN-06025: no backup of archived log for thread 1 with sequence 70 and starting SCN of 928588642 found to restore

In this case we need to restore sequences 70 through 73 from a backup, and make these available to the destination server. See below for details before proceeding with the following.

    
Once all the archived logs have been applied, up to and including the desired sequence of 73, in this case, exit from RMAN. 

Start sqlplus::

    sqlplus sys/password as sysdba
    @e:\backups\azdba01\rename_logs.sql
    alter database disable block change tracking;
    alter database open resetlogs;
    
That's it. The database has been restored on a new server. 

If this was simply a backup test restore, then it seems to have worked.

See the section below on tidying up, for details of what might be required next, regardless of whether the database restore was an exercise or if the database just restored will be kept and used.


Missing Archived Logs
=====================

It is possible that some of the archived logs required for the above recovery of the database are not present on disc. They may have been archived off to a backup vault, or whatever. They must be restored to the location visible to the database being recovered.

**Warning:** You will be using the catalog here and so, any restores of archived logs will affect the source database as future backups will attempt to backup the archived logs in the location you are about to restore into.

During the recovery phase, ``RMAN`` complained about the following::

    RMAN-06025: no backup of archived log for thread 1 with sequence 70 and starting SCN of 928588642 found to restore

As we require up to and including sequence 73, we will probably need to restore sequences 70 through 73. We do this in a *separate ``RMAN`` session* to the one running the recovery.

To restore to the same location that the archived logs were backed up from::

    run {
        allocate channel d1 device type disk;
        restore archivelog from sequence 70 until sequence 73;
        release channel d1;
    }

On the other hand, to restore to a location that is different::

    run {
        allocate channel d1 device type disk;
        
        set archivelog destination to 'e:\backups\azdba01';
        
        restore archivelog from sequence 70 until sequence 73;
        release channel d1;
    }

If you use the latter, to restore the archived logs directly to the destination server, and you intend to keep the source database, then you must run the following commands on the *source server*::

    rman target sys/password catalog rman11g/<password>@rmancatsrv
    crosscheck archivelog all;
    exit
    
It is not advisable to run a ``delete obsolete`` command afterwards as that may get rid of more than just the obsloete archived logs on the non-existent ``e:\backups\\azdba01`` location!
    
    
Validation Restore
==================

Once the SPFILE and Controlfiles have been restored and edited as required, and the dump files from the source server have been [copied and] catalogued in the control file, a validation only  restore will:

- MOUNT the instance. The instance should actually be MOUNTed after the restoration of the controlfiles;
- Execute a ``RESTORE VALIDATE`` command in ``RMAN``.


Server ORCDEVORC01
------------------

Backups files for the appropriate ``RMAN`` backup of the database, and archived logs, need to be found and made available to the destination server. See the section *Determining Which Backup Files are Required*, above, for full details.

You can determine the required backup files by scanning the backup logfile for the "piece handle" lines, similar to this for the database::

    piece handle=H:\BACKUPS\AZDBA01\04RLI3KG_1_120161122 tag=TAG20161122T114821 comment=NONE
    
And this for the archived logs:

    piece handle=H:\BACKUPS\AZDBA01\0FRLIA4N_1_120161122 tag=TAG20161122T133930 comment=NONE
    
There will, of course be numerous piece handles and all of them will be required to be accessed from, or copied to, the destination server. You will note that the database and archived logs have different tags.


Server DEVORC01
---------------

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

That's it. The most recent incremental level 0 database backup has been validated on a new server. You are warned, again, that any level 1 backups taken since that one have not been applied nor validated. This is a risk. Equally, none of the required archived logs have been validated either.

See the section below on tidying up, for details of what might be required next.


Tidying Up
==========

Keeping the Database
--------------------

If this was a required restore onto a new server, perhaps to migrate a database, and the new database is to be retained for future use, then the following tasks remain to be carried out in ``SQL*Plus``::

    -- Reapply block change tracking.
    alter database enable block change tracking
    using file 'e:\mnt\fast_recovery_area\azdba01\bct.dbf';
    
    -- Make sure we run with an spfile.
    create spfile=`%ORACLE_HOME%\database\spfileAZDBA01.ora`
    from pfile=`%ORACLE_HOME%\database\initAZDBA01.ora`;
    shutdown immediate;
    startup;
    
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
    
The source database may now be shutdown. It is assumed to be no longer required.

The ``tnsnames.ora`` file(s) spread throughout the estate may now require updating to point the azdba01 alias at the new host.

A standby database and Data Guard configuration may now be set up as required for the database.


Backup Test Only
----------------

If, on the other hand, this restore was simply an exercise in testing the backups, then it's time to tidy up. Some of the following will not be required for a validation only restore. Errors can be ignored.

- First, drop the database::

    startup force restrict mount;
    select instance_name from v$instance; -- Just to be sure!
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


You may wish to remove the files from the backup area, ``e:\backups\azdba01`` in this exercise, if they are no longer required. You will obviously *not* be deleting these files if they were accessed via a full UNC pathname from the source server!

