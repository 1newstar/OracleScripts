set define off
set lines 500 trimspool on
set pages 2000
set echo on
set feedback on
set timing on

---------------------------------------------------------------------------
-- This script will convert the two bitmap indexes on the PNET.PCL table to
-- normal indexes. This should prevent the vast number of TX Mode 4 dead-
-- locks we see every day against these two objects.
--
-- Norman Dunbar
-- 23 April 2018.
---------------------------------------------------------------------------
-- Script tested in database PNET01D1 on 30 April 2018 with no problems. 
---------------------------------------------------------------------------


spool c:\users\hisg494\downloads\pcl_bitmap_indexes.log

/*
 * Drop XIEPCL index - queries will use index XIE8PCL which has the
 * same leading column. This will allow XIE7PCL to be recreated without
 * resorting to a temporary index.
 */
drop index pnet.xie7pcl;

create index pnet.xie7pcl 
    on pnet.pcl (lower(eml_addr)) 
    local visible
    tablespace pnet_tracking;

-- Gather stats.
exec dbms_stats.gather_index_stats(ownname => 'PNET', indname =>'XIE7PCL');

-- Now check the plan. 
explain plan for
select eml_addr,cust_pstcde_mod 
from pnet.pcl 
where lower(eml_addr) like 'ndxx%';

-- Should now use the new XIE7PCL index.
select * from table(dbms_xplan.display);



/*
 * Create a temporary XIE8PCL but because it has been indexed, add an 'X'.
 * Then switch XIE8PCL to the temporary index while we drop and recreate
 * XIE8PCL as a NORMAL index. Queries will automatically start using the
 * temporary index while we work on recreating the original.
 */
create index pnet.xie8pcl_b 
    on pnet.pcl (lower(eml_addr), cust_pstcde_mod, 'X')  
    local visible 
    tablespace pnet_tracking;


-- Lose the bitmap index.    
drop index pnet.xie8pcl;

-- Recreate as NORMAL.
create index pnet.xie8pcl 
    on pnet.pcl (lower(eml_addr), cust_pstcde_mod)  
    local visible 
    tablespace pnet_tracking;

-- Gather stats.
exec dbms_stats.gather_index_stats(ownname => 'PNET', indname =>'XIE8PCL');

-- And lose the temporary stuff.    
drop index pnet.xie8pcl_b;


-- Now check the plan. 
explain plan for 
select eml_addr,cust_pstcde_mod 
from pnet.pcl 
where lower(eml_addr) like 'ndxx%' 
and cust_pstcde_mod like 'E%';

-- Should now use the new XIE8PCL index.
select * from table(dbms_xplan.display);


spool off