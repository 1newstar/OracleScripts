set serverout on size unlimited
set lines 2000 pages 2000 trimspool on

spool MoveDefaultTablespace.lst

-- Move any non oracle accounts with a default tablespace of SYSTEM
-- out of SYSTEM into CFA. 
-- No quota will be allocated as none of the users have quota on SYSTEM.
-- No objects are curently owned by these accounts, in SYSTEM so there
-- are no complicated moves of tables and rebuilds of indexes to do.
--
declare
  vSQL varchar2(1000);
  vNewDefaultTablespace constant dba_tablespaces.tablespace_name%type := 'CFA';
  
begin
    for x in (
        select username, default_tablespace from dba_users
        where default_tablespace = 'SYSTEM'
        and username not in (
            -- Administrative accounts
            'ANONYMOUS',
            'CTXSYS',
            'DBSNMP',
            'EXFSYS',
            'LBACSYS',
            'MDSYS',
            'MGMT_VIEW',
            'OLAPSYS',
            'OWBSYS',
            'ORDPLUGINS',
            'ORDSYS',
            'OUTLN',
            'SI_INFORMTN_SCHEMA',
            'SYS',
            'SYSMAN',
            'SYSTEM',
            'TSMSYS',
            'WK_TEST',
            'WKSYS',
            'WKPROXY',
            'WMSYS',
            'XDB',
            -- Non-administrative accounts
            'APEX_PUBLIC_USER',
            'DIP',
            'FLOWS_30000',
            'FLOWS_FILES',
            'MDDATA',
            'ORACLE_OCM',
            'SPATIAL_CSW_ADMIN_USR',
            'SPATIAL_WFS_ADMIN_USR',
            'XS$NULL',
            -- Demo accounts
            'BI',
            'HR',
            'OE',
            'PM',
            'IX',
            'SH'
        )
        order by 1)
    loop
        begin
            vSql := 'alter user ' || x.username || ' default tablespace ' || vNewDefaultTablespace;
            dbms_output.put_line(vSql);
            execute immediate vSql;
            
        exception
            when others then
                dbms_output.put_line('Failed to: ' || vSql);
        end;
    end loop;
end;
/

spool off        