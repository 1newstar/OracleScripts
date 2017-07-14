=============================
Refreshing SCTEST from SCPROD
=============================

Introduction
============

This document gives step by step details, for a DBA, to refresh the SCTEST database using 'last night's' SCPROD production backups. This serves two main purposes:

-   It refreshes the test database as requested;
-   It proves that the backup of the production database can be used to restore it, should the need ever arise.

It should also be noted that unlike the previous instructions to refresh the SCTEST database, there is no need to close the production database at any point. The production database will not be touched - only the latest production dump files will be used. The test database will, obviously, require to be closed during the exercise.


SCTEST Configuration
====================

As of the refresh carried out on 14th July 2017, by Norman, the following locations for SCTEST match those for SCPROD - so that further refreshes can be carried out without too much hassle of changing parameters, creating folders and generally messing about. It also means that the test database reflects the production one in structure, other than the database name, where applicable.

File Locations
--------------

-   Data, Temp, control & some redo files are located in ``d:\oracle\oradata\SCTEST\``.
-   Some redo files are located in ``e:\oracle\oradata\SCTEST\``.
-   The FRA (Fast Recovery Area) is now located in ``e:\oracle\fast_recovery_area`` in the folder ``SCTEST``.

These locations match those on the production server, but obviously, the database name, where used, is different.

Refreshing the SCTEST Database
==============================

The process to be followed is:

-   Drop the current database;
-   Start a new test instance.
-   Tidy away any remaining data files etc;
-   Copy the production dump files to the test server;
-   Restore the production dump to the test database;
-   Clean up the test database afterwards & check that no production detritus remains in the test database;
-   Clean up the production dumps from the test server;
-   Handover the database to Daryl (DevOps) to have the application synchronised.

    **Note** At present, there is no depersonalisation requirements, this *may* change in the future. Also, the users do not want the test database, post completion, to have any passwords changed - even though they reflect the current production database ones.


Drop the Test Database
----------------------

The test database should be available for our use at this point, check with the users before continuing. Once approval has been gained, proceed as follows:

..  code-block:: none

    sqlplus / as sysdba

Once logged in, check the database is the correct one:

..  code-block:: sql

    select name, db_unique_name from v$database;
    
Make sure that you see ``SCTEST`` for both columns. If so, start the database in restricted mode, then drop it, otherwise make sure you connect to the correct database. We do not drop production databases!

    
..  code-block:: sql

    startup force restrict mount;
    drop database;
    exit;

Start the Test Instance
-----------------------

Check that the ``initSCTEST.ora`` file in ``D:\product\12.1.0\dbhome_1\database`` contains only the following:

..  code-block:: none

    db_name='sctest'
    
If the file doesn't exist, or, contains any further information, edit it to ensure it looks like the above. Save the file and exit the editor.

Make sure that the file named ``spfileSCTEST.ora`` is removed, if present. *Do not* delete the file ``pwdSCTEST.ora``, we need that one to be kept.
    
    
Log back in to sqlplus - you cannot drop the database and immediately start an instance without exiting.

..  code-block:: none

    sqlplus / as sysdba

Once logged in, start the *instance*:

..  code-block:: sql

    startup nomount pfile='?\database\initSCTEST.ora';
    exit;
    
The instance is ready to have the database recreated from the production dumps.
    
Copy Production Dumps
---------------------

The production database appears to be backed up to the FRA every night, and only the latest copy of the database is kept there. The data files will be copied into the FRA and we need the latest backups from there to be copied to the test server, to a location of our choice.

We also need the backup of the production database's SPFILE and CONTROL FILES, so they will need to be identified and copied. They, of course, live in a completely different location.

Identify the Data Dumps
~~~~~~~~~~~~~~~~~~~~~~~

To identify the dump files required, log in to the production server and run an RMAN session, as follows:

..  code-block:: none

    rman target /
    
Once connected, run the following command to list the backups of the database:

..  code-block:: none

    list backup of database summary;
    
You should see something  resembling the following:

..  code-block:: none

    List of Backups
    ===============
    Key     TY LV ..... Compressed Tag
    ------- -- -- ..... ---------- ---
    16163   B  0  ..... YES        TAG20170713T200302
    16164   B  0  ..... YES        TAG20170713T200302

