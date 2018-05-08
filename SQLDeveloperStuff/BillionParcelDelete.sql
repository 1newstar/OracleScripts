set lines 3000 trimspool on trimout on pages 500
set define off
set timing on
set time on


spool billion_parcels.log

---------------------------------------------------------------------
-- Delete old data to allow sequence number(s) to roll-over. This
-- occurs whenever we get close to one billion parcels. 
--
-- Most tables, with partitions, simply get all rows deleted from
-- the old partitions (we are keeping 13 months of data) but 4
-- tables (at the end) need a WHERE clause because the oldest
-- partition has data we need to keep. These tables are:
--
-- pnet.CLN_EXCN_PROG  partition (PNET_CLN_EPROG_PART_201712)
-- pnet.CLN_ITM_PROG   partition (PNET_CLN_IPROG_PART_201712)
-- pnet.PCL_BCDE_TEST  partition (PNET_BCDE_PART_201709)
-- pnet.PCL_DIVN_DET   partition (PCL_DIVN_DET_201708)
-- 
-- (and pnet.PCL_DIVN_DET doesn't use TMESTP by the way!)
--
-- Norman Dunbar
-- 26th March 2018.
---------------------------------------------------------------------

delete from pnet.CLN partition (PNET_CLN_PART_201606);
commit;

delete from pnet.CLN partition (PNET_CLN_PART_201608);
commit;

delete from pnet.CLN partition (PNET_CLN_PART_201609);
commit;

delete from pnet.CLN partition (PNET_CLN_PART_201610);
commit;

delete from pnet.CLN partition (PNET_CLN_PART_201611);
commit;

delete from pnet.CLN_BCDE partition (PNET_CLN_BCDE_PART_201606);
commit;

delete from pnet.CLN_BCDE partition (PNET_CLN_BCDE_PART_201608);
commit;

delete from pnet.CLN_BCDE partition (PNET_CLN_BCDE_PART_201609);
commit;

delete from pnet.CLN_BCDE partition (PNET_CLN_BCDE_PART_201610);
commit;

delete from pnet.CLN_BCDE partition (PNET_CLN_BCDE_PART_201611);
commit;

delete from pnet.CLN_PROG partition (PNET_CLN_PROG_PART_201606);
commit;

delete from pnet.CLN_PROG partition (PNET_CLN_PROG_PART_201608);
commit;

delete from pnet.CLN_PROG partition (PNET_CLN_PROG_PART_201610);
commit;

delete from pnet.CLN_PROG partition (PNET_CLN_PROG_PART_201611);
commit;

delete from pnet.CLN_RQST_PROG partition (PNET_CLN_RQST_PROG_PART_201606);
commit;

delete from pnet.CLN_RQST_PROG partition (PNET_CLN_RQST_PROG_PART_201608);
commit;

delete from pnet.CLN_RQST_PROG partition (PNET_CLN_RQST_PROG_PART_201610);
commit;

delete from pnet.CLN_RQST_PROG partition (PNET_CLN_RQST_PROG_PART_201611);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201401);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201606);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201607);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201608);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201609);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201610);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201611);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201612);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201701);
commit;

delete from pnet.MFST partition (PNET_MFST_PART_201702);
commit;

delete from pnet.MFST_CLN_DET partition (MFST_CLN_DET_201611);
commit;

delete from pnet.MFST_CLN_DET partition (MFST_CLN_DET_201612);
commit;

delete from pnet.MFST_LNK_DET partition (MFST_LNK_DET_201611);
commit;

delete from pnet.MFST_LNK_DET partition (MFST_LNK_DET_201612);
commit;

delete from pnet.MFST_LNK_DET partition (MFST_LNK_DET_201702);
commit;

delete from pnet.MFST_PCL_DET partition (MFST_PCL_DET_201611);
commit;

delete from pnet.MFST_PCL_DET partition (MFST_PCL_DET_201612);
commit;

delete from pnet.MFST_PCL_DET partition (MFST_PCL_DET_201702);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201607);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201608);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201609);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201611);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201612);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201701);
commit;

delete from pnet.MNL_MFST_PCL_DET partition (PNET_MMFSTPD_PART_201702);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201606);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201608);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201609);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201610);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201611);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201612);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201701);
commit;

delete from pnet.PCL partition (PNET_PCL_PART_201702);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201303);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201508);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201510);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201512);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201601);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201602);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201603);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201604);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201606);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201607);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201608);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201610);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201701);
commit;

delete from pnet.PCL_IMG partition (PCLIMG_PART_201702);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201608);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201609);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201610);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201611);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201612);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201701);
commit;

delete from pnet.PCL_ITM_PROG partition (PNET_PCL_IPROG_PART_201702);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201401);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201606);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201608);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201609);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201610);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201611);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201612);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201701);
commit;

delete from pnet.PCL_PROG partition (PNET_PCL_PROG_PART_201702);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201606);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201608);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201610);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201611);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201612);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201701);
commit;

delete from pnet.RET_BCDE_CRS_REF partition (RET_BCDE_CRS_REF_201702);
commit;

-- The rest need a WHERE clause on TMESTP or DIVN_CREATE_TMESTP
-- as the partition has data we need to keep.

delete from pnet.CLN_EXCN_PROG partition (PNET_CLN_EPROG_PART_201712)
where TMESTP < to_date('01/03/2017', 'dd/mm/yyyy');
commit;

delete from pnet.CLN_ITM_PROG  partition (PNET_CLN_IPROG_PART_201712)
where TMESTP < to_date('01/03/2017', 'dd/mm/yyyy');
commit;

delete from pnet.PCL_BCDE_TEST  partition (PNET_BCDE_PART_201709)
where TMESTP < to_date('01/03/2017', 'dd/mm/yyyy');
commit;

delete from pnet.PCL_DIVN_DET  partition (PCL_DIVN_DET_201708)
where DIVN_CREATE_TMESTP < to_date('01/03/2017', 'dd/mm/yyyy');
commit;


spool off