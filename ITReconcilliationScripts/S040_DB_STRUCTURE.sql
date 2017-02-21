CONNECT / as sysdba

SET lines 170 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL file_name FORMAT a100

SPOOL S040_DB_STRUCTURE_results.lis

SELECT tablespace_name, bytes, status, file_name 
  FROM dba_data_files 
 ORDER BY tablespace_name, file_name;

SET lines 100
COL ddl FORMAT a100

SELECT to_char(dbms_metadata.get_ddl('TABLESPACE',tablespace_name)) "DDL" 
FROM dba_Tablespaces
where tablespace_name <> 'EXAMPLE';

SPOOL off