-- A number of users, around 92, have their default tablespace set
-- to SYSTEM. This is wrong and must be fixed. However, if they have
-- tables or indexes in SYSTEM, those must be moved.
--
-- If this script produces any rows, then execute the data as a script
-- to do the needful.
--
-- LONG columns or non-table/index objects will need doing manually.
-- but these swill be few and far between, if any.
--
with objects as  (
    select /*+ materialize */ unique owner, segment_type, segment_name 
    from dba_segments
    where owner in (
        select username from dba_users
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
    )
)    
--
select 'alter table ' || o.owner || '.' || o.segment_name || ' move tablespace cfa;'     
from objects o
where o.segment_type = 'TABLE'
union all
select 'alter index ' || o.owner || '.' || o.segment_name || ' rebuild online tablespace cfa;'     
from objects o
where o.segment_type = 'INDEX'
-- Make sure tables move first!
-- However, the default tablespace must be changed and QUOTA allocated
-- BEFORE running the output from here.
order by 1 desc;

