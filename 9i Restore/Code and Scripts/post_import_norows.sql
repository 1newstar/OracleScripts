@@disable_triggers.sql
--@@drop_xml_stuff.sql

set lines 2000 trimspool on pages 0

spool post_import_norows.lst

-- Make sure no audit_log or alert_log updates take place
-- Something is updating these during the imports!
-- They will get recreated after the imports are done.
-- By the CONSTRAINTS import.
drop package fcs.table_audit;
drop package fcs.pk_alerts;

-- Make sure we don't bother with  the old 9i materialised view tables.
drop table fcs.investor_mv cascade constraints ;
drop table fcs.ordtran_mv cascade constraints ;

-- And just in case we have an 11g MLOG$ table lying around, drop that too.
drop table fcs.MLOG$_ORDTRAN cascade constraints ;
drop table fcs.MLOG$_INVESTOR cascade constraints ;

spool off