You will note two backups, both with the same tag. The tag is formatted as 'TAGyyyymmddThhmmss' (the standard ISO format for dates and times, if you are interested!) and gives you a good idea that you have the correct date and time for the backups. To get a list of the required files, proceed as follows:

..  code-block:: none

    list backup tag "TAG20170713T200302";
    
Which will give something like the following as output:

..  code-block:: none
    
    List of Backup Sets
    ===================

    BS Key  Type LV Size       Device Type Elapsed Time Completion Time
    ------- ---- -- ---------- ----------- ------------ ---------------
    16163   Incr 0  10.37G     DISK        00:35:08     13-JUL-17
            BP Key: 16163   Status: AVAILABLE  Compressed: YES  Tag: TAG20170713T200302
            Piece Name: E:\ORACLE\FAST_RECOVERY_AREA\SCPROD\BACKUPSET\ORA_DF949262582_S16281_S1_1
    ...
    
You only need the ``piece name`` to extract the location. All the files found there will be copied to the test server. You can see that the location is ``E:\ORACLE\FAST_RECOVERY_AREA\SCPROD\BACKUPSET``. If you open windows file explorer and navigate to that location, you will see around 5 or 6 files. These should be copied to the test server - see below for details.

Identify the Other Dumps
~~~~~~~~~~~~~~~~~~~~~~~~

Similarly to the above, you need to identify the spfile and control file backups.

..  code-block:: none

    list backup of spfile summary;
    
The output will show something like:

..  code-block:: none

    List of Backups
    ===============
    Key     TY LV .... Compressed Tag
    ------- -- -- .... ---------- ---
    16166   B  F  .... NO         TAG20170713T204103

Again, to get the details:

..  code-block:: none

    list backup tag "TAG20170713T204103";
    
The output from which will be as follows:

..  code-block:: none

    List of Backup Sets
    ===================

    BS Key  Type LV Size       Device Type Elapsed Time Completion Time
    ------- ---- -- ---------- ----------- ------------ ---------------
    16166   Full    24.17M     DISK        00:00:00     13-JUL-17
            BP Key: 16166   Status: AVAILABLE  Compressed: NO  Tag: TAG20170713T204103
            Piece Name: D:\ORACLE\PRODUCT\12.1.0\DBHOME_1\DATABASE\C-2025107939-20170713-00
      SPFILE Included: Modification time: 03-JUL-17
      SPFILE db_unique_name: SCPROD
      Control File Included: Ckp SCN: 1638026191   Ckp time: 13-JUL-17

You are interested in the following:

-   *SPFILE Included* - to show that the backup has the spfile within.
-   *Control File Included* - to show that the backup also includes the control file backup.
-   *Piece Name* - to show the name of the file you need to copy to the test server.
      
Copy the Files
~~~~~~~~~~~~~~

A share has been created on the test server, in folder ``e:\SCPROD_BACKUPS``, the share name is the same, ``SCPROD_BACKUPS``. 

Map this share as a drive *on the production server* (the test server cannot see the production backups location etc) as the Y drive, for example. The full share name is ``\\uatbckdimora02\SCPROD_Backups`` - make sure you do not choose the option to reconnect at logon, just in case.

-   Copy the spfile backup file that was identified above to the newly mapped Y drive. The file in this example is ``D:\ORACLE\PRODUCT\12.1.0\DBHOME_1\DATABASE\C-2025107939-20170713-00`` and contains the spfile and control file backups.

-   Copy all the files located in the folder identified as the data files backup location above, to the Y drive. This includes all the files found in ``E:\ORACLE\FAST_RECOVERY_AREA\SCPROD\BACKUPSET`` in our example above. Normally, this takes a couple on minutes for the two biggest files and the rest are pretty much instant.


Refresh the Test database
-------------------------

On the test server now, open an administrator enabled command session, and change to the location of the backups that were copied from the production server:

..  code-block:: none

    cd /d e:\SCPROD_Backups
    
Start RMAN and connect only to the test instance on the auxiliary connection:

..  code-block:: none

    rman auxiliary /

