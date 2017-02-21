spool T030_CREATE_REDO_LOG_GROUPS_results.lis

-- create new logfile groups and members

Alter database add logfile group  4 ('??:\mnt\oradata\ORACLE_SID\redo4a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo4b.log')  size 100m reuse;
Alter database add logfile group  5 ('??:\mnt\oradata\ORACLE_SID\redo5a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo5b.log')  size 100m reuse;
Alter database add logfile group  6 ('??:\mnt\oradata\ORACLE_SID\redo6a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo6b.log')  size 100m reuse;
Alter database add logfile group  7 ('??:\mnt\oradata\ORACLE_SID\redo7a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo7b.log')  size 100m reuse;
Alter database add logfile group  8 ('??:\mnt\oradata\ORACLE_SID\redo8a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo8b.log')  size 100m reuse;
Alter database add logfile group  9 ('??:\mnt\oradata\ORACLE_SID\redo9a.log' ,
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo9b.log')  size 100m reuse;
Alter database add logfile group 10 ('??:\mnt\oradata\ORACLE_SID\redo10a.log',
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo10b.log') size 100m reuse;
Alter database add logfile group 11 ('??:\mnt\oradata\ORACLE_SID\redo11a.log',
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo11b.log') size 100m reuse;
Alter database add logfile group 12 ('??:\mnt\oradata\ORACLE_SID\redo12a.log',
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo12b.log') size 100m reuse;
Alter database add logfile group 13 ('??:\mnt\oradata\ORACLE_SID\redo13a.log',
                                     '!!:\mnt\fast_recovery_area\ORACLE_SID\redo13b.log') size 100m reuse;
-- Switch until they became active ;
Alter system switch logfile;
Alter system switch logfile;
Alter system switch logfile;
Alter system checkpoint;

set lines 2000 pages 2000 trimspool on

select * from v$log;
                                    
--Drop old one :
Alter database drop logfile group 1;
Alter database drop logfile group 2;
Alter database drop logfile group 3;


set pages 50 lines 150
col FSIZE Head 'Size in Mb'
col member format a70
compute sum of FSIZE on report

break on report

SELECT a.group#, a.member, b.bytes/1024/1024 FSIZE
FROM v$logfile a, v$log b 
WHERE a.group# = b.group#;

spool off

