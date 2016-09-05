--
-- List looping synonyms, PUBLIC ones, that either
-- circulate (loop) or are not pointing at anything.
--
-- Doesn't work on 9i. Shame.
select  owner, synonym_name, connect_by_iscycle CYCLE
from    dba_synonyms
where   connect_by_iscycle > 0
connect by nocycle prior table_name = synonym_name
and     prior table_owner = owner
union
select 'PUBLIC', synonym_name, 1
from    dba_synonyms
where   owner = 'PUBLIC'
and     table_name = synonym_name
and     (table_name, table_owner) not in (
            select object_name, owner 
            from   dba_objects
            where  object_type != 'SYNONYM'
        );

