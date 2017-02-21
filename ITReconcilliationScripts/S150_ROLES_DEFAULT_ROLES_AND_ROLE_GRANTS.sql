SET DEFINE OFF
set head off

PROMPT : 
PROMPT : CONNECT is a Deprecated Role in 11g and therefore has to be EXCLUDED from the GRANT and ALTER USER statements. 
PROMPT : We DO want to replace the CONNECT with CREATE SESSION privilege though, so the fist SQL statement does a DECODE on DBA_ROLE_PRIVS
PROMPT : to facilitate a REPLACE / SUBSTITUTE of { CONNECT with CREATE SESSION }
PROMPT : 
PROMPT : and the second SQL fetches from a VIEW of DBA_ROLE_PRIVS (called DEVOPS_ROLE_PRIVS) which has been created WITHOUT the CONNECT rows. 
PROMPT : 
PROMPT : Tests to create a VIEW of DBA_ROLE_PRIVS failed, so created a temporary table instead. This worked. 
PROMPT : (Drop the [temporary] table at the end) 
PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on the two parts to this UNION statement, using "DBA_ROLE_PRIVS UNION DEVOPS_ROLE_PRIVS" statement. 
PROMPT :        Hence - the join into DBA_USERS. thioin s bilt in to the vops-privs table too. 
PROMPT :        [ 4 minuts to execute. ] 
PROMPT : 
    
PROMPT : 
PROMPT : THE FOLLOWING QUERY CAN TAKE upto 4m:15s to execute
PROMPT : 
    
select 'GRANT ' ||decode(drp.GRANTED_ROLE,'CONNECT','CREATE SESSION',drp.GRANTED_ROLE) || ' to ' || drp.GRANTEE || decode(drp.ADMIN_OPTION,'YES',' WITH ADMIN OPTION;','NO',';',';')
from dba_role_privs drp, 
     dba_users du
where du.account_status != 'EXPIRED & LOCKED'
AND   drp.grantee = du.username  
AND   drp.grantee not in 
(/* Pre-Defined Administrative Accounts */
 'ANONYMOUS'  ,'APPQOSSYS' ,'CSMIG'         ,'CTXSYS'       
,'DBSNMP'     ,'DMSYS'     ,'EXFSYS'        ,'LBACSYS'      
,'MDSYS'      ,'MGMT_VIEW' ,'ODM'           ,'ODM_MTR'
,'OLAPSYS'    ,'OWBSYS'    ,'OWBSYS_AUDIT'  ,'ORACLE_OCM'  
,'ORDPLUGINS' ,'ORDSYS'    ,'OUTLN'            ,'PERFSTAT'    
,'SI_INFORMTN_SCHEMA'      ,'SNAPADMIN'     ,'SYS'
,'SYSMAN'    ,'SYSTEM'        ,'TRACESVR'     ,'TSMSYS'     
,'WKSYS'     ,'WKUSER'     ,'WMSYS'         ,'XDB'
/* Pre-Defined Non-Administrative Accounts */
,'APEX_PUBLIC_USER'       ,'APEX_030200' ,'AURORA$JIS$UTILITY$'   
,'AURORA$ORB$UNAUTHENTICATED'            ,'AWR_STAGE'   
,'DIP'      ,'FLOWS_30000'               ,'FLOWS_FILES' 
,'MDDATA'   ,'ORACLE_OCM' ,'ORDDATA'     ,'PUBLIC'   
,'SPATIAL_CSW_ADMIN_USER' ,'SPATIAL_WFS_ADMIN_USR' 
,'WKPROXY' ,'WK_TEST'     ,'XS$NULL'
/* Default Sample Schema User Accounts */
,'SCOTT'  ,'ADAMS' ,'JONES'    ,'CLARK' ,'BLAKE' ,'DEMO'
,'BI'     ,'HR'    ,'IX'       ,'OE'    ,'PM'    ,'QS'    ,'SH' 
,'QS_ADM' ,'QS_CB' ,'QS_CBADM' ,'QS_CS' ,'QS_ES' ,'QS_OS' ,'QS_WS' 
/* ROLES */
,'AQ_ADMINISTRATOR_ROLE'      ,'CONNECT'        ,'DBA'
,'DATAPUMP_EXP_FULL_DATABASE' ,'DATAPUMP_IMP_FULL_DATABASE'
,'EXP_FULL_DATABASE'          ,'IMP_FULL_DATABASE'
,'JAVADEBUGPRIV'              ,'RECOVERY_CATALOG_OWNER'     
,'RESOURCE'                   ,'OWB$CLIENT'
,'OEM_MONITOR'                ,'OEM_ADVISOR'    ,'OLAP_DBA'
,'OLAP_USER',                 'SCHEDULER_ADMIN' , 'WKUSER'
/* THIRD PARTY PRODUCT ACCOUNTS */
,'TOAD','SPHINXCST','JLM')
UNION
select 'ALTER USER ' || dorp.GRANTEE || ' DEFAULT ROLE ' || rtrim (xmlagg (xmlelement (e, dorp.GRANTED_ROLE || ',')).extract ('//text()'), ',') || ';'
from  (    select admin_option, default_role, grantee, granted_role 
    from sys.dba_role_privs rp, 
         dba_users u
    where rp.grantee = u.username
    and   rp.granted_role != 'CONNECT'
    and   u.account_status != 'EXPIRED & LOCKED') dorp
