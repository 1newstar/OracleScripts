set pages 3000 lines 2000 trimspool on
set serverout on size unlimited

spool gather_stats.lst

declare
    cursor tc is (  select owner, table_name
                    from dba_tables
                    where owner in ('FCS','OEIC_RECALC')
                    and (owner, table_name) not in (select owner, table_name from dba_external_tables)
                    and temporary <> 'Y'
                 );
                     
    type ttc is table of tc%rowtype index by pls_integer;
    
    stats ttc;
    
    vSql varchar2(4000);
    
begin
    open tc;
    
    fetch tc
    bulk collect into stats;  
  
    close tc;
    
    -- Allow the user to monitor progress.
    -- select sid, module, action
    -- from v$session
    -- where module = ''UPGRADE: Gather Stats';
    DBMS_APPLICATION_INFO.set_module('UPGRADE: Gather Stats', null);

    for x in 1 .. stats.count loop
        begin
            vSql := 'begin dbms_stats.gather_table_stats(ownname=>''' || stats(x).owner || '''' ||
                    ', tabname=>''' || stats(x).table_name || '''' ||
                    ', Method_Opt=>''FOR ALL INDEXED COLUMNS SIZE AUTO'',Degree=>4,Cascade=>TRUE,No_Invalidate=>FALSE); end;';
            
            -- Update v$Session.action.
            DBMS_APPLICATION_INFO.set_action(stats(x).owner || '.' || stats(x).table_name);
		    --dbms_output.put_line(vSql);        
            execute immediate vSql;
                               
        exception
            when others then
                dbms_output.put_line('Failed to gather stats ' || stats(x).owner || '.' || stats(x).table_name);
        end;
    end loop;
  
end;
/

-- At 10g onwards, we need to gather dictionary stats too.
begin
    dbms_stats.gather_dictionary_stats;
end;
/

spool off
