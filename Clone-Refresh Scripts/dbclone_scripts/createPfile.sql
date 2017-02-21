set heading off lines 100 trimspool on pages 3000 echo off feed off

whenever oserror exit oscode
whenever sqlerror exit sql.sqlcode

-- A script to create a PFILE for the database from the current SPFILE.
-- Used by the dbClone script to make sure that the AUXILIARY_DB 
-- is ready to be refreshed.
--
-- Norman Dunbar. 
-- June 2016.
--
create pfile='&1' from spfile='&2';
exit 0