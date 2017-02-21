BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'JISA_18Bday_Conversion'
      ,start_date      => trunc(sysdate)+23/24
      ,repeat_interval => 'FREQ=daily;byhour=23'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'PLSQL_BLOCK'
      ,job_action      => 'BEGIN
    FCS.MESSAGE_LOGGER.P_WRITE_LOG(''I'',''pk_jisa_18_birthday_convert'',1,''STARTED Running JISA Conversion'');
    FCS.pk_jisa_18_birthday_convert.jisa_conversion_Job();
    FCS.MESSAGE_LOGGER.P_WRITE_LOG(''I'',''pk_jisa_18_birthday_convert'',1,''FINISHED Running JISA Conversion'');
EXCEPTION WHEN OTHERS THEN
    FCS.MESSAGE_LOGGER.P_WRITE_LOG(''I'',''pk_jisa_18_birthday_convert'',1,''JOB FAILED : '' || SQLERRM (SQLCODE));
END;'
      ,comments        => NULL
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'RESTARTABLE'
     ,value     => TRUE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_FULL);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 3);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'JISA_18Bday_Conversion'
     ,attribute => 'AUTO_DROP'
     ,value     => FALSE);

-- Don't enable just yet ....
--  SYS.DBMS_SCHEDULER.ENABLE
--    (name                  => 'JISA_18Bday_Conversion');

END;
/