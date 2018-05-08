select table_name from dict where table_name like '%IND%' order by 1;

HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C

'F_PCLSHP_OVRALL_SOS_B2C_201802'

select sql_id,executions,sql_fulltext
from v$sqlarea
where upper(sql_fulltext) like '%F_PCLSHP_OVRALL_SOS_B2C%'
and sql_fulltext not like 'select%' 
and sql_fulltext not like 'SELECT%' ;