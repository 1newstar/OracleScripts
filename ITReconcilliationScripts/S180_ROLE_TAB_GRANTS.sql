set head off feedback off

/*
NOTES: There are 8 Schemas which have issued GRANTS to Roles AND Whose Account Status is 'EXPIRED & LOCKED'
       These Account, and number of grants issued to Roles are : 
       
       REM Version 3 112  Grants
       =========================
           select distinct(owner), count('x') 
            from role_tab_privs rtp, 
                 dba_users du
            where rtp.owner = du.username
            and du.account_status = 'EXPIRED ' || CHR(38) || ' LOCKED'
            group by owner;

        OWNER,COUNT('X')
        ===============
        CTXSYS,5
        MDSYS,1
        OLAPSYS,69
        ORDSYS,2
        OUTLN,3
        WKSYS,1
        WMSYS,22
        XDB,9

        Given that these are all NON-APPLICATION Schemas, and ARE Standard DB Users, 
        , and DO exist in the new 11g Databaase, we do NOT Need to join the following 
        Query into DBA_USERS, like several of the preceding scripts. 


*/
set head off pages 50000

select 'GRANT ' || privilege || ' ON ' || OWNER || '.' || TABLE_NAME || ' TO ' || ROLE || decode(GRANTABLE,'YES',' WITH ADMIN OPTION;',';')
from role_tab_privs

spool T180_CREATE_ROLE_TAB_GRANTS.sql
/
spool off