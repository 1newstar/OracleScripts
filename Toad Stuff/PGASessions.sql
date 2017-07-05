-- Script to extract the "rogue" Dimension logins.
-- These seem to be a problem area when:
--
2
-- * The USERNAME is SERVER;
-- * The program is 'DYA141MR.EXE';
-- * The module is 'Report Execution'.
--
-- The latter seems to be the problem. The other modules
-- appear to login and "do stuff" pretty much constantly,
-- apart from the one "Authentication Service", but the
-- report execution modules login, do stuff, then go
-- idle and stay there for days.
--
-- It looks like a problem in either:
--
-- * Getting the users to log out after running a report; or
-- * The application is not disconnecting after running one.
--
-- Having said that, the module 'dya141mr.exe' might not be
-- helping as a few of those have been idle for some time too.
--
select s.sid, s.serial#, p.spid,
round(p.pga_used_mem/1024/1024, 3) PGA_USED_MB,
s.status, s.event, s.module, s.logon_time,
s.state, s.seconds_in_wait,
sysdate - (s.seconds_in_wait/(24*60*60)) as waiting_since
from v$session s ,v$process p
where s.paddr=p.addr
--and s.username = 'SERVER'
and upper(s.program) = 'DYA141MR.EXE'
order by s.module, seconds_in_wait asc;