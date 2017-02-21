-- Recreate the current FCS DBMS_JOBs as DBMS_SCHEDULER_JOBs.
-- Then delete the no longer required jobs.
--
-- Must be run as FCS user post import.
--
-- Norman Dunbar.   27/09/2016
--

connect fcs/devenv

set pages 2000 lines 2000 trimspool on
set echo on

spool create_fcs_scheduled_jobs.lst


-- These are no longer required, or are "dead" on 9i production already!
--@@BANKHALL_Housekeeping.sql
--@@BANKHALL_Cancellations.sql
--@@BANKHALL_AddSource.sql

-- These are still required.
@@ALERTS_Heartbeat.sql
@@ClearLogs.sql
@@JISA_18Bday_Conversion.sql

-- Remove the old jobs now, we no longer need them.
begin
  for x in (select job from user_jobs) loop
    begin
      dbms_job.remove(x.job);
    exception
      when others then 
        dbms_output.put_line('Failed to drop job ' || to_char(x.job) || ' for user FCS. Check DBA_JOBS.');
    end;
  end loop;
  commit;
end;
/

set echo off
spool off

-- DO NOT REMOVE
exit