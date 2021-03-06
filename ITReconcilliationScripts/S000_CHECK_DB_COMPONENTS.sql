SET lines 90 NUMWIDTH 12 PAGES 10000 LONG 2000000000

ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL version FORMAT a12
COL comp_id FORMAT a8
COL schema LIKE version
COL comp_name FORMAT a35
COL status FORMAT a12

SELECT comp_id,schema,status,version,comp_name 
  FROM dba_registry 
 ORDER BY 1

spool S000_CHECK_DB_COMPONENTS_results.lis
/
spool off
