================================
Production Azure Server Patching
================================

Assumptions
===========

+-------------------------+---------------------------+-------------+
| Database Names          | *Current* Database Role   | Server Name |
+=========================+===========================+=============+
| CFG/CFGAUDIT/CFGRMN     | Primary databases.        | UVORC01     |
+-------------------------+---------------------------+-------------+
| CFGSB/CFGAUDSB/CFGRMNSB | Standby databases.        | UVORC02     |
+-------------------------+---------------------------+-------------+
| CFGDR/CFGAUDDR/CFGRMNDR | Standby databases for DR. | DRUVORC03   |
+-------------------------+---------------------------+-------------+


Server Preparation
==================

-   All RMAN backup jobs should be running on the primary server. If the patching will result in a change to the primary server, then the backup tasks must be disabled in Windows Task Scheduler on the current primary server, and enabled on the server that will become the primary server.

-   Beware if you have added new SYSDBA enabled users to the running primary. These will be replicated to the standby databases, however, unless you also have copied the primary password file to the standby servers, and renamed it to suit the applicable standby database, then these SYSDBA users will not be usable.


Patch SB server - UVORC02
=========================

It is assumed that DGMGRL checks will be carried out here to ensure that standby databases are up to date with no gaps.

-   Go to CFG/CFGAUDIT/CFGRMN and login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        disable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        
-   Go to CFGSB/CFGAUDSB/CFGRMNSB and:

    ..  code-block:: sql
    
        shutdown immediate.
        
-   Patch the SB server.
-   Go to CFGSB/CFGAUDSB/CFGRMNSB and:

    ..  code-block:: sql
    
        startup mount
        
-   Go to CFG/CFGAUDIT/CFGRMN  login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        enable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        

Patch the DR Server - DRUVORC03
===============================

-   Go to CFG/CFGAUDIT/CFGRMN  login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        disable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        
-   Go to CFGDR/CFGAUDDR/CFGRMNDR and:

    ..  code-block:: sql
    
        shutdown immediate.
        
-   Patch the DR server.
-   Go to CFGDR/CFGAUDDR/CFGRMNDR and:

    ..  code-block:: sql
    
        startup mount

-   Go to CFG/CFGAUDIT/CFGRMN  login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        enable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        

Patch the Primary Server - UVORC01
==================================

At this point, both standby servers have been patched and all standby databases are running again. We need to check, again, from the primary database server, that DGMGRL shows all databases are up to date with the primary database before we continue.

-   On the primary server, login to DGMGRL for each database in turn (CFG/CFGAUDIT/CFGRMN) and:

    ..  code-block:: sql
  
        switchover to "XXXSB"
     
    Replacing "XXX" with the appropriate standby database name.

        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.

At this point we are now running  the various "SB" databases as primary, the various "DR" databases are still DR standby databases, and the previously running primary databases are now running as standby databases. We can now patch what was the previous primary server.

-   Go to CFGSB/CFGAUDSB/CFGRMNSB  login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        disable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        
-   Go to CFG/CFGAUDIT/CFGRMN and:

    ..  code-block:: sql
    
        shutdown immediate.
        
-   Patch the primary server.
-   Go to CFG/CFGAUD/CFGRMN and:

    ..  code-block:: sql
    
        startup mount
        
-   Go to CFGSB/CFGAUDSB/CFGRMNSB  login to ``dgmgrl`` as the sys user, with a password, then:

    ..  code-block:: none
    
        show configuration
        enable database <whatever>
        
    This will stop the primary database from sending and applying logs on the named standby. 
    
        **NOTE**: You need to check the configuration first. If the database names are in UPPER CASE, then they must be typed in upper case with surrounding double quotes. If they are listed in lower case, then they must be typed in lower case.
        

At this point we are running the old primary databases as a standby, the old DR servers are still running as a DR standby, but the old standby databases are now the current primary databases.

    
Restart The Various Services
============================

Mark Phillips can now be utilised to restart all known services and ensure that they correctly connect to the now running primary databases, the ones with "SB" at the end of their names. 

    **Note**\ : This was a bad choice of naming standards.
    
It is assumed that DGMGRL checks will be carried out once more to ensure that all databases are up to date with no gaps.
