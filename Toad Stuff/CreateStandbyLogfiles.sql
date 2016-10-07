set serveroutput on size unlimited
 
declare
    -- Gap between top ONLINE and bottom STANDBY group#.
    -- CHANGE THIS to suit your requirements.
    vDesiredOffset constant number := 10;
    
    -- Current highest and lowest ONLINE group.
    vMaxOnlineGroup v$logfile.group#%type;
    vMinOnlineGroup v$logfile.group#%type;
    
    -- Current number of threads;
    vThreadCount number;
    
    -- New desired GROUP# for the STANDBY logs
    vNewGroup v$logfile.group#%type;
    
    -- How big is a log file?
    vMaxBytes v$log.bytes%type;
    
    -- PATH to the 'a' redo log.
    vRedoAPath v$logfile.member%type;
    
    -- PATH to the 'b' redo log.
    vRedoBPath v$logfile.member%type;
    
    -- Allows me to grab the members of the highest
    -- ONLINE group of redo logs, to extract the paths.
    type tLogFileMembers is table of v$logfile.member%type
        index by binary_integer; 
    
    vLogFileMembers tLogFileMembers;
    
begin

    -- Get current maximum online group#.
    select  min(group#), max(group#) 
    into    vMinOnlineGroup, vMaxOnlineGroup
    from    v$logfile 
    where   type = 'ONLINE';
    
    -- Get maximum size of a current logfile.
    select  max(bytes) 
    into    vMaxBytes
    from    v$log; 
    
    -- Get the A and B paths. There could be more than 2 members.
    select  member
    bulk    collect
    into    vLogFileMembers
    from    v$logfile
    where   group# = vMaxOnlineGroup;
    
    -- This assumes at least two members in each ONLINE group. 
    -- Any less might/will be a problem.
    vRedoAPath := substr(vLogFileMembers(1), 1, instr(vLogFileMembers(1), '\', -1));
    vRedoBPath := substr(vLogFileMembers(2), 1, instr(vLogFileMembers(2), '\', -1));
    
    -- Get the thread count.
    select  count(*)
    into    vThreadCount
    from    v$thread;
  
   
    -- Build the desired standby groups.
    for onlineLog in (select distinct group# as gn 
                      from   v$logfile
                      where  type = 'ONLINE'
                      order by 1)
    loop
        -- If current max is 13, we want the minimum standby group to
        -- be 23 + desired offset + 1. The minimum new group will be
        -- that number.
            
        vNewGroup := onlineLog.gn + vMaxOnlineGroup - vMinOnlineGroup + vDesiredOffset + 1;
        
        dbms_output.put('alter database add standby logfile group ');
        dbms_output.put_line(to_char(vNewGroup) || ' (');
        dbms_output.put_line('''' || vRedoAPath || 'stby' || to_char(vNewGroup) || 'a.log'',');
        dbms_output.put_line('''' || vRedoBPath || 'stby' || to_char(vNewGroup) || 'b.log');
        dbms_output.put_line(') size ' || to_char(vMaxBytes) || ';');
        dbms_output.put_line(' ');
    
    end loop;


    -- We also need an extra standby for each entry in V$THREAD.
    dbms_output.put_line('-- We also need one extra standby for each entry in V$THREAD.');
    for extraLog in 1..vThreadCount 
    loop
        vNewGroup := vNewGroup + 1;
        
        dbms_output.put('alter database add standby logfile group ');
        dbms_output.put_line(to_char(vNewGroup) || ' (');
        dbms_output.put_line('''' || vRedoAPath || 'stby' || to_char(vNewGroup) || 'a.log'',');
        dbms_output.put_line('''' || vRedoBPath || 'stby' || to_char(vNewGroup) || 'b.log'') ');
        dbms_output.put_line('size ' || to_char(vMaxBytes) || ';');
    end loop;
        
end;
/  


