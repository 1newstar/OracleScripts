set lines 2000 pages 3000 trimspool on
set echo on
spool grants.lst

@@CMTEMP_grants.sql
@@FCS_grants.sql
@@ITOPS_grants.sql
@@LEEDS_CONFIG_grants.sql
@@OEIC_RECALC_grants.sql
@@ONLOAD_grants.sql
@@UVSCHEDULER_grants.sql

spool off
