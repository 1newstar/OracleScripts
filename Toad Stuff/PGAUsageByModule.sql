-- Script to determine the total number, and PGA Usage
-- of all the sessions logged into SERVER using program DYA141MR.EXE.
--
select s.module, count(*),
round(sum(p.pga_used_mem)/1024/1024, 3) PGA_MB_USED
from v$session s ,v$process p
where s.paddr=p.addr
--and s.username = 'SERVER'
and upper(s.program) = 'DYA141MR.EXE'
group by rollup(s.module)
order by s.module;