=====================================
Daily Statistics - Installation Guide
=====================================

..  Author:     Norman Dunbar
..  Date:       23rd March 2018.
..  Changes:    13/03/2018: Added logging of start, end and errors as appropriate.
..              13/03/2018: Jobs now submitted for all databases.
..              13/03/2018: MISA jobs are "load balanced" in an effort to spread the load.
..              19/04/2018: Big tables get special handling. 
..              23/05/2018: Procedure ``emergencyAnalyse`` added for ETL3 overrun situations.
..                          Split into Installation, User and Technical guides.


..  -----------------------------------------------------------------------------------------------------------
..  NOTE:   To get a hyperlink in a docx/pdf output file that looks for something in the current document 
..          instead of a web page, do this:
..
..          ... `Rolling Back <#rolling-back>`_ ... 
..
..          Rolling Back' is the link text as it will appear in the document.
..          <#rolling-back> is the hyperlinked section heading, massaged for correct use.
..
..          Section headings are lower cased and all spaces and punctuation, except hyphens, are replaced
..          with hyphens.
..  -----------------------------------------------------------------------------------------------------------

    

This document explains how to install the new Daily Statistics Gathering System into a database. At the time of writing, this has already been installed in the primary databases for MyHermes, PNET and MISA. These instructions can be followed to install on other databases, as required.


Installation Kit
================

An install kit exists, named ``DAILYSTATS.zip`` and can be found in the DBA Team's software repository at ``P:\Parcelnet System Development\dba\software_repository\Daily Stats\Latest`` while archived versions, can be found in ``P:\Parcelnet System Development\dba\software_repository\Daily Stats\Archive\yyyy-mm-dd`` where the date part of the name is the date *on which the new (latest) version was installed*. It is not the date that the software was released.

In other words, the code in the archive for 2018-04-23 was the code in place until that date, when a new version was installed.

Installation Scripts
--------------------

*   ``dailystats_control.sql`` - The top level script which calls the others in order, to install the system and assigns any required privileges to the HUK DBA team members only, at present. The ``DBA_USER`` account is also granted the ``CREATE JOB`` privilege so that the required scheduler jobs can be created when processing the MISA database. The script creates a log file of everything that was carried out - ``dailystats_control.log`` - in the current directory.

*   ``dailystats_exclusions.sql`` - Creates the table ``DBA_USER.DAILY_STATS_EXCLUSIONS``, plus trigger ``DAILY_STATS_EXCLUSIONS_TRG``.

*   ``dailystats_logging.sql`` - Creates the table ``DBA_USER.DAILY_STATS_LOG``, trigger ``DAILY_STATS_LOG_TRG`` and a sequence ``DAILY_STATS_LOG_SEQ``. 

*   ``pkg_dailystats.pks`` - Creates the package ``DBA_USER.PKG_DAILYSTATS``.

*   ``pkg_dailystats.pkb`` - Creates the package body for ``DBA_USER.PKG_DAILYSTATS``.

*   ``load_exclusions.sql`` - Loads a number of default users which we wish to exclude from the gathering of statistics under the new system. This includes the standard Oracle supplied system type user accounts, the HUK DBA team's own accounts and a few other *obvious* accounts.

Rollback Script
---------------

There is a rollback script to remove the new system, should this be necessary.

*   ``dailystats_rollback.sql`` - Rolls back the entire installation of the new system. Actions (and any errors) are recorded in the log file ``dailystats_rollback.log``.

Execution Shell Scripts
-----------------------

There are also three shell scripts to be installed on the servers, and *edited as appropriate, to change the database names*:

*   ``dailystats_auto`` - Allows the statistics to be gathered automatically. Generates the SQL commands required and submits a number of DBMS_SCHEDULER jobs to execute the commands. The jobs are submitted in the *enabled* state, and so will execute immediately. For MISA the number of jobs is configured within the package (default 18) while for other databases, the script submits a single scheduler job.

    It should be noted that additional jobs may be created is any of the objects identified as being long-running, are being analysed. These always create a special job, running only a single analysis.
    
*   ``dailystats_semi`` - Allows the statistics to be gathered semi-automatically. Generates the SQL commands required and submits a number of DBMS_SCHEDULER jobs to execute the commands, however, the jobs are submitted *disabled* so do not execute until the DBA enables them. For MISA the number of jobs is configured within the package (default 18) while for other databases, the script submits a single scheduler jobs.

