column name format a40
column creation_timestamp format a30 
column restore_to_time format a30

spool logs\RestorePointChecks.lst

select  name, to_char(storage_size/1024/1024/1024, '9,990.00') as size_gb,
        time as creation_timestamp 
from    v$restore_point
--where   trunc(systimestamp) - trunc(time) >= 7
order   by time;

spool off
