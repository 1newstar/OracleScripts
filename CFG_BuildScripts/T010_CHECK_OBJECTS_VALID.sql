SET lines 100 NUMWIDTH 12 PAGES 10000 LONG 2000000000 trimspool on

ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';

COL status FORMAT a9
COL object_type FORMAT a20;
COL owner.object FORMAT a50

SELECT status, object_id, object_type, owner||'.'||object_name "OWNER.OBJECT"
  FROM dba_objects
 WHERE status != 'VALID' AND object_name NOT LIKE 'BIN$%' 
 ORDER BY 4,2
 
 SPOOL T010_CHECK_OBJECTS_VALID_results.lis
 
 /
 
 SPOOL OFF
 
