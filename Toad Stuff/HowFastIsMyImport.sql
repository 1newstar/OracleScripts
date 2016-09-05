-- How fast is my import runnig?
-- Only shows timings etc for imp session that are
-- currently loading the tables. Creating indexes will
-- not show up.
--
-- BEWARE, however, sessions that are creating indexes
-- will show a decreasing "rows per minute" figure as there
-- are no more rows importing, but time is still passing!
--
select  substr(sql_text,instr(sql_text,'INTO "') +6,instr(sql_text, '(') - instr(sql_text,'INTO "') -8) table_name,
        null index_name,
        rows_processed,
        round((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
        trunc(rows_processed/((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_min    
from    sys.v_$sqlarea
where   sql_text like 'INSERT %INTO "%'
and     command_type = 2
and     open_versions > 0
--
union all
--
select  replace(substr(sql_text,instr(sql_text,'ON "') +4,instr(sql_text, '(') - instr(sql_text,'ON "') -6),'"', null) table_name,
        replace(substr(sql_text,instr(sql_text,'INDEX "') +7,instr(sql_text, ' ON') - instr(sql_text,'INDEX "') -8),'"', null) index_name,
        null rows_processed,
        round((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
        null rows_per_min    
from    sys.v_$sqlarea
where   sql_text like 'CREATE %INDEX%'
and     command_type = 9
and     open_versions > 0
--
-- List the table first, then the index creation, if any.
order   by 1, 2 nulls first;

