set head off 
 
select 'CREATE OR REPLACE DIRECTORY ' || DIRECTORY_NAME || ' AS ' || CHR(39) || DIRECTORY_PATH || CHR(39)  || ';'   
from dba_directories

set head off feedback off lines 500 pages 2000 trimspool on

spool T155a_CREATE_DIRS.sql
/
SPOOL OFF

/* EDIT T155a_CREATE_DIRS.SQL and replace UNIX Paths with WINDOWS PATHS */

select 'GRANT '  || rtrim (xmlagg (xmlelement (e, dtp.PRIVILEGE    || ',')).extract ('//text()'), ',') || ' ON DIRECTORY ' || dtp.TABLE_NAME || ' TO ' || dtp.GRANTEE || ';'  
from dba_tab_privs dtp
WHERE table_name in
    (select distinct(directory_name) 
     from dba_directories
	 where dtp.GRANTEE not in 
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
		,'TOAD','SPHINXCST','JLM'))	 
group by dtp.TABLE_NAME, dtp.GRANTEE 

set head off feedback off lines 500 pages 2000

spool T155b_GRANT_DIRS.sql
/
spool off

set head off 
 
select 'CREATE OR REPLACE LIBRARY ' || OWNER || '.' || LIBRARY_NAME || ' AS ' || CHR(39) || FILE_SPEC || CHR(39)  || ';'   
from dba_libraries
where owner = 'FCS'

set head off feedback off lines 500 pages 2000

spool T155c_CREATE_LIBS.sql
/
SPOOL OFF

/* EDIT T155c_CREATE_LIBS.SQL and replace UNIX Paths with WINDOWS PATHS */

