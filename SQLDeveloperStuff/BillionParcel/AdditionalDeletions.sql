set lines 500 trimspool on
set pages 200
set timing on time on
set echo on
set define off

spool AdditionalDeletions.log

delete /*+ parallel(8) */ from pnet.pcl_prog where pcl_id between 244410747 and 601865299;
commit;

delete /*+ parallel(8) */ from pnet.pcl where pcl_id between 244410747 and 601865299;
commit;

delete /*+ parallel(8) */ from pnet.pcl_img where pcl_id between 244410747 and 601865299;
commit;

delete /*+ parallel(8) */ from pnet.mfst_pcl_det where pcl_id between 244410747 and 601865299;
commit;

spool off