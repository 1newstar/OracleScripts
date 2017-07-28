set lines 2000 trimspool on pages 2000

spool PGAKillerSchedule.log

begin
    sys.dbms_scheduler.drop_job(job_name => 'SYS.PGA_SESSION_KILLER', force => true);
end;
/    

BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'SYS.PGA_SESSION_KILLER'
      ,start_date      => TO_TIMESTAMP_TZ('2017/07/06 15:00:00.000000 +01:00','yyyy/mm/dd hh24:mi:ss.ff tzr')
      ,repeat_interval => 'FREQ=MINUTELY;INTERVAL=30'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'PLSQL_BLOCK'
      ,job_action      => 'BEGIN
SYS.PGASESSIONKILLER
  (PIMODULE => ''Report Execution'' ,
   PIPROGRAM => ''dya141mr.exe'' ,
   PISECONDS => 1800 ,
   PIDOKILL => true  );
END;'
      ,comments        => 'This job will check for any stuck sessions and kill them.
The session''s being killed will be logged to the alert.log and to the
trace file for the scheduler session.'
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'RESTARTABLE'
     ,value     => TRUE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_FULL);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 3);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.PGA_SESSION_KILLER'
     ,attribute => 'AUTO_DROP'
     ,value     => FALSE);

  SYS.DBMS_SCHEDULER.ENABLE
    (name       => 'SYS.PGA_SESSION_KILLER');
END;
/

spool off