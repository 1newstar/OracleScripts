-- Create a schedule to gather stats on Sunday at 18:00
-- Used by the STATSGEN scheduler job, which is also created.
--
-- Must be run as SYS.

-- Create Error Log table for STATSGEN job.
create table sys.statsgen_errors(
    owner varchar2(30),
    table_name varchar2(30),
    error_code number,
    error_text varchar2(500)
) tablespace cfa;    
                                

-- Create Log table for STATSGEN job.
create table sys.expire_password_log(
    username varchar2(30),
    action varchar2(30),
    error_code number,
    error_text varchar2(500)
) tablespace cfa;    

create table sys.utmsodrm_errors(
    owner varchar2(30),
    table_name varchar2(30),
    error_code number,
    error_text varchar2(500)
) tablespace cfa;    
                                

-- Create Schedules.
begin
    -- One for Stats Gathering. Sunday at 18:00.
    dbms_scheduler.create_schedule(
        schedule_name => 'SUNDAY_1800',
        repeat_interval => 'freq=weekly;byday=sun;byhour=18;byminute=0',
        comments => 'Schedule to collect statistics every Sunday at 18:00'
    );
end;
/
    
begin
    -- One for Password Expires, truncates etc. Daily at 20:20.
    dbms_scheduler.create_schedule(
        schedule_name => 'DAILY_2020',
        repeat_interval => 'freq=daily;byhour=20;byminute=20',
        comments => 'Schedule to expire passwords, truncate tables every day at 20:20'
    );
end;
/

-- Scheduler job for stats gathering.    
begin    
    dbms_scheduler.create_job(
        job_name => 'STATSGEN',
        job_type => 'STORED_PROCEDURE',
        job_action => 'sys.solaris_cronjobs.statsgen',
        schedule_name => 'SUNDAY_1800',
        enabled => true
    );


  dbms_scheduler.set_attribute
    ( name => 'STATSGEN'
     ,attribute => 'RESTARTABLE'
     ,value => true);

  dbms_scheduler.set_attribute
    ( name => 'STATSGEN'
     ,attribute => 'LOGGING_LEVEL'
     ,value => sys.dbms_scheduler.logging_full);
     
  dbms_scheduler.enable
    (name => 'STATSGEN');

end;
/

-- Scheduler job for expiring passwords.
begin    
    dbms_scheduler.create_job(
        job_name => 'EXPIRE_PASSWORDS',
        job_type => 'PLSQL_BLOCK',
        job_action => 'begin sys.solaris_cronjobs.expire_passwords(''APP_USER'', 30, 30); end;',
        schedule_name => 'DAILY_2020',
        enabled => true
    );


  dbms_scheduler.set_attribute
    ( name => 'EXPIRE_PASSWORDS'
     ,attribute => 'RESTARTABLE'
     ,value => true);

  dbms_scheduler.set_attribute
    ( name => 'EXPIRE_PASSWORDS'
     ,attribute => 'LOGGING_LEVEL'
     ,value => sys.dbms_scheduler.logging_full);
     
  dbms_scheduler.enable
    (name => 'EXPIRE_PASSWORDS');

end;
/

-- Scheduler job for truncating tables.
begin    
    dbms_scheduler.create_job(
        job_name => 'UTMSODRM',
        job_type => 'STORED_PROCEDURE',
        job_action => 'sys.solaris_cronjobs.endofday_utmsodrm',
        schedule_name => 'DAILY_2020',
        enabled => true
    );


  dbms_scheduler.set_attribute
    ( name => 'UTMSODRM'
     ,attribute => 'RESTARTABLE'
     ,value => true);

  dbms_scheduler.set_attribute
    ( name => 'UTMSODRM'
     ,attribute => 'LOGGING_LEVEL'
     ,value => sys.dbms_scheduler.logging_full);
     
  dbms_scheduler.enable
    (name => 'UTMSODRM');

end;
/

