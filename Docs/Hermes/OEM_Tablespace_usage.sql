Tablespace Utilisation From OEM
===============================

See: http://www.ewan.cc/sites/ewan.cc/files/ts_trend_sql.txt



REM $Id: ts_trend.sql,v 1.7 2013/06/21 14:06:42 ewan Exp $

column target_name format a30 new_value def_t
column target_type format a20
select target_name, target_type from mgmt$target
where
  target_type='rac_database'
  or (target_type='oracle_database' and type_qualifier3 != 'RACINST')
order by lower(target_name)
/

set verify off

accept db prompt "db [&def_t]> " default '&def_t'

column target_guid new_value t_guid
select target_guid from mgmt_targets where target_name='&db';

accept res prompt "aggregation (y, m or d) [d]> " default 'd'

column format new_value form
select
  case
    when '&res'='y' then 'yyyy'
    when '&res'='m' then 'yyyy-mm'
    else 'yyyy-mm-dd'
  end as format
from dual
/

alter session set nls_date_format='&form';

column dstart new_value def_d1
column dfinish new_value def_d2
select current_date - interval '12' month as dstart, current_date as dfinish
from dual
/

select distinct
  m.key_value as tablespace
from
  mgmt$metric_daily m
where
  m.target_guid=hextoraw('&t_guid')
  and m.metric_name='tbspAllocation'
order by
  m.key_value
/

accept ts prompt "ts [%]> " default '%'
accept start prompt "start (&form) [&def_d1]> " default '&def_d1'
accept finish prompt "finish (&form) [&def_d2]> " default '&def_d2'

set linesize 80 pagesize 0 feedback off
set numformat 99999999
column tablespace format a32

define out=ts_trend_&res._&db._&ts._&start._&finish
spool &out..txt

select
  to_date(to_char(alloc.timestamp,'&form'),'&form') as stamp,
  alloc.tablespace as tablespace,
  round(avg(alloc.avg_size_mb),2) as avg_size_mb,
  round(avg(used.avg_used_mb),2) as avg_used_mb,
  round(avg(alloc.avg_size_mb - used.avg_used_mb),2) as avg_free_mb
  --round(avg((used.avg_used_mb*100)/decode(alloc.avg_size_mb,0,1,alloc.avg_size_mb)),2) as avg_used_pct
  --round(max(alloc.max_size_mb),2) as max_size_mb,
  --round(max(used.max_used_mb),2) as max_used_mb,
  --round(max(alloc.avg_size_mb - used.avg_used_mb),2) as max_free_mb,
  --round(max((used.avg_used_mb*100)/decode(alloc.avg_size_mb,0,1,alloc.avg_size_mb)),2) as max_used_pct,
  --round(min(alloc.min_size_mb),2) as min_size_mb,
  --round(min(used.min_used_mb),2) as min_used_mb,
  --round(min(alloc.avg_size_mb - used.avg_used_mb),2) as min_free_mb,
  --round(min((used.avg_used_mb*100)/decode(alloc.avg_size_mb,0,1,alloc.avg_size_mb)),2) as min_used_pct
from
  (
    select
      m.key_value as tablespace,
      m.rollup_timestamp as timestamp,
      avg(m.average) as avg_size_mb,
      min(m.minimum) as min_size_mb,
      max(m.maximum) as max_size_mb
    from
      mgmt$metric_daily m
      inner join mgmt$target_type t
        on m.target_guid=t.target_guid and m.metric_guid=t.metric_guid
    where
      t.target_guid=hextoraw('&t_guid')
      and (
        t.target_type='rac_database'
        or (t.target_type='oracle_database' and t.type_qualifier3 != 'RACINST')
      )
      and m.key_value like '&ts'
      and t.metric_name='tbspAllocation'
      and t.metric_column='spaceAllocated'
      and m.rollup_timestamp >= to_date('&start')
      and m.rollup_timestamp <= to_date('&finish')
    group by
      m.rollup_timestamp,
      m.key_value
  ) alloc
  inner join (
    select
      m.key_value as tablespace,
      m.rollup_timestamp as timestamp,
      avg(m.average) as avg_used_mb,
      min(m.minimum) as min_used_mb,
      max(m.maximum) as max_used_mb
    from
      mgmt$metric_daily m
      inner join mgmt$target_type t
        on m.target_guid=t.target_guid and m.metric_guid=t.metric_guid
    where
      t.target_guid=hextoraw('&t_guid')
      and (
        t.target_type='rac_database'
        or (t.target_type='oracle_database' and t.type_qualifier3 != 'RACINST')
      )
      and m.key_value like '&ts'
      and t.metric_name='tbspAllocation'
      and t.metric_column='spaceUsed'
      and m.rollup_timestamp >= to_date('&start')
      and m.rollup_timestamp <= to_date('&finish')
    group by
      m.rollup_timestamp,
      m.key_value
  ) used
    on alloc.timestamp=used.timestamp and alloc.tablespace=used.tablespace
group by
  to_char(alloc.timestamp,'&form'),
  alloc.tablespace
order by
  alloc.tablespace,
  to_char(alloc.timestamp,'&form')
/

spool off

spool &out..gp

prompt set datafile separator whitespace
prompt set terminal pdfcairo
prompt set output "&out..pdf"
prompt set term pdfcairo enhanced font "Arial, 8"
prompt 
prompt set title "Tablespace &ts history for &db"
prompt 
prompt set xlabel "Date"
prompt set xdata time
prompt set timefmt "%Y-%m-%d"
prompt set xtics format "%m/%Y"
prompt 
prompt set ylabel "MiB"
prompt 
prompt set pointsize 0.4
prompt set style data linespoints
prompt 
prompt plot "&out..txt" using 1:3 title "Allocated", \
prompt      "&out..txt" using 1:4 title "Used", \
prompt      "&out..txt" using 1:5 title "Free"

spool off

set pagesize 14 verify on feedback on