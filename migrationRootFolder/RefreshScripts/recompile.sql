set echo on feedback on lines 2000 pages 3000 trimspool on

col owner format a30
col object_name format a50
col object_type format a19
col object_status format a7


EXECUTE UTL_RECOMP.RECOMP_PARALLEL(4);

spool recompile.lst

select owner, object_name, object_type, status
from dba_objects 
where owner in ('FCS','OEIC_RECALC','LEEDS_CONFIG','CMTEMP','ITOPS','ONLOAD','UVSCHEDULER')
and status = 'INVALID'
order by owner, object_type, object_name;

spool off
