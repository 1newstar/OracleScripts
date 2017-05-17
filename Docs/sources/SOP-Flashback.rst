========================
Flashing Back a Database
========================

Abstract
========
This document gives details of the process involved, and the standard operating procedures to be followed, in the event that a database is to be flashed back.

Special consideration must be given to Data Guarded databases, or, those databases connected in a primary-standby setup, especially if more than one standby database is configured.

Databases may be flashed back to a SCN, to a point in time, to just before a restelogs, or, to a named restore point. By default flashing back is only possible to a point in the last "period" where the period is determined by the initialisation parameter ``db_flashback_retention_target``, which is set to 1440 minutes by default. This corresponds to 1 day. In order to flash back further, a restore point is most likely required, however, Oracle may hold flashback data longer than the configured limit, if it deems it necessary.

Restore points should be created with the option ``GUARANTEE FLASHBACK DATABASE`` specified.


Introduction
============

Regardless of how the databases are configured, a few checks and operations are common to all configurations.

-   All of the flashing back must be done in ``SQL*Plus`` as a ``SYSDBA`` enabled user.

-   Check ``V$DATABASE`` to ensure that flashback is indeed configured:

    ..  code-block:: sql
        
        select flashback_on 
        from v$database;
        
    If the result is 'YES' then this database is a candidate to be flashed back. Otherwise, there is no possibility that this database can be flashed back.
    
-   Check the ``V$FLASHBACK_DATABASE_LOG`` view to determine how far back we can flashback, if we don't have a restore point:

    ..  code-block:: sql
    
        select value/60 as hours
        from v$parameter
        where name = 'db_flashback_retention_target';
        
    and:
    
    ..  code-block:: sql
    
        select * from v$flashback_database_log;
    

    Under normal circumstances, the latter gives the oldest SCN and Date-Time that this database can be flashed back to.
    
    
Flashback Points
================

When flashing a database back in time, you specify where in its history you want to go to. This can be a SCN, a RESETLOGS, a DATE-TIME or a restore point name.    

SCN
---

..  code-block:: sql

    flashback  [standby] database to scn 123456789;
    
This will take the database back to the SCN in question. The CURRENT_SCN will be, briefly, set to the number given. However, if y9ou need to go back to *just before* the SCN given, then you should:

..  code-block:: sql

    flashback [standby] database to before scn 123456789;
    
This will take the database back to just before the given SCN.    

Resetlogs
---------

..  code-block:: sql

    flashback [standby] database to before resetlogs;
    
This will take the database back to just before the most recent ``OPEN RESETLOGS``.

    **Note**\ : It is not possible to flashback to an actual resetlogs point, only to a point just before it.


Date-Time
---------

..  code-block:: sql

    flashback [standby] database to timestamp XXX;
    
This will take the database back to the timestamp given as "XXX".

..  code-block:: sql

    flashback [standby] database to before timestamp xxx;
    
This will take the database back to just before the timestamp given as "XXX".

Timestamps
~~~~~~~~~~

In the examples above, Timestamps are shown as "XXX". The following are examples of valid timestamps to replace "XXX":

-   ``SYSDATE-1`` means exactly 24 hours ago, to the second.
-   ``trunc(SYSDATE)-1`` means to the *beginning* of yesterday - dd/mm/yyyy 00:00:00. (AKA Midnight!)
-   ``TO_DATE('07/04/2017 21:00:00','dd/mm/yyyy hh24:mi:ss')`` means to exactly the date and time specified, *providing* enough flashback logs exist in the FRA.


Restore Point
-------------

..  code_block:: sql

    flashback [standby] database to restore point rp_name;

This flashes the database back to the SCN represented by the restore point with the given name, which should not be in quotes. 

    **Note**\ : It is not possible to flashback to *before* a restore point.

Stand-Alone Databases
=====================

Stand-alone databases have no standby. They stand by themselves and are the easiest to flashback.

..  code-block:: sql

    shutdown
    startup mount
    flashback database to XXX;
    alter database open resetlogs;
    
XXX, in the above, is a flashback point as defined above.


Primary-Standby Databases
=========================

A primary and standby database, regardless of how many standby databases are configured, must be flashed back together. The process is as follows:

-   Connect to the standby database and flash it back to a point prior to that which the primary database will be flashed back to.
-   Connect to the primary database and flash it back to the desired point.


Flashing Databases Forward
==========================

Databases can be flashed back to a previous point in its history, as explained above, however, you can also flash forward to a point in its future history.

    Warning**\ : This has only been tested with existing *restore points*.
    
If a restore point exists at a point in time in the past, and you create a new restore point "now", then you can flash back to the previous restore point, do your work and then flash "back" to the "now" restore point.    
    