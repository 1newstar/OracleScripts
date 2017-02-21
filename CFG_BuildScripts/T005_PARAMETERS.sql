set lines 2000 pages 2000 trimspool on
set echo on feedback on 

spool T005_PARAMETERS_results.lis

-- For details of why etc, see "Building databases after DBCA creation.docx" in TFS at
-- $TFS\TA\DEV\Projects\Oracle Upgrade 9i to 11g\UKRegulated\Database\DBA Documentation\Build Documents.

--=============================================
-- Delete Obsolete Parameters
--=============================================
-- These have indeed been deleted.
--
--AQ_TM_PROCESSES
--CURSOR_SPACE_FOR_TIME
--DB_BLOCK_BUFFERS
--FAST_START_IO_TARGET 
--LOG_ARCHIVE_START 
--MAX_ENABLED_ROLES 
--PARALLEL_AUTOMATIC_TUNING 
--PARALLEL_SERVER 
--PARALLEL_SERVER_INSTANCES 
--PLSQL_V2_COMPATIBILITY 
--REMOTE_OS_AUTHENT 
--SERIAL_REUSE 
--SQL_TRACE 


--=============================================
-- Adjust Database Usage Specific Parameters
--=============================================
-- Uncomment as required. Use either production
-- or non-production settings as appropriate.

-----------------------------------------------
-- Production Settings, or ...
-----------------------------------------------
-- alter system set sga_target=5g scope=spfile;
-- alter system set sga_max_size=6g scope=spfile;
-- alter system set pga_aggregate_target = 1g scope = spfile;     
-- alter system set db_recovery_file_dest_size=500g scope=spfile;

-----------------------------------------------
-- ... Non-production Settings
-----------------------------------------------
alter system set sga_target=2g scope=spfile;
alter system set sga_max_size=3g scope=spfile;
alter system set pga_aggregate_target = 500m scope = spfile;     
alter system set db_recovery_file_dest_size=100g scope=spfile;


--=============================================
-- Adjust Standard Parameters.
--=============================================
alter system set streams_pool_size=300m scope=spfile;
alter system set log_archive_dest_1='location=use_db_recovery_file_dest' scope=spfile;
alter system set log_archive_format='%D_%S_%R.%T.arc'scope=spfile;


--=============================================
-- ALWAYS Turn off extra cost options
-- to get around Oracle licencing sneakiness!
--=============================================
alter system set control_management_pack_access='NONE' scope=spfile;
alter system set enable_ddl_logging=false scope=both;


