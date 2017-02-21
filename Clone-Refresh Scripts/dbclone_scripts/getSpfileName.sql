set heading off lines 100 trimspool on pages 3000 echo off feed off

whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode

-- A script to fetch the SPFILE name for this databse.
-- Used by the dbClone script to make sure that the TARGET_DB 
-- is correctly using an SPFILE or the clone will not work.
--
-- To call this in a cmd session use one % sign:
-- for /f "delims=" %a in ('sqlplus -s sys/ForConfig2lock as sysdba @getHostName') do @set spfile_name=%a
-- echo spfile_name
--
--
-- To call it in a batch file use two % signs (go Windoze!):
-- for /f "delims=" %%a in ('sqlplus -s sys/ForConfig2lock as sysdba @getHostName') do @set spfile_name=%%a
--
-- Norman Dunbar. 
-- June 2016.
--

var spfile_name varchar2(500)

begin
select upper(trim(value))
into :spfile_name 
from v$parameter
where name = 'spfile';
end;
/

print spfile_name 
exit 0
