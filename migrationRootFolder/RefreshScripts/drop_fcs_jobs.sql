set lines 2000 pages 2000 trimspool on

-- We need to drop any pre-existing FCS DBMS_JOBS or we get import errors.
-- We must do this as FCS too, SYS canot drop other users' jobs.

spool drop_fcs_jobs.lst

connect fcs/devenv

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


spool off.

-- DO NOT REMOVE!
exit

