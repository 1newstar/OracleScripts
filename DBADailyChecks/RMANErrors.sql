spool logs\RMANErrors.lst

undefine PARENT_RECID

select output
from v$rman_output
-- Use the parent_id for the failed session...
where session_recid=&&PARENT_RECID
and output <> ' '
order by recid asc;

spool off