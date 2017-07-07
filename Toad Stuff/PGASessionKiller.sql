create or replace procedure sys.PGASessionKiller(

    piModule v$session.module%type := 'Report Execution',
    piProgram v$session.program%type := 'dya141mr.exe',
    piSeconds v$session.seconds_in_wait%type := 1800,
    piDoKill boolean := false

) as    

    -- Where we want to write messages to.
    cTraceFileOnly constant number := 1;
    cAlertLogOnly constant number := 2;
    cTraceFileAndAlertLog constant number := 3;
    
    -- SQL to drop the user session.
    vSql varchar2(1024);
    
    -- Message for the trace file.
    vMessage varchar2(2048);

begin
    -- Validate the parameters.
    -- NULL is not permitted.    
    if ((piModule is NULL) or (piProgram is NULL)) then
        raise_application_error(-20001, 'Program and/or module cannot be NULL');
        return;
    end if;
    
    -- NULL or less than 500 is not permitted.
    if (nvl(piSeconds, 0) < 500) then
        raise_application_error(-20001, 'Seconds cannot be NULL or less than 500');
        return;
    end if;
    
    
    
    -- Build a list of stuck sessions, being very careful about
    -- exactly which sessions we choose. The parameters passed in
    -- MUST match exactly those in V$SESSION.
    for stuckSession in (
        select  s.module,
                s.program,
                s.seconds_in_wait,
                s.sid,
                'alter system kill session '''|| s.sid || ', ' || s.serial# || 
                ''' immediate' as sqlText
        from    v$session s
        where   s.module = piModule
        and     s.program = piProgram
        and     s.event = 'SQL*Net message from client'
        and     s.state = 'WAITING'
        and     s.seconds_in_wait > piSeconds
        order   by s.sid)
    loop
        -- Build the Message and extract the SQL statement.
        -- The message will be written to the current session's 
        -- trace file which you can find by running:
        --
        --  select p.tracefile
        --  from v$session s, v$process p
        --  where p.addr = s.paddr
        --  and s.sid = SYS_CONTEXT('USERENV', 'SID');
        --
        -- But run it in the same session (or Toad Tab) as the execution
        -- of this procedure or you won't get the correct tracefile name.
        
        if (piDoKill) then
            vMessage := 'Killing';
        else
            vMessage := 'Listing';
        end if;
        
        vMessage := vMessage || ' stuck session: ' || stuckSession.sid ||
                    ' which is running ' || stuckSession.program ||
                    ', module ' || stuckSession.module ||
                    ', and has been stuck for ' || 
                    stuckSession.seconds_in_wait || ' seconds.';
        vSql := stuckSession.sqlText;
                     
        -- =============================================================
        -- Normally we would kill the sessions, but if the execute
        -- immediate line is commented out, we are just testing.
        -- If we are runnig the SQL for real, each session killed
        -- will automatically be logged to the alert log.
        --
        -- For testing, we simply use the trace file for logging.
        -- =============================================================
        
        begin
            -- Log the SQL we are about to execute to the trace file
            -- for this session.
            dbms_system.ksdwrt(cTraceFileOnly, vMessage);
        exception
            -- We don't appear to be able to execute DBMS_SYSTEM. 
            -- C'est lavvy. as they say in Wales.
            when others then null;    
        end;
            
        begin
            if (piDoKill) then
                -- This is where we kill the session.
                execute immediate vSql;
            end if;
        exception
            -- We don't appear to be able to 'execute immediate' - hmmm. 
            when others then
                dbms_system.ksdwrt(cTraceFileAndAlertLog, 'FAILED: ' || vSql);
        end;
            
    end loop;
       
end;
/