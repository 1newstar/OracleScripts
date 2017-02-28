===================================================
Use and Monitoring of the Oracle Fast Recovery Area
===================================================

Introduction
============

Oracle introduced the *Flash Recovery Area* at 10g for the use of the
various Flashback features introduced to the database at that release.
Almost immediately they renamed it to *Fast Recovery Area* as it became
used for more than just Flashback Logs.

This document attempts to explain the usage and monitoring of this area
in respect of the new Azure 11g databases.

Initialisation Parameters
=========================

There are a number of initialisation parameters that control the usage
of this area. These are as follows:

-   ``db_recovery_file_dest`` - specified where the FRA is to be
    located. This is the full path to a section of disc storage where
    Oracle will create any required folders and files. Typical content
    here would be:

    -  ``Archivelog`` (folder) - created by the database. Used to store
       archived logs if the database is, or has been, running in
       ARCHIVELOG mode. These are kept in individual folders used on a
       daily basis. Folders are named ``yyyy_mm_dd``.

       Files here may be deleted manually, however it is advised not to do
       this as you may be deleting files that have not been backed up and
       which will be required for a restore in the future.

    -  ``Autobackup`` (folder) - created by the database. Used to save
       automatic backups of the controlfile and spfile. Backups are kept in
       individual folders used on a daily basis. Folders are named
       ``yyyy_mm_dd``.

       Files here may be deleted manually, however it is advised not to do
       this as you may be deleting files that have not been backed up and
       which will be required for a restore in the future.

    -  ``Flashback`` (folder) - created by the database for use in storing
       various flashback logs. These are used to facilitate commands such as
       flashback database or flashback table etc.

       Files here must not be deleted manually. If you must delete them,
       the only way is to take the database out of flashback mode, delete
       the files that Oracle doesn't delete for you, then put the database
       back into flashback mode.

    -  ``Onlinelog`` (folder) - Created automatically by the database [1]_.
       Used to contain any standby redo log files that have been created as
       part of a Data Guarded database pair. Do not delete files in this
       location.

    -  ``Others`` - user created files and folders may also be present.
       Things such as the block change tracking file, online redo logs,
       control file mirrors and RMAN backups etc.

-   ``db_recovery_file_dest_size`` - This parameter specifies the
    amount of space that this database can use in the FRA before it hangs
    up and stops working! See below for details.

-   ``log_archive_dest_n`` - Normally, ``log_archive_dest_1`` is used
    to specify a local location for the archived log files. If this is
    set to ``location=use_db_recovery_file_dest`` then the archivelogs
    folder (above) will be created and used. Other destinations may also
    be specified, for example, a standby database service name.

FRA Usage
=========

The FRA is self-cleaning, in effect, as space usages approaches the
quota set in the parameter ``db_recovery_file_dest_size``, Oracle will
start to clean out any files it considers can be deleted. Which files
are considered for deletion?

There are 4 different types of files that may be found in the FRA. These
are:

-  Managed Files
-  Unmanaged Files
-  Orphaned Files
-  Unknown Files

*Only the managed files are considered by the self-cleaning process*. The
other files must be kept tidy as appropriate, manually.

You should be aware that if space usage in the FRA is such that, there
is insufficient free space after cleaning out the managed files, then
the database will hang if there is no space for a new archived log to be
created.

Guaranteed restore points, for example, will mark archived logs as being
undeletable so that the restore point can be kept in a guaranteed state.

Managed Files
-------------

Managed files are those which the database knows about and which are
located in the FRA.

These files are the only ones that will be considered for deletion if
and when space in the FRA becomes tight *and* all consumers of the
file(s) have completed their usage.

Managed files are considered for deletion if they have been backed up,
at least once.

Managed files can be identified by the value "YES" in the column
``IS_RECOVERY_DEST_FILE`` in various V$ views such as:

-  ``V$ARCHIVED_LOG``
-  ``V$BACKUP_COPY_DETAILS``
-  ``V$BACKUP_PIECE``
-  ``V$BACKUP_PIECE_DETAILS``
-  ``V$CONTROLFILE``
-  ``V$DATAFILE_COPY``
-  ``V$FOREIGN_ARCHIVED_LOG``
-  ``V$LOGFILE``