*   ``dailystats_manual`` - Allows the statistics to be gathered manually as at present. Simply displays the SQL commands required. The DBA will be responsible for copying and pasting into SQL*Plus, or similar, to actually carry out the statistics gathering.


Installation
------------

1.  Transfer the installation kit (one zip file) to the appropriate database server. You will have to transfer it to your own account as direct login to the oracle account is (usually) disabled.
1.  Login to the server as your own account, and change the permissions on the install kit to allow everyone the ability to read it.

    ..  code-block:: bash
    
        chmod a+r DAILYSTATS.zip

1.  Become the oracle user in the normal manner. Set the appropriate Oracle environment, again in the normal manner.

    ..  code-block:: bash
    
        sudo -iu oracle
        . oraenv
        
1.  Create a new directory, for example, ``dailystats_install``, and change into it.

    ..  code-block:: bash
    
        mkdir -p dailystats_install
        cd dailystats_install

1.  Copy the installation kit into the new directory and unzip it.

    ..  code-block:: bash
    
        cp /home/your_user/DAILYSTATS.zip ./
        unzip DAILYSTATS.zip

1.  Check that the files listed above are all present.
1.  Connect to SQL*Plus as either your own DBA enabled user, or as a SYDBA enabled user.

    ..  code-block:: bash
    
        sqlplus your_user/your_password

1.  Execute the ``dailystats_control.sql`` script. This will install the system.

    ..  code-block:: sql
    
        @dailystats_control

    Once this has completed, the ``dailystats_control.log`` file should be checked for any errors and anything untoward resolved before using the system.

    The privilege, ``CREATE JOB`` will be granted to the DBA_USER account, however, some, but not all, databases already have this granted. This will not cause an error. This privilege *will not* be removed if the system is rolled back (see `Rolling Back <#rolling-back>`_ below.)

1.  If necessary:
    *   Copy the three ``dailystats_*`` shell scripts to the ``/home/oracle/alain`` directory. They must be owned by the oracle account. Also, ensure that the scripts are made executable by at least owner and group.
    
        ..  code-block:: bash
        
            cp dailystats_{manual,semi,auto} ../alain/
            chown oracle:oinstall ../alain/dailystats_{manual,semi,auto}
            chmod ug+x ../alain/dailystats_{manual,semi,auto}
    
    *   Edit the scripts to change one occurrence of 'XXXX' to the appropriate database name (MISA, RTT (or PNET) and MYHERMES only are permitted.)


Configuration
-------------

After installation has been completed, and checked, it may be advisable to execute the following code in a SQL*Plus session (or Toad, SQLDeveloper etc):

..  code-block:: sql

    set serverout on size unlimited
    set lines 300 trimspool on trimout on pages 200
    exec dba_user.pkg_dailystats.reportExcludedUsers;
    
This will display all the users currently excluded from the checks for objects with stale statistics. Depending on the database, you may need or wish to add others, or, remove some of the usernames listed. The package contains some user management procedures to carry out those tasks. See the User Guide for details.


Rolling Back
============

Should it be necessary to rollback the new system, and remove it from the database, simply:

1.  Login to the server as your own account, and become the oracle user in the normal manner. Set the appropriate Oracle environment, again in the normal manner.

    ..  code-block:: bash
    
        sudo -iu oracle
        . oraenv

1.  Change to the new directory, ``dailystats_install``.

    ..  code-block:: bash
    
        cd dailystats_install

1.  Connect to SQL*Plus as either your own DBA enabled user or as a SYSDBA enabled user.

    ..  code-block:: bash
    
        sqlplus your_user/your_password

1.  Execute the ``dailystats_rollback.sql`` script. This will uninstall the system.

    ..  code-block:: sql
    
        @dailystats_rollback


1.  Check the ``dailystats_rollback.log`` file for any errors.
1.  Remove the ``dailystats_*`` scripts from ``/home/oracle/alain``:
    
    ..  code-block:: bash
    
        rm ../alain/dailystats_{auto,manual,semi}

Note that the rollback script *will not* revoke ``CREATE JOB`` from the DBA_USER account as some databases have been found to have had this privilege granted *prior* to the system being installed.


