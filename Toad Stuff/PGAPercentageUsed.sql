select round(100 * a.value / (select value from v$parameter where name = 'pga_aggregate_limit'), 2) as PGA_PCT_USED
from v$pgastat a
where name = 'total PGA allocated';