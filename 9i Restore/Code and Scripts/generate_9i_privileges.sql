set lines 2000 trimspool on pagesize 0
spool recreate_9i_privileges.sql


-- type# = 1 -> User.
-- type# = 0 -> role.

select 'grant ' || p.privilege || ' on ' || p.owner || '."' || p.table_name || '"' ||
       ' to ' || p.grantee || 
       case p.grantable
           when 'YES' then ' with grant option'
           else null
       end ||
       -- 
       case p.hierarchy
           when 'YES' then ' with hierarchy option'
           else null
       end || 
       --
       ';'
--       
from dba_tab_privs p, sys.user$ u
where p.grantee = u.name
and u.type# = 1
--===========================================================
-- EDIT the following list to match the NOROWS list, and make
-- sure that FCS is also included.
--===========================================================
and p.owner in (
    'FCS', 
    'CMTEMP', 
    'ITOPS', 
    'LEEDS_CONFIG', 
    'OEIC_RECALC', 
    'UVSCHEDULER', 
    'IBASHIR', 
    'JRICHARDSON1', 
    'PPHILLIPS', 
    'SMAHALA', 
    'TAKEON_ARCH_GLO', 
    'TAKEON_CF_INVESTEC', 
    'TAKEON_MITON', 
    'TAKEON_PANTHER', 
    'TAKEON_PENNINE', 
    'TAKEON_WAY', 
    'TAKEON_WOOD_ST'
) order by 1;        

spool off       
