drop trigger logon_trigger;

create or replace trigger logon_trigger 
after logon on cfgwebportal.schema
begin
    execute immediate 'alter session set tracefile_identifier = ''JOE''';
    execute immediate 'alter session set events ''10046 trace name context forever, level 12''';
exception
    -- Ignore all exceptions, in case we barf the database.
    when others then null;    
end;
/

