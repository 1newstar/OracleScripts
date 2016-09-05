select  t.sid,
        s.username,
        s.program,
        n.name, 
        t.value
from    v$sesstat t
join    v$session s on (t.sid = s.sid)
join    v$statname n on (t.statistic# = n.statistic#)
where   t.value <> 0
and     s.username is not null -- exclude Oracle processes
order   by t.sid, t.value desc;        