create or replace trigger azdba_service_trigger 
after startup on database
declare
    v_role V$DATABASE.DATABASE_ROLE%TYPE;

begin
    --===================================================
    -- Make sure we only start the AZDBA_SERVICE on this
    -- database if it is running as the primary database.
    --===================================================
    select  database_role 
    into    v_role 
    from    v$database;

    if (v_role = 'PRIMARY') then
        dbms_service.start_service('AZDBA_SERVICE');
    else
        dbms_service.stop_service('AZDBA_SERVICE');
    end if;
end;
/