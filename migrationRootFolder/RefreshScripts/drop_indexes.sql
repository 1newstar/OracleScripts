set pages 3000 lines 2000 trimspool on
setserverout on size unlimited

spool drop_indexes.lst

declare
    cursor ti is (  select owner, index_name
                    from dba_indexes
                    where owner in ('FCS','OEIC_RECALC')
                    and index_type <> 'LOB'
                    and upper(index_name) not like 'SYS%'
                    and table_name in ('ORDTRAN','RENEWAL_COMMISSION','AUDIT_LOG_DETAIL','AUDIT_LOG')
                 );
                     
    type tti is table of ti%rowtype index by pls_integer;
    
    indices tti;
    
begin
    open ti;
    
    fetch ti
    bulk collect into indices;  
  
    close ti;
    
    for x in 1 .. indices.count loop
        begin
            execute immediate 'drop index ' || indices(x).owner || '.'  || indices(x).index_name;
		 dbms_output.put_line(indices(x).owner || '.' indices(x).index_name || ' dropped');
        exception
            when others then
                dbms_output.put_line('Failed to drop index ' || indices(x).owner || '.' || indices(x).index_name);
        end;
    end loop;
  
end;
/

spool off
