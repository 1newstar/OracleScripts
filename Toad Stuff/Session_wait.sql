select  w.sid,
        s.serial#,
        s.username,
        s.logon_time,
        s.program,
        w.event,
        w.state,
        w.wait_time,
        w.seconds_in_wait,
        w.p1,
        w.p2,
        w.p3
from    v$session_wait w
join    v$session s on (s.sid = w.sid)
where   w.state = 'WAITING'
and     s.username is not null
order   by w.seconds_in_wait desc;         