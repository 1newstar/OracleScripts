--=========================================================================================
-- How much space is allocated and free in each (production) ASM instance. All disc groups
-- are listed. Daily usage (since yesterday) is reported and used to calculate the number
-- of days space we have left.
-------------------------------------------------------------------------------------------
-- Runs in OEM and queries the CCUK01P1 database, which is the OEM repository.
-- Set up as a report - "ND - ASM Disk Groups - Free Space Days Remaining" under the
-- Monitoring, Database Targets category.
--------- ----------------------------------------------------------------------------------
-- Author : Norman Dunbar
-- Date   : 14 February 2018
--=========================================================================================
-- History
--
-- Author : Norman Dunbar
-- Date   : 16 February 2018
-- Purpose: James requested on the DATA disk group be considered.
--
-- Author : Norman Dunbar
-- Date   : 20 February 2018
-- Purpose: Base the days left on a running 14 day average of additional daily used space.
--=========================================================================================
--
--
-- ALLOC gets a list of ASM instances, a date (daily), the disk group name (always DATA)
-- the allocated space in MB for 'yesterday' and works out a change from the previous day for
-- each instance for the last 14 days.
--
with alloc as (
    select  m.target_name as Instance,
            m.rollup_timestamp as datestamp,
            m.key_value as disk_group,
            m.maximum as alloc_mb,
            -- Yesterday's allocated space minus today's allocated space
            m.maximum - lag (m.maximum, 1, null) over (partition by m.target_name, m.key_value order by m.rollup_timestamp) as delta_alloc
    from
            mgmt$metric_daily m
            inner join mgmt$target_type t on m.target_guid = t.target_guid and m.metric_guid = t.metric_guid
    where
            m.target_name in (
                '+ASM_axukprdmisadb01.int.hlg.de', 
                '+ASM_axukprdmisddb01.int.hlg.de', 
                '+ASM_axukprdmoddb01.int.hlg.de', 
                '+ASM_axukprdmhdb01.int.hlg.de', 
                '+ASM_axukprdrttdb01.int.hlg.de', 
                '+ASM_axukprdmisadb02.int.hlg.de', 
                '+ASM_axukprdmisddb02.int.hlg.de', 
                '+ASM_axukprdmoddb02.int.hlg.de', 
                '+ASM_axukprdmhdb02.int.hlg.de', 
                '+ASM_axukprdrttdb02.int.hlg.de'
            )
    and
            (t.target_type='osm_cluster' or (t.target_type='osm_instance' and t.type_qualifier2 != 'ASMINST'))
    and
            t.metric_name = 'DiskGroup_Usage'
    and
            t.metric_column = 'usable_total_mb'
    and        
            m.rollup_timestamp >= trunc(sysdate) - 14
    and        
            m.key_value = 'DATA'
),
--
--
-- FREE gets a list of ASM instances, a date (daily), the disk group name (always DATA)
-- the free space in MB for 'yesterday' and works out a change from the previous day for
-- each instance for the last 14 days.
--
free as (
    select  m.target_name as Instance,
            m.rollup_timestamp as datestamp,
            m.key_value as disk_group,
            m.maximum as free_mb,
            -- Yesterday's free space minus today's free space
            lag (m.maximum, 1, null) over (partition by m.target_name, m.key_value order by m.rollup_timestamp) - m.maximum as delta_free
    from
            mgmt$metric_daily m
            inner join mgmt$target_type t on m.target_guid = t.target_guid and m.metric_guid = t.metric_guid
    where
            m.target_name in (
                '+ASM_axukprdmisadb01.int.hlg.de', 
                '+ASM_axukprdmisddb01.int.hlg.de', 
                '+ASM_axukprdmoddb01.int.hlg.de', 
                '+ASM_axukprdmhdb01.int.hlg.de', 
                '+ASM_axukprdrttdb01.int.hlg.de', 
                '+ASM_axukprdmisadb02.int.hlg.de', 
                '+ASM_axukprdmisddb02.int.hlg.de', 
                '+ASM_axukprdmoddb02.int.hlg.de', 
                '+ASM_axukprdmhdb02.int.hlg.de', 
                '+ASM_axukprdrttdb02.int.hlg.de'
            )
    and
            (t.target_type='osm_cluster' or (t.target_type='osm_instance' and t.type_qualifier2 != 'ASMINST'))
    and
            t.metric_name = 'DiskGroup_Usage'
    and
            t.metric_column = 'usable_file_mb'
    and        
            m.rollup_timestamp >= trunc(sysdate) - 14
    and        
            m.key_value = 'DATA'
),
--
--
-- EVERYTHING joins ALLOC and FREE and lists the ASM instances, a date (daily), the disk group 
-- name (always DATA), the allocated GB, free GB, and the Daily GB usage. We still have 14 days 
-- worth of data for each ASM instance at this point. We need it later.
--
everything as (
    select  alloc.instance as ASM_instance,
            decode(alloc.instance,
                '+ASM_axukprdmisadb01.int.hlg.de', 'MISA01P1',
                '+ASM_axukprdmisddb01.int.hlg.de', 'MISD01P1',
                '+ASM_axukprdmoddb01.int.hlg.de', 'MOD01P1',
                '+ASM_axukprdmhdb01.int.hlg.de', 'UKMHPRDDB:Primary',
                '+ASM_axukprdrttdb01.int.hlg.de', 'RTT/PNET01P1',
                '+ASM_axukprdmisadb02.int.hlg.de', 'MISA01P2',
                '+ASM_axukprdmisddb02.int.hlg.de', 'MISD01P2',
                '+ASM_axukprdmoddb02.int.hlg.de', 'MOD01P2',
                '+ASM_axukprdmhdb02.int.hlg.de', 'UKMHPRDDB:Standby',
                '+ASM_axukprdrttdb02.int.hlg.de', 'RTT/PNET01P2',
                alloc.instance
    ) as Database,
            to_char(alloc.datestamp, 'dd/mm/yyyy') as datestamp,
            alloc.disk_group,
            round(alloc.alloc_mb/1024,2) as alloc_gb,
            round(free.free_mb/1024,2) as free_gb,
            round(free.delta_free/1024,2) as daily_gb
    from    alloc
    join    free 
    on      alloc.instance = free.instance 
    and     alloc.datestamp = free.datestamp 
    and     alloc.disk_group = free.disk_group
    where   free.delta_free is not null
    order   by alloc.instance, alloc.disk_group, alloc.datestamp
),
--
--
-- AVERAGE_14_DAY lists everything from EVERYTHING plus it works out the average daily
-- disc space usage over the 14 day period for each asm instance. Again, we still have the
-- 14 days for each ASM instance at this point - otherwise we can't work out the average.
--
average_14_day as (
    select  e.*, 
            avg(e.daily_gb) over (partition by e.asm_instance, e.database) as average_gb
from    everything e
),
--
--
-- ONLY_YESTERDAY (can I hear music?) strips out only the entry for yesterday. This reduces
-- the 14 days above down to 1 day here.
--
only_yesterday as (
    select  a.*,
            case 
                when a.average_gb > 0
                    then round(a.free_gb/a.average_gb, 2)
                else
                    null
            end as days_left
    from    average_14_day a
    -- Yesterday only, we don't need the other 13 days now.
    where   a.datestamp = trunc(sysdate) - 1
) 
--
--   
-- Finally, we are only interested in those data disc groups due to run out of space
-- in the next 60 days based on the 14 day average usage. We use 61 because
-- the most recent metrics available are 'yesterday' and not 'today'.
--
select  yesterday.*
from    only_yesterday yesterday
where   yesterday.days_left < 61
order   by yesterday.asm_instance, yesterday.database