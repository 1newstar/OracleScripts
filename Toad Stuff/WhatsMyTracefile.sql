-- ====================================================================
-- Find out which is the tracefile for my current session.
-- In Toad, etc, each tab might be on a separate session
-- so run this in the correct tab.
--
-- Norman Dunbar
-- 6th July 2017.
-- ====================================================================
select p.tracefile
from v$session s, v$process p
where p.addr = s.paddr
and s.sid = SYS_CONTEXT('USERENV', 'SID');

