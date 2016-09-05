set pages 3000 lines 2000 trimspool on
setserverout on size unlimited

spool novalidate_constraints.lst

declare
    cursor tc is (  select owner, table_name, constraint_name
                    from dba_constraints
                    where owner in ('FCS','OEIC_RECALC','ONLOAD','LEEDS_CONFIG','CMTEMP','UVSCHEDULER','ITOPS')
                    and constraint_type in ('R')
                    and (
                        constraint_name not like 'SYS\_C%' escape '\'
                        and
                        table_name not like 'SYS\_%==' escape '\'
                    )
                 );
                     
    type ttc is table of tc%rowtype index by pls_integer;
    
    constraints ttc;
    vSQL varchar2(4000);
    
begin
    open tc;
    
    fetch tc
    bulk collect into constraints;  
  
    close tc;
    
    for x in 1 .. constraints.count loop
        begin
            vSQL :=  'alter table ' || constraints(x).owner || '.'  || 
                     constraints(x).table_name || ' modify constraint ' || 
                     constraints(x).constraint_name || ' novalidate';
                     
            execute immediate vSQL;
            dbms_output.put_line(constraints(x).owner || '.' || constraints(x).table_name || ' - ' || constraints(x).constraint_name || ' modified');
            
        exception
            when others then
                dbms_output.put_line(SQLERRM);
                dbms_output.put_line('FAILED to modify constraint ' || constraints(x).owner || '.' || constraints(x).table_name || ' - ' || constraints(x).constraint_name);
                
        end;
    end loop;
  
end;
/

spool off
