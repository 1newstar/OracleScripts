-- S100_PROFILES.sql

select 'create profile ' || profile || ' limit ' || rtrim (xmlagg (xmlelement (e, RESOURCE_NAME || ' ' ||  LIMIT  || ' ')).extract ('//text()'), ',') || ';'
from dba_profiles
where profile not in ('DEFAULT')
group by PROFILE

set head off lines 500 pages 2000 feedback off 
prompt
spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql

prompt set head off feedback off lines 2000 pages 2000 define off
prompt spool T090_CREATE_OBJECTS_AFTER_IMP_NOROWS.lis

prompt
prompt -- create profiles

/
spool off

select 'alter profile "DEFAULT" limit ' || rtrim (xmlagg (xmlelement (e, RESOURCE_NAME || decode(RESOURCE_NAME,'PASSWORD_VERIFY_FUNCTION',' NULL ',' UNLIMITED ') )).extract ('//text()'), ',') || ';'
from dba_profiles
where profile = 'DEFAULT'
group by PROFILE

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

prompt 

/
spool off


-- S110_USERS_AND_ROLES

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

This is a DIFFERENCE of 1 which Im unable to trace at this time. -- MARK H
*/

 
SELECT    'create user '
       || u.username
       || ' identified by values '''
       || u.password
       || ''' default tablespace '
       || u.default_tablespace
       || ' temporary tablespace '
       || u.temporary_tablespace
       || ' profile '
       || u.profile
       || ' account unlock;'
  FROM dba_users u
 WHERE        u.account_status != 'EXPIRED ' || CHR (38) || ' LOCKED'
          AND u.username NOT IN (    /* Pre-Defined Administrative Accounts */
                                 'ANONYMOUS',
                                 'APPQOSSYS',
                                 'CSMIG',
                                 'CTXSYS',
                                 'DBSNMP',
                                 'DMSYS',
                                 'EXFSYS',
                                 'LBACSYS',
                                 'MDSYS',
                                 'MGMT_VIEW',
                                 'ODM',
                                 'ODM_MTR',
                                 'OLAPSYS',
                                 'OWBSYS',
                                 'OWBSYS_AUDIT',
                                 'ORACLE_OCM',
                                 'ORDPLUGINS',
                                 'ORDSYS',
                                 'OUTLN',
                                 'PERFSTAT',
                                 'SI_INFORMTN_SCHEMA',
                                 'SNAPADMIN',
                                 'SYS',
                                 'SYSMAN',
                                 'SYSTEM',
                                 'TRACESVR',
                                 'TSMSYS',
                                 'WKSYS',
                                 'WKUSER',
                                 'WMSYS',
                                 'XDB'/* Pre-Defined Non-Administrative Accounts */
                                 ,
                                 'APEX_PUBLIC_USER',
                                 'APEX_030200',
                                 'AURORA$JIS$UTILITY$',
                                 'AURORA$ORB$UNAUTHENTICATED',
                                 'AWR_STAGE',
                                 'DIP',
                                 'FLOWS_30000',
                                 'FLOWS_FILES',
                                 'MDDATA',
                                 'ORACLE_OCM',
                                 'ORDDATA',
                                 'PUBLIC',
                                 'SPATIAL_CSW_ADMIN_USER',
                                 'SPATIAL_WFS_ADMIN_USR',
                                 'WKPROXY',
                                 'WK_TEST',
                                 'XS$NULL'/* Default Sample Schema User Accounts */
                                 ,
                                 'SCOTT',
                                 'ADAMS',
                                 'JONES',
                                 'CLARK',
                                 'BLAKE',
                                 'DEMO',
                                 'BI',
                                 'HR',
                                 'IX',
                                 'OE',
                                 'PM',
                                 'QS',
                                 'SH',
                                 'QS_ADM',
                                 'QS_CB',
                                 'QS_CBADM',
                                 'QS_CS',
                                 'QS_ES',
                                 'QS_OS',
                                 'QS_WS'/* ROLES */
                                 ,
                                 'AQ_ADMINISTRATOR_ROLE',
                                 'CONNECT',
                                 'DBA',
                                 'DATAPUMP_EXP_FULL_DATABASE',
                                 'DATAPUMP_IMP_FULL_DATABASE',
                                 'EXP_FULL_DATABASE',
                                 'IMP_FULL_DATABASE',
                                 'JAVADEBUGPRIV',
                                 'RECOVERY_CATALOG_OWNER',
                                 'RESOURCE',
                                 'OWB$CLIENT',
                                 'OEM_MONITOR',
                                 'OEM_ADVISOR',
                                 'OLAP_DBA',
                                 'OLAP_USER',
                                 'SCHEDULER_ADMIN',
                                 'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                 ,
                                 'TOAD',
                                 'SPHINXCST',
                                 'JLM'/* SPECIFICALLY EXCLUDED FROM PREVIOUS CREATE ERRORS */
                                 ,
                                 'AQ_ADMINISTRATOR_ROLE',
                                 'AQ_USER_ROLE',
                                 'SELECT_CATALOG_ROLE',
                                 'WM_ADMIN_ROLE',
                                 'DELETE_CATALOG_ROLE',
                                 'EXECUTE_CATALOG_ROLE',
                                 'GLOBAL_AQ_USER_ROLE',
                                 'HS_ADMIN_ROLE',
                                 'AUTHENTICATEDUSER',
                                 'CONNECT',
                                 'CTXAPP',
                                 'DBA',
                                 'EJBCLIENT',
                                 'EXP_FULL_DATABASE',
                                 'GATHER_SYSTEM_STATISTICS',
                                 'IMP_FULL_DATABASE',
                                 'JAVADEBUGPRIV',
                                 'JAVAIDPRIV',
                                 'JAVASYSPRIV',
                                 'JAVAUSERPRIV',
                                 'JAVA_ADMIN',
                                 'JAVA_DEPLOY',
                                 'LOGSTDBY_ADMINISTRATOR',
                                 'OEM_MONITOR',
                                 'OLAP_DBA',
                                 'OLAP_USER',
                                 'RECOVERY_CATALOG_OWNER',
                                 'RESOURCE',
                                 'XDBADMIN',
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
                                 'SWILKS')
       OR u.username LIKE 'APEX%'
UNION
SELECT    'create user '
       || o.owner
       || ' identified by values '''
       || u2.password
       || ''' default tablespace '
       || u2.default_tablespace
       || ' temporary tablespace '
       || u2.temporary_tablespace
       || ' profile '
       || u2.profile
       || ' account unlock;'
  FROM dba_objects o JOIN dba_users u2 ON o.owner = u2.username
 WHERE    o.owner NOT IN (           /* Pre-Defined Administrative Accounts */
                          'ANONYMOUS',
                          'APPQOSSYS',
                          'CSMIG',
                          'CTXSYS',
                          'DBSNMP',
                          'DMSYS',
                          'EXFSYS',
                          'LBACSYS',
                          'MDSYS',
                          'MGMT_VIEW',
                          'ODM',
                          'ODM_MTR',
                          'OLAPSYS',
                          'OWBSYS',
                          'OWBSYS_AUDIT',
                          'ORACLE_OCM',
                          'ORDPLUGINS',
                          'ORDSYS',
                          'OUTLN',
                          'PERFSTAT',
                          'SI_INFORMTN_SCHEMA',
                          'SNAPADMIN',
                          'SYS',
                          'SYSMAN',
                          'SYSTEM',
                          'TRACESVR',
                          'TSMSYS',
                          'WKSYS',
                          'WKUSER',
                          'WMSYS',
                          'XDB'/* Pre-Defined Non-Administrative Accounts */
                          ,
                          'APEX_PUBLIC_USER',
                          'APEX_030200',
                          'AURORA$JIS$UTILITY$',
                          'AURORA$ORB$UNAUTHENTICATED',
                          'AWR_STAGE',
                          'DIP',
                          'FLOWS_30000',
                          'FLOWS_FILES',
                          'MDDATA',
                          'ORACLE_OCM',
                          'ORDDATA',
                          'PUBLIC',
                          'SPATIAL_CSW_ADMIN_USER',
                          'SPATIAL_WFS_ADMIN_USR',
                          'WKPROXY',
                          'WK_TEST',
                          'XS$NULL'/* Default Sample Schema User Accounts */
                          ,
                          'SCOTT',
                          'ADAMS',
                          'JONES',
                          'CLARK',
                          'BLAKE',
                          'DEMO',
                          'BI',
                          'HR',
                          'IX',
                          'OE',
                          'PM',
                          'QS',
                          'SH',
                          'QS_ADM',
                          'QS_CB',
                          'QS_CBADM',
                          'QS_CS',
                          'QS_ES',
                          'QS_OS',
                          'QS_WS'/* ROLES */
                          ,
                          'AQ_ADMINISTRATOR_ROLE',
                          'CONNECT',
                          'DBA',
                          'DATAPUMP_EXP_FULL_DATABASE',
                          'DATAPUMP_IMP_FULL_DATABASE',
                          'EXP_FULL_DATABASE',
                          'IMP_FULL_DATABASE',
                          'JAVADEBUGPRIV',
                          'RECOVERY_CATALOG_OWNER',
                          'RESOURCE',
                          'OWB$CLIENT',
                          'OEM_MONITOR',
                          'OEM_ADVISOR',
                          'OLAP_DBA',
                          'OLAP_USER',
                          'SCHEDULER_ADMIN',
                          'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                          ,
                          'TOAD',
                          'SPHINXCST',
                          'JLM',
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
                          'SWILKS')
       OR o.owner LIKE 'APEX%'
UNION
SELECT    'CREATE ROLE '
       || R.role
       || DECODE (R.password_required,
                  'NO', ' NOT IDENTIFIED;',
                  'YES', ' IDENTIFIED BY ' || db.name || '123;',
                  'GLOBAL', ' IDENTIFIED GLOBALLY;',
                  ' ;')
  FROM dba_roles R, v$database DB
 WHERE     1 != 2
       AND R.role NOT IN ('AQ_ADMINISTRATOR_ROLE',
                          'AQ_USER_ROLE',
                          'SELECT_CATALOG_ROLE',
                          'WM_ADMIN_ROLE',
                          'DELETE_CATALOG_ROLE',
                          'EXECUTE_CATALOG_ROLE',
                          'GLOBAL_AQ_USER_ROLE',
                          'HS_ADMIN_ROLE',
                          'AUTHENTICATEDUSER',
                          'CONNECT',
                          'CTXAPP',
                          'DBA',
                          'EJBCLIENT',
                          'EXP_FULL_DATABASE',
                          'GATHER_SYSTEM_STATISTICS',
                          'IMP_FULL_DATABASE',
                          'JAVADEBUGPRIV',
                          'JAVAIDPRIV',
                          'JAVASYSPRIV',
                          'JAVAUSERPRIV',
                          'JAVA_ADMIN',
                          'JAVA_DEPLOY',
                          'LOGSTDBY_ADMINISTRATOR',
                          'OEM_MONITOR',
                          'OLAP_DBA',
                          'OLAP_USER',
                          'RECOVERY_CATALOG_OWNER',
                          'RESOURCE',
                          'XDBADMIN')
ORDER BY 1 ASC

set head off feedback off lines 500 pages 2000 define off
 
spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append
prompt 
prompt -- create users and roles
/

SPOOL OFF

-- S120_TABLESPACE_QUOTAS.sql

PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on the two parts to this UNION statement, using "DBA_TS_QUOTAS UNION DBA_SYS_PRIVS" statement. 
PROMPT : 

SELECT    'alter user '
       || dts.username
       || ' quota '
       || dts.max_bytes
       || ' on '
       || dts.tablespace_name
       || ';'
  FROM dba_ts_quotas dts, dba_users du
 WHERE     du.account_status != 'EXPIRED ' || CHR (38) || ' LOCKED'
       AND dts.username = du.username
       AND dts.max_bytes <> -1
       AND dts.username NOT IN (     /* Pre-Defined Administrative Accounts */
                                'ANONYMOUS',
                                'APPQOSSYS',
                                'CSMIG',
                                'CTXSYS',
                                'DBSNMP',
                                'DMSYS',
                                'EXFSYS',
                                'LBACSYS',
                                'MDSYS',
                                'MGMT_VIEW',
                                'ODM',
                                'ODM_MTR',
                                'OLAPSYS',
                                'OWBSYS',
                                'OWBSYS_AUDIT',
                                'ORACLE_OCM',
                                'ORDPLUGINS',
                                'ORDSYS',
                                'OUTLN',
                                'PERFSTAT',
                                'SI_INFORMTN_SCHEMA',
                                'SNAPADMIN',
                                'SYS',
                                'SYSMAN',
                                'SYSTEM',
                                'TRACESVR',
                                'TSMSYS',
                                'WKSYS',
                                'WKUSER',
                                'WMSYS',
                                'XDB'/* Pre-Defined Non-Administrative Accounts */
                                ,
                                'APEX_PUBLIC_USER',
                                'APEX_030200',
                                'AURORA$JIS$UTILITY$',
                                'AURORA$ORB$UNAUTHENTICATED',
                                'AWR_STAGE',
                                'DIP',
                                'FLOWS_30000',
                                'FLOWS_FILES',
                                'MDDATA',
                                'ORACLE_OCM',
                                'ORDDATA',
                                'PUBLIC',
                                'SPATIAL_CSW_ADMIN_USER',
                                'SPATIAL_WFS_ADMIN_USR',
                                'WKPROXY',
                                'WK_TEST',
                                'XS$NULL'/* Default Sample Schema User Accounts */
                                ,
                                'SCOTT',
                                'ADAMS',
                                'JONES',
                                'CLARK',
                                'BLAKE',
                                'DEMO',
                                'BI',
                                'HR',
                                'IX',
                                'OE',
                                'PM',
                                'QS',
                                'SH',
                                'QS_ADM',
                                'QS_CB',
                                'QS_CBADM',
                                'QS_CS',
                                'QS_ES',
                                'QS_OS',
                                'QS_WS'/* ROLES */
                                ,
                                'AQ_ADMINISTRATOR_ROLE',
                                'CONNECT',
                                'DBA',
                                'DATAPUMP_EXP_FULL_DATABASE',
                                'DATAPUMP_IMP_FULL_DATABASE',
                                'EXP_FULL_DATABASE',
                                'IMP_FULL_DATABASE',
                                'JAVADEBUGPRIV',
                                'RECOVERY_CATALOG_OWNER',
                                'RESOURCE',
                                'OWB$CLIENT',
                                'OEM_MONITOR',
                                'OEM_ADVISOR',
                                'OLAP_DBA',
                                'OLAP_USER',
                                'SCHEDULER_ADMIN',
                                'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                ,
                                'TOAD',
                                'SPHINXCST',
                                'JLM',
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
                                'SWILKS')
UNION
SELECT 'grant unlimited tablespace to ' || dsp.grantee || ';'
  FROM dba_sys_privs dsp, dba_users du2
 WHERE     du2.account_status != 'EXPIRED ' || CHR (38) || ' LOCKED'
       AND dsp.privilege = 'UNLIMITED TABLESPACE'
       AND dsp.grantee = du2.username
       AND dsp.grantee NOT IN (      /* Pre-Defined Administrative Accounts */
                               'ANONYMOUS',
                               'APPQOSSYS',
                               'CSMIG',
                               'CTXSYS',
                               'DBSNMP',
                               'DMSYS',
                               'EXFSYS',
                               'LBACSYS',
                               'MDSYS',
                               'MGMT_VIEW',
                               'ODM',
                               'ODM_MTR',
                               'OLAPSYS',
                               'OWBSYS',
                               'OWBSYS_AUDIT',
                               'ORACLE_OCM',
                               'ORDPLUGINS',
                               'ORDSYS',
                               'OUTLN',
                               'PERFSTAT',
                               'SI_INFORMTN_SCHEMA',
                               'SNAPADMIN',
                               'SYS',
                               'SYSMAN',
                               'SYSTEM',
                               'TRACESVR',
                               'TSMSYS',
                               'WKSYS',
                               'WKUSER',
                               'WMSYS',
                               'XDB'/* Pre-Defined Non-Administrative Accounts */
                               ,
                               'APEX_PUBLIC_USER',
                               'APEX_030200',
                               'AURORA$JIS$UTILITY$',
                               'AURORA$ORB$UNAUTHENTICATED',
                               'AWR_STAGE',
                               'DIP',
                               'FLOWS_30000',
                               'FLOWS_FILES',
                               'MDDATA',
                               'ORACLE_OCM',
                               'ORDDATA',
                               'PUBLIC',
                               'SPATIAL_CSW_ADMIN_USER',
                               'SPATIAL_WFS_ADMIN_USR',
                               'WKPROXY',
                               'WK_TEST',
                               'XS$NULL'/* Default Sample Schema User Accounts */
                               ,
                               'SCOTT',
                               'ADAMS',
                               'JONES',
                               'CLARK',
                               'BLAKE',
                               'DEMO',
                               'BI',
                               'HR',
                               'IX',
                               'OE',
                               'PM',
                               'QS',
                               'SH',
                               'QS_ADM',
                               'QS_CB',
                               'QS_CBADM',
                               'QS_CS',
                               'QS_ES',
                               'QS_OS',
                               'QS_WS'/* ROLES */
                               ,
                               'AQ_ADMINISTRATOR_ROLE',
                               'CONNECT',
                               'DBA',
                               'DATAPUMP_EXP_FULL_DATABASE',
                               'DATAPUMP_IMP_FULL_DATABASE',
                               'EXP_FULL_DATABASE',
                               'IMP_FULL_DATABASE',
                               'JAVADEBUGPRIV',
                               'RECOVERY_CATALOG_OWNER',
                               'RESOURCE',
                               'OWB$CLIENT',
                               'OEM_MONITOR',
                               'OEM_ADVISOR',
                               'OLAP_DBA',
                               'OLAP_USER',
                               'SCHEDULER_ADMIN',
                               'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                               ,
                               'TOAD',
                               'SPHINXCST',
                               'JLM',
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
                               'SWILKS')
ORDER BY 1

set head off feedback off lines 500 pages 2000

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append
prompt
prompt -- grant tablespace quotas
prompt 
/ 
spool off

-- S130_SYSTEM_PRIVS.sql

PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on this SQL statement, using "DBA_SYS_PRIVS". 
PROMPT : 

  SELECT    'GRANT '
         || dsp.PRIVILEGE
         || ' TO '
         || dsp.GRANTEE
         || DECODE (dsp.ADMIN_OPTION, 'YES', ' WITH ADMIN OPTION ', '')
         || ';'
    FROM dba_sys_privs dsp, dba_users du
   WHERE     dsp.grantee = du.username
         AND du.account_status != 'EXPIRED ' || CHR (38) || ' LOCKED'
         AND dsp.grantee NOT IN (    /* Pre-Defined Administrative Accounts */
                                 'ANONYMOUS',
                                 'APPQOSSYS',
                                 'CSMIG',
                                 'CTXSYS',
                                 'DBSNMP',
                                 'DMSYS',
                                 'EXFSYS',
                                 'LBACSYS',
                                 'MDSYS',
                                 'MGMT_VIEW',
                                 'ODM',
                                 'ODM_MTR',
                                 'OLAPSYS',
                                 'OWBSYS',
                                 'OWBSYS_AUDIT',
                                 'ORACLE_OCM',
                                 'ORDPLUGINS',
                                 'ORDSYS',
                                 'OUTLN',
                                 'PERFSTAT',
                                 'SI_INFORMTN_SCHEMA',
                                 'SNAPADMIN',
                                 'SYS',
                                 'SYSMAN',
                                 'SYSTEM',
                                 'TRACESVR',
                                 'TSMSYS',
                                 'WKSYS',
                                 'WKUSER',
                                 'WMSYS',
                                 'XDB'/* Pre-Defined Non-Administrative Accounts */
                                 ,
                                 'APEX_PUBLIC_USER',
                                 'APEX_030200',
                                 'AURORA$JIS$UTILITY$',
                                 'AURORA$ORB$UNAUTHENTICATED',
                                 'AWR_STAGE',
                                 'DIP',
                                 'FLOWS_30000',
                                 'FLOWS_FILES',
                                 'MDDATA',
                                 'ORACLE_OCM',
                                 'ORDDATA',
                                 'PUBLIC',
                                 'SPATIAL_CSW_ADMIN_USER',
                                 'SPATIAL_WFS_ADMIN_USR',
                                 'WKPROXY',
                                 'WK_TEST',
                                 'XS$NULL'/* Default Sample Schema User Accounts */
                                 ,
                                 'SCOTT',
                                 'ADAMS',
                                 'JONES',
                                 'CLARK',
                                 'BLAKE',
                                 'DEMO',
                                 'BI',
                                 'HR',
                                 'IX',
                                 'OE',
                                 'PM',
                                 'QS',
                                 'SH',
                                 'QS_ADM',
                                 'QS_CB',
                                 'QS_CBADM',
                                 'QS_CS',
                                 'QS_ES',
                                 'QS_OS',
                                 'QS_WS'/* ROLES */
                                 ,
                                 'AQ_ADMINISTRATOR_ROLE',
                                 'CONNECT',
                                 'DBA',
                                 'DATAPUMP_EXP_FULL_DATABASE',
                                 'DATAPUMP_IMP_FULL_DATABASE',
                                 'EXP_FULL_DATABASE',
                                 'IMP_FULL_DATABASE',
                                 'JAVADEBUGPRIV',
                                 'RECOVERY_CATALOG_OWNER',
                                 'RESOURCE',
                                 'OWB$CLIENT',
                                 'OEM_MONITOR',
                                 'OEM_ADVISOR',
                                 'OLAP_DBA',
                                 'OLAP_USER',
                                 'SCHEDULER_ADMIN',
                                 'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                 ,
                                 'TOAD',
                                 'SPHINXCST',
                                 'JLM',
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
                                 'SWILKS')
ORDER BY dsp.grantee

set head off feedback off lines 500 pages 2000

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

PROMPT
PROMPT -- GRANT SYSTEM PRIVILEGES
PROMPT

/
spool off

-- S140_PROXIES.sql

PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on this SQL statement, using "PROXY_USERS". 
PROMPT : 

SELECT 'ALTER USER ' || CLIENT || ' GRANT CONNECT THROUGH ' || PROXY || ';'
  FROM proxy_users pu, dba_users du
 WHERE     pu.client = du.username
       AND du.account_status != 'EXPIRED ' || CHR (38) || ' LOCKED'
       AND DU.USERNAME NOT IN ('YLOWE',
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
                               'SWILKS')

set head off feedback off lines 500 pages 2000

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

PROMPT
PROMPT -- GRANT PROXIES
PROMPT

/
spool off

-- S150_ROLES_DEFAULT_ROLES_AND_ROLE_GRANTS.sql 

set head off feedback off lines 500 pages 2000 define off


PROMPT : 
PROMPT : CONNECT is a Deprecated Role in 11g and therefore has to be EXCLUDED from the GRANT and ALTER USER statements. 
PROMPT : We DO want to replace the CONNECT with CREATE SESSION privilege though, so the fist SQL statement does a DECODE on DBA_ROLE_PRIVS
prompt : to facilitate a REPLACE / SUBSTITUTE of { CONNECT with CREATE SESSION }
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
prompt PROMPT : 

    
SELECT    'GRANT '
       || DECODE (drp.GRANTED_ROLE,
                  'CONNECT', 'CREATE SESSION',
                  drp.GRANTED_ROLE)
       || ' to '
       || drp.GRANTEE
       || DECODE (drp.ADMIN_OPTION,
                  'YES', ' WITH ADMIN OPTION;',
                  'NO', ';',
                  ';')
  FROM dba_role_privs drp, dba_users du
 WHERE     du.account_status != 'EXPIRED & LOCKED'
       AND drp.grantee = du.username
       AND drp.grantee NOT IN (      /* Pre-Defined Administrative Accounts */
                               'ANONYMOUS',
                               'APPQOSSYS',
                               'CSMIG',
                               'CTXSYS',
                               'DBSNMP',
                               'DMSYS',
                               'EXFSYS',
                               'LBACSYS',
                               'MDSYS',
                               'MGMT_VIEW',
                               'ODM',
                               'ODM_MTR',
                               'OLAPSYS',
                               'OWBSYS',
                               'OWBSYS_AUDIT',
                               'ORACLE_OCM',
                               'ORDPLUGINS',
                               'ORDSYS',
                               'OUTLN',
                               'PERFSTAT',
                               'SI_INFORMTN_SCHEMA',
                               'SNAPADMIN',
                               'SYS',
                               'SYSMAN',
                               'SYSTEM',
                               'TRACESVR',
                               'TSMSYS',
                               'NORMA_AURA',
                               'WKSYS',
                               'WKUSER',
                               'WMSYS',
                               'XDB'/* Pre-Defined Non-Administrative Accounts */
                               ,
                               'APEX_PUBLIC_USER',
                               'APEX_030200',
                               'AURORA$JIS$UTILITY$',
                               'AURORA$ORB$UNAUTHENTICATED',
                               'AWR_STAGE',
                               'DIP',
                               'FLOWS_30000',
                               'FLOWS_FILES',
                               'MDDATA',
                               'ORACLE_OCM',
                               'ORDDATA',
                               'PUBLIC',
                               'SPATIAL_CSW_ADMIN_USER',
                               'SPATIAL_WFS_ADMIN_USR',
                               'WKPROXY',
                               'WK_TEST',
                               'XS$NULL'/* Default Sample Schema User Accounts */
                               ,
                               'SCOTT',
                               'ADAMS',
                               'JONES',
                               'CLARK',
                               'BLAKE',
                               'DEMO',
                               'BI',
                               'HR',
                               'IX',
                               'OE',
                               'PM',
                               'QS',
                               'SH',
                               'QS_ADM',
                               'QS_CB',
                               'QS_CBADM',
                               'QS_CS',
                               'QS_ES',
                               'QS_OS',
                               'QS_WS'/* ROLES */
                               ,
                               'AQ_ADMINISTRATOR_ROLE',
                               'CONNECT',
                               'DBA',
                               'DATAPUMP_EXP_FULL_DATABASE',
                               'DATAPUMP_IMP_FULL_DATABASE',
                               'EXP_FULL_DATABASE',
                               'IMP_FULL_DATABASE',
                               'JAVADEBUGPRIV',
                               'RECOVERY_CATALOG_OWNER',
                               'RESOURCE',
                               'OWB$CLIENT',
                               'OEM_MONITOR',
                               'OEM_ADVISOR',
                               'OLAP_DBA',
                               'OLAP_USER',
                               'SCHEDULER_ADMIN',
                               'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                               ,
                               'TOAD',
                               'SPHINXCST',
                               'JLM',
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
                               'SWILKS')
UNION
  SELECT    'ALTER USER '
         || dorp.GRANTEE
         || ' DEFAULT ROLE '
         || RTRIM (
               XMLAGG (XMLELEMENT (e, dorp.GRANTED_ROLE || ',')).EXTRACT (
                  '//text()'),
               ',')
         || ';'
    FROM (SELECT admin_option,
                 default_role,
                 grantee,
                 granted_role
            FROM sys.dba_role_privs rp, dba_users u
           WHERE     rp.grantee = u.username
                 AND rp.granted_role != 'CONNECT'
                 AND u.account_status != 'EXPIRED & LOCKED') dorp
   WHERE     dorp.default_role = 'YES'
         AND dorp.grantee NOT IN (   /* Pre-Defined Administrative Accounts */
                                  'ANONYMOUS',
                                  'APPQOSSYS',
                                  'CSMIG',
                                  'CTXSYS',
                                  'DBSNMP',
                                  'DMSYS',
                                  'EXFSYS',
                                  'LBACSYS',
                                  'MDSYS',
                                  'MGMT_VIEW',
                                  'ODM',
                                  'ODM_MTR',
                                  'OLAPSYS',
                                  'OWBSYS',
                                  'OWBSYS_AUDIT',
                                  'ORACLE_OCM',
                                  'ORDPLUGINS',
                                  'ORDSYS',
                                  'OUTLN',
                                  'PERFSTAT',
                                  'SI_INFORMTN_SCHEMA',
                                  'SNAPADMIN',
                                  'SYS',
                                  'SYSMAN',
                                  'SYSTEM',
                                  'TRACESVR',
                                  'TSMSYS',
                                  'NORMA_AURA',
                                  'WKSYS',
                                  'WKUSER',
                                  'WMSYS',
                                  'XDB'/* Pre-Defined Non-Administrative Accounts */
                                  ,
                                  'APEX_PUBLIC_USER',
                                  'APEX_030200',
                                  'AURORA$JIS$UTILITY$',
                                  'AURORA$ORB$UNAUTHENTICATED',
                                  'AWR_STAGE',
                                  'DIP',
                                  'FLOWS_30000',
                                  'FLOWS_FILES',
                                  'MDDATA',
                                  'ORACLE_OCM',
                                  'ORDDATA',
                                  'PUBLIC',
                                  'SPATIAL_CSW_ADMIN_USER',
                                  'SPATIAL_WFS_ADMIN_USR',
                                  'WKPROXY',
                                  'WK_TEST',
                                  'XS$NULL'/* Default Sample Schema User Accounts */
                                  ,
                                  'SCOTT',
                                  'ADAMS',
                                  'JONES',
                                  'CLARK',
                                  'BLAKE',
                                  'DEMO',
                                  'BI',
                                  'HR',
                                  'IX',
                                  'OE',
                                  'PM',
                                  'QS',
                                  'SH',
                                  'QS_ADM',
                                  'QS_CB',
                                  'QS_CBADM',
                                  'QS_CS',
                                  'QS_ES',
                                  'QS_OS',
                                  'QS_WS'/* ROLES */
                                  ,
                                  'AQ_ADMINISTRATOR_ROLE',
                                  'CONNECT',
                                  'DBA',
                                  'DATAPUMP_EXP_FULL_DATABASE',
                                  'DATAPUMP_IMP_FULL_DATABASE',
                                  'EXP_FULL_DATABASE',
                                  'IMP_FULL_DATABASE',
                                  'JAVADEBUGPRIV',
                                  'RECOVERY_CATALOG_OWNER',
                                  'RESOURCE',
                                  'OWB$CLIENT',
                                  'OEM_MONITOR',
                                  'OEM_ADVISOR',
                                  'OLAP_DBA',
                                  'OLAP_USER',
                                  'SCHEDULER_ADMIN',
                                  'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                  ,
                                  'TOAD',
                                  'SPHINXCST',
                                  'JLM',
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
                                  'SWILKS')
GROUP BY dorp.GRANTEE
ORDER BY 1 DESC

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

prompt -- grant privileges

/


select 'GRANT ' || granted_role || ' TO ' || ROLE || decode(ADMIN_OPTION,'YES',' WITH ADMIN OPTION;',';') 
from role_role_privs

/

select 'GRANT ' || privilege || ' TO ' || ROLE || decode(ADMIN_OPTION,'YES',' WITH ADMIN OPTION;',';')
from role_sys_privs

/

-- S155_DIRECTORIES_AND_LIBRARIES.sql

set head off 
 
select 'CREATE OR REPLACE DIRECTORY ' || DIRECTORY_NAME || ' AS ' || CHR(39) || DIRECTORY_PATH || CHR(39)  ||';'|| chr(10)||'/'   
from dba_directories;

set head off feedback off lines 500 pages 2000



prompt
prompt -- create directories
prompt

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

/
SPOOL OFF

/* EDIT T155a_CREATE_DIRS.SQL and replace UNIX Paths with WINDOWS PATHS */

  SELECT    'GRANT '
         || RTRIM (
               XMLAGG (XMLELEMENT (e, dtp.PRIVILEGE || ',')).EXTRACT (
                  '//text()'),
               ',')
         || ' ON DIRECTORY '
         || dtp.TABLE_NAME
         || ' TO '
         || dtp.GRANTEE
         || ';'
    FROM dba_tab_privs dtp
   WHERE table_name IN
            (SELECT DISTINCT (directory_name)
               FROM dba_directories
              WHERE dtp.GRANTEE NOT IN ( /* Pre-Defined Administrative Accounts */
                                        'ANONYMOUS',
                                        'APPQOSSYS',
                                        'CSMIG',
                                        'CTXSYS',
                                        'DBSNMP',
                                        'DMSYS',
                                        'EXFSYS',
                                        'LBACSYS',
                                        'MDSYS',
                                        'MGMT_VIEW',
                                        'ODM',
                                        'ODM_MTR',
                                        'OLAPSYS',
                                        'OWBSYS',
                                        'OWBSYS_AUDIT',
                                        'ORACLE_OCM',
                                        'ORDPLUGINS',
                                        'ORDSYS',
                                        'OUTLN',
                                        'PERFSTAT',
                                        'SI_INFORMTN_SCHEMA',
                                        'SNAPADMIN',
                                        'SYS',
                                        'SYSMAN',
                                        'SYSTEM',
                                        'TRACESVR',
                                        'TSMSYS',
                                        'WKSYS',
                                        'WKUSER',
                                        'WMSYS',
                                        'XDB'/* Pre-Defined Non-Administrative Accounts */
                                        ,
                                        'APEX_PUBLIC_USER',
                                        'APEX_030200',
                                        'AURORA$JIS$UTILITY$',
                                        'AURORA$ORB$UNAUTHENTICATED',
                                        'AWR_STAGE',
                                        'DIP',
                                        'FLOWS_30000',
                                        'FLOWS_FILES',
                                        'MDDATA',
                                        'ORACLE_OCM',
                                        'ORDDATA',
                                        'PUBLIC',
                                        'SPATIAL_CSW_ADMIN_USER',
                                        'SPATIAL_WFS_ADMIN_USR',
                                        'WKPROXY',
                                        'WK_TEST',
                                        'XS$NULL'/* Default Sample Schema User Accounts */
                                        ,
                                        'SCOTT',
                                        'ADAMS',
                                        'JONES',
                                        'CLARK',
                                        'BLAKE',
                                        'DEMO',
                                        'BI',
                                        'HR',
                                        'IX',
                                        'OE',
                                        'PM',
                                        'QS',
                                        'SH',
                                        'QS_ADM',
                                        'QS_CB',
                                        'QS_CBADM',
                                        'QS_CS',
                                        'QS_ES',
                                        'QS_OS',
                                        'QS_WS'/* ROLES */
                                        ,
                                        'AQ_ADMINISTRATOR_ROLE',
                                        'CONNECT',
                                        'DBA',
                                        'DATAPUMP_EXP_FULL_DATABASE',
                                        'DATAPUMP_IMP_FULL_DATABASE',
                                        'EXP_FULL_DATABASE',
                                        'IMP_FULL_DATABASE',
                                        'JAVADEBUGPRIV',
                                        'RECOVERY_CATALOG_OWNER',
                                        'RESOURCE',
                                        'OWB$CLIENT',
                                        'OEM_MONITOR',
                                        'OEM_ADVISOR',
                                        'OLAP_DBA',
                                        'OLAP_USER',
                                        'SCHEDULER_ADMIN',
                                        'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                        ,
                                        'TOAD',
                                        'SPHINXCST',
                                        'JLM',
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
                                        'SWILKS'))
GROUP BY dtp.TABLE_NAME, dtp.GRANTEE

set head off feedback off lines 500 pages 2000



prompt
prompt -- create libraries
prompt

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append

/
spool off

set head off 
 
select 'CREATE OR REPLACE LIBRARY ' || OWNER || '.' || LIBRARY_NAME || ' AS ' || CHR(39) || FILE_SPEC || CHR(39)  || ';' ||chr(10)||'/'
from dba_libraries
where owner = 'FCS'

set head off feedback off lines 500 pages 2000

prompt
prompt -- create libraries
prompt

spool T085_CREATE_OBJECTS_BEFORE_IMP_NOROWS.sql append
/
SPOOL OFF

/* EDIT T155c_CREATE_LIBS.SQL and replace UNIX Paths with WINDOWS PATHS */

-- S170_PUBLIC_SYNONYMS.sql

/* Produce the required CREATE PUBLIC SYNONYM SCRIPT */

set head off feedback off lines 500 pages 2000 

  SELECT    'CREATE OR REPLACE PUBLIC SYNONYM '
         || SYNONYM_NAME
         || ' FOR '
         || TABLE_OWNER
         || '.'
         || TABLE_NAME
         || ';'
    FROM dba_synonyms
   WHERE     owner = 'PUBLIC'
         AND TABLE_OWNER NOT IN (    /* Pre-Defined Administrative Accounts */
                                 'ANONYMOUS',
                                 'APPQOSSYS',
                                 'CSMIG',
                                 'CTXSYS',
                                 'DBSNMP',
                                 'DMSYS',
                                 'EXFSYS',
                                 'LBACSYS',
                                 'MDSYS',
                                 'MGMT_VIEW',
                                 'ODM',
                                 'ODM_MTR',
                                 'OLAPSYS',
                                 'OWBSYS',
                                 'OWBSYS_AUDIT',
                                 'ORACLE_OCM',
                                 'ORDPLUGINS',
                                 'ORDSYS',
                                 'OUTLN',
                                 'PERFSTAT',
                                 'SI_INFORMTN_SCHEMA',
                                 'SNAPADMIN',
                                 'SYS',
                                 'SYSMAN',
                                 'SYSTEM',
                                 'TRACESVR',
                                 'TSMSYS',
                                 'WKSYS',
                                 'WKUSER',
                                 'WMSYS',
                                 'XDB'/* Pre-Defined Non-Administrative Accounts */
                                 ,
                                 'APEX_PUBLIC_USER',
                                 'APEX_030200',
                                 'AURORA$JIS$UTILITY$',
                                 'AURORA$ORB$UNAUTHENTICATED',
                                 'AWR_STAGE',
                                 'DIP',
                                 'FLOWS_30000',
                                 'FLOWS_FILES',
                                 'MDDATA',
                                 'ORACLE_OCM',
                                 'ORDDATA',
                                 'PUBLIC',
                                 'SPATIAL_CSW_ADMIN_USER',
                                 'SPATIAL_WFS_ADMIN_USR',
                                 'WKPROXY',
                                 'WK_TEST',
                                 'XS$NULL'/* Default Sample Schema User Accounts */
                                 ,
                                 'SCOTT',
                                 'ADAMS',
                                 'JONES',
                                 'CLARK',
                                 'BLAKE',
                                 'DEMO',
                                 'BI',
                                 'HR',
                                 'IX',
                                 'OE',
                                 'PM',
                                 'QS',
                                 'SH',
                                 'QS_ADM',
                                 'QS_CB',
                                 'QS_CBADM',
                                 'QS_CS',
                                 'QS_ES',
                                 'QS_OS',
                                 'QS_WS'/* ROLES */
                                 ,
                                 'AQ_ADMINISTRATOR_ROLE',
                                 'CONNECT',
                                 'DBA',
                                 'DATAPUMP_EXP_FULL_DATABASE',
                                 'DATAPUMP_IMP_FULL_DATABASE',
                                 'EXP_FULL_DATABASE',
                                 'IMP_FULL_DATABASE',
                                 'JAVADEBUGPRIV',
                                 'RECOVERY_CATALOG_OWNER',
                                 'RESOURCE',
                                 'OWB$CLIENT',
                                 'OEM_MONITOR',
                                 'OEM_ADVISOR',
                                 'OLAP_DBA',
                                 'OLAP_USER',
                                 'SCHEDULER_ADMIN',
                                 'WKUSER'/* THIRD PARTY PRODUCT ACCOUNTS */
                                 ,
                                 'TOAD',
                                 'SPHINXCST',
                                 'JLM',
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
                                 'SWILKS')
ORDER BY table_owner


prompt
prompt -- create public synonyms
prompt

spool T090_CREATE_OBJECTS_AFTER_IMP_NOROWS.sql
/
spool off

-- S180_ROLE_TAB_GRANTS.sql

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

prompt
prompt alter user fcs identified by devenv;
prompt

prompt
prompt -- grants object privileges
prompt

spool T090_CREATE_OBJECTS_AFTER_IMP_NOROWS.sql append

/


spool off

prompt -- end of deployment script
prompt spool off

spool off


