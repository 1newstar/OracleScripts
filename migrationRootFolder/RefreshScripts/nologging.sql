set pages 3000 lines 2000 trimspool on
set serverout on size unlimited

spool nologging.lst

alter database no force logging;

declare
    vSQL varchar2(1000);

begin
    for x in (select 'table' as what, table_name as name, owner
              from dba_tables
              where owner in ('CMTEMP','FCS','ITOPS','LEEDS_CONFIG','OEIC_RECALC','ONLOAD','UVSCHEDULER')
              and temporary <> 'Y'
              and (owner,table_name) not in (select owner, table_name from dba_external_tables)
              --
              union all
              --
              select 'index', i.index_name, i.owner
              from dba_indexes i
              join dba_tables t on (t.owner = i.owner and t.table_name = i.table_name)
              where i.owner in ('CMTEMP','FCS','ITOPS','LEEDS_CONFIG','OEIC_RECALC','ONLOAD','UVSCHEDULER')
              and t.temporary <> 'Y'
              and (i.owner, i.table_name) not in (select owner, table_name from dba_external_tables)
              and i.index_name not like 'SYS_IL%'
              and i.index_name <> 'REVSTOCKTRANSFER_PK'
              order by 1, 3, 2
            ) 
    loop
        begin
            vSQL := 'alter ' || x.what || ' ' || x.owner || '.' || x.name || ' nologging';       
            --dbms_output.put_line(vSQL);
            execute immediate vSQL;

        exception
            when others then
                dbms_output.put_line('FAILED: ' || vSQL);
        end;
    end loop;
end;
/

spool off


