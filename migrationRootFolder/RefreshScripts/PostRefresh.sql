set lines 2000 pages 3000 trimspool on
set echo on
spool PostRefresh.lst

-- Make sure auditing is as per current production.
-- Needs a restart to work.
alter system set audit_sys_operations=true scope=spfile;
alter system set audit_trail='DB' scope=spfile;

-- Make sure all FCS etc tables have extents allocated in case
-- we need to export with 9i software for a reversion of the migration.
@RefreshScripts\allocate_extents

shutdown immediate;
startup mount;

alter database archivelog;
alter database flashback on;
alter database open;

archive log list;

spool off

exit
