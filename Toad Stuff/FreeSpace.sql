-- Work out tablespace sizes, usages and free space.
-- Works on 9i and above.
-- Norman Dunbar.
with    space_size as (
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
        to_char(round(s.bytes/1024/1024, 2), '9,999,990.00') as size_mb,
        to_char(round(nvl(f.bytes, 0) /1024/1024, 2), '9,999,990.00') as free_mb,
        to_char(round((nvl(f.bytes, 0) * 100 / s.bytes), 2), '990.00') as free_pct,
        to_char(round((s.bytes - nvl(f.bytes, 0))/1024/1024, 2), '9,999,990.00') as used_mb,
        to_char(round((100 - (nvl(f.bytes, 0) * 100 / s.bytes)), 2), '990.00') as used_pct,        
        to_char(round(s.maxbytes/1024/1024, 2), '9,999,990.00') as max_mb,
        to_char(round((nvl(s.bytes, 0) * 100 / s.maxbytes), 2), '990.00') as size_pct_max,
        to_char(round((nvl(f.bytes, 0) * 100 / s.maxbytes), 2), '990.00') as free_pct_max,
        to_char(round((s.bytes - nvl(f.bytes, 0)) * 100 / s.maxbytes, 2), '990.00') as used_pct_max        
from    space_size s
left join free_space f
on      (f.tablespace_name = s.tablespace_name)
order   by 1;
        