-- We should avoid problems by dropping the PUBLIC database links
-- before attempting to recreate them as part of the import.
--
-- Norman Dunbar
-- 26 September 2016.
--

set lines 2000 pages 2000 trimspool on
set serveroutput on size unlimited

spool DropPublicDBLinks.lst

declare
  vSql varchar2(1000);

begin
  for x in (select db_link from dba_db_links where owner = 'PUBLIC') loop
    vSql := 'drop public database link ' || x.db_link;
    begin
      execute immediate vSql;
    exception
      when others then
        dbms_output.put_line('FAILED: ' || vSql);

    end;
  end loop;

end;
/

spool off
