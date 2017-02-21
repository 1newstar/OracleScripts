PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on this SQL statement, using "DBA_SYS_PRIVS". 
PROMPT : 

select 'GRANT ' || dsp.PRIVILEGE || ' TO ' || dsp.GRANTEE || decode(dsp.ADMIN_OPTION,'YES',' WITH ADMIN OPTION ', '') || ';'
FROM dba_sys_privs dsp,
     dba_users du
WHERE dsp.grantee = du.username
AND   du.account_status  != 'EXPIRED ' || CHR(38) || ' LOCKED'
AND   dsp.grantee NOT IN 
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
order by dsp.grantee

set head off feedback off lines 500 pages 2000 trimspool on

spool T130_CREATE_SYSTEM_PRIVS.sql
/
spool off
