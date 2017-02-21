COL TABLESPACE_NAME FORMAT A20
COL FILE_NAME FORMAT A60
COL BYTES FORMAT 999,999,999,999
SET LINES 180 PAGES 200

BREAK ON TABLESPACE_NAME
compute sum of BYTES on TABLESPACE_NAME

spool S280_VERIFICATION_CHECKS_results.lis

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