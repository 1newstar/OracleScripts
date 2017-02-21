-- This script drops two XML based tables and the cascaded of user defined
-- types used to create them. This should allow the data in these tables to 
-- be imported, which at present, it does not.
-- 
-- This script should be run as part of the post_import_norows.sql script,
-- but most defuibnitely before the various row impoprts are started.
--
-- Norman Dunbar.
-- August/September 2016.
--
-- Workaround for an Ortacle bug, that they have not fixed in 11.2.0.4.
--

set lines 2000 pages 2000 trimspool on

spool drop_xml_stuff.lst

drop table fcs."UKFATCASubmissionFIRe98_TAB" cascade constraints purge;
drop table fcs.xml_fatca_reports cascade constraints purge;
drop type fcs."UKFATCASubmissionFIRepo97_T" force;
drop type fcs."SubmissionType94_T" force;
drop type fcs."ReplaceMessageType93_T" force;
drop type fcs."MessageDataType96_T" force;
drop type fcs."FIReturn95_COLL" force;
drop type fcs."FIReturnType90_T" force;
drop type fcs."VoidMessageType89_T" force;

spool off