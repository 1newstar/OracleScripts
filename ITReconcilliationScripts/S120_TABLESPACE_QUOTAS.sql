SET DEFINE OFF

PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on the two parts to this UNION statement, using "DBA_TS_QUOTAS UNION DBA_SYS_PRIVS" statement. 
PROMPT : 

select 'alter user ' || dts.username || ' quota ' || dts.max_bytes ||  ' on ' || dts.tablespace_name || ';'
from dba_ts_quotas dts, 
     dba_users     du 
where du.account_status != 'EXPIRED ' || CHR(38) || ' LOCKED'
and   dts.username = du.username
and   dts.max_bytes <> -1 
and   dts.username not in 
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
union
SELECT 'grant unlimited tablespace to ' || dsp.grantee || ';' 
FROM dba_sys_privs dsp,
     dba_users     du2 
WHERE du2.account_status != 'EXPIRED ' || CHR(38) || ' LOCKED'
and   dsp.privilege = 'UNLIMITED TABLESPACE'
and   dsp.grantee = du2.username
and   dsp.grantee not in
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
order by 1

set head off feedback off lines 500 pages 2000

spool T120_CREATE_TABLESPACE_QUOTAS.sql
/ 
spool off
