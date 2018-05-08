-- Replacement V$OBJECT_USAGE which shows all users, not just
-- the one you are logged in as.
select  u.name, io.name as index_name, t.name as table_name,
        decode(bitand(i.flags, 65536), 0, 'NO', 'YES') as monitoring,
        decode(bitand(ou.flags, 1), 0, 'NO', 'YES') as used,
        ou.start_monitoring,
        ou.end_monitoring
from    sys.obj$ io, 
        sys.obj$ t, 
        sys.ind$ i, 
        sys.object_usage ou, 
        sys.user$ u
where   i.obj# = ou.obj#
and     io.obj# = ou.obj#
and     t.obj# = i.bo#
and     u.user# = io.owner#;