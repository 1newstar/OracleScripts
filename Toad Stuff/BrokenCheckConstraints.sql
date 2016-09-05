-- Create some SQL to check the data for broken check constraints.
-- Things created by "... check(column_name in ('Y','N',NULL))"
-- Which we know just doesn't work.
-- Norman Dunbar.


-- Can't filter search_condition as it's a LONG data type.
create global temporary table check_constraints on commit preserve rows
as (
    select owner, table_name, constraint_name, to_lob(search_condition) as search_condition
    from dba_constraints
    where owner = 'FCS' and constraint_type = 'C'
) ;

-- Get rid of the dross.
delete from check_constraints
where upper(search_condition) not like '%IN%,%NULL%';

-- And the other two that are ok.
delete from check_constraints
where constraint_name like 'SERVICE_CONFIG_C0%';
commit;

-- Should be 21 rows here (AZPPD03)
select * from check_constraints;

-- Build SQL Script to check tables affected.
set lines 2000 trimspool on
set pages 2000
set serverout on size 1000000

declare
    column user_tab_columns.column_name%type;
    in_values varchar2(50);
    
begin
    for x in (select table_name as tn, search_condition as sc from check_constraints) loop
        -- Extract the column_name
        column := substr(x.sc, 1, instr(upper(x.sc), ' IN') -1);        
        
        
        -- Extract the correct values.
        in_values := substr(x.sc, instr(x.sc, '('));
        in_values := replace(upper(in_values), ',NULL', null);
        
        dbms_output.put_line('select ' || column || ', count(*) from ' || x.tn || ' where ' || column || ' not in ' || in_values || ' group by ' || column || ' order by ' || column ||';');   

    end loop;

end;
/



-- When done, run these to tidy up.
truncate table check_constraints;
drop table check_constraints purge;




