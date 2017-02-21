set heading off lines 100 trimspool on pages 3000 echo off feed off

-- A script to NOMOUNT the database using a PFILE.
-- Used by the dbClone script to make sure that the AUXILIARY_DB 
-- is ready to be refreshed.
--
-- Norman Dunbar. 
-- June 2016.
--
startup force nomount pfile='&1'
exit 0