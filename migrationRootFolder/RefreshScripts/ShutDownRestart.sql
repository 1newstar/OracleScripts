set lines 2000 pages 3000 trimspool on
set echo on
spool ShutDownRestart.lst

shutdown immediate;
startup mount;
alter database flashback off;
alter database noarchivelog;
alter database open;
archive log list;

spool off

--exit