WHERE dorp.default_role = 'YES'
AND   dorp.grantee not in 
(/* Pre-Defined Administrative Accounts */
 'ANONYMOUS'  ,'APPQOSSYS' ,'CSMIG'         ,'CTXSYS'       
,'DBSNMP'     ,'DMSYS'     ,'EXFSYS'        ,'LBACSYS'      
,'MDSYS'      ,'MGMT_VIEW' ,'ODM'           ,'ODM_MTR'
,'OLAPSYS'    ,'OWBSYS'    ,'OWBSYS_AUDIT'  ,'ORACLE_OCM'  
,'ORDPLUGINS' ,'ORDSYS'    ,'OUTLN'            ,'PERFSTAT'    
,'SI_INFORMTN_SCHEMA'      ,'SNAPADMIN'     ,'SYS'
,'SYSMAN'    ,'SYSTEM'        ,'TRACESVR'     ,'TSMSYS'     
,'WKSYS'     ,'WKUSER'     ,'WMSYS'         ,'XDB'
/* Pre-Defined Non-Administrative Accounts */
,'APEX_PUBLIC_USER'       ,'APEX_030200' ,'AURORA$JIS$UTILITY$'   
,'AURORA$ORB$UNAUTHENTICATED'            ,'AWR_STAGE'   
,'DIP'      ,'FLOWS_30000'               ,'FLOWS_FILES' 
,'MDDATA'   ,'ORACLE_OCM' ,'ORDDATA'     ,'PUBLIC'   
,'SPATIAL_CSW_ADMIN_USER' ,'SPATIAL_WFS_ADMIN_USR' 
,'WKPROXY' ,'WK_TEST'     ,'XS$NULL'
/* Default Sample Schema User Accounts */
,'SCOTT'  ,'ADAMS' ,'JONES'    ,'CLARK' ,'BLAKE' ,'DEMO'
,'BI'     ,'HR'    ,'IX'       ,'OE'    ,'PM'    ,'QS'    ,'SH' 
,'QS_ADM' ,'QS_CB' ,'QS_CBADM' ,'QS_CS' ,'QS_ES' ,'QS_OS' ,'QS_WS' 
/* ROLES */
,'AQ_ADMINISTRATOR_ROLE'      ,'CONNECT'        ,'DBA'
,'DATAPUMP_EXP_FULL_DATABASE' ,'DATAPUMP_IMP_FULL_DATABASE'
,'EXP_FULL_DATABASE'          ,'IMP_FULL_DATABASE'
,'JAVADEBUGPRIV'              ,'RECOVERY_CATALOG_OWNER'     
,'RESOURCE'                   ,'OWB$CLIENT'
,'OEM_MONITOR'                ,'OEM_ADVISOR'    ,'OLAP_DBA'
,'OLAP_USER',                 'SCHEDULER_ADMIN' , 'WKUSER'
/* THIRD PARTY PRODUCT ACCOUNTS */
,'TOAD','SPHINXCST','JLM')
group by dorp.GRANTEE
union all
select distinct 'grant create session to '|| grantee || ';'
from (
    select grantee,granted_role as role_or_priv
    from dba_role_privs, dba_roles
    where granted_role = 'CONNECT'
    and grantee=role
    union all
    select grantee,privilege
    from dba_sys_privs, dba_roles
    where privilege = 'CREATE SESSION'
    and grantee=role
)
where grantee not in (
    'CONNECT','DBA','OEM_MONITOR','OLAP_USER',
    'RECOVERY_CATALOG_OWNER','SCHED_MANAGER_ROLE',
    'SQLLOAD_ROLE','WKUSER','DISCUSER','DISCUSER_REMOTE',
    'LOGSTDBY_ADMINISTRATOR'
    )
order by 1 desc

set head off feedback off lines 2000 pages 2000  trimspool on
 
spool T150a_CREATE_ROLES.sql
/
spool off

select 'GRANT ' || granted_role || ' TO ' || ROLE || decode(ADMIN_OPTION,'YES',' WITH ADMIN OPTION;',';') 
from role_role_privs

spool T150b_CREATE_ROLES.sql
/
spool off

select 'GRANT ' || privilege || ' TO ' || ROLE || decode(ADMIN_OPTION,'YES',' WITH ADMIN OPTION;',';')
from role_sys_privs

spool T150c_CREATE_ROLES.sql
/
spool off





