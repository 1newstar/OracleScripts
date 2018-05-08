column tree format a12
column session_recid noprint
break on session_recid skip 2
set lines 2000 trimspool on pages 2000

--spool logs\RMANBackupCheck.lst

-- Hierarchic data.
select session_recid, rpad('|', (level-1) * 3, '_') || recid as tree, recid, to_char(start_time, 'dd/mm/yyyy hh24:mi:ss') as start_time, to_char(end_time, 'dd/mm/yyyy hh24:mi:ss') as end_time, object_type, status, operation 
from (
--
    select session_recid, recid, parent_recid, start_time, end_time, object_type, status, operation 
    from v$rman_status
    where row_type in ('COMMAND', 'RECURSIVE OPERATION')
    and (
            -- BACKUP of archived log and database...
            (object_type is not null and operation = 'BACKUP') 
            or 
            -- AUTOBACKUP of controlfile and spfile
            ( object_type is null and operation like 'CONTROL FILE%')
        )
    -- Everything from Monday, Sunday, Saturday and Friday, maximum.
    and start_time >= trunc(sysdate) -1
    --
    union all
    --
    select session_recid, recid, parent_recid, start_time, end_time, object_type, status, operation 
    from v$rman_status
    where operation in ('RMAN')
    and row_type = 'SESSION'
    --and status != 'COMPLETED'
    and start_time >= trunc(sysdate) -1
--
)
connect by nocycle prior recid = parent_recid
start with (parent_recid is null and operation = 'RMAN')
order siblings by end_time, recid;

spool off