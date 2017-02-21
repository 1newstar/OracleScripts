@@grants.sql
@@gather_stats.sql
--@@logging.sql
@@recompile.sql
@@materialised_views.sql
@@DropExternalTables.sql

spool post_import_rows.lst

alter system set undo_retention=43200 scope=both;

-- DO NOT DO THIS ON PRODUCTION !! --
/*
column db_name new_value my_dbname noprint;
select name as db_name from v$database;
alter role NORMAL_USER identified by &&my_dbname.123;
alter role SVC_AURA_SERV_ROLE identified by &&my_dbname.123;
alter system set service_names='&&my_dbname' scope=both;
alter system set instance_name='&&my_dbname' scope=spfile;
*/

@@uvscheduler_role.sql
@@svc_aura_serv_create_session.sql

grant select on sys.v_$DATABASE to itops; 
grant select any table, 
      select any sequence, 
      execute any procedure to database_reader_uv;

grant create session to comms_role;

-- The following should negate the need for SCV_AURA_SERV_ROLE
-- to "need" EXECUTE_ANY_PROCEDURE whihc is present on 9i but
-- DOES NOT get transferred to 11g for some reason.
-- See Staurt Worswick for details.
grant execute on FCS. F_GET_HIST_HOLDING_VALUE to SVC_AURA_SERV_ROLE ;
grant execute on FCS.F_HOLDING_TILL_DATE  to SVC_AURA_SERV_ROLE ;

spool off

-- Make sure that the 11g database uses Quick Address.
@@11g-QAS.sql
