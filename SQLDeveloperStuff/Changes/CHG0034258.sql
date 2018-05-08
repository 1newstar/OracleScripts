--==================================================================================
-- A script for change CHG0034258 as requested by Paul Boundry.
-- Author: Norman Dunbar
-- Date: 18/01/2018
--
-- Purpose: Some rows in the PNET.PCL table, since the 16th January, do not have a
-- value in PCL_TIMESTAMP. This is currently defined as NULLABLE but in the history
-- table that these rows are copied to, the column is NOT NULL.
--
-- This script will copy the affected data rows to a temporary table, then update
-- each "broken" row with a default value for the column.
-- If all is well, the DBA must commit.
--==================================================================================
-- Script to be run as a DBA enabled user, in SQLDeveloper, using F5 to execute.
-- At end, type commit; and F9 to commit the changes. (Or rollback; and F9. as
-- appropriate.
--==================================================================================

-- Drop temporary table - if found.
-- Errors here can be ignored.
drop table pnet.pcl_temp_norman cascade constraints purge;


-- Create a temporary table.
create table pnet.pcl_temp_norman
as (
        select * from pnet.pcl
        where CRE_TMESTP > to_date('16/01/2018','dd/mm/yyyy') 
        and PCL_ID > 850000000 
        and PCL_TMESTP is null
    );


-- Count the rows - to compare with the rows updated below.    
select count(*) from pnet.pcl_temp_norman;

    
--====================================================================
-- We should never be mixing DDL (above) and DML (below) but as the
-- DDL is completed, there will be no implicit COMMITs executed by
-- the DDL that might mess up our ability to ROLLBACK the DML.
--====================================================================


-- Update the broken data.
update pnet.pcl 
set PCL_TMESTP = to_timestamp('16/01/2018 17.00.00.000000000', 'dd/mm/yyyy hh24.mi.ss.ff')
where CRE_TMESTP > to_date('16/01/2018','dd/mm/yyyy')  
and PCL_ID > 850000000 
and PCL_TMESTP is null;


-- Prompt the DBA to commit, if all went well.
prompt ************************************
prompt If all was well, please commit;
prompt Otherwise, please ROLLBACK;
prompt ************************************
-- commit;
-- rollback;

select pcl_id, cre_tmestp from pnet.pcl where pcl_id in (select pcl_id from pnet.pcl_temp_norman);



