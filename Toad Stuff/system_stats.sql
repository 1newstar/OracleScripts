select  name, 
        value
from    v$sysstat
where   value <> 0
order   by value desc;        