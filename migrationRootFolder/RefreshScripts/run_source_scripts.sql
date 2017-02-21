
spool create_users_and_roles.lst
@Scripts\T110_CREATE_USERS_AND_ROLES
spool off


spool create_tablespace_quotas.lst
@Scripts\T120_CREATE_TABLESPACE_QUOTAS
spool off


spool create_system_privs.lst
@Scripts\T130_CREATE_SYSTEM_PRIVS
spool off


spool create_proxies.lst
@Scripts\T140_CREATE_PROXIES
spool off


spool create_roles.lst
@Scripts\T150A_CREATE_ROLES
spool off

-- No longer required. Directories are not used on Production.
--spool create_dirs.lst
--@Scripts\T155A_CREATE_DIRS
--spool off

-- This is needed to avoid all the external tables barfing.
-- Will be removed by a later script which deletes the externals.
CREATE OR REPLACE DIRECTORY THREAD_EXT_TABLES AS 'c:\any\old\rubbish\here'; 


-- No longer required. Directories are not used on Production.
--spool create_dirs.lst
--spool grant_dirs.lst
--@Scripts\T155B_GRANT_DIRS
--spool off


-- No longer required. These Libraries are not being used in Azure Production.
--spool create_libs.lst
--@Scripts\T155C_CREATE_LIBS
--spool off

exit