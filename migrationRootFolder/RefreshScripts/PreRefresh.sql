set lines 2000 pages 3000 trimspool on
set echo on
set serverout on size unlimited

@Refreshscripts\T060_CREATE_VERIFY_FUNCTION
spool create_profiles.lst
@Scripts\T100_CREATE_PROFILES
spool off

spool PreRefresh.lst

drop user leeds_config cascade;
create user LEEDS_CONFIG identified by values '9C7B27D7D68FA027' default tablespace USERS temporary tablespace TEMP profile LEEDS_CONFIG_PROFILE account unlock;

drop user cmtemp cascade;
create user CMTEMP identified by values '7ACAE695010ABFFC' default tablespace USERS temporary tablespace TEMP profile APP_USER account unlock;

drop user itops cascade;
create user ITOPS identified by values '2DD9A863242E95E8' default tablespace USERS temporary tablespace TEMP profile DEFAULT account unlock;

drop user onload cascade;
create user ONLOAD identified by values 'B084F4B16F4BD3CA' default tablespace TAKEON temporary tablespace TEMP profile DEFAULT account unlock;

drop user uvscheduler cascade;
create user UVSCHEDULER identified by values '4CAB486961F07A50' default tablespace CFA temporary tablespace TEMP profile UVPROFILE account unlock;

drop user fcs cascade;
create user FCS identified by devenv default tablespace UVDATA01 temporary tablespace TEMP profile DEFAULT account unlock;

drop user oeic_recalc cascade;
create user OEIC_RECALC identified by values '08F2E1B5CB93F274' default tablespace CFA temporary tablespace TEMP profile DEFAULT account unlock;

spool off



@@grants.sql
@@DropPublicDBLinks.sql

set echo off

prompt **********************************************
prompt The following may fail. If it does, worry not.
prompt Either fix it and rerun manually, or...
prompt Fix the path to the script!
prompt **********************************************

spool T095_recreatePublic_DB_links.lst
@scripts\T095_recreatePublic_DB_links.sql
spool off

@@drop_old_users.sql
@@run_source_scripts.sql

--exit