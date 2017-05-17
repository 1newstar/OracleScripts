spool logs\TablespaceFreeSpace.lst


-- Work out tablespace sizes, usages and free space.
-- Works on 9i and above.
-- 
-- Tablespaces at the top of the list need attention most.
-- Anything over 80% is a warning, 90% is getting critical.
--
-- Norman Dunbar.
with
space_size as (
    select  tablespace_name,
            count(*) as files, 
            sum(bytes) as bytes,
            sum(
                case autoextensible
                when 'YES' then maxbytes
                else bytes 
                end
            ) as maxbytes
    from    dba_data_files
    group   by tablespace_name
),
--
free_space as (
    select  tablespace_name, sum(bytes) as bytes
    from    dba_free_space
    group   by tablespace_name
)
--
select  s.tablespace_name, 
        s.files as data_files,
        round(s.bytes/1024/1024, 2) as size_mb,
        round(nvl(f.bytes, 0) /1024/1024, 2) as free_mb,
        round((nvl(f.bytes, 0) * 100 / s.bytes), 2) as free_pct,
        round((s.bytes - nvl(f.bytes, 0))/1024/1024, 2) as used_mb,
        round((100 - (nvl(f.bytes, 0) * 100 / s.bytes)), 2) as used_pct,        
        round(s.maxbytes/1024/1024, 2) as max_mb,
        round((nvl(s.bytes, 0) * 100 / s.maxbytes), 2) as size_pct_max,
        round((nvl(f.bytes, 0) * 100 / s.maxbytes), 2) as free_pct_max,
        round((s.bytes - nvl(f.bytes, 0)) * 100 / s.maxbytes, 2) as used_pct_max        
from    space_size s
left join free_space f
on      (f.tablespace_name = s.tablespace_name)
--
union all
--
-- Get actual TEMP usage as opposed to DBA_FREE_SPACE figures.
select  h.tablespace_name,
        count(*) data_files,
        --
        round(sum(h.bytes_free + h.bytes_used) / 1048576, 2) as size_mb,
        --
        round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 
        1048576, 2) as free_mb,
        --
        round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 
        sum(h.bytes_used + h.bytes_free)) * 100, 2) as  Free_pct,
        --
        round(sum(nvl(p.bytes_used, 0))/ 1048576, 2) as used_mb,
        100 - round((sum((h.bytes_free + h.bytes_used) - 
        nvl(p.bytes_used, 0)) / 
        sum(h.bytes_used + h.bytes_free)) * 100, 2) as  used_pct,
        --
        round(sum(decode(f.autoextensible, 
                         'YES', f.maxbytes, 
                         'NO', f.bytes) / 
        1048576), 2) as max_mb,
        --
        round(sum(h.bytes_free + h.bytes_used) * 100 / 
        sum(decode(f.autoextensible, 
                   'YES', f.maxbytes, 
                   'NO', f.bytes)), 2) as  size_pct_max,
        --
        round(sum((h.bytes_free + h.bytes_used) - 
        nvl(p.bytes_used, 0)) * 100 / 
        sum(decode(f.autoextensible, 
                   'YES', f.maxbytes, 
                   'NO', f.bytes)), 2) as  free_pct_max,
        --
        round(sum(nvl(p.bytes_used, 0)) * 100 / 
        sum(decode(f.autoextensible, 
                   'YES', f.maxbytes, 
                   'NO', f.bytes)), 2) as  used_pct_max
        --
from    sys.v_$TEMP_SPACE_HEADER h,
        sys.v_$Temp_extent_pool p,
        dba_temp_files f 
where   p.file_id(+) = h.file_id
and     p.tablespace_name(+) = h.tablespace_name
and     f.file_id = h.file_id
and     f.tablespace_name = h.tablespace_name
group   by h.tablespace_name
--
order   by used_pct_max desc;


spool off