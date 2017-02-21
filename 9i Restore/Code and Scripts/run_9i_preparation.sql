-- Build a script to recreate the 9i privileges, some may be missing in 11g.
@@generate_9i_privileges.sql

-- Now do the other stuff.
set lines 2000 pages 2000 trimspool on
set serverout on size 1000000    
set echo off

spool run_9i_preparation.lst

drop snapshot log on fcs.investor;
drop snapshot log on fcs.ordtran;

drop materialized view fcs.investor_cat_mv;
drop materialized view ordtran_mv;



declare

    --=====================================================================
    -- Helper routines. Called from main code below.
    --=====================================================================

    procedure JustDoIt(vSQL in varchar2) 
    as
    begin
        -- For debugging ease, comment out the execute and uncomment
        -- the dbms_output line.
        execute immediate vSQL;        
        --dbms_output.put_line(vSQL);
                        
    exception
        when others then
            dbms_output.put_line('FAILED: ' || to_char(sqlcode) || ' ' || vSQL);
    end;
    
    
    procedure DropAllTables(
            iOwner in dba_tables.owner%type
        )
    as
        vSQL varchar2(1024);
        
    begin
        -- Drop all tables, indexes, triggers for same, and LOBs.
        for x in (select table_name
                  from dba_tables
                  where owner = iOwner
                  and temporary <> 'Y'
                  -- Tables with mixed case names are an abomination!
                  and upper(table_name ) not in ('UKFATCASUBMISSIONFIRE98_TAB','XML_FATCA_REPORTS')
                  and (owner,table_name) not in (
                        select owner, table_name 
                        from dba_external_tables)
                  )
        loop
            -- Use double quotes everywhere here as there are case sensitive
            -- table names. Sigh!
            vSQL := 'drop table ' || iOwner || '."' || x.table_name || '" ' ||
                    'cascade constraints';
                    
            JustDoIt(vSQL);

        end loop;
    end;

    
    --=====================================================================
    procedure DropAllOtherObjects(
            iOwner in dba_objects.owner%type
        )
    as
        vSQL varchar2(1024);
        
    begin
        -- Drop all remaining objects.
        for x in (select object_type, object_name
                  from   dba_objects
                  where  object_type not in ('TABLE','INDEX', 'TYPE','TYPE_BODY','PACKAGE BODY','DATABASE LINK', 'LOB')
                  and    owner = iOwner)
        loop
            vSql := 'drop ' || x.object_type || ' ' || iOwner || '."' ||
                    x.object_name || '" ' ||
                    case x.object_type
                        when 'TYPE' then 'force '
                    end;
                    
            JustDoIt(vSQL);                   
        end loop;
    end;

    
    --=====================================================================

    
--=========================================================================
-- Main code starts here...
--=========================================================================
begin

    -- Truncate the two XML FCS tables.
    JustDoIt('truncate table FCS.XML_FATCA_REPORTS');
    JustDoIt('truncate table FCS."UKFATCASubmissionFIRe98_TAB"');

    -- Lose the MVs.
    JustDoIt('drop materialized view FCS.ORDTRAN_MV');
    JustDoIt('drop materialized view FCS.INVESTOR_CAT_MV');    

    for x in (select username as owner from (
              --
              -- Make sure this matches the NOFCS export parameter file.
              -- And that FCS is also present.
              --
                    select 'FCS' as username from dual union all
                    select 'CMTEMP' from dual union all
                    select 'ITOPS'  from dual union all
                    select 'LEEDS_CONFIG'  from dual union all
                    select 'OEIC_RECALC'  from dual union all
                    select 'UVSCHEDULER'  from dual union all
                    select 'IBASHIR'  from dual union all
                    select 'JRICHARDSON1'  from dual union all
                    select 'PPHILLIPS'  from dual union all
                    select 'SMAHALA'  from dual union all
                    select 'TAKEON_ARCH_GLO'  from dual union all
                    select 'TAKEON_CF_INVESTEC'  from dual union all
                    select 'TAKEON_MITON'  from dual union all
                    select 'TAKEON_PANTHER'  from dual union all
                    select 'TAKEON_PENNINE'  from dual union all
                    select 'TAKEON_WAY'  from dual union all
                    select 'TAKEON_WOOD_ST'  from dual
                )
    ) loop
        
        -- Disable constraints.
        DropAllTables(
            iOwner => x.owner
        );    
        
        -- Drop *most* of the remaining objects.
        -- Keep the XML table indexes, TYPEs etc.
        DropAllOtherObjects(
            iOwner => x.owner
        );
            
        -- The above may not work completely on the first trip through.
        -- Drop *most* remaining remaining objects!
        DropAllOtherObjects(
            iOwner => x.owner
        );
               
    end loop;
    
end;
/    

spool off