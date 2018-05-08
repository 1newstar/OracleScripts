--------------------------------------------------------------------------
-- A script to check out parallel query potential problems where we are
-- getting downgrades - ie requested 32 parallel servers, got none - which
-- is causing performance problems on the ETL runs.
--
-- Norman Dunbar
-- 21 February 2018
--------------------------------------------------------------------------
--
-- Execute this as a script (F5) in Toad, or SQLDeveloper (if you must!)
--
--------------------------------------------------------------------------

set lines 2000 trimspool on
set pages 2000

--------------------------------------------------------------------------
-- Who is running parallel queries?
--------------------------------------------------------------------------
prompt ==========================================
prompt Who is currently running parallel queries?
prompt ==========================================
prompt " "
select 
    decode(px.qcinst_id,NULL,username, 
        ' - '||lower(substr(s.program,length(s.program)-4,4) ) ) as username, 
    decode(px.qcinst_id,NULL, 'QC', '(Slave)') as qc_slave, 
    to_char( px.server_set) as slave_set, 
    to_char(s.sid) as SID, 
    decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) as QC_SID, 
    px.req_degree as Requested_DOP, 
    px.degree as Actual_DOP
from 
    v$px_session px, 
    v$session s 
where 
    px.sid=s.sid (+) 
and 
    px.serial#=s.serial# 
order by qc_sid , username desc;

--------------------------------------------------------------------------
-- Just the query coordinators. Lose the slaves.
--------------------------------------------------------------------------
prompt ==========================================
prompt    Query Coordinators Only, With DOP.
prompt ==========================================
prompt " "
with all_parallel_sessions as (
    select 
        decode(px.qcinst_id,NULL,username, 
            ' - '||lower(substr(s.program,length(s.program)-4,4) ) ) as username, 
        decode(px.qcinst_id,NULL, 'QC', '(Slave)') as qc_slave, 
        to_char( px.server_set) as slave_set, 
        to_char(s.sid) as SID, 
        decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) as QC_SID, 
        avg(px.req_degree) over (partition by px.qcsid, px.server_set) as Requested_DOP, 
        avg(px.degree) over (partition by px.qcsid, px.server_set) as Actual_DOP
    from 
        v$px_session px, 
        v$session s 
    where 
        px.sid=s.sid (+) 
    and 
        px.serial#=s.serial# 
    --order by 5 , 1 desc
),
--
just_slaves as (
    select  distinct qc_sid, requested_dop, actual_dop
    from    all_parallel_sessions   
    -- Miss out the QC sessions.
    where   requested_dop is not null
)
select  a.username, a.qc_sid, s.requested_dop, s.actual_dop
from    all_parallel_sessions a
join    just_slaves s on (s.qc_sid = a.qc_sid and a.requested_dop is null)
order by a.username,a.qc_sid;

--------------------------------------------------------------------------
-- How many parallel slaves are busy? Idle?
--------------------------------------------------------------------------
prompt ==========================================
prompt      Status of Slave Sessions.
prompt ==========================================
prompt " "
select status,count(*) from v$pq_slave group by status;

--------------------------------------------------------------------------
-- Any Downgrades? Could be a bug. Could be due to PARALLEL_MAX_SERVERS
-- defaulting too low, or being set too low.
--------------------------------------------------------------------------
prompt ==========================================
prompt  Any Sessions Which Have Been Downgraded?
prompt ==========================================
prompt " "
select * from (
    select  px.qcsid as Query_Coordinator,
            px.server_set as slave_set,
            avg(px.req_degree) as requested,
            avg(px.degree) as actual
    from    v$px_session px
    where   px.server_set is not null
    group   by qcsid, server_set
) where requested <> actual;