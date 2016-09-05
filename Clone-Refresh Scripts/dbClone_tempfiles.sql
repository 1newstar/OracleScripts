set echo off termout off feed off heading off lines 1000 trimspool on pages 1000

col file_id noprint

select file_id, 'alter tablespace ' || tablespace_name || ' drop tempfile ''' || file_name || ''';' as sql
from dba_temp_files f
--
union all
--
select file_id, 'alter tablespace ' || tablespace_name || ' add tempfile ''' || file_name || ''' size ' || bytes || ' reuse;'
from dba_temp_files f
--
order by file_id, sql desc

spool tempfiles.sql

/

spool off
exit