-- Generate extents for empty tables. This is needed in the event that we ever
-- have to export with 9i client to revert back to 9i on Solaris.
-- Which is unlikely, but .....

set serverout on size unlimited
set lines 2000 trimspool on pages 3000

declare
    vSQL varchar2(350);

begin
        for x in (
            SELECT owner, table_name
            FROM dba_tables
            WHERE segment_created = 'NO'
            AND owner NOT IN ('ORDSYS', 'MDSYS', 'CTXSYS', 'ORDPLUGINS','SYSMAN',
                   'LBACSYS', 'XDB', 'SI_INFORMTN_SCHEMA', 'DIP','FLOWS_FILES',
                   'DBSNMP', 'EXFSYS', 'WMSYS','APEX_030200', 'ORACLE_OCM','OLAPSYS','PERFSTAT','OWBSYS','ORDDATA',
                   'ANONYMOUS', 'XS$NULL', 'APPQOSSYS')
            ORDER by 1
        ) loop
            vSQL := 'alter table ' || x.owner || '.' || x.table_name || ' allocate extent';
            begin
                execute immediate vSQL;
            exception
                when others then
                    dbms_output.put_line('FAILED: ' || vSQL);
            end;
        end loop;
end;
/
        
            
 
 
 
 
     
     