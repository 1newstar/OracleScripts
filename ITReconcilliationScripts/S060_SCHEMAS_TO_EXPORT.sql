SELECT distinct(owner) 
FROM dba_objects 
WHERE owner NOT IN 
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
			,'TOAD','SPHINXCST','JLM',
			/* EXPIRED AND LOCKED ACCOUNTS */
'YLOWE',
'VLING',
'TLONG',
'TCHANTER',
'SPARKINSON',
'SMATTHEWS',
'SDUNN',
'SDREWETT',
'SCOTTHARRIS',
'SCALLOW',
'SAPPLEBY',
'RBEVIN',
'RANJANISULUR',
'PCOLLINS',
'NEPTUNE',
'MWRIGHT',
'MKENNARD',
'MITAYLOR',
'MGEDULT',
'MATAYLOR',
'LTAYLOR',
'LHALTON',
'LGARDNERBROWN',
'KMAYGER',
'KHENNESSY',
'KATIEBILODEAU',
'JSWAISLAND',
'JSTEVENSON',
'JLEWIS',
'JKEY',
'JBRADLEY',
'IBURROWS',
'HSBCREMOTE',
'HCRAIG',
'GYOUNG',
'GTAIT',
'FROBERTS',
'ESMITH',
'DTHOMAS',
'DLAKE',
'DHOLLAND',
'DARRENWENGER',
'DANCOBLE',
'CANDREW',
'BHOWLETT',
'BENKOTHE',
'AWAITE',
'ANNANEPOMNYASCHY',
'AMEANEY1',
'AMCCALLUM',
'AJOHNSTON',
'AHEAD',
'AGULIN',
'ADAMROBINS',
'ADELIOSTEVANATO',
'BRIANC',
'DISCADMIN',
'GHIPKIN',
'GLENNCROSSLEY',
'SHEPWORTH',
'SKAPOOR',
'SSUHAN',
'JRICHARDSON1',
'SWILKS'
)
   OR owner LIKE 'APEX%'
ORDER BY 1
 
spool S060_SCHEMAS_TO_EXPORT_results.lis
/
spool off
