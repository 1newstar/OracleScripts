create or replace procedure dba_user.frkControl (
    piOwner in all_constraints.owner%type,                      -- Who owns this table?
    piTableName in all_constraints.table_name%type,             -- Which table?
    piConstraintName in all_constraints.constraint_name%type,   -- Which constraint?
    piAction in varchar2                                        -- Enable or disable.
)

    --------------------------------------------------------------------------------------
    -- A procedure to replace explicit calls to ALTER TABLE which required ALTER ANY TABLE
    -- privileges, which are no longer allowed. This code explicitly checks for PNET or
    -- PNET_COL_PRD as the schema name (aka owner) when called. 
    -- It simply allows the caller to enable or disable a referential integrity constraint
    -- by name, as part of the FRK.KSH "application". 
    --------------------------------------------------------------------------------------
    -- Author:       Norman Dunbar
    -- Date Created: 22 March 2018.
    -- Description:  Created for Rob Tomkins & Karl Voros.
    --------------------------------------------------------------------------------------
    -- Amendment History.
    --
    -- Author:
    -- Date Created:
    -- Description:
    --------------------------------------------------------------------------------------
    
    AUTHID DEFINER                                              -- Run as DBA_USER.
is
    -- Validated parameters.
    vOwner all_constraints.owner%type;
    vTableName all_constraints.table_name%type;
    vConstraintName all_constraints.constraint_name%type;
    vAction varchar2(10);
    
    -- Anything else needed?
    vError boolean;
    vSQL varchar2(500);
    
    -- Constants for parameter errors.
    cParameterError constant number := -20001;
    cParameterMessage constant varchar2(50) := 'One or more parameters are invalid.';
        
    -- Helper Routine(s).
    procedure raiseError (
        piErrorCode in number,
        piMessage in varchar2
    ) is
    begin
        raise_application_error(piErrorCode, piMessage);
    end; 
    
begin
    -- Validate parameters.
    vError := false;
    
    -- Schema name, owner of table.
    vOwner := upper(piOwner);
    if (vOwner is null) then
        vError := true;
    end if;
    
    if (vOwner not in ('PNET', 'PNET_COL_PRD')) then
        vError := true;
    end if;
    
    -- Tablename is uppercase.
    vTableName := upper(piTableName);
    if (vTableName is null) then
        vError := true;
    end if;
    
    -- Constraint name is upper case.
    vConstraintName := upper(piConstraintName);
    if (vConstraintName is null) then
        vError := true;
    end if;
    
    -- Action is upper case, and must be ENABLE or DISABLE.
    vAction := upper(nvl(piAction, 'X'));
    if (vAction not in ('ENABLE','DISABLE')) then
        vError := true;
    end if;    
    
    -- Any parameter errors detected?    
    if (vError) then
        raiseError(cParameterError, cParameterMessage);
    end if;

    -- Build the SQL statement to be executed.
    vSQL := 'alter table ' || vOwner || '.' || vTableName || ' ' ||
            vAction || ' constraint ' || vConstraintName;

    -- Execute the SQL and catch any exceptions. These could be invalid SQL
    -- or invalid owners, tables, constraint names or no privileges to actually
    -- do the enabling.
    begin
        execute immediate vSQL;
        dbms_output.put_line(vSQL);
    exception
        when others then
            -- Simply abort, passing the exception out to the caller.
            raise;
    end;
    
end;
/

-- Create private synonyms for permitted callers.
create or replace synonym pnet.frkcontrol for dba_user.frkcontrol;
create or replace synonym pnet_col_prd.frkcontrol for dba_user.frkcontrol;
create or replace synonym colservice.frkcontrol for dba_user.frkcontrol;
create or replace synonym corebatch.frkcontrol for dba_user.frkcontrol;

-- Grants to the permitted callers.
grant execute on dba_user.frkControl to pnet;
grant execute on dba_user.frkControl to pnet_col_prd;
grant execute on dba_user.frkControl to corebatch;
grant execute on dba_user.frkControl to colservice;

