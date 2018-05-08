--------------------------------------------------------------------------------------
-- Script to extract details about a given SQL_ID, from the ASH history tables
--
--       SO YOU BETTER BE LICENCED FOR DIAGNOSTICS & TUNING PACKS
--
-- You can limit the results to any given period by adjusting the timestamp.
--------------------------------------------------------------------------------------
-- The stats returned are per snapshot - hence the use of xxx_delta columns. Also, the
-- delta figures for some columns accumulate the parallel slaves and the coordinator.
--------------------------------------------------------------------------------------
-- Norman Dunbar
-- 01 Febrauary 2018.
--------------------------------------------------------------------------------------
set numwidth 10
set pages 100
set lines 2000 trimspool on trimout on
set verify off

col module format a25
col username format a15
col cpu_seconds format 9G999G999D99
col cpu_s_exec format 99G999G999D99
col ela_seconds format 99G999G999D99
col ela_s_exec format 99G999G999D99
col io_wait_seconds format 99G999G999D99
col iow_s_exec format 99G999G999D99
col cost format 999G990
col buffs_exec format 99G999G999D99
col reads_exec format 99G999G999D99
col rows_exec format 99G999G999

select  ss.snap_id as snapshot,
        to_char(ss.begin_interval_time, 'dd/mm/yyyy hh24:mi') as snapshot_start,
        to_char(ss.end_interval_time, 'dd/mm/yyyy hh24:mi') as snapshot_end,
        sh.sql_id,
        --sh.optimizer_cost as cost,
        sh.module,
        -- Since instance startup
        -- sh.executions_total as total_execs,
        -- Just in this snapshot
        sh.executions_delta as snapshot_execs,
        sh.parsing_schema_name as username,
        -- CPU Time.
        round(sh.cpu_time_delta/1e6,2) as cpu_seconds,
        round(sh.cpu_time_delta/sh.executions_delta/1e6, 2) as cpu_s_exec,
        -- Elapsed Time includes Parallel stuff.
        --round(sh.elapsed_time_delta/(sh.px_servers_execs_delta/sh.executions_delta)/1e6,2) as ela_seconds,
        --round(sh.elapsed_time_delta/sh.executions_delta/(sh.px_servers_execs_delta/sh.executions_delta)/1e6, 2) as ela_s_exec,
        -- IO Wait Time includes Parallel stuff.
        --round(sh.iowait_delta/(sh.px_servers_execs_delta/sh.executions_delta)/1e6,2) as io_wait_seconds,
        --round(sh.iowait_delta/sh.executions_delta/(sh.px_servers_execs_delta/sh.executions_delta)/1e6, 2) as iow_s_exec,
        -- Buffer Gets/Disk Reads includes parallel stuff
        --round(sh.buffer_gets_delta/(sh.px_servers_execs_delta/sh.executions_delta), 2) as buffs_exec,
        --round(sh.disk_reads_delta/(sh.px_servers_execs_delta/sh.executions_delta), 2) as reads_exec,
        -- Rows per exec.
        --round(sh.rows_processed_delta/sh.executions_delta, 2) as rows_exec,
        st.sql_text
from    dba_hist_snapshot ss
join    dba_hist_sqlstat sh
        on (sh.snap_id = ss.snap_id)
join    dba_hist_sqltext st
        on (st.sql_id = sh.sql_id)
        -- Put your SQL selection here ...
where   upper(st.sql_text) like '%DELETE%'
and     sh.optimizer_cost is not null
and     sh.executions_delta <> 0
        -- Limit the start date/time here ...
and     ss.begin_interval_time >= to_timestamp('28-03-2018 22:00:00','dd-mm-yyyy hh24:mi:ss')
order   by sh.snap_id desc;