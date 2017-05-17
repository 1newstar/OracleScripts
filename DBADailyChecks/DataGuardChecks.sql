column db_unique_name format a10
column dest_name format a20
column destination format a20
column error format a100 wrap
column gap_status format a20

spool logs\DataGuardChecks.lst


select  dest_id, gap_status, 
        Dest_name, destination, 
        archived_seq#, applied_seq#,
        db_unique_name, error
from   v$archive_dest_status
where  status <> 'INACTIVE'
and    dest_id in (2,3);


spool off
