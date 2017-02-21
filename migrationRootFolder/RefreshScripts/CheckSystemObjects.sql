-- A number of users, around 92, have their default tablespace set
-- to SYSTEM. This is wrong and must be fixed. However, if they have
-- tables or indexes in SYSTEM, those must be moved.
--
-- If this script produces any rows, a manual move of the objects
-- must be carried out.
--
select owner, segment_type, count(*) 
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
group by owner, segment_type
order by 1,2;

