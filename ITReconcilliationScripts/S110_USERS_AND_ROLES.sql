/*
The UNION performs a DISTINCT by default

851 USERS (SCHEMA OWNERS and USERS NOT EXPIRED and LOCKED)
 79 ROLES
930 TOTAL

 72 Schema Owners
796 Users NOT EXPIRED & LOCKED
---
868 Total INCLUDING DUPLICATES
===
851 CREATE USER STATEMENTS are created by the new revised SQL using a UNION between DBA_USERS and DBA_OBJECTS

There are 16 users which are SCHEMAS and are NOT EXPIRED and LOCKED - and therefore are DUPLICATES and are removed by the UNION

868
 16 -
--- 
852
===

This is a DIFFERENCE of 1 which Im unable to trace at this time. 
*/
 
 select 'create user ' || u.username || ' identified by values '''|| u.password ||
        ''' default tablespace '|| u.default_tablespace ||
        ' temporary tablespace '|| u.temporary_tablespace ||
        ' profile '|| u.profile ||
        ' account unlock;'
 from dba_users u
 where u.account_status != 'EXPIRED ' || CHR(38) || ' LOCKED'
 and   u.username not in 
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
,'TOAD','SPHINXCST','JLM'
/* SPECIFICALLY EXCLUDED FROM PREVIOUS CREATE ERRORS */
,'AQ_ADMINISTRATOR_ROLE'      ,'AQ_USER_ROLE'   ,'SELECT_CATALOG_ROLE'    
,'WM_ADMIN_ROLE'              ,'DELETE_CATALOG_ROLE'     
,'EXECUTE_CATALOG_ROLE'       ,'GLOBAL_AQ_USER_ROLE'    
,'HS_ADMIN_ROLE'              ,'AUTHENTICATEDUSER'       
,'CONNECT'                    ,'CTXAPP'        
,'DBA'                        ,'EJBCLIENT'               
,'EXP_FULL_DATABASE'          ,'GATHER_SYSTEM_STATISTICS'
,'IMP_FULL_DATABASE'          ,'JAVADEBUGPRIV'           
,'JAVAIDPRIV'                 ,'JAVASYSPRIV'             
,'JAVAUSERPRIV'               ,'JAVA_ADMIN'            
,'JAVA_DEPLOY'                ,'LOGSTDBY_ADMINISTRATOR'  
,'OEM_MONITOR'                ,'OLAP_DBA'                
,'OLAP_USER'                  ,'RECOVERY_CATALOG_OWNER'  
,'RESOURCE'                   ,'XDBADMIN')
 OR u.username LIKE 'APEX%'
 UNION
 select 'create user ' || o.owner || ' identified by values '''|| u2.password ||
        ''' default tablespace '|| u2.default_tablespace ||
        ' temporary tablespace '|| u2.temporary_tablespace ||
        ' profile '|| u2.profile ||
        ' account unlock;' 
 from dba_objects o 
 join dba_users u2
   on  o.owner = u2.username
 where o.owner not in 
            (/* Pre-Defined Administrative Accounts */
             'ANONYMOUS'  ,'APPQOSSYS' ,'CSMIG'         ,'CTXSYS'       
            ,'DBSNMP'     ,'DMSYS'     ,'EXFSYS'        ,'LBACSYS'            ,'MDSYS'      ,'MGMT_VIEW' ,'ODM'           ,'ODM_MTR'
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
   OR o.owner LIKE 'APEX%'
   UNION
select 'CREATE ROLE ' || R.role || 
        DECODE(R.password_required,'NO',    ' NOT IDENTIFIED;',
                                  'YES',   ' IDENTIFIED BY ' || db.name || '123;',
                                  'GLOBAL',' IDENTIFIED GLOBALLY;',
                                  ' ;')
from dba_roles R, 
     v$database DB
where 1 != 2
and R.role not in 
('AQ_ADMINISTRATOR_ROLE'      ,'AQ_USER_ROLE'   ,'SELECT_CATALOG_ROLE'    
,'WM_ADMIN_ROLE'              ,'DELETE_CATALOG_ROLE'     
,'EXECUTE_CATALOG_ROLE'       ,'GLOBAL_AQ_USER_ROLE'    
,'HS_ADMIN_ROLE'              ,'AUTHENTICATEDUSER'       
,'CONNECT'                    ,'CTXAPP'        
,'DBA'                        ,'EJBCLIENT'               
,'EXP_FULL_DATABASE'          ,'GATHER_SYSTEM_STATISTICS'
,'IMP_FULL_DATABASE'          ,'JAVADEBUGPRIV'           
,'JAVAIDPRIV'                 ,'JAVASYSPRIV'             
,'JAVAUSERPRIV'               ,'JAVA_ADMIN'            
,'JAVA_DEPLOY'                ,'LOGSTDBY_ADMINISTRATOR'  
,'OEM_MONITOR'                ,'OLAP_DBA'                
,'OLAP_USER'                  ,'RECOVERY_CATALOG_OWNER'  
,'RESOURCE'                   ,'XDBADMIN')
   ORDER BY 1 ASC

set head off feedback off lines 500 pages 2000  trimspool on
 
spool T110_CREATE_USERS_AND_ROLES.sql
/
spool off


                

