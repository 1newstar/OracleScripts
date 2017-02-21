-- Generate extents for empty tables. Required in the event that we ever
-- have to export with 9i client to revert back to 9i on Solaris.
-- Which is unlikely, but .....

set serverout on size unlimited
set lines 2000 trimspool on pages 3000
spool deferred_segments.lst

declare
    vSQL varchar2(350);

begin
        for x in (
            SELECT owner, table_name
            FROM dba_tables
            WHERE segment_created = 'NO'
            and table_name not like 'SYS_NT%'
            --================================================================
            -- The following list must match the NOROWS export list of OWNERS
            -- and must include also the FCS schema.
            --================================================================
            AND owner in (
                'CMTEMP','FCS','ITOPS','LEEDS_CONFIG','OEIC_RECALC','UVSCHEDULER','IBASHIR',
                'JRICHARDSON1','PPHILLIPS','SMAHALA','TAKEON_ARCH_GLO','TAKEON_CF_INVESTEC',
                'TAKEON_MITON','TAKEON_PANTHER','TAKEON_PENNINE','TAKEON_WAY','TAKEON_WOOD_ST'
            )
            ORDER by 1
        ) loop
            vSQL := 'alter table ' || x.owner || '.' || x.table_name || ' allocate extent';
            begin
                execute immediate vSQL;
            exception
                when others then
                    dbms_output.put_line('FAILED: ' || vSQL);
            end;
        end loop;
end;
/

-- The one exception. This table is not in DBA_TABLES!
alter table fcs."UKFATCASubmissionFIRe98_TAB" allocate extent;

spool off