In addition, any file whose name appears in the following view is also
managed:

-  ``V$FLASHBACK_DATABASE_LOGFILE``

Examples of managed files are:

-  Archived logs;
-  Files created by the RMAN backup as ``copy ...`` commands;
-  Foreign archived logs - those from another database - catalogued for
   Log Miner operations;
-  Flashback logs.

Oracle will never delete files in the FRA, even if managed, if they are:

-  Control Files;
-  Online Redo log files;
-  Data or Temp Files;
-  Required for a flashback;
-  Have not been backed up.
-  Required by Golden Gate/Standby databases.

To find a count of managed files, look at the
``V$FLASH_RECOVERY_AREA_USAGE`` or ``V$RECOVERY_AREA_USAGE`` if you have
11gR2 or higher.

..  code-block:: sql

    col percent_space_used for 990.00 heading PCT_USED
    col percent_space_reclaimable for 990.00 heading PCT_RCLMBLE
    col number_of_files for 9,999,990 heading NUM_FILES
    set lines 300 trimspool on pages 300

    select * from v$recovery_area_usage;

    FILE_TYPE            PCT_USED PCT_RCLMBLE  NUM_FILES
    -------------------- -------- ----------- ----------
    CONTROL FILE             0.00        0.00          0
    REDO LOG                 1.07        0.00         11
    ARCHIVED LOG             0.00        0.00          0
    BACKUP PIECE             0.43        0.02         17
    IMAGE COPY               0.00        0.00          0
    FLASHBACK LOG            0.98        0.68         10
    FOREIGN ARCHIVED LOG     0.00        0.00          0

    7 rows selected.

To list the files, select the ``NAME`` (or ``MEMBER``) column from any of the
above views as in the following example:


..  code-block:: sql

    select member from v$logfile
    where IS_RECOVERY_DEST_FILE='YES'
    and lower(member) like'%fast_recovery%';

    MEMBER
    ------------------------------------------------------------------
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\ONLINELOG\O1_MF_27_CP5F4HVB_.LOG
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\ONLINELOG\O1_MF_28_CP5F4N2H_.LOG
    ...
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\ONLINELOG\O1_MF_36_CP5F5FCW_.LOG
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\ONLINELOG\O1_MF_37_CQ1V8FOR_.LOG

Unmanaged Files
---------------

Unmanaged files are those files that the database knows about, which are
located in the FRA, and which are not managed by the database's
self-cleaning processing.

These files will never be cleaned out or removed from the FRA and will
continue to consume space in the FRA, but will not have this consumption
accounted for in the following views:

-  ``V$RECOVERY_FILE_DEST``
-  ``V$RECOVERY_AREA_USAGE`` (11gR2 onwards)
-  ``V$FLASH_RECOVERY_AREA_USAGE``

Unmanaged files can be identified by the value "NO" in the column
``IS_RECOVERY_DEST_FILE`` in various V$ views such as:

-  ``V$ARCHIVED_LOG``
-  ``V$BACKUP_COPY_DETAILS``
-  ``V$BACKUP_PIECE``
-  ``V$BACKUP_PIECE_DETAILS``
-  ``V$CONTROLFILE``
-  ``V$DATAFILE_COPY``
-  ``V$FOREIGN_ARCHIVED_LOG``
-  ``V$LOGFILE``

Examples of unmanaged files are:

-  Files created by RMAN using commands similar to ``copy datafile n to
   '...'`` where the destination is within the FRA.
-  Controlfiles
-  Redo log files
-  Standby log files
-  Data or Temp files created - *accidentally* - in the FRA.

NOTE: It been seen in some 11g databases, the control and redo log files
located in the FRA, for example, are shown as being managed when they
are not. This is most likely a bug.

There is *not* a way to obtain a count of unmanaged files in the FRA as
the views ``V$FLASH_RECOVERY_AREA_USAG``E and ``V$RECOVERY_AREA_USAGE`` (if
you have 11gR2 or higher) only track managed files.

To list the files, select the ``NAME`` (or ``MEMBER``) column from any of the
above views as in the following example:

..  code-block:: sql

    select member from v$logfile
    where IS_RECOVERY_DEST_FILE='NO'
    and lower(member) like '%fast_recovery%';

    MEMBER
    --------------------------------------------
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\REDO4B.LOG
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\REDO5B.LOG
    ...
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\REDO8B.LOG
    G:\MNT\FAST_RECOVERY_AREA\AZDBA01\REDO9B.LOG

Orphaned Files
--------------

Orphaned files are those files that were once managed, but now no longer
are and which are subsequently unable to be deleted by the FRA
self-cleaning processes. Some examples of orphan files would include:

-  Flashback logs that were originally required for a guaranteed restore
   point but a flashback has taken place to a GRP *prior* to the one
   these files were needed for. Because these files didn't exist at the
   time of the oldest save point, the database is now unaware that they
   exist, and they have been orphaned. Of course, the database can be
   flashed "back" to the future again, in which case, these files are no
   longer considered orphans.

-  Standby redo logs. These can be created when a (stand-alone) database
   was originally created by cloning from a database which had a
   standby. The various standby redo logs will have been created in the
   FRA but will never be used. The ``V$LOGFILE`` & ``V$STANDBY_LOG`` views will
   help identify these files.

Orphaned flashback logs can be found by, first of all, extracting a list
of *known* flashback logs using the following process:

..  code-block:: sql

    select name
    from V$FLASHBACK_DATABASE_LOGFILE
    where lower(name) like '%fast_recovery_area%'
    order by 1;

The list of *all files* that are currently located in the flashback
location for this database should now extracted from a directory listing
and compared with the above list to identify the orphans. This is an
intensive process on Windows, and much easier on Unix where tools are
available to assist.

Both listings of the files must be sorted into the same order - to make
comparisons easier.

Unknown Files
-------------

Unknown files are all other files, created within the FRA, by manual
means, or by humans. These files cannot be cleaned out by the database
as they are not managed and the database doesn't know about them.

Self Cleaning
=============

Oracle will attempt to keep space in the FRA used up to the maximum
quota specified in the ``db_recovery_file_dest_size`` parameter. As
usage approaches the quota limit, space must be made available for new
files, archived logs for example, to be created in the FRA. Usually,
when there is *around* 15% free space left, Oracle will start to clean
out no longer needed files, but this is not a hard and fast number and
should not be treated as such.

The database can be forced to carry out a cleansing by setting the
``db_recovery_file_dest_size`` parameter to a smaller and smaller value,
with ``scope=memory`` only. At each reduction in quota, Oracle should start
clearing files out. The ``alert.log`` will show the details of the files
that have been deleted, however, it may not start doing so until space
is needed - alter system archive log current should help kick off the
cleansing process.

If you manage to reduce the FRA quota too far, the ``alert.log`` will show
that the archiver has been suspended when it next tries to archive a log
file.

It is preferable to remove [managed] files from the FRA in this manner
rather than manually deleting files which could lead to the wrong files
being removed.

The ``V$RECOVERY_AREA_USAGE`` view has details of how much space could be
reclaimed in the FRA for each different type of managed file stored
there. If space is short, it is this reclaimable space that will be
reused as desired.

..  code-block:: sql

    col percent_space_used for 990.00 heading PCT_USED
    col percent_space_reclaimable for 990.00 heading PCT_RCLMBLE
    col number_of_files for 9,999,990 heading NUM_FILES

    set lines 300 trimspool on pages 300

    select * from v$recovery_area_usage;

    FILE_TYPE            PCT_USED PCT_RCLMBLE NUM_FILES
    -------------------- -------- ----------- ----------
    CONTROL FILE             0.00        0.00         0
    REDO LOG                 1.07        0.00        11
    ARCHIVED LOG             0.00        0.00         0
    BACKUP PIECE             0.43        0.02        17
    IMAGE COPY               0.00        0.00         0
    FLASHBACK LOG            0.98        0.68        10
    FOREIGN ARCHIVED LOG     0.00        0.00         0

    7 rows selected.

FRA Monitoring
==============

Oracle support provide document **1936710.1** as a good source of
information, and scripts, to monitor space usage in the FRA.

Monitoring basically involves checking which files are present in the
FRA and will be self-cleaned as well as monitoring those unmanaged and
other files in the FRA that will never be cleared out.

Details of these checks are included above.

.. [1]
   This *appears* to be the case. It may not be 100% accurate though!
