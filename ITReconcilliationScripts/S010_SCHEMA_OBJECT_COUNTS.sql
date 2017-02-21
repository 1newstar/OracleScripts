CONNECT / as sysdba

SET lines 80 NUMWIDTH 12 PAGES 10000 LONG 2000000000 trimspool on
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';

COL version FORMAT a12
COL comp_id FORMAT a8
COL schema LIKE version
COL comp_name FORMAT a35
COL status FORMAT a12
COL owner FORMAT a25

SELECT owner, object_type, count(*) 
FROM dba_objects 
WHERE owner NOT IN ('APPQOSSYS', 'DBSNMP', 'CTXSYS', 'OLAPSYS', 'MDSYS', 'DMSYS', 'WKSYS', 'LBACSYS',
                    'ORDSYS', 'XDB', 'EXFSYS', 'OWBSYS', 'WMSYS', 'SYSMAN','SYS','SYSTEM', 'ORACLE_OCM',
                    'ORDPLUGINS','OUTLN','ORDDATA','OWBSYS_AUDIT','SCOTT','SI_INFORMTN_SCHEMA', 'HR','OE',
                    'PM','QS','SH','TOAD','QS_ADM','QS_CBADM','QS_CS','QS_ES','QS_OS','QS_WS','ODM')
   and owner not LIKE 'APEX%'
   and owner not like 'FLOWS%'
GROUP BY owner, object_type
having count(*) > 0
ORDER BY 1
 
spool S010_SCHEMA_OBJECT_COUNTS_results.lis
/
spool off
 
 
SELECT owner, object_type, COUNT(*) 
  FROM dba_objects
 WHERE object_type LIKE 'JAVA%'
 GROUP BY owner, object_type
 ORDER BY 1,2
 
 SPOOL S010_SCHEMA_OBJECT_COUNTS_JAVA_results.lis
 /
 SPOOL OFF
 
 
 