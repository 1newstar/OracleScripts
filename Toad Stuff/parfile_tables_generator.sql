declare
    type ttables is table of dba_tables.table_name%type index by pls_integer;
    
    table_names ttables;
    
begin
    dbms_output.enable(1000000);
    
    select table_name
    bulk collect into table_names  
    from dba_tables 
    where owner = 'FCS' 
    and table_name != 'AUDIT_LOG_DETAIL' 
    order by 1;
  

    dbms_output.put_line('Tables=(');
  
    for x in 1 .. table_names.count loop
        if (x != table_names.count) then
            dbms_output.put_line('fcs.' || table_names(x) || ',');
        else
            dbms_output.put_line('fcs.' || table_names(x));
        end if;
    end loop;

    dbms_output.put_line(')');
  
end;
/