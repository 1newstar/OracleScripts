INSERT /*+ FULL PARALLEL (HEDW_STG_COURIER_PROG 32) */ 
INTO hedw_edw.courier_parcel_events (
    tmestp, locn_typ, locn_cde, addl_info, pcl_cre_tmestp, clng_card_ref, crrd_fwd_to_dte,
    db_row_tmestp, ffm_txt, gps_lgtde, gps_lttde, hht_evt_tmestp, if_tmestp, mfst_itm_id,
    mfst_nbr, mfst_pg_nbr, mfst_sctn_id, pcl_addr_ln_1, pcl_addr_ln_2, pcl_addr_ln_3,
    pcl_addr_ln_4, pcl_addr_ln_5, pcl_addr_ln_6, pcl_nme, pcl_pstcde, sgtry_addr_ln_1,
    sgtry_addr_ln_2, sgtry_addr_ln_3, sgtry_addr_ln_4, sgtry_addr_ln_5, sgtry_addr_ln_6,
    sgtry_nme, sgtry_pstcde, gps_durn, tracking_points_trkg_pnt_id, md_load_date,
    couriers_cr_id, parcels_pcl_id, inst_upd_seq, hub_id, dpot_id, hermes_wrt_tmestp,
    edw_ins_upd_seq
)
    SELECT
        tmestp, locn_typ, locn_cde, addl_info, pcl_cre_tmestp, clng_card_ref, crrd_fwd_to_dte,
        db_row_tmestp, ffm_txt, gps_lgtde, gps_lttde, hht_evt_tmestp, if_tmestp, mfst_itm_id,
        mfst_nbr, mfst_pg_nbr, mfst_sctn_id, pcl_addr_ln_1, pcl_addr_ln_2, pcl_addr_ln_3,
        pcl_addr_ln_4, pcl_addr_ln_5, pcl_addr_ln_6, pcl_nme, pcl_pstcde, sgtry_addr_ln_1,
        sgtry_addr_ln_2, sgtry_addr_ln_3, sgtry_addr_ln_4, sgtry_addr_ln_5, sgtry_addr_ln_6,
        sgtry_nme, sgtry_pstcde, gps_durn, tracking_points_trkg_pnt_id, md_load_date,
        couriers_cr_id, parcels_pcl_id, inst_upd_seq, hub_id, dpot_id, hermes_wrt_tmestp,
        hedw_edw.seq_edw_pte_ins_upd.nextval
    FROM
        (
            SELECT
                hedw_stg_courier_prog.tmestp tmestp, hedw_stg_courier_prog.locn_typ locn_typ,
                hedw_stg_courier_prog.locn_cde locn_cde, hedw_stg_courier_prog.addl_info addl_info,
                hedw_stg_courier_prog.pcl_cre_tmestp pcl_cre_tmestp, hedw_stg_courier_prog.clng_card_ref clng_card_ref,
                hedw_stg_courier_prog.crrd_fwd_to_dte crrd_fwd_to_dte, hedw_stg_courier_prog.db_row_tmestp db_row_tmestp,
                hedw_stg_courier_prog.ffm_txt ffm_txt, hedw_stg_courier_prog.gps_lgtde gps_lgtde,
                hedw_stg_courier_prog.gps_lttde gps_lttde,
                ( nvl(hedw_stg_courier_prog.hht_evt_tmestp,hedw_stg_courier_prog.tmestp) ) hht_evt_tmestp,
                hedw_stg_courier_prog.if_tmestp if_tmestp, hedw_stg_courier_prog.mfst_itm_id mfst_itm_id,
                hedw_stg_courier_prog.mfst_nbr mfst_nbr, hedw_stg_courier_prog.mfst_pg_nbr mfst_pg_nbr,
                hedw_stg_courier_prog.mfst_sctn_id mfst_sctn_id, hedw_stg_courier_prog.pcl_addr_ln_1 pcl_addr_ln_1,
                hedw_stg_courier_prog.pcl_addr_ln_2 pcl_addr_ln_2, hedw_stg_courier_prog.pcl_addr_ln_3 pcl_addr_ln_3,
                hedw_stg_courier_prog.pcl_addr_ln_4 pcl_addr_ln_4, hedw_stg_courier_prog.pcl_addr_ln_5 pcl_addr_ln_5,
                hedw_stg_courier_prog.pcl_addr_ln_6 pcl_addr_ln_6, hedw_stg_courier_prog.pcl_nme pcl_nme,
                hedw_stg_courier_prog.pcl_pstcde pcl_pstcde, hedw_stg_courier_prog.sgtry_addr_ln_1 sgtry_addr_ln_1,
                hedw_stg_courier_prog.sgtry_addr_ln_2 sgtry_addr_ln_2, hedw_stg_courier_prog.sgtry_addr_ln_3 sgtry_addr_ln_3,
                hedw_stg_courier_prog.sgtry_addr_ln_4 sgtry_addr_ln_4, hedw_stg_courier_prog.sgtry_addr_ln_5 sgtry_addr_ln_5,
                hedw_stg_courier_prog.sgtry_addr_ln_6 sgtry_addr_ln_6, hedw_stg_courier_prog.sgtry_nme sgtry_nme,
                hedw_stg_courier_prog.sgtry_pstcde sgtry_pstcde, hedw_stg_courier_prog.gps_durn gps_durn,
                hedw_stg_courier_prog.trkg_pnt_id tracking_points_trkg_pnt_id,
                SYSDATE md_load_date,
                nvl( ( (
                    SELECT
                        couriers.cr_id cr_id
                    FROM
                        (
                            SELECT
                                couriers.cr_id cr_id, couriers.ownr_cr_id ownr_cr_id, couriers.cr_frst_nme cr_frst_nme, couriers.cr_midl_init cr_midl_init,
                                couriers.cr_last_nme cr_last_nme, couriers.gndr gndr, couriers.dte_of_brth dte_of_brth, couriers.cr_drvg_lic_nbr cr_drvg_lic_nbr,
                                couriers.nbr_of_ret_pads nbr_of_ret_pads, couriers.ret_pad_min ret_pad_min, couriers.snrity_flg snrity_flg,
                                couriers.crdt_chck_flg crdt_chck_flg, couriers.cr_ld_tmestp cr_ld_tmestp, couriers.cr_strt_dte cr_strt_dte,
                                couriers.cr_end_dte cr_end_dte, couriers.reus_flg reus_flg, couriers.cat_alcn_flg cat_alcn_flg, couriers.cr_vat_nbr cr_vat_nbr,
                                couriers.vat_eftv_dte vat_eftv_dte, couriers.vat_derg_dte vat_derg_dte, couriers.vat_doc_seen_dte vat_doc_seen_dte,
                                couriers.agrt_rcvd_dte agrt_rcvd_dte, couriers.cr_trdg_nme cr_trdg_nme, couriers.cr_mgr_id cr_mgr_id, couriers.cr_ttl cr_ttl,
                                couriers.grge_flg grge_flg, couriers.cr_typ_id cr_typ_id, couriers.ok_to_pay_flg ok_to_pay_flg, couriers.vcle_reg_nbr vcle_reg_nbr,
                                couriers.pymt_tfr_typ pymt_tfr_typ, couriers.stat_id stat_id, couriers.vat_dets_prst vat_dets_prst, couriers.cr_drvg_lic_ind cr_drvg_lic_ind,
                                couriers.locn_bcde_reqd_flg locn_bcde_reqd_flg, couriers.locn_bcde locn_bcde, couriers.usr_id usr_id, couriers.coy_nme coy_nme,
                                couriers.coy_flg coy_flg, couriers.caps_nme_srch caps_nme_srch, couriers.eltc_mfst_typ_cat eltc_mfst_typ_cat,
                                couriers.eltc_mfst_typ eltc_mfst_typ, couriers.kyd_mfst_retd kyd_mfst_retd, couriers.act_mfst_retd act_mfst_retd,
                                couriers.cr_pymt_prd cr_pymt_prd, couriers.cr_stmnt_typ cr_stmnt_typ, couriers.inv_crctr_flg inv_crctr_flg, couriers.rp_trig_lvl rp_trig_lvl,
                                couriers.pad_typ pad_typ, couriers.pad_typ_cat pad_typ_cat, couriers.pay_prd_end_dte pay_prd_end_dte, couriers.doc_opt doc_opt,
                                couriers.md_insert_timestamp md_insert_timestamp, couriers.md_update_timestamp md_update_timestamp
                            FROM
                                hedw_edw.couriers couriers
                        ) couriers
                    WHERE
                        (couriers.cr_id = (regexp_replace(hedw_stg_courier_prog.usr_id,'[^0-9]+','') ) )
                        AND   (ROWNUM = 1)
                ) ),-1000) couriers_cr_id,
                hedw_stg_courier_prog.pcl_id parcels_pcl_id,
                hedw_stg_courier_prog.inst_upd_seq inst_upd_seq,
                nvl( ( (
                    SELECT
                        hub.hub_id hub_id
                    FROM
                        (
                            SELECT
                                hub.hub_id hub_id, hub.hub_nme hub_nme, hub.mgr_id mgr_id, hub.area_txt_1 area_txt_1, hub.area_txt_2 area_txt_2, hub.area_txt_3 area_txt_3,
                                hub.nme_txt_1 nme_txt_1, hub.nme_txt_2 nme_txt_2, hub.nme_txt_3 nme_txt_3, hub.telno_txt_1 telno_txt_1, hub.telno_txt_2 telno_txt_2,
                                hub.telno_txt_3 telno_txt_3, hub.dets_txt_1 dets_txt_1, hub.dets_txt_2 dets_txt_2, hub.dets_txt_3 dets_txt_3, hub.dpot_hht_rets_ind dpot_hht_rets_ind,
                                hub.ret_sort_lvl_1_cde ret_sort_lvl_1_cde, hub.ret_sort_lvl_1_mrd ret_sort_lvl_1_mrd, hub.ret_bcde_pfx ret_bcde_pfx,
                                hub.md_insert_timestamp md_insert_timestamp, hub.md_update_timestamp md_update_timestamp
                            FROM
                                hedw_edw.hub hub
                        ) hub
                    WHERE
                        (
                            hedw_stg_courier_prog.locn_typ = 'HUB'
                            AND   hedw_stg_courier_prog.locn_cde = hub.hub_id
                        )
                        AND   (ROWNUM = 1)
                ) ),'XX') hub_id,
                nvl( ( (
                    SELECT
                        depot.dpot_id dpot_id
                    FROM
                        (
                            SELECT
                                depot.dpot_id dpot_id, depot.dpot_long_nme dpot_long_nme, depot.dpot_shrt_nme dpot_shrt_nme, depot.lse_expy_dte lse_expy_dte,
                                depot.dpot_rent dpot_rent, depot.optg_lic_rsrn optg_lic_rsrn, depot.mod_nbr mod_nbr, depot.mgr_id mgr_id,
                                depot.dpot_area dpot_area, depot.cnsd_dpot_nbr cnsd_dpot_nbr, depot.mfst_seq_nbr mfst_seq_nbr, depot.tmestp tmestp,
                                depot.usr_id usr_id, depot.clt_srvcs_ctlr clt_srvcs_ctlr, depot.dpot_cnct_id dpot_cnct_id, depot.lbl_prtr_id lbl_prtr_id,
                                depot.lbl_prtr_caty lbl_prtr_caty, depot.min_rp_ord min_rp_ord, depot.md_insert_timestamp md_insert_timestamp,
                                depot.md_update_timestamp md_update_timestamp
                            FROM
                                hedw_edw.depot depot
                        ) depot
                    WHERE
                        (
                            hedw_stg_courier_prog.locn_typ = 'DEP'
                            AND   hedw_stg_courier_prog.locn_cde = depot.dpot_id
                        )
                        AND   (ROWNUM = 1)
                ) ),'XX') dpot_id,
                hedw_stg_courier_prog.hermes_wrt_tmestp hermes_wrt_tmestp
            FROM
                hedw_stage.hedw_stg_courier_prog hedw_stg_courier_prog
            WHERE
                ( 1 = 1 )
                AND   (
                    (
                        hedw_stg_courier_prog.locn_typ = 'COU'
                        AND   hedw_stg_courier_prog.inst_upd_seq > 11647306184
                        AND   hedw_stg_courier_prog.md_load_date > SYSDATE - 10
                    )
                    OR    (
                        hedw_stg_courier_prog.locn_typ = 'COU'
                        AND   hedw_stg_courier_prog.md_load_status = 2
                        AND   hedw_stg_courier_prog.md_load_date > SYSDATE - 10
                    )
                )
        )
    LOG ERRORS INTO hedw_edw.err$_courier_parcel_events REJECT LIMIT UNLIMITED;