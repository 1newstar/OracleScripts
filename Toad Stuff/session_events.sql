select  e.SID,
        nvl(s.USERNAME, s.program) as USERNAME,      
        e.EVENT, 
        e.TOTAL_WAITS, 
        e.TOTAL_TIMEOUTS, 
        e.TIME_WAITED, 
        e.AVERAGE_WAIT,
        s.row_wait_obj#,
        o.owner,
        o.object_type,
        o.object_name,
        s.row_wait_file#,
        d.name as file_name,
        s.row_wait_block#,
        s.row_wait_row#
from    v$session_event e
join    v$session s on (s.sid = e.sid)
left    join v$datafile d on (d.file# = s.row_wait_file#)
left    join dba_objects o on (o.object_id = s.row_wait_obj#)
where   e.time_waited <> 0
order   by username, 
        e.time_waited desc;