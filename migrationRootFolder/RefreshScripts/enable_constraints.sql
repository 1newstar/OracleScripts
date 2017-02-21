set pages 3000 lines 2000 trimspool on
setserverout on size unlimited

spool enable_constraints.lst

declare
    cursor tc is (  select owner, table_name, constraint_name
                    from dba_constraints
                    where owner in ('FCS','OEIC_RECALC','ONLOAD','LEEDS_CONFIG','CMTEMP','UVSCHEDULER','ITOPS')
                    and constraint_type in ('R','P','C','U')
                 );
                     
    type ttc is table of tc%rowtype index by pls_integer;
    
    constraints ttc;
    
begin
    open tc;
    
    fetch tc
    bulk collect into constraints;  
  
    close tc;
    
    for x in 1 .. constraints.count loop
        begin
			execute immediate 'alter table ' || constraints(x).owner || '.'  || constraints(x).table_name || ' enable novalidate constraint ' || constraints(x).constraint_name;
			dbms_output.put_line(constraints(x).owner || '.' || constraints(x).constraint_name || ' enabled');
        exception
            when others then
                dbms_output.put_line('Failed to enable constraint ' || constraints(x).owner || '.' || constraints(x).constraint_name);
        end;
    end loop;
  
end;
/

alter table fcs.renewal_commission enable novalidate constraint renewal_commission_c04;

spool off
