set heading off lines 100 trimspool on pages 3000 echo off feed off

whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode

-- A script to fetch the server name for this databse.
-- Used by the dbClone script to make sure that the NOFILENAMECHECK parameter
-- is correctly set according to the database hosts.
--
-- To call this in a cmd session use one % sign:
-- for /f "delims=" %a in ('sqlplus -s sys/ForConfig2lock as sysdba @getHostName') do set host_name=%a
-- echo drive_letter
--
--
-- To call it in a batch file use two % signs (go Windoze!):
-- for /f "delims=" %%a in ('sqlplus -s sys/ForConfig2lock as sysdba @getHostName') do set host_name=%%a
--
-- Norman Dunbar. 
-- June 2016.
--

-- Must b e the same as v$INSTANCE.HOST_NAME%TYPE:
var host_name varchar2(64)

begin
select upper(trim(host_name))
into :host_name 
from v$instance;
end;
/

print host_name 
exit 0
