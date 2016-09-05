-- Index Creation Times are valid provided that all the
-- indexes were created one after the other, as in an imp
-- or impdp (perhaps - untested) for example.
--
-- DBA_OBJECT.CREATED = time CREATE INDEX sql was submitted.
-- Therefore we order by created and take the LAG() difference
-- to get the time to create this index.
select  i.index_name, 
        o.created,
        numtodsinterval(o.created - lag(o.created, 1) 
            over (order by o.created desc), 'DAY') 
            as time_days_hh_mm_ss
from    dba_indexes i, 
        dba_objects o
where   i.owner='FCS' 
and     i.table_name in( 'ORDTRAN')
and     o.owner = i.owner
and     o.object_name = i.index_name
order   by o.created desc;