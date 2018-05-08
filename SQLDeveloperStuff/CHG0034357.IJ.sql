--==============================================================
-- truncate partitions
alter table hermes_mi_mart.d_pcl_ctry truncate partition d_pcl_ctry_201710 reuse storage;
alter table hermes_mi_mart.d_pcl_ctry truncate partition d_pcl_ctry_201711 reuse storage;
alter table hermes_mi_mart.d_pcl_ctry truncate partition d_pcl_ctry_201712 reuse storage;
alter table hermes_mi_mart.d_pcl_ctry truncate partition d_pcl_ctry_201801 reuse storage;
alter table hermes_mi_mart.d_pcl_ctry truncate partition d_pcl_ctry_201802 reuse storage;

-- Disable he PK to drop its index to allow reloading.
alter table hermes_mi_mart.d_pcl_ctry disable primary key;

-- Make sure index has gone - should respond with an error.
drop index hermes_mi_mart.xpkdpclctry;

-- Ian can load data now ............

-- Recreate Index for primary key.
create  unique index hermes_mi_mart.xpkdpclctry 
        on hermes_mi_mart.d_pcl_ctry(pcl_id, pcl_tmestp) 
        pctfree 5 initrans 2 maxtrans 255 compute statistics 
        storage(
            initial 1048576 next 1048576 minextents 1 maxextents 2147483645
            pctincrease 0 freelists 1 freelist groups 1
            buffer_pool default flash_cache default cell_flash_cache default
        )
        tablespace hermes_mi_dimensions 
parallel;

-- Enable primary key again.  
alter table hermes_mi_mart.d_pcl_ctry enable primary key;
  

-- gather table stats:
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', degree => 8, cascade => true);

-- And for the most recent 5 partitions.
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', 'D_PCL_CTRY_201710', granularity => 'partition', degree => 8, cascade => true);
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', 'D_PCL_CTRY_201711', granularity => 'partition', degree => 8, cascade => true);
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', 'D_PCL_CTRY_201712', granularity => 'partition', degree => 8, cascade => true);
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', 'D_PCL_CTRY_201801', granularity => 'partition', degree => 8, cascade => true);
exec dbms_stats.gather_table_stats('HERMES_MI_MART','D_PCL_CTRY', 'D_PCL_CTRY_201802', granularity => 'partition', degree => 8, cascade => true);

