-- How much is that doggy in the FRA?
-- Norman Dunbar
-- October 2016.
--
-- Ok, it's not really a doggy, it's more of an amount of space used
-- in the FRA - converted from a percentage to actualy MB.
select  file_type, 
        percent_space_used, 
        ((select value from v$parameter where name ='db_recovery_file_dest_size') * percent_space_used/100)/1024/1024 as mb_used,
        percent_space_reclaimable,
        ((select value from v$parameter where name ='db_recovery_file_dest_size') * percent_space_reclaimable/100)/1024/1024 as mb_reclaimable,
        number_of_files        
from V$RECOVERY_AREA_USAGE;
