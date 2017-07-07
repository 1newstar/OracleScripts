-- A script to disable the scheduled job that will
-- remove all traces of the PGAKiller patch applied
-- to remove stuck Dimension jobs that were holding
-- on to large amounts of PGS memory, causing other
-- active sessions to be killed.
--
-- Norman Dunbar
-- 6th July 2017.

set lines 2000 trimspool on pages 2000

spool PGAKillerRollback.log

-- If present, disable the scheduled job. Erros about
-- the job not existing can be ignored.
begin
    dbms_scheduler.disable(name => 'SYS.PGASESSIONKILLER', 
                           force => true);
                           
    dbms_scheduler.drop_job(name => 'SYS.PGASESSIONKILLER', 
                            force => true);                           
end;
/                           

-- Drop the procedure
drop procedure sys.PGASESSIONKILLER;


spool off                           
