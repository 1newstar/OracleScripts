-- The following is a list of default users created in a new database.
-- We would not want to be deleting those!
--

-- First of all, we know we can drop all the '%_AURA' users and the 
-- corresponding user without the '_AURA' suffix.

set lines 2000 pages 2000 trimspool on
spool drop_old_users.lst

set serverout on size unlimited

declare
    vDropSql varchar2(1000);
    vDropAuraSql varchar2(1000);
    
begin
    for x in (select username
              from   dba_users
              where  username like '%\_AURA' escape '\'
              order  by username)
    loop
        vDropAuraSql := 'drop user ' || x.username || ' cascade';
        vDropSql := replace(vDropAuraSql, '_AURA', NULL);
              
        begin
            dbms_output.put_line('ABOUT TO: ' || vDropAuraSql);        
            execute immediate vDropAuraSql;
        exception
            when others then
                dbms_output.put_line('FAILED TO: ' || vDropAuraSQL);
        end;

        begin
            dbms_output.put_line('ABOUT TO: ' || vDropSql);        
            execute immediate vDropSql;
        exception
            when others then
                dbms_output.put_line('FAILED TO: ' || vDropSQL);
        end;
    end loop;
end;
/

-- For the remainder, we need to check first, so generate a script.

set echo off

spool drop_old_users_2.sql

select 'drop user ' || username || ' cascade;'
from dba_users
where username not in 
('ANONYMOUS',
'APEX_030200',
'APEX_PUBLIC_USER',
'APPQOSSYS',
'CTXSYS',
'DBSNMP',
'DIP',
'EXFSYS',
'FLOWS_FILES',
'MDDATA',
'MDSYS',
'MGMT_VIEW',
'OLAPSYS',
'ORACLE_OCM',
'ORDDATA',
'ORDPLUGINS',
'ORDSYS',
'OUTLN',
'OWBSYS',
'OWBSYS_AUDIT',
'PERFSTAT',
'SI_INFORMTN_SCHEMA',
'SPATIAL_CSW_ADMIN_USR',
'SPATIAL_WFS_ADMIN_USR',
'SYS',
'SYSMAN',
'SYSTEM',
'WMSYS',
'XDB',
'XS$NULL',
'FCS',
'ITOPS',
'LEEDS_CONFIG',
'OEIC_RECALC',
'CMTEMP',
'ONLOAD',
'OEIC_RECALC',
'UVSCHEDULER')
order by 1;

spool off

spool drop_old_users_2.lst
@drop_old_users_2.sql
spool off
