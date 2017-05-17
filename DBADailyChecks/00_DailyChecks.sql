set lines 2000 trimspool on pages 20000

-- Run all the Daily Checks scripts.
alter session set nls_date_format='yyyy/mm/dd hh24:mi';

-- Where Are We?
select instance_name || ' on server ' || host_name as Database_and_Server
from v$instance;

-- If the following produces any error messages
-- you need to check with a manual run of RMANErrors.sql
-- and pass in the PARENT_RECID of the failing RMAN job.
@@RMANBackupChecks

-- We are expecting to find "NO GAP" for all the standby databases.
@@DataGuardChecks

-- Anything over 80% of max, is needing attention.
@@TablespaceFreeSpace

-- Anyone who will need a password change in the next 14 days?
@@PasswordExpiryChecks

-- Any old restore pointes that we don't want?
@@RestorePointChecks

-- How much space is used in the FRA?
@@FRAChecks
