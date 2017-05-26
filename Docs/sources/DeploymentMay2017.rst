====================================
May 2017 Deployment Process for Norm
====================================

PreProd (ppdcfg)
----------------

#.	Take incremental backup/Create restore point.
#.	Give required users restricted session on the desired database.
#.	Put the desired database in restricted mode.
#.	The scripts are found on ``$/TA/MAIN/Non Source/Dev DBA/Database Release/Active/R804 May Release/R804_V01_P00_MayRel_db_release_master.zip`` - but this will vary, see "go-ahead" email for full details.
#.	Copy the file on the server in ``F:\_devops\Releases\YYYYMon``.
#.	After unzipping the file run ``sqlplus /nolog @R804_V01_P00_MayRel_db_release_master.sql`` on the desired database *RUN AS FCS* user when prompted.
#.  *Stop here if you are running on production, then see below.*
#.	Check the logs.
#.	Disable restricted session.
#.	Do a schema compare between PRDUAT and PreProd.
#.	Send results to Lead dev.
#.  Send email - "I am finished! - please check".
#.  Delete restore point, when confirmation that all is well has been received.


Prod (cfg)
----------

The initial steps are identical to steps 1-6 above.

7.  Run IO Terminal Adhoc Fix attached. (Or, see below.)
#.  Check USER folder as extracted from zip. 
#.  For each user, generate a secure password and amend the script to use the password defined for each user in KeePass under Production->Services->UserName.
#.	Check the logs.
#.	Disable restricted session.
#.	Do a schema compare between PreProd and Live.
#.	Send results to Lead dev.
#.  Send email - "I am finished! - please check".
#.  Delete restore point, when confirmation that all is well has been received.


Terminal Adhoc Fix Script
-------------------------

This script should be executed on the production database only, after applying the deployment script(s).

..  code-block:: none

    /* Formatted on 06/05/2015 10:06:29 (QP5 v5.240.12305.39446) */
    /********************************************************************
     Support works Log - F0954437
     Developer         - SSUBHAN
     Business Contact  - BoNY
     Description       - validation exception failed script 
    ********************************************************************/

    SPOOL F0954437.lst

    SET DEFINE OFF
    SET ECHO ON
    SET TIMING ON
    SET FEEDBACK 1
    SET NULL *
    SET PAGES 1000
    SET LINES 2000
    SET TRIMSPOOL ON

    SELECT TO_CHAR (SYSDATE, 'dd-mon-yyyy hh24:mi:ss') FROM DUAL;

    SELECT osuser, username
      FROM v$session
     WHERE audsid = USERENV ('sessionid');


    --select 1 rows

    Select * from Service_Actions;
    -- 6 rows Selected

    UPDATE SERVICE_actions
       SET last_ddl = PK_IOTERMINAL.F_GET_LAST_DDL('PK_STATPRO')
     WHERE action_object IN
              ('FCS.PK_STATPRO.GETPORTFOLIOINFORMATION',
               'FCS.PK_STATPRO.GETNAVINFORMATION');
    -- 1 row updated
               
    UPDATE SERVICE_actions
       SET last_ddl = PK_IOTERMINAL.F_GET_LAST_DDL('P_INSERT_EXCHRATE')
     WHERE action_object = 'FCS.P_INSERT_EXCHRATE';     
    -- 1 row updated
       
    UPDATE SERVICE_actions
       SET last_ddl = PK_IOTERMINAL.F_GET_LAST_DDL('F_INVESTOR_HAS_HOLDINGS')
     WHERE action_object = 'FCS.F_INVESTOR_HAS_HOLDINGS';         
    -- 1 row updated
               

               
    Select * from Service_Actions;
    -- 6 rows Selected



    SPOOL OFF
