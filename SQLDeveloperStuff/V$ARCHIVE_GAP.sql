-- REPLACEMENT for V$ARCHIVE_GAP which suffers from a MERGE JOIN CARTESIAN between
-- three SYS tables, and takes literally, forever.  The following is the official Oracle
-- workaround, which does work.
--
-- The V$ARCHIVE_GAP fixed view on a physical standby database only returns the next
-- gap that is currently blocking redo apply from continuing.
--
-- After resolving the identified gap and starting redo apply, query the V$ARCHIVE_GAP
-- fixed view again on the physical standby database to determine the next gap
-- sequence, if there is one.
--
-- SELECT * FROM v$archive_gap; BUG RIDDEN, Replacement below.
--
select USERENV('Instance'), high.thread#, low.lsq, high.hsq
from
  (select a.thread#, rcvsq, min(a.sequence#)-1 hsq
   from v$archived_log a,
        (select lh.thread#, lh.resetlogs_change#, max(lh.sequence#) rcvsq
           from v$log_history lh, v$database_incarnation di
          where lh.resetlogs_time = di.resetlogs_time
            and lh.resetlogs_change# = di.resetlogs_change#
            and di.status = 'CURRENT'
            and lh.thread# is not null
            and lh.resetlogs_change# is not null
            and lh.resetlogs_time is not null
         group by lh.thread#, lh.resetlogs_change#
        ) b
   where a.thread# = b.thread#
     and a.resetlogs_change# = b.resetlogs_change#
     and a.sequence# > rcvsq
   group by a.thread#, rcvsq) high,
(select srl_lsq.thread#, nvl(lh_lsq.lsq, srl_lsq.lsq) lsq
   from
     (select thread#, min(sequence#)+1 lsq
      from
        v$log_history lh, x$kccfe fe, v$database_incarnation di
      where to_number(fe.fecps) <= lh.next_change#
        and to_number(fe.fecps) >= lh.first_change#
        and fe.fedup!=0 and bitand(fe.festa, 12) = 12
        and di.resetlogs_time = lh.resetlogs_time
        and lh.resetlogs_change# = di.resetlogs_change#
        and di.status = 'CURRENT'
      group by thread#) lh_lsq,
     (select thread#, max(sequence#)+1 lsq
      from
        v$log_history
      where (select min( to_number(fe.fecps))
             from x$kccfe fe
             where fe.fedup!=0 and bitand(fe.festa, 12) = 12)
      >= next_change#
      group by thread#) srl_lsq
   where srl_lsq.thread# = lh_lsq.thread#(+)
  ) low
where low.thread# = high.thread#
and lsq < = hsq
and hsq > rcvsq;
