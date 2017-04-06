..  To build a Word "docx" file:
..  The reference doc contains examples of the styles you wish to use.

..  pandoc -f rst -t docx -o 9iRestore.docx --reference-docx=..\pandoc_reference.docx --table-of-contents --toc-depth=3 9iRestore.rst

..  To build a PDF:
..  Colour names are case sensitive!

..  DBA Documentation\9i Restore>pandoc -f rst -t latex -o 9iRestore.pdf --table-of-contents --toc-depth=3 9iRestore.rst --variable toccolor=Gray --variable linkcolor=Gray --variable urlcolor=Gray

========================================
Solaris 9i Import From Azure Windows 11g
========================================

Abstract
========

This document describes the processes that should be followed in order to restore the 9i Solaris database from an export, taken using 9i ``exp`` software, from an 11g database on Windows, created and restored from an RMAN database backup of the production database in Azure. 

Due to a couple of bugs in the Oracle versions in use, which Oracle have never resolved, there is a lot more work done in this exercise than should have been required.


Introduction
============

The processes, in brief, to restore a 9i database from Azure, are:

- Use RMAN to backup the database in Azure, using 11g software. (Leeds DBAs)
- Transfer the numerous dump files, two data and redo file "renaming" scripts, one control file (and spfile) autobackup to the ftp server. (Leeds DBAs)
- FTP the files down to Beckenham. (Leeds or Beckenham DBAs)
- Use RMAN on a Windows server, running 11.2.0.4 Oracle software to restore the backups to a temporary working database. Full instructions have been provided to, and tested by, the Beckenham DBAs already. See document *RMANRestore.docx* for details.  (Beckenham DBAs)
- Connect to the Windows 11.2.0.4 database from a Solaris server, with Oracle 9i ``exp`` software.  (Beckenham DBAs)
- Follow the instructions below to prepare the 11g database for the export.  (Beckenham DBAs)
- Export the database users using the same export parameter files that were used when the 9i database was exported for Azure to import.  (Beckenham DBAs)
- Follow the instructions below to prepare the 9i database for the import.  (Beckenham DBAs)
- Follow the instructions below to import the 11g data to the 9i database.  (Beckenham DBAs)
- Follow the instructions below to run the post import processes.  (Beckenham DBAs)
- Run any reconciliation or checking scripts etc, that may be required by the business. ( Beckenham DBAs and Business)
- Open the database for general use.  (Beckenham DBAs)


Assumptions
===========

- A full set of export files have been created exactly as per a 9i to 11g export.
- These parameter files are available on the 9i server.
- The 9i database has had no changes or processing done since the files were exported to 11g.
- The tables and users *not* imported into 11g are not required on 9i either. Temporary tables, developer tables, QUEST and TOAD tables never had *data* exported to 11g so will be blank in 11g. After the 9i import, they will be empty in 9i too.


Known Problem Areas
===================

- There is an Oracle bug/feature related to view EXU9DEFPSWITCHES. The problem is identified in doc 1154215.1 and the fix/workaround is detailed in doc 550740.1. The fix is supplied in the *run_11g_preparation.sql* script. This must be applied to the 11g database *prior* to the 9i export.
- Oracle 11g has DEFERRED_SEGMENT_CREATION while 9i does not. This causes errors on the export, as follows::

        EXP-00008: ORACLE error 1455 encountered
        ORA-01455: converting column overflows integer datatype
    
  This error can appear *after* a table name - caused by the table having no allocated segments yet - or after all tables - caused by snapshot logs existing in 11g. In the case of the latter, an SR was opened with Oracle for investigation. 
    
  In the case of the former the solution is to run a script that will allocate an extent to any table that has no extents allocated - these will be tables with no rows. A script, *deferred_segments.sql*, has been supplied to do this.

- The following error may result during the 9i export::

      Table UKFATCASubmissionFIRe98_TAB will be exported in conventional path.
      . . exporting table    UKFATCASubmissionFIRe98_TAB
      EXP-00056: ORACLE error 31013 encountered
      ORA-31013: Invalid XPATH expression
      ORA-06512: at "XDB.DBMS_XDBUTIL_INT", line 482 
    
  However, the table in question is blank in 11g at present and will already exist in 9i prior to the import running, so not a great problem. However, SR 3-1379877961 has been raised for this and the other problem mentioned above, error ORA-01455 on the NOROWS export.
    
  The workaround/solution, for the ORA-01455 errors, as supplied by Oracle, is to:
    
  .. code-block:: sql
    
      drop snapshot log on fcs.investor;
      drop snapshot log on fcs.ordtran;
        
  You may also wish to examine the DBA_SNAPSHOTS and DBA_SNAPSHOT_LOGS to determine if any others need dropping - for the users we are about to export only though.
    
- Tables which use sequences to populate a primary (or unique) key column will have a higher ``nextval`` in the 11g database than those in the 9i database. This could, if not resolved, cause duplicate key values, or unique constraint violations post import.
- Sequences cannot be imported by themselves. They must be imported from the NOROWS export file as they do not exist in the various FCS* export files as these are table level exports.


11g Preparation
===============

