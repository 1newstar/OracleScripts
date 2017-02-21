CONNECT / as sysdba

SET lines 80 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL file_name FORMAT a100

SELECT * FROM v$pwfile_users

spool S050_SYSDBA_USERS_results.lis
/
spool off