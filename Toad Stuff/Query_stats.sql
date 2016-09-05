select sum(parse_calls), sum(executions), sum(invalidations), sum(elapsed_time), sum(cpu_time), sum(buffer_gets), sum(rows_processed),sql_text
from v$sql
where upper(sql_text) like '%PK_QDS.SPLIT_QDS_PER_CANC_RIGHTS%'
and plan_hash_value = 0
group by sql_text;

select sum(parse_calls), sum(executions), sum(invalidations), sum(elapsed_time), sum(cpu_time), sum(buffer_gets), sum(rows_processed),sql_text
from v$sql
where upper(sql_text) like '%INSERT INTO ORDTRAN_QDS_CR%'
and plan_hash_value = 0
group by sql_text;

select sum(parse_calls), sum(executions), sum(invalidations), sum(elapsed_time), sum(cpu_time), sum(buffer_gets), sum(rows_processed),sql_text
from v$sql
where upper(sql_text) like '%DELETE FROM ORDTRAN_QDS_CR OCR%'
and plan_hash_value = 0
group by sql_text;