The 11g database requires minimal preparation, however, there are some work that is mandatory before an export with 9i software will work, and not corrupt the export file.

- Ensure that all empty tables have a segment allocated;
- Drop snapshot logs on any tables that we will be exporting;
- Drop two materialized views;
- Rebuild view EXU9DEFPSWITCHES. See note 550740.1 for full details.

The script *run_11g_preparation.sql* carries out the required work.


In Detail - 11g
---------------

Login to the 11g database as SYSDBA, and edit the following scripts and/or sub-scripts. The list of users *must* be edited to ensure that it matches the similar list in the NOROWS export parameter file, plus the FCS schema:

- *Deferred_segments.sql*

Run the script *run_11g_preparation.sql* as the SYSDBA user. 

Check the following spool files for errors:

- *Deferred_segments.lst* - you must resolve any problems before continuing. The 9i import will not be able to work if this script has not run to completion.
- *Run_11g_preparation.lst* - you can ignore any failures to drop the materialized views and/or snapshot logs in this file, but everything else must have completed successfully.

The script *run_11g_preparation.sql* *must* be completed successfully *before* the export is attempted using the 9i ``exp`` utility. If not, the generated export file will be (silently) corrupted and the 9i ``imp`` will fail with a core dump.

The *run_11g_preparation.sql* script can be re-run at will without any special considerations, in the event that errors have been detected and resolved etc.


9i Preparation
==============

The 9i database must also be prepared to receive the import from 11g.

- Generate a privileges script to be run after the import;
- Drop *most* of the users' tables;

The script *run_9i_preparation.sql* carries out the above work. After the import, the following are required:

The imports can then be run, in the following order:

- Import the NOROWS export file;
- Run a script to do some tidying up after the import.
- Run a script to recreate two XML tables.
- In parallel, and after the completion of the above, run the various ROWS imports;
- When the above have completed, run the CONSTRAINTS import.

Various parameter files have been supplied to carry out the above imports. These should be edited to ensure that the ``file=`` and ``log=`` parameters are correctly set to match the locations of the dump files on the 9i server.

After *all* the imports have completed and any problems resolved:

- Recreate the dropped materialized views;
- Run the generated privileges script.

The scripts *post_9i_import.sql* and *materialised_views.sql* carry out the above work.


In Detail - 9i
--------------

The 9i database should have all its *application* tables, apart from the FCS.XML_FATCA_REPORTS and FCS."UKFATCASUBMISSIONFIRE98_TAB", and all sequences etc dropped prior to the imports. Indexes, triggers etc attached to the two exception tables should not be dropped.

This should be done by checking the export parameter file for the original NOROWS export, the file in question is the *exp_rows_NOFCS.par* one. In that file you will find a list of user accounts *similar* to the following:

.. code-block:: sql

    ...
    owner=(CMTEMP,ITOPS,LEEDS_CONFIG,OEIC_RECALC,UVSCHEDULER,
    IBASHIR,JRICHARDSON1,PPHILLIPS,SMAHALA,TAKEON_ARCH_GLO,
    TAKEON_CF_INVESTEC,TAKEON_MITON,TAKEON_PANTHER,
    TAKEON_PENNINE,TAKEON_WAY,TAKEON_WOOD_ST)
    ...

These users, *plus FCS*, are the ones you need to clear out in preparation for reimporting their tables etc. see below for scripts etc to facilitate this requirement.

    
9i Preparation Script
---------------------    

A script has been supplied, *run_9i_preparation.sql*, which will drop all required tables in those selected schemas (plus the FCS schema) and drop any sequences etc owned by the various schemas.

**You must ensure that the list of schemas in the *run_9i_preparation.sql* script and in the sub-script, *generate_9i_privileges.sql*, matches those in the NOFCS export parameter file, plus FCS.**

Any exceptions will be listed in the following spool file(s) and the code will attempt to continue with the remaining tables and/or sequences. Any problems *must* be resolved prior to continuing.

- *run_9i_preparation.lst*

The *run_9i_preparation.sql* script can be run repeatedly, if desired.


Run the Imports
===============

The database is now be ready to accept the data back from 11g. It *must* have been exported with the 9i software though, otherwise, it will fail to import.  


Import the NOROWS data
----------------------

You should start with a NOROWS import to recreate the sequences, amongst other objects, with their 11g values. **Please edit the *imp_NOROWS.par* parameter file to set the following options correctly as per the 9i server**:

- file=/path/to/exp_NOROWS.dmp
- log=/path/to/imp_NOROWS.log

Then run the import::

    imp parfile=imp_NOROWS.par
    
Check the results when the import has completed. Resolve any issues before continuing, however, any problems relating to the tables FCS.XML_FATCA_REPORTS and/or FCS."UKFATCASubmissionFIRe98_TAB", or the various FCS TYPEs "already existing with a different identifier" should be ignored. Other problems should be investigated.


Run the Post NOROWS Import Script
---------------------------------

Triggers *must* be disabled after the NOROWS import as well as dropping the materialized views and a couple of packages. Run the script *post_import_norows.sql* to do this. Then check the following log files for any problems which must be resolved before continuing:

