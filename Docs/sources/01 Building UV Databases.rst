=======================================================
Building Databases after DBCA Creation on Azure Servers
=======================================================

Abstract
========

This document describes the processes that should be followed in order
to take a default database, created by DBCA, and make it resemble a
production, pre-production, staging or test database for UV etc.

It is assumed that the database was created by following the
instructions in the document *``00 Using DBCA to Build Initial Databases``*.
That process builds a standard blank general purpose
database with the minimum of tablespaces etc.

In order to convert this default database to one that can be used as a UV database, some
additional build instructions must be followed to create the required
tablespaces etc. These are detailed below.


Continuing the Database Build
=============================

Initial Database Build
----------------------

The database was initially built as a general purpose database using the
``dbca.bat`` utility, and configured as per the document mentioned above.
The database was initially created in NOARCHIVELOG mode - this will be changed later.

Upgrading the Database to UV
----------------------------

To create a UV database we need some additional build processes. There
are scripts available in TFS, at *$TFS\\TA\\DEV\\Projects\\Oracle
Upgrade 9i to 11g\\UKRegulated\\Database\\DBA
Documentation\\Code\\TrialRunStuff\\CFG\_BuildScripts*, which can be
used to bring a default database up to UV requirements.


T005\_Parameters
================

This is a script found in the above location, which sets numerous
parameters to those required by an 11g database for UV use. The script
will need editing on a case by case basis as not all databases will be
required to be production ready, some are merely staging databases for
various refreshes etc.


Delete Obsolete Parameters
--------------------------

Check for, and remove if found, any and all of the following depreciated
parameters from the script. The database will not start if these are
present.

As of October 2016 this should not be required as the file in TFS has
been correctly amended to remove the above – however, it pays to sanity
check, just in case!

..  code-block::

    AQ_TM_PROCESSES (Cannot be explicitly set to zero on 11g).
    CURSOR_SPACE_FOR_TIME
    FAST_START_IO_TARGET
    LOG_ARCHIVE_START
    MAX_ENABLED_ROLES
    PARALLEL_AUTOMATIC_TUNING
    PARALLEL_SERVER
    PARALLEL_SERVER_INSTANCES
    PLSQL_V2_COMPATIBILITY
    REMOTE_OS_AUTHENT
    SERIAL_REUSE
    SQL_TRACE
    DB_BLOCK_BUFFERS (Cannot be set, even to its default value, if
    SGA_TARGET or MEMORY_TARGET are present.)


Adjust Database Usage Specific Parameters
-----------------------------------------

Some parameters in the script are currently configured for production
usage. This may not be appropriate, so ensure that the following are set
according to the proposed usage of the database.

For production type usage, and test databases which are running in
archivelog mode, including pre-production:

..  code-block:: sql

    alter system set sga_target=5g scope=spfile;
    alter system set sga_max_size=6g scope=spfile;
    alter system set pga_aggregate_target = 1g scope = spfile;
    alter system set db_recovery_file_dest_size=500g scope=spfile;

Non production type databases, such as testing or staging, require
lesser settings. The following are advised:

..  code-block:: sql

    alter system set sga_target=2g scope=spfile;
    alter system set sga_max_size=3g scope=spfile;
    alter system set pga_aggregate_target = 500m scope = spfile;
    alter system set db_recovery_file_dest_size=100g scope=spfile;

Non-production databases usually run in NOARCHIVELOG mode, so do not
need a huge FRA. If the database is to be run in ARCHIVELOG mode, adjust
accordingly as per production.


Adjust Standard Parameters
--------------------------

The following must be set as below regardless of the database usage.

..  code-block:: sql

    alter system set streams_pool_size=300m scope=spfile;

    alter system set
    log_archive_dest_1='location=use_db_recovery_file_dest'
    scope=spfile;

    alter system set
    log_archive_format='%D_%S_%R.%T.arc'scope=spfile;

    
Always Turn Off Extra Cost Options
----------------------------------

Oracle sneakily sets a couple of parameters to enable some extra cost
options when using Enterprise Edition. We don’t pay for these options,
so the must be disabled to avoid being fined in the event of a licencing
audit.

..  code-block:: sql

    alter system set control_management_pack_access='NONE' scope=spfile;

    alter system set enable_ddl_logging=false scope=both;

    
Reset the Parameters
--------------------

The parameters need to be applied to the database.

Login to the database as the SYSDBA user and execute the script. This
will set the parameters in the spfile, only, ready to be applied at the
next database start up.

..  code-block:: batch

    set ORACLE_HOME=C:\OracleDatabase\product\11.2.0\dbhome_1
    set ORACLE_SID=CFG
    set NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss

Alternatively:    

..  code-block:: batch

    oraenv CFG

Then:
    
..  code-block:: batch
   
    sqlplus sys/<password> as sysdba 
    @t005_parameters.sql

Check the output from the above script before continuing. Fix any errors
noted.


Fixing SPFILE Errors
--------------------

In the *unlikely event* that you get a parameter setting wrong when setting it in the SPFILE, you
will not know until the next start up. Oracle validates parameter settings
at "memory" time, not at "spfile" time. The database will probably fail to start
in this case.

This is easily fixed by creating a PFILE (``initSID.ora``) and setting the
``spfile`` parameter within to the existing spfile name, which has the
broken parameter(s), and *then*, adding the corrections. For example, if
``REMOTE_LISTENER`` has been incorrectly set and is preventing the database from starting:

Create a pfile in ``%ORACLE_HOME%\database`` with the following content:

..  code-block:: 

    spfile='C:\OracleDatabase\product\11.2.0\dbhome_1\spfileSID.ora'
    REMOTE_LISTENER = 'Correct Value'

Start the database in MOUNT mode using the above PFILE.

..  code-block:: sql

    sqlplus sys/<password> as sysdba 
    startup mount pfile='?\database\initSID.ora'

Then, for each incorrect parameter that you added to the PFILE, run SQL
commands to correct them in the SPFILE for future use. For our example
of REMOTE\_LISTENER, the following will suffice:

..  code-block:: sql

    alter system set remote_listener = 'Correct Value' scope=spfile;

Once you have corrected everything in the spfile, startup the database
with the corrections applied:

..  code-block:: sql

    startup force

The database will restart and will pick up and use the corrected spfile named above.

    
T030\_Create\_redo\_log\_groups
===============================

All our databases end up with a set of redo logfiles, in groups of two
members, which match the production databases. Each group should have a
member on the oradata side, and a member on the fra.

The script creates log groups 4 through 13, inclusive, and adds two
members, correctly placed, in each group. The two paths for the members
are assumed to be:

-  ``??:\mnt\oradata\ORACLE_SID\`` for the oradata member; and
-  ``!!:\mnt\fast_recovery_area\ORACLE_SID\`` for the FRA member.

Once the new groups are created, the existing groups 1 through 3 are
rotated out and dropped, leaving only the new groups present.

Obviously, you will have to edit the script to correctly identify the
desired drives and database name in the two paths above.

Edit ``t030_create_redo_log_groups.sql`` and:

-  Make sure that the various file and/or disc locations are correct.
   Replace ``??:`` with your desired oradata disc letter, and ``!!:``
   with your desired FRA drive letter.

-  Replace ``\ORACLE_SID\`` with the oracle database name.

-  Make sure that one of the redo log files in each group is on the
   FRA with the other in the oradata area.

-  Save the changes.

Execute ``t030_create_redo_log_groups.sql``:

..  code-block:: sql

    sqlplus sys/<password> as sysdba 
    @t030_create_redo_log_groups.sql


T040\_Create\_tablespaces
=========================

This script creates any desired new tablespaces for a UV database. As
with the redo logfile script, the drive letters have been obfuscated to
prevent accidental execution with the wrong drive, or database name,
specified.

The script ``T040_create_tablespaces.sql`` was edited to fill in the
details from the latest export reconciliation script for the Trial
Run of the migration. This has all the commands required to create
all the tablespaces, but requires a little editing to:

-  Make sure that the disc locations are correct. All data files are
   assumed to be created on the oradata path and are currently set to
   use ``??:\mnt\oradata\ORACLE_SID\`` for the path.

-  Change ``??:`` to reflect your desired oradata path's drive letter.

-  Change ``\ORACLE_SID\`` to reflect the correct database name.

-  Save the changes.

Execute the script:

..  code-block:: sql

    sqlplus sys/<password> as sysdba 
    @t040_create_tablespaces.sql

It will take a while to complete as it is adding quite a few
gigabytes of data files to the database.

    
T060\_Create\_verify\_function
==============================

This script creates the default password verification function for the
UV databases. It simply requires to be executed.

..  code-block:: sql

    sqlplus sys/<password> as sysdba 
    @t060_create_verify_function.sql

    
Post Creation Tasks
===================

After the database has been built up to a UV standard, there is a little
tidying up to carry out. Although the DBCA script was told *not* to create
the demo schemas, it did still create a database with the ``scott`` schema
present. This needs to be deleted for security purposes. 

All databases
will have Statspack installed, but only production will actually utilise
it (at present!)

Tidy Up and Install Statspack
-----------------------------

..  code-block:: sql

    sqlplus sys/<password> as sysdba 

    set timing off
    alter database force logging;
    
    -- REPLACE !! in the following with the FRA drive letter.
    alter database enable block change tracking using file
    '!!:\mnt\fast_recovery_area\ORACLE_SID\bct.dbf';

    drop user scott cascade;

    -- Install Statspack
    @?\rdbms\admin\spcreate

    -- You are now logged in to PERFSTAT, no longer to SYS!

Check Tablespaces
-----------------

..  code-block:: sql

    connect sys/<password> as sysdba

    col gb format 9,990.99
    set lines 2000 pages 2000 trimspool on

    select tablespace_name, sum(bytes)/1024/1024/1024 as gb
    from dba_data_files
    where tablespace_name not in
    ('SYSTEM','SYSAUX','UNDOTBS1','XDB','DRSYS','TOOLS')
    group by tablespace_name
    --
    union all
    --
    select tablespace_name, sum(bytes)/1024/1024/1024 as gb
    from dba_temp_files
    group by tablespace_name
    --
    order by 1;

The results should resemble the following:

..  code-block::

    TABLESPACE\_NAME    GB
    ---------------- -----
    ARCHIVE1          0.49
    ARCHIVE1_INDEX    0.49
    AURA              0.00
    AURA_INDEX        1.37
    CFA              21.24
    CFA_INDEX         5.00
    CFGLOG            4.65
    CFGLOG_INDEX     14.57
    COA               3.61
    COA_INDEX         2.79
    CWMLITE           0.02
    FTREG             4.23
    FTREG_INDEX       2.02
    INDX              0.02
    ODM               0.02
    PERFSTAT          2.00
    SNAPLOG           0.10
    TAKEON            3.56
    TAKEON_INDEX      1.12
    TEMP             10.00
    USERS             0.04
    USERS_INDEX       0.01
    UVDATA01          1.00
    UVDATA01_INDEX    0.49
    UVLOG01           1.00
    UVLOG01_INDEX     0.49

    26 rows selected

If the database is to be run in archivelog mode – currently only
production and pre-production databases get this - then proceed as
follows:

..  code-block:: sql

    shutdown
    startup mount
    alter database archivelog;
    alter database flashback on;
    alter database open;
    exit

Update tnsnames.ora
-------------------

The ``tnsnames.ora`` file on (at least) this Azure server and any 
others, for standby or DR purposes, needs to be updated with details 
of the newly configured database, if not already present. 

..  code-block:: 

    cd %ORACLE_HOME%\network\admin
    notepad tnsnames.ora

Add a new entry for the newly created database, then save the file.
        
Consider also updating the central ``tnsnames.ora`` file located in ``\\CFSLDSFP01\Apps.Net\Aura\TNSNAMES_CENTRE``.


Conclusion
==========

This concludes initial configuration for the database. Running an import
of data taken from either the 9i database currently (at the time of
writing) or from another 11g Azure database, will create all the
required grants etc.
