set lines 2000 trimspool on
set pages 2000
set echo on
set verify off
set define off

spool dailystats_control.log

-- Create exclusions table.
@@dailystats_exclusions.sql

-- Create the logging table
@@dailystats_logging.sql

-- We need these privileges before the package is compiled.
grant select on dba_tab_statistics to dba_user;
grant analyze any to dba_user;
grant   create job to dba_user; 

-- Create package and package body.
@@pkg_dailystats.pks

--Create package and package body.
@@pkg_dailystats.pkb

-- Let the DBAs use it.
grant   execute on dba_user.pkg_dailystats
to      /* ROLE */  dba, 
        /* USERS */ fowleyjam, williamsrhy, hibbertant, dunbarnor;
        
-- Load up users we wish to ignore.
@@load_exclusions.sql

spool off

set verify on
set define &
