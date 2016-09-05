PROMPT Blocked and Blocker Sessions

col blocker_sid format 99999999999
col blocked_sid format 99999999999
col min_blocked format 99999999999
col request format 9999999

select /*+ ORDERED */
blocker.sid blocker_sid
, blocked.sid blocked_sid
, TRUNC(blocked.ctime/60) mins_blocked
, blocked.request
from (select *
from v$lock
where block != 0
and type = 'TX') blocker
, v$lock blocked
where
blocked.type='TX'
and blocked.block = 0
and blocked.id1 = blocker.id1;

prompt blocked objects from V$LOCK and SYS.OBJ$

set lines 132
col BLOCKED_OBJ format a35 trunc
select /*+ ORDERED */
l.sid
, l.lmode
, TRUNC(l.ctime/60) mins_blocked
, u.name||'.'||o.NAME blocked_obj
from (select *
from v$lock
where type='TM'
and sid in (select sid
from v$lock
where block!=0)) l
, sys.obj$ o
, sys.user$ u
where o.obj# = l.ID1
and o.OWNER# = u.user#
/

prompt blocked sessions from V$LOCK

select /*+ ORDERED */
blocker.sid blocker_sid
, blocked.sid blocked_sid
, TRUNC(blocked.ctime/60) mins_blocked
, blocked.request
from (select *
from v$lock
where block != 0
and type = 'TX') blocker
, v$lock blocked
where blocked.type='TX'
and blocked.block = 0
and blocked.id1 = blocker.id1
/

prompt blokers session details from V$SESSION

set lines 132
col username format a10 trunc
col osuser format a12 trunc
col machine format a15 trunc
col process format a15 trunc
col action format a50 trunc
SELECT sid
, serial#
, username
, osuser
, machine
FROM v$session
WHERE sid IN (select sid
from v$lock
where block != 0
and type = 'TX')
/
