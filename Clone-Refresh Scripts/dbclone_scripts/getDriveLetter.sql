set heading off lines 100 trimspool on pages 3000 echo off feed off

whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode

-- A script to fetch the drive letter from the SYSTEM tablespace's first file.
-- Used by the dbClone script to make sure that the source and destination
-- databases are on the correct drives.
--
-- To call this in a cmd session use one % sign:
-- for /f "delims=" %a in ('sqlplus -s sys/ForConfig2lock as sysdba @getdriveletter') do set drive_letter=%a
-- echo drive_letter
--
--
-- To call it in a batch file use two % signs (go Windoze!):
-- for /f "delims=" %%a in ('sqlplus -s sys/ForConfig2lock as sysdba @getdriveletter') do set drive_letter=%%a
--
-- Norman Dunbar. 
-- June 2016.
--

var drive_letter char(1)

begin
select substr(file_name, 1, 1)
into :drive_letter 
from dba_data_files
where file_id=1
and file_name like '_:%';
exception
  when others then
     select '?' into :drive_letter from dual;
end;
/

print drive_letter 
exit 0
