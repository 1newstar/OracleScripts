-- Norman Dunbar
-- October 2016.
--
-- What is the space used in the FRA - converted from a percentage to GB.

spool logs\FRAChecks.lst

select  file_type, 
        percent_space_used, 
        ((select value from v$parameter where name ='db_recovery_file_dest_size') * percent_space_used/100)/1024/1024/1024 as gb_used,
        percent_space_reclaimable,
        ((select value from v$parameter where name ='db_recovery_file_dest_size') * percent_space_reclaimable/100)/1024/1024/1024 as gb_reclaimable,
        number_of_files        
from V$RECOVERY_AREA_USAGE;

spool off