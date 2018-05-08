with    
alloc   as (
    select
        t.target_name as instance,
        m.key_value as disk_group,
        -- Get monthly totals here
        trunc(m.rollup_timestamp, 'MM') as tstamp,
        --
        avg(m.average) as avg_size_mb,
        min(m.minimum) as min_size_mb,
        max(m.maximum) as max_size_mb
    from
        mgmt$metric_daily m
    inner join 
        mgmt$target_type t
        on  m.target_guid = t.target_guid 
        and m.metric_guid = t.metric_guid
    where 
        (
            t.target_type = 'osm_cluster'
            or (t.target_type = 'osm_instance' and t.type_qualifier2 != 'ASMINST')
        )
    and t.metric_name = 'DiskGroup_Usage'
    and t.metric_column = 'usable_total_mb'
    and m.rollup_timestamp >= add_months(trunc(sysdate), -6)
    group by
      t.target_name,
        -- Get monthly totals here
        trunc(m.rollup_timestamp, 'MM'),
      m.key_value
),
free    as (
    select
        t.target_name as instance,
        m.key_value as disk_group,
        -- Get monthly totals here
        trunc(m.rollup_timestamp, 'MM') as tstamp,
        --
        avg(m.average) as avg_free_mb,
        min(m.minimum) as min_free_mb,
        max(m.maximum) as max_free_mb
    from
        mgmt$metric_daily m
    inner join 
        mgmt$target_type t
        on m.target_guid = t.target_guid 
        and m.metric_guid = t.metric_guid
    where
        (
            t.target_type = 'osm_cluster'
            or (t.target_type = 'osm_instance' and t.type_qualifier2 != 'ASMINST')
        )
    and t.metric_name = 'DiskGroup_Usage'
    and t.metric_column = 'usable_file_mb'
    and m.rollup_timestamp >= add_months(trunc(sysdate), -6)
    group by
      t.target_name,
        -- Get monthly totals here
        trunc(m.rollup_timestamp, 'MM'),
      m.key_value
)
--
select
    alloc.instance,
    alloc.tstamp as datestamp,
    alloc.disk_group,
    --
    round(avg(alloc.avg_size_mb)/1024,2) as avg_size_gb,
    round(avg(alloc.avg_size_mb)/1024 - lag (avg(alloc.avg_size_mb),1,null) over (partition by alloc.disk_group order by alloc.tstamp )/1024,2) as avg_size_diff_gb,
    round(avg(alloc.avg_size_mb - free.avg_free_mb)/1024,2) as avg_used_gb,
    round(avg(alloc.avg_size_mb - free.avg_free_mb)/1024 - lag (avg(alloc.avg_size_mb - free.avg_free_mb),1,null) over (partition by alloc.disk_group order by alloc.tstamp )/1024,2) as avg_used_diff_gb,
    round(avg(free.avg_free_mb)/1024,2) as avg_free_gb,
    round(avg(free.avg_free_mb)/1024 - lag (avg(free.avg_free_mb),1,null) over (partition by alloc.disk_group order by alloc.tstamp )/1024,2) as avg_free_diff_gb
from alloc
join free
on (alloc.instance = free.instance
     and alloc.tstamp = free.tstamp
     and alloc.disk_group = free.disk_group)
where alloc.instance in (
    '+ASM_axukprdmisadb01.int.hlg.de',
    '+ASM_axukprdmisddb01.int.hlg.de',
    '+ASM_axukprdmoddb01.int.hlg.de',
    '+ASM_axukprdrttdb01.int.hlg.de',
    '+ASM_axukprdmhdb01.int.hlg.de',
    '+ASM_axukprdmisadb02.int.hlg.de',
    '+ASM_axukprdmisddb02.int.hlg.de',
    '+ASM_axukprdmoddb02.int.hlg.de',
    '+ASM_axukprdrttdb02.int.hlg.de',
    '+ASM_axukprdmhdb02.int.hlg.de'    
)     
group by alloc.instance, alloc.tstamp, alloc.disk_group
order by alloc.instance, alloc.disk_group, alloc.tstamp 