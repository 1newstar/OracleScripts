SET lines 90 NUMWIDTH 12 PAGES 10000 LONG 2000000000

ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL version FORMAT a12
COL comp_id FORMAT a8
COL schema LIKE version
COL comp_name FORMAT a35
COL status FORMAT a12

PROMPT -- S000_CHECK_DB_COMPONENTS
PROMPT -- DBA_REGISTERY CHECK

SELECT comp_id,schema,status,version,comp_name 
  FROM dba_registry 
 ORDER BY 1

spool T000_DB_CHECKS_results.lis
/

PROMPT --S010_SCHEMA_OBJECT_COUNTS
PROMPT --SCHEMA OBJECTS COUNT

SET lines 80 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';

COL version FORMAT a12
COL comp_id FORMAT a8
COL schema LIKE version
COL comp_name FORMAT a35
COL status FORMAT a12

COL owner FORMAT a25
SELECT owner, object_type, count(*) 
FROM dba_objects 
WHERE owner NOT IN ('CTXSYS', 'OLAPSYS', 'MDSYS', 'DMSYS', 'WKSYS', 'LBACSYS',
                    'ORDSYS', 'XDB', 'EXFSYS', 'OWBSYS', 'WMSYS', 'SYSMAN','SYS','SYSTEM')
   OR owner LIKE 'APEX%'
GROUP BY owner, object_type
ORDER BY 1
 
spool T000_DB_CHECKS_results.lis append
/
spool off
 
 
SELECT owner, object_type, COUNT(*) 
  FROM dba_objects
 WHERE object_type LIKE 'JAVA%'
 GROUP BY owner, object_type
 ORDER BY 1,2
 
spool T000_DB_CHECKS_results.lis append
/

spool off

SET lines 80 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL value FORMAT a15

prompt --S020_CHECK_CHAR_SET
prompt --check character set information

SELECT * FROM nls_database_parameters 
WHERE  parameter LIKE '%SET' 
ORDER  BY 1
 
spool T000_DB_CHECKS_results.lis append
/

SPOOL OFF

prompt --S030_REDO_STRUCTURE
prompt -- check redo structure

SET lines 140 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL member FORMAT a100

spool T000_DB_CHECKS_results.lis append

SELECT group#,bytes,members,status 
  FROM v$log
 ORDER BY 1;

SELECT * FROM v$logfile 
 ORDER BY 1,3;

SPOOL off

prompt --S040_DB_STRUCTURE
prompt -- check database structure for tablespace and datafiles

SET lines 170 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL file_name FORMAT a100

spool T000_DB_CHECKS_results.lis append

SELECT tablespace_name, bytes, status, file_name 
  FROM dba_data_files 
 ORDER BY tablespace_name, file_name;

SET lines 100
COL ddl FORMAT a100

SELECT to_char(dbms_metadata.get_ddl('TABLESPACE',tablespace_name)) "DDL" 
FROM dba_Tablespaces
where tablespace_name <> 'EXAMPLE';

SPOOL off

prompt --S050_SYSDBA_USERS
prompt --check for sysdba users


SET lines 80 NUMWIDTH 12 PAGES 10000 LONG 2000000000
ALTER SESSION SET nls_date_format='YYYY-MM-DD HH24:MI:SS';
COL file_name FORMAT a100

SELECT * FROM v$pwfile_users

spool T000_DB_CHECKS_results.lis append
/
spool off

prompt --S280_VERIFICATION_CHECKS
prompt --other verification checks


COL TABLESPACE_NAME FORMAT A20
COL FILE_NAME FORMAT A60
COL BYTES FORMAT 999,999,999,999
SET LINES 180 PAGES 200

BREAK ON TABLESPACE_NAME
compute sum of BYTES on TABLESPACE_NAME

spool T000_DB_CHECKS_results.lis append

PROMPT 1. TABLESPACE, DATAFILE AND SEGMENT REPORT
PROMPT *******************************************

SELECT ddf.tablespace_name, ddf.bytes, ddf.status, ddf.status, ddf.file_name 
FROM   dba_data_files  ddf 
ORDER BY 1,5
/

CLEAR BREAKS

PROMPT 2. SEGMENT_SPACE REPORT
PROMPT ***********************

select ds.owner || '.' || ds.segment_type, sum(ds.bytes)/1024/1024/1024 SIZE_Gb
from dba_segments ds
group by ds.owner || '.' || ds.segment_type
/

PROMPT 3. OBJECT-BY-TYPE COUNT REPORT
PROMPT ******************************

select do.owner || '.' || do.object_type, count('x')
from dba_objects do
group by do.owner || '.' || do.object_type
/

PROMPT 4. INVALID OBJECT REPORT
PROMPT ************************

select do.owner, do.object_type || '.' || do.object_name, do.status 
from dba_objects do
where   do.status = 'INVALID'
/


PROMPT 5. DB LINKS REPORT
PROMPT ******************

set echo on feedback on lines 120 

col owner format a15
col db_link format a40
col username format a30
col host format a20

select * 
from dba_db_links
/

spool off