- *disable_triggers.lst*
- *post_import_norows.lst*

Any errors in the latter about the materialized views/snapshot logs not existing can be safely ignored.


Import the ROWS Data
--------------------
    
**Edit all the *imp_FCSn.par*, except FCS9, files to set the following options correctly as per the 9i server**:

- file=/path/to/exp_FCSn.dmp
- log=/path/to/imp_FCSn.log

You need not bother with FCS9 as we will not be importing that one as it cannot be imported into a 9i database. There is a workaround however.

**Edit the *imp_NOFCS.par* file to set the following options correctly as per the 9i server**:

- file=/path/to/exp_NOFCS.dmp
- log=/path/to/imp_NOFCS.log


Import the Remaining Data
~~~~~~~~~~~~~~~~~~~~~~~~~

Run the remaining imports, everything *apart from* FCS9::

    imp parfile=imp_NOFCS.par   &
    imp parfile=imp_FCS1.par    &
    imp parfile=imp_FCS2D.par   &
    imp parfile=imp_FCS3.par    &
    imp parfile=imp_FCS4.par    &
    imp parfile=imp_FCS5.par    &
    imp parfile=imp_FCS6.par    &
    imp parfile=imp_FCS7.par    &
    imp parfile=imp_FCS8.par    &

These will run in parallel. The longest running will be FCS7 and FCS4 which contain large tables (2 and 3 million rows plus) with LOB columns. These tables import one row at a time and commit, so are orders of magnitude slower than all the other imports. :-(

These imports will import data, PL/SQL etc and indexes. They *will not* recreate the grants or constraints.


Fix XML_FATCA_REPORTS
~~~~~~~~~~~~~~~~~~~~~

Due to 11g storage options, which 9i doesn't understand and thus throws import errors, we cannot recreate the XML_FATCA_REPORTS table using an `imp` of FCS9. We need to do it via a database link which has proved to be the only way so far, in numerous tests. As SYS:

.. code-block:: sql

    create database link xml_fatca
    connect to fcs
    identified by devenv
    using 'alias for rollback 11g database';

You will need to use the appropriate tns alias for the 11g rollback database of course!

.. code-block:: sql
    
    insert into fcs.xml_fatca_reports 
    select * from xml_fatca_reports@xml_fatca;
    commit;

This should complete without errors. Do not proceed until they are resolved.   

.. code-block:: sql
    
    drop database link xml_fatca;
    
Import Timings
--------------

As a rough guide, the longest running import *into 11g* took 6.5 hours (STP_MESSAGES aka FCS4) as it is a table with nearly 3 million rows - possibly higher now - and as there are LOB columns, each row is imported and committed. FCS7 takes about 20 minutes less as the slowest table in that import is also a LOB enabled table (WS_MESSAGE_HISTORY). The other imports will be finished long before these two.


Re-enable Grants & Constraints
==============================

After all the imports have finished, the XML tables have been recreated and the materialized views rebuilt, the constraints require rebuilding and all the previous 9i grants reapplying. 

**Edit the *imp_CONSTRAINTS.par* file to set the following options correctly as per the 9i server**:

- file=/path/to/exp_NOROWS.dmp
- log=/path/to/imp_CONSTRAINTS.log

**Note**: The dump file is indeed the NOROWS one, the above is correct.

Double-check that ``grants=y``, ``constraints=y``, ``indexes=n`` and ``rows=n`` are also applied.

Run the following import to recreate the constraints::

    imp parfile=imp_CONSTRAINTS.par

You should check the log file for any errors and resolve accordingly before continuing.


Recreate Materialized Views
===========================

Because the creation of the materialized views requires a primary key to be present, we must make sure that the step above completed without problems before continuing.

Execute the script *materialised_views.sql*, as the SYSDBA or FCS user, to recreate the two materialised views. You can obviously ignore any errors on DROP statements but other problems noted should be resolved before continuing. The logfile is *materialised_views.lst*. The following errors can be ignored:

- ORA-12002 and ORA-00942 - Anything that failed to DROP as it did not exist;
- ORA-00955 but only on creation of UNIQUE INDEXes, named FCS.ORDTRAN_PK1 or FCS.INVCODE_PK1.


Post 9i Import Script
=====================

A script has been supplied, *post_9i_import.sql* which will reapply all the previously existing privileges to ensure that they are all identical after the import from 11g, to how they were before the original export to 11g. Because some users were not migrated to 11g, those users will have lost their privileges in the 9i database due to the tables being dropped.

**The script must be edited to ensure that the list of selected schemas matches that in the *run_9i_preparation.sql* script.** 
   
When complete, any messages logged to the following spool file(s) are errors that may need to be resolved. The script above, or the individual scripts that it calls, can be run repeatedly, if desired.

- *recreate_9i_privileges.lst*

The following error can be ignored:

.. code-block:: sql

    grant EXECUTE on FCS."PK_COVERALL_AUTOSETT_MONIT" to AURA_USER
    
And also, to any other user where the grants fail. It seems that that package is no longer to be found.    


Open the Database for User Testing
==================================

Once there are no errors remaining, then the imports have been successful and any required testing, prior to user login and use, can begin.

