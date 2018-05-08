set lines 2000 trimspool on
set pages 2000
set echo on
set verify off
set define off

spool dailystats_rollback.log

-- Wipe everything.
drop package dba_user.pkg_dailystats;
drop table dba_user.daily_stats_exclusions purge;
drop table dba_user.daily_stats_log purge;
drop sequence dba_user.daily_stats_log_seq;

-- And and (new) grants.
revoke select on dba_tab_statistics from dba_user;
revoke analyze any from dba_user;

-- Commented out as some databases already had this.
--revoke create job to dba_user; 

spool off

set verify on
set define &