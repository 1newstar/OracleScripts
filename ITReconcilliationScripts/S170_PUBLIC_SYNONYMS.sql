/* Produce the required CREATE PUBLIC SYNONYM SCRIPT */

set head off feedback off lines 500 pages 2000 trimspool on

select 'CREATE OR REPLACE PUBLIC SYNONYM ' || SYNONYM_NAME || ' FOR ' || TABLE_OWNER || '.' || TABLE_NAME || ';'
from dba_synonyms
where owner = 'PUBLIC' 
and TABLE_OWNER NOT IN 
(/* Pre-Defined Administrative Accounts */
 'ANONYMOUS'  ,'APPQOSSYS' ,'CSMIG'         ,'CTXSYS'       
,'DBSNMP'     ,'DMSYS'     ,'EXFSYS'        ,'LBACSYS'      
,'MDSYS'      ,'MGMT_VIEW' ,'ODM'           ,'ODM_MTR'
,'OLAPSYS'    ,'OWBSYS'    ,'OWBSYS_AUDIT'  ,'ORACLE_OCM'  
,'ORDPLUGINS' ,'ORDSYS'    ,'OUTLN'	        ,'PERFSTAT'    
,'SI_INFORMTN_SCHEMA'      ,'SNAPADMIN'     ,'SYS'
,'SYSMAN'    ,'SYSTEM' 	   ,'TRACESVR'     ,'TSMSYS'     
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
order by table_owner

spool T170_CREATE_PUBLIC_SYNONYMS.sql
/
spool off