And run the script provided (see below) in the above location, which takes care of running the refresh, changing parameters and opening the database at the end:
    
..  code-block:: none
   
    @Refresh_SCTEST.rman


Post Refresh Clean Up
---------------------

After the refresh has completed, the database will have been opened ready for use. We need to adjust a couple of settings and make sure that we have no left overs from production hanging around.

..  code-block:: none

    sqlplus / as sysdba
    
Run the following command to check the initialisation parameters:

..  code-block:: sql

    select name, value
    from v$parameter
    where upper(value) like '%SCPROD%'    
    and lower(name) not like '%file_name_convert';

    
The database needs to be taken out of archivelog mode etc, so:

..  code-block:: sql

    -- Ignore errors from the following command.
    alter database disable block change tracking;
    
    startup force mount;
    
    alter database flashback off;
    alter database noarchivelog;
    alter database open;

Now drop the perfstat user and its dedicated temporary tablespace:

..  code-block:: sql

    drop user perfstat cascade;
    drop tablespace PERFSTAT_TEMP including contents and datafiles;

And finally, delete the backup files etc copied over from the production database from ``e:\SCPROD_Backups``. You should keep the script ``Refresh_SCTEST.rman`` for next month when we will do it all again.


Appendix - ``Refresh_SCTEST.rman`` Script
=========================================

The script mentioned above, to refresh the test database from the production backup files is as follows, should yo ever need to replace it:

..  code-block:: none

    #------------------------------------------------------------
    # Clone SCTEST from SCPROD Backups using RMAN. The refresh is
    # to the latest production dump and it is assumed that the
    # dump files are located in the e:\SCPROD_BACKUPS folder on
    # the test server.
    #------------------------------------------------------------
    # sqlplus / as sysdba
    # startup nomount pfile='?\database\initSCTEST.ora'
    # exit
    #
    # cd e:\SCPROD_Backups
    # rman AUXILIARY /
    # @refresh_SCTEST.rman
    #------------------------------------------------------------

    run {
        #
        # Not allowed any "normal" channels when not connecting to target!
        #

        allocate auxiliary channel x1 device type DISK;
        allocate auxiliary channel x2 device type DISK;
        allocate auxiliary channel x3 device type DISK;
        
        duplicate database SCPROD to SCTEST
        spfile
            set instance_name 'SCTEST'
            set service_names 'SCTEST'
            set fal_server=''
            set local_listener=''
            set log_archive_format='SCTEST_%s_%t_%r.arc'
            set log_archive_config=''
            set log_archive_dest_2=''
            set log_archive_dest_3=''
            set dispatchers '(PROTOCOL=TCP) (SERVICE=SCTESTXDB)'
            set audit_file_dest 'C:\ORACLE\ADMIN\SCTEST\ADUMP'
            set core_dump_dest='D:\ORACLE\ADMIN\SCTEST\CDUMP'
            set db_recovery_file_dest 'e:\oracle\fast_recovery_area'
            set dg_broker_start 'false'
            set dg_broker_config_file1=''
            set dg_broker_config_file2=''
            set control_files
                'd:\oracle\oradata\SCTEST\control1.ctl',
                'e:\oracle\oradata\SCTEST\control2.ctl'
            set db_file_name_convert
                'd:\oracle\oradata\SCPROD',
                'd:\oracle\oradata\SCTEST'
            set log_file_name_convert
                'd:\oracle\oradata\SCPROD',
                'd:\oracle\oradata\SCTEST',
                'e:\oracle\oradata\SCPROD',
                'e:\oracle\oradata\SCTEST'
        #
        # If we want to restore a particular backup date at 03:00 in the AM.
        # 
        #UNTIL TIME "to_date('27/06/2017 03:00:00', 'dd/mm/yyyy hh24:mi:ss')"
        #
        # We must tell RMAN where to find the backups as we are
        # not connecting to the CATALOG either.
        #
        backup location 'E:\SCPROD_Backups'
        nofilenamecheck;

        release channel x1;
        release channel x2;
        release channel x3;
    }

----

| Author: Norman Dunbar
| Email: norman@dunbar-it.co.uk
| Created: 14th July 2017
| Last Updated: 14th July 2017