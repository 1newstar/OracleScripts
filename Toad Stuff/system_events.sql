select  EVENT, 
        TOTAL_WAITS, 
        TOTAL_TIMEOUTS, 
        TIME_WAITED, 
        AVERAGE_WAIT
from    v$system_event
where   time_waited <> 0
order   by time_waited desc;