set pages 3000 lines 2000 trimspool on
set serverout on size 1000000

spool disable_triggers.lst

declare
    type ttriggers is table of dba_triggers.trigger_name%type index by pls_integer;
    
    trigger_names ttriggers;
    
begin
    select trigger_name
    bulk collect into trigger_names  
    from dba_triggers 
    where owner in ('FCS', 'OEIC_RECALC')
    order by 1;
  
    for x in 1 .. trigger_names.count loop
		begin
			execute immediate 'alter trigger fcs.' || trigger_names(x) || ' disable';
			--dbms_output.put_line('Trigger FCS.' || trigger_names(x) || ' disabled.');
		exception
			when others then
				dbms_output.put_line('Failed to disable trigger fcs.' || trigger_names(x));
		end;
    end loop;
  
end;
/

spool off