--=============================================
-- Everything else...
--=============================================
alter system set "_trace_files_public" = TRUE scope = spfile;        
alter system set O7_DICTIONARY_ACCESSIBILITY = TRUE scope = spfile;        
alter system set archive_lag_target = 900 scope = BOTH;        
alter system set audit_sys_operations = TRUE scope = spfile;        
alter system set audit_trail = DB scope = spfile;        
alter system set background_core_dump = partial scope = spfile;        
alter system set bitmap_merge_area_size = 1048576 scope = spfile;        
alter system set blank_trimming = FALSE scope = spfile;        
alter system set circuits = 830 scope = spfile;        
alter system set cluster_database = FALSE scope = spfile;        
alter system set cluster_database_instances = 1 scope = spfile;        
alter system set commit_point_strength = 1 scope = spfile;        
alter system set control_file_record_keep_time = 28 scope = BOTH; 
alter system set cursor_sharing = EXACT scope = BOTH;        
alter system set db_16k_cache_size = 0 scope = BOTH;        
alter system set db_2k_cache_size = 0 scope = BOTH;        
alter system set db_4k_cache_size = 0 scope = BOTH;        
alter system set db_block_checking = FALSE scope = BOTH;        
alter system set db_block_checksum = TRUE scope = BOTH;        
alter system set db_cache_advice = ON scope = BOTH;        
alter system set db_cache_size = 500m scope = BOTH;        
alter system set db_file_multiblock_read_count = 16 scope = BOTH;        
alter system set db_files = 200 scope = spfile;        
alter system set db_keep_cache_size = 0 scope = BOTH;        
alter system set db_recycle_cache_size = 0 scope = BOTH;        
alter system set db_writer_processes = 2 scope = spfile;        
alter system set dbwr_io_slaves = 0 scope = spfile;        
alter system set dg_broker_config_file1 = '?/dbs/dr1@.dat' scope = BOTH;        
alter system set dg_broker_config_file2 = '?/dbs/dr2@.dat' scope = BOTH;
alter system set dg_broker_start = FALSE scope = BOTH;
alter system set disk_asynch_io = TRUE scope = spfile;        
alter system set distributed_lock_timeout = 60 scope = spfile;        
alter system set dml_locks = 3652 scope = spfile;        
alter system set fast_start_mttr_target = 300 scope = BOTH;        
alter system set fast_start_parallel_rollback = LOW scope = BOTH;        
alter system set file_mapping = FALSE scope = BOTH;
alter system set global_names = FALSE scope = BOTH;        
alter system set hi_shared_memory_address = 0 scope = spfile;        
alter system set hs_autoregister = TRUE scope = BOTH;        
alter system set instance_number = 0 scope = spfile;        
alter system set java_max_sessionspace_size = 0 scope = spfile;        
alter system set java_pool_size = 100m scope = spfile;        
alter system set java_soft_sessionspace_limit = 0 scope = spfile;        
alter system set job_queue_processes = 10 scope = BOTH;        
alter system set large_pool_size = 16m scope = BOTH;        
alter system set lock_sga = FALSE scope = spfile;    
alter system set log_archive_dest_state_1 = ENABLE scope = BOTH;        
alter system set log_archive_dest_state_10 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_2 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_3 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_4 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_5 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_6 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_7 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_8 = DEFER scope = BOTH;        
alter system set log_archive_dest_state_9 = DEFER scope = BOTH;        
alter system set log_archive_max_processes = 4 scope = BOTH;        
alter system set log_archive_min_succeed_dest = 1 scope = BOTH;        
alter system set log_archive_trace = 0 scope = BOTH;        
alter system set log_buffer = 1572864 scope = spfile;                    
alter system set log_checkpoint_interval = 0 scope = BOTH;        
alter system set log_checkpoint_timeout = 1800 scope = BOTH;        
alter system set log_checkpoints_to_alert = FALSE scope = BOTH;        
alter system set max_dispatchers = 5 scope = spfile;        
alter system set max_dump_file_size = UNLIMITED scope = BOTH;
alter system set max_shared_servers = 20 scope = spfile;                
alter system set nls_date_format = "DD-MON-YYYY" scope = spfile;        
alter system set nls_language = AMERICAN scope = spfile;        
alter system set nls_length_semantics = BYTE scope = BOTH;        
alter system set nls_nchar_conv_excp = FALSE scope = BOTH;        
alter system set nls_territory = AMERICA scope = spfile;        
alter system set open_cursors = 300 scope = BOTH;
alter system set open_links = 4 scope = spfile;        
alter system set open_links_per_instance = 4 scope = spfile;   
alter system set optimizer_dynamic_sampling = 1 scope = BOTH;
alter system set optimizer_features_enable = "11.2.0.4" scope = spfile;
alter system set optimizer_index_caching = 0 scope = spfile;        
alter system set optimizer_index_cost_adj = 100 scope = spfile; 
alter system set os_authent_prefix = ops$ scope = spfile;        
alter system set os_roles = FALSE scope = spfile;        
alter system set parallel_adaptive_multi_user = FALSE scope = BOTH;        
alter system set parallel_execution_message_size = 2152 scope = spfile;        
alter system set parallel_max_servers = 5 scope = spfile;        
alter system set parallel_min_percent = 0 scope = spfile;        
alter system set parallel_min_servers = 0 scope = spfile;        
alter system set parallel_threads_per_cpu = 2 scope = BOTH;        
alter system set pre_page_sga = FALSE scope = spfile;        
alter system set processes = 1000 scope = spfile;        
alter system set query_rewrite_enabled = TRUE scope = BOTH;        
alter system set query_rewrite_integrity = enforced scope = BOTH;        
alter system set read_only_open_delayed = FALSE scope = spfile;        
alter system set recovery_parallelism = 0 scope = spfile;
alter system set remote_dependencies_mode = TIMESTAMP scope = BOTH;        
alter system set remote_login_passwordfile = EXCLUSIVE scope = spfile;        
alter system set remote_os_roles = FALSE scope = spfile;        
alter system set replication_dependency_tracking = TRUE scope = spfile;
alter system set resource_limit = TRUE scope = BOTH;        
alter system set session_cached_cursors = 0 scope = spfile;        
alter system set session_max_open_files = 10 scope = spfile;        
alter system set sessions = 830 scope = spfile;        
alter system set shadow_core_dump = partial scope = spfile;        
alter system set shared_memory_address = 0 scope = spfile;        
alter system set shared_pool_reserved_size = 50m scope = spfile;        
alter system set shared_pool_size = 150m scope = BOTH;        
alter system set shared_server_sessions = 300 scope = spfile;        
alter system set shared_servers = 1 scope = BOTH;        
alter system set sql92_security = FALSE scope = spfile;        
alter system set standby_file_management = MANUAL scope = BOTH;        
alter system set star_transformation_enabled = FALSE scope = spfile;        
alter system set statistics_level = TYPICAL scope = BOTH;   
alter system set tape_asynch_io = TRUE scope = spfile;        
alter system set thread = 0 scope = spfile;        
alter system set timed_os_statistics = 0 scope = BOTH;        
alter system set timed_statistics = TRUE scope = BOTH;        
alter system set trace_enabled = TRUE scope = BOTH;
alter system set transactions = 913 scope = spfile;        
alter system set transactions_per_rollback_segment = 5 scope = spfile;        
alter system set undo_management = AUTO scope = spfile;        
alter system set undo_retention = 10800 scope = BOTH;        
alter system set undo_tablespace = UNDOTBS1 scope = BOTH;        
alter system set use_indirect_data_buffers = FALSE scope = spfile;        
alter system set workarea_size_policy = AUTO scope = BOTH;    

spool off