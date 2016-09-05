select  name, 
        round((misses/decode(gets,0,1,gets))*100, 4) "Get/Miss Ratio",
        round((immediate_misses/decode(immediate_gets,0,1,immediate_gets))*100, 4) "Immediate Get/Miss Ratio",
        gets,
        spin_gets, 
        sleeps,
        round(wait_time/1e6,4) wait_time_seconds
from    v$latch
where   wait_time > 0
order   by wait_time desc