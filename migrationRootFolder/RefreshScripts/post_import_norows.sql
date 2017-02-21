@@grants.sql
@@recompile.sql
@@disable_triggers.sql
@@workarounds.sql
@@drop_xml_stuff.sql

-- This user is not required any more.
drop user discadmin cascade;

-- Make sure no audit_log or alert_log updates take place
-- Something is updating these during the imports!
drop package fcs.table_audit;
drop package fcs.pk_alerts;

-- Make sure we don't bother with  the old 9i materialised view tables.
drop table fcs.investor_mv cascade constraints purge;
drop table fcs.ordtran_mv cascade constraints purge;

-- And just in case we have an 11g MLOG$ table lying around, drop that too.
drop table fcs.MLOG$_ORDTRAN cascade constraints purge;
drop table fcs.MLOG$_INVESTOR cascade constraints purge;

-- The next job must be last and will exit.
@@drop_fcs_jobs.sql

