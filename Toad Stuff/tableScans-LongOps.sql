select sid, start_time, start_time + ((time_remaining+elapsed_seconds)/24/60/60) as end_time, time_remaining, elapsed_seconds, message
from v$session_longops
where message like 'Table Scan%'
order by start_time desc;