col spid for a10
col event for a35
col program for a25
col blocked_sid for a40
col blocking_sid for a15

set lines 300 trimspool on pages 3000

-- Who is blocking other blockers?
select  lpad(' ', (level-1) * 2) || sid as blocked_sid,
        nvl(to_char(blocking_session),'<--- CULPRIT') as blocking_sid
from    v$session
where   blocking_session is not null
or      sid in (
                select  blocking_session
                from    v$session
                where   blocking_session is not null
               )
connect by prior sid = blocking_session
order   siblings by sid;

-- And who else is blocked?
select  p.spid,
        s.sid,
        s.blocking_session,
        s.program,
        s.event,
        s.p1,
        s.p2,
        s.p3,
        s.seconds_in_wait,
        s.state
from    v$session s
join    v$process p on (p.addr = s.paddr)
where   s.blocking_session is not null
or      s.sid in (
                select  blocking_session
                from    v$session
                where   blocking_session is not null
               )
order   by s.sid;
                               
