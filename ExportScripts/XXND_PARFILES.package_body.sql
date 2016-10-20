create or replace package body xxnd_parfiles as 

    -- Private procedure. I can't be bothered typing dbms_output.put_line 
    -- all the time! ;-)
    procedure pl(iMessage in varchar2) is
    begin
        dbms_output.put_line(iMessage);
    end;
    
    
    -- Private procedure. I can't be bothered typing dbms_output.put 
    -- all the time! ;-)
    procedure p(iMessage in varchar2) is
    begin
        dbms_output.put(iMessage);
    end;
    
    
    -- Private procedure. Common stuff for the various exp_ROWS_xxx parfiles.
    procedure buildCommon is
    begin
        pl(buffer_1e9);
        pl(yesCompress);
        pl(yesConstraints);
        pl(yesDirect);
        pl(yesGrants);
        pl(yesIndexes);
        pl(yesRows);
        pl(noStatistics);
        pl(yesConsistent);
    end;
    

    -- Private procedure. Write out the table lists.
    procedure buildTables(iTableList in tTableList) is
    
        indexer dba_tables.table_name%type;
        terminator dba_tables.table_name%type;
    begin
        indexer := iTableList.first;
        if (indexer is NULL) then
            -- Nothing to do
            return;
        end if;
        
        -- Get the final one.
        terminator := iTableList.last;
        
        pl(openTables);

        while (indexer is not null) loop
            p('fcs.' || iTableList(indexer));
            
            if (indexer <> terminator) then
                -- Print a comma
                pl(',');
            else
                -- Print a line feed.
                pl(NULL);    
            end if;

            indexer := iTableList.next(indexer);
        end loop;
        
        pl(closeTables);
        
    end;
    

    -- Publically visible stuff follows.
    
    procedure buildNOROWS(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_NOROWS.dmp';
        logFile constant varchar2(30) := 'exp_NOROWS.log';
    begin
        pl(buffer_1e9);
        pl(yesConstraints);
        pl(yesGrants);
        pl(yesIndexes);
        pl(noRows);
        pl(noStatistics);
        pl('owner=' || allOwners);
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
    end;
    
    procedure buildNOFCS(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_NOFCS.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_NOFCS.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        pl('owner=' || replace(allOwners,'FCS,',NULL));
    end;

    procedure buildFCS1(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS1.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS1.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs1Tables);
    end;
    
    procedure buildFCS2D(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS2D.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS2D.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs2Tables);
    end;
    
    procedure buildFCS3(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS3.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS3.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs3Tables);
    end;
    
    procedure buildFCS4(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS4.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS4.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs4Tables);
    end;
    
    procedure buildFCS5(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS5.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS5.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs5Tables);
    end;
    
    procedure buildFCS6(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS6.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS6.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs6Tables);
    end;
    
    procedure buildFCS7(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS7.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS7.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs7Tables);
    end;
    
    procedure buildFCS8(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS8.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS8.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs8Tables);
    end;
    
    procedure buildFCS9(iFolder in varchar2) is
        dumpFile constant varchar2(30) := 'exp_ROWS_FCS9.dmp';
        logFile constant varchar2(30) := 'exp_ROWS_FCS9.log';
    begin
        buildCommon();
        pl('file=' || iFolder || '/' || dumpFile);
        pl('log=' || iFolder || '/' || logFile);
        buildTables(fcs9Tables);
    end;
    
-- Code to initialise the various lists when this package is loaded.
-- Each list is indexed by it's own value, which makes deleting
-- and finding a lot easier, if not much harder to type when doing
-- the initialisation.    
begin
    -- *************************************************************
    -- The code here gets executed ONCE, when the package is first
    -- loaded into the session. Every session has it's own copy, so 
    -- if two sessions run the code, they won't interfere with each
    -- other.
    -- *************************************************************

    -- First we build a list of the TAKEON% schema names plus all those 
    -- that are not LOCKED and EXPIRED, which are not Oracle created users,
    -- and which own objects. We need those.  
    -- We have also hard coded the following users, in the package secification:
    -- CMTEMP,FCS,ITOPS,LEEDS_CONFIG,OEIC_RECALC and UVSCHEDULER
    -- ONLOAD was removed as unwanted after the Trial Run.   

    for takeon in (
        select username 
        from dba_users 
        where username like 'TAKEON%'        
        --
        union 
        --
        -- These are owners of objects. With OPEN accounts.
        SELECT distinct(owner) 
        FROM dba_objects o, dba_users u 
        WHERE
            o.owner = u.username
            -- Exclude expired and locked accounts.
            and u.account_status not like 'EXPIRED _ LOCKED'
            -- Exclude APEX users, including the FLOWS ones.
            and o.owner not LIKE 'APEX%'
            and o.owner not like 'FLOWS\_%' escape '\'
            -- We don't want AURORA users either.
            and o.owner not like 'AURORA$%'
            -- Nor do we care about any of the following:
            and o.owner NOT IN 
                (       
                        -- Hard coded users that we aalways export.
                        'CMTEMP', 'FCS', 'ITOPS', 'LEEDS_CONFIG', 'OEIC_RECALC', 
                        'ONLOAD', 'UVSCHEDULER',
                        -- Pre-Defined Administrative Accounts.
                         'ANONYMOUS'  ,'APPQOSSYS' ,'CSMIG'         ,'CTXSYS'       
                        ,'DBSNMP'     ,'DMSYS'     ,'EXFSYS'        ,'LBACSYS'      
                        ,'MDSYS'      ,'MGMT_VIEW' ,'ODM'           ,'ODM_MTR'
                        ,'OLAPSYS'    ,'OWBSYS'    ,'OWBSYS_AUDIT'  ,'ORACLE_OCM'  
                        ,'ORDPLUGINS' ,'ORDSYS'    ,'OUTLN'         ,'PERFSTAT'    
                        ,'SI_INFORMTN_SCHEMA'      ,'SNAPADMIN'     ,'SYS'
                        ,'SYSMAN'    ,'SYSTEM'     ,'TRACESVR'      ,'TSMSYS'     
                        ,'WKSYS'     ,'WKUSER'     ,'WMSYS'         ,'XDB'
                        -- Pre-Defined Non-Administrative Accounts
                        ,'AWR_STAGE','DIP'
                        ,'MDDATA'   ,'ORACLE_OCM' ,'ORDDATA'     ,'PUBLIC'   
                        ,'SPATIAL_CSW_ADMIN_USER' ,'SPATIAL_WFS_ADMIN_USR' 
                        ,'WKPROXY' ,'WK_TEST'     ,'XS$NULL'
                        -- Default Sample Schema User Accounts (Why are these
                        -- in a production databasde please?)
                        ,'SCOTT'  ,'ADAMS' ,'JONES'    ,'CLARK' ,'BLAKE' ,'DEMO'
                        ,'BI'     ,'HR'    ,'IX'       ,'OE'    ,'PM'    ,'QS'    ,'SH' 
                        ,'QS_ADM' ,'QS_CB' ,'QS_CBADM' ,'QS_CS' ,'QS_ES' ,'QS_OS' ,'QS_WS' 
                        -- Third party product accounts.
                        ,'TOAD','SPHINXCST','JLM', 'DISCADMIN','ONLOAD'
                )
        ORDER BY username
    )
    loop
        allOwners := allOwners || takeon.username || ',';
    end loop;
    
    allOwners := '(' || rtrim(alwaysOwners || ',' || allOwners, ',') || ')';
    -- dbms_output.put_line(allOwners);
    
    
    -- *************************************************************
    -- *************************************************************
    -- **                                                         **
    -- ** WARNING WARNING WARNING WARNING WARNING WARNING WARNING ** 
    -- **                                                         **
    -- *************************************************************
    -- ** All the table names in the following lists MUST be in   **
    -- ** lower case and MUST NOT have the schema name prefixed.  **
    -- *************************************************************
    -- *************************************************************


    -- First, a list of tables that we don't want exporting.
    -- These should all be in lower case.
    
    -- First we have the Category 1 tables, old Data Take-on.

    unLovedTables('bwd_ledgers') := 'bwd_ledgers';
    unLovedTables('bwdclientdata') := 'bwdclientdata';
    unLovedTables('bwdmsrep') := 'bwdmsrep';
    unLovedTables('bwdrbill') := 'bwdrbill';
    unLovedTables('bwdtemp01') := 'bwdtemp01';
    unLovedTables('bwdtrlbal') := 'bwdtrlbal';
    unLovedTables('cty_temp_holding') := 'cty_temp_holding';
    unLovedTables('cty_temp_ifa') := 'cty_temp_ifa';
    unLovedTables('cty_temp_investor') := 'cty_temp_investor';
    unLovedTables('er_temp_holding') := 'er_temp_holding';
    unLovedTables('er_temp_ifa') := 'er_temp_ifa';
    unLovedTables('er_temp_investor') := 'er_temp_investor';
    unLovedTables('fs_temp_holding') := 'fs_temp_holding';
    unLovedTables('fs_temp_ifa') := 'fs_temp_ifa';
    unLovedTables('fs_temp_investor') := 'fs_temp_investor';
    unLovedTables('fs_temp_isaplan') := 'fs_temp_isaplan';
    unLovedTables('fs2_jointholders') := 'fs2_jointholders';
    unLovedTables('fs2_temp_jointholders') := 'fs2_temp_jointholders';
    unLovedTables('fs3_int_ifa') := 'fs3_int_ifa';
    unLovedTables('fs3_int_investor') := 'fs3_int_investor';
    unLovedTables('fs3_int_isaplan') := 'fs3_int_isaplan';
    unLovedTables('fs3_int_isatot') := 'fs3_int_isatot';
    unLovedTables('fs3_int_ordtran') := 'fs3_int_ordtran';
    unLovedTables('fs3_int_register') := 'fs3_int_register';
    unLovedTables('fs3_int_saver') := 'fs3_int_saver';
    unLovedTables('ifa_dilution_levy_maint') := 'ifa_dilution_levy_maint';
    unLovedTables('nep_int_bacspay') := 'nep_int_bacspay';
    unLovedTables('nep_int_ifa') := 'nep_int_ifa';
    unLovedTables('nep_int_ifa_bank') := 'nep_int_ifa_bank';
    unLovedTables('nep_int_investor') := 'nep_int_investor';
    unLovedTables('nep_int_mandaddr') := 'nep_int_mandaddr';
    unLovedTables('nep_int_ordtran') := 'nep_int_ordtran';
    unLovedTables('nep_int_register') := 'nep_int_register';
    unLovedTables('nep_int_saver') := 'nep_int_saver';
    unLovedTables('nep_int_trust') := 'nep_int_trust';
    unLovedTables('nep_temp_investorbank') := 'nep_temp_investorbank';
    unLovedTables('rl_27posts') := 'rl_27posts';
    unLovedTables('rl_3r_conhist') := 'rl_3r_conhist';
    unLovedTables('rl_3r_hfax') := 'rl_3r_hfax';
    unLovedTables('rl_3r_hphone') := 'rl_3r_hphone';
    unLovedTables('rl_3r_hphone2') := 'rl_3r_hphone2';
    unLovedTables('rl_3r_wfax') := 'rl_3r_wfax';
    unLovedTables('rl_3r_wphone') := 'rl_3r_wphone';
    unLovedTables('rl_babrpf_banknames') := 'rl_babrpf_banknames';
    unLovedTables('rl_chdrpf_contractheader') := 'rl_chdrpf_contractheader';
    unLovedTables('rl_chrg_fb') := 'rl_chrg_fb';
    unLovedTables('rl_chrg_fbpen') := 'rl_chrg_fbpen';
    unLovedTables('rl_chrg_mvr') := 'rl_chrg_mvr';
    unLovedTables('rl_chrg_other') := 'rl_chrg_other';
    unLovedTables('rl_chrg_wc') := 'rl_chrg_wc';
    unLovedTables('rl_clbapf_bacspay') := 'rl_clbapf_bacspay';
    unLovedTables('rl_clntpf_investor') := 'rl_clntpf_investor';
    unLovedTables('rl_clrrpf') := 'rl_clrrpf';
    unLovedTables('rl_final_bonus_rates') := 'rl_final_bonus_rates';
    unLovedTables('rl_mandpf_dd') := 'rl_mandpf_dd';
    unLovedTables('rl_marketing_linda') := 'rl_marketing_linda';
    unLovedTables('rl_marketing_three') := 'rl_marketing_three';
    unLovedTables('rl_payrpf') := 'rl_payrpf';
    unLovedTables('rl_policy_cross_ref') := 'rl_policy_cross_ref';
    unLovedTables('rl_policy_cross_ref_2009_2010') := 'rl_policy_cross_ref_2009_2010';
    unLovedTables('rl_policy_status') := 'rl_policy_status';
    unLovedTables('rl_policy_status_2009_2010') := 'rl_policy_status_2009_2010';
    unLovedTables('rl_policy_status_temp') := 'rl_policy_status_temp';
    unLovedTables('rl_prv_count_2009_2010') := 'rl_prv_count_2009_2010';
    unLovedTables('rl_rounding_audit') := 'rl_rounding_audit';
    unLovedTables('rl_temp_bacspay') := 'rl_temp_bacspay';
    unLovedTables('rl_temp_bacspay_issues') := 'rl_temp_bacspay_issues';
    unLovedTables('rl_temp_cm1') := 'rl_temp_cm1';
    unLovedTables('rl_temp_cm2') := 'rl_temp_cm2';
    unLovedTables('rl_temp_corraddress') := 'rl_temp_corraddress';
    unLovedTables('rl_temp_dd_import') := 'rl_temp_dd_import';
    unLovedTables('rl_temp_divpay') := 'rl_temp_divpay';
    unLovedTables('rl_temp_divpay_date') := 'rl_temp_divpay_date';
    unLovedTables('rl_temp_fb') := 'rl_temp_fb';
    unLovedTables('rl_temp_fbdeals') := 'rl_temp_fbdeals';
    unLovedTables('rl_temp_fbpen') := 'rl_temp_fbpen';
    unLovedTables('rl_temp_fbpendeals') := 'rl_temp_fbpendeals';
    unLovedTables('rl_temp_fundswitch') := 'rl_temp_fundswitch';
    unLovedTables('rl_temp_goneaways') := 'rl_temp_goneaways';
    unLovedTables('rl_temp_inchlder_other') := 'rl_temp_inchlder_other';
    unLovedTables('rl_temp_inchldr_dtype') := 'rl_temp_inchldr_dtype';
    unLovedTables('rl_temp_invalid_clients') := 'rl_temp_invalid_clients';
    unLovedTables('rl_temp_investor') := 'rl_temp_investor';
    unLovedTables('rl_temp_investor_corresaddr') := 'rl_temp_investor_corresaddr';
    unLovedTables('rl_temp_investor_dblspace') := 'rl_temp_investor_dblspace';
    unLovedTables('rl_temp_investorbank') := 'rl_temp_investorbank';
    unLovedTables('rl_temp_isadate') := 'rl_temp_isadate';
    unLovedTables('rl_temp_isaplan') := 'rl_temp_isaplan';
    unLovedTables('rl_temp_merged_policies') := 'rl_temp_merged_policies';
    unLovedTables('rl_temp_missingaddress') := 'rl_temp_missingaddress';
    unLovedTables('rl_temp_mvr') := 'rl_temp_mvr';
    unLovedTables('rl_temp_mvrdeals') := 'rl_temp_mvrdeals';
    unLovedTables('rl_temp_register') := 'rl_temp_register';
    unLovedTables('rl_temp_reinvestor') := 'rl_temp_reinvestor';
    unLovedTables('rl_temp_saver') := 'rl_temp_saver';
    unLovedTables('rl_temp_saver_commas') := 'rl_temp_saver_commas';
    unLovedTables('rl_temp_saver_issues') := 'rl_temp_saver_issues';
    unLovedTables('rl_temp_saver_mand') := 'rl_temp_saver_mand';
    unLovedTables('rl_temp_saver_old') := 'rl_temp_saver_old';
    unLovedTables('rl_temp_saversplit') := 'rl_temp_saversplit';
    unLovedTables('rl_temp_trust') := 'rl_temp_trust';
    unLovedTables('rl_temp_warrant_investors') := 'rl_temp_warrant_investors';
    unLovedTables('rl_temp_wc') := 'rl_temp_wc';
    unLovedTables('rl_temp_wcdeals') := 'rl_temp_wcdeals';
    unLovedTables('rl_tmp_da') := 'rl_tmp_da';
    unLovedTables('rl_tmp_dispatchaddr_clients') := 'rl_tmp_dispatchaddr_clients';
    unLovedTables('rl_tmp_ow') := 'rl_tmp_ow';
    unLovedTables('rl_tmp_registconsol') := 'rl_tmp_registconsol';
    unLovedTables('rl_tmp_stat_anniversaries') := 'rl_tmp_stat_anniversaries';
    unLovedTables('rl_ufndpf') := 'rl_ufndpf';
    unLovedTables('rl_ulnkpf') := 'rl_ulnkpf';
    unLovedTables('rl_ulnkpf_issues') := 'rl_ulnkpf_issues';
    unLovedTables('rl_uswdpf') := 'rl_uswdpf';
    unLovedTables('rl_utrn_all') := 'rl_utrn_all';
    unLovedTables('rl_utrn_unset') := 'rl_utrn_unset';
    unLovedTables('rl_utrn2000') := 'rl_utrn2000';
    unLovedTables('rl_utrn2001') := 'rl_utrn2001';
    unLovedTables('rl_utrn2002') := 'rl_utrn2002';
    unLovedTables('rl_utrn2003') := 'rl_utrn2003';
    unLovedTables('rl_utrn2004') := 'rl_utrn2004';
    unLovedTables('rl_utrn2005') := 'rl_utrn2005';
    unLovedTables('rl_utrn2006') := 'rl_utrn2006';
    unLovedTables('rl_utrn2007') := 'rl_utrn2007';
    unLovedTables('rl_utrspf_register') := 'rl_utrspf_register';
    unLovedTables('rl_val_fixes') := 'rl_val_fixes';
    unLovedTables('rl_val1_supplied') := 'rl_val1_supplied';
    unLovedTables('rl_valrep1') := 'rl_valrep1';
    unLovedTables('rl_valuation1') := 'rl_valuation1';
    unLovedTables('rl_vprcpf_price') := 'rl_vprcpf_price';
    unLovedTables('rl_vw_temp_reg') := 'rl_vw_temp_reg';
    unLovedTables('rl_vw_temp_regb') := 'rl_vw_temp_regb';
    unLovedTables('rl_vw_temp_regc') := 'rl_vw_temp_regc';
    unLovedTables('rl_zaudpf_bacsref') := 'rl_zaudpf_bacsref';
    unLovedTables('rl_zchfpf_isatot') := 'rl_zchfpf_isatot';
    unLovedTables('rl_zcsppf') := 'rl_zcsppf';
    unLovedTables('rl_zdhfpf_divpay') := 'rl_zdhfpf_divpay';
    unLovedTables('rl_zdifpf_disinc') := 'rl_zdifpf_disinc';
    unLovedTables('rl_zdrfpf_dividend') := 'rl_zdrfpf_dividend';
    unLovedTables('rl_ziatpf') := 'rl_ziatpf';
    unLovedTables('rl_zv1cpf') := 'rl_zv1cpf';
    unLovedTables('rl_zv1cpf_uv') := 'rl_zv1cpf_uv';
    unLovedTables('sh_temp_dividend') := 'sh_temp_dividend';
    unLovedTables('sh_temp_dividend_timetable') := 'sh_temp_dividend_timetable';
    unLovedTables('sh_temp_divpay') := 'sh_temp_divpay';
    unLovedTables('sh_temp_investor_etc') := 'sh_temp_investor_etc';
    unLovedTables('sh_temp_investor_shc') := 'sh_temp_investor_shc';
    unLovedTables('sh_temp_investorbank') := 'sh_temp_investorbank';
    unLovedTables('sh_temp_isatot_b4_update') := 'sh_temp_isatot_b4_update';
    unLovedTables('sh_temp_oeiprice') := 'sh_temp_oeiprice';
    unLovedTables('sh_temp_ordtran_etc') := 'sh_temp_ordtran_etc';
    unLovedTables('sh_temp_ordtran_shc') := 'sh_temp_ordtran_shc';
    unLovedTables('sh_temp_ordtran_shc_new') := 'sh_temp_ordtran_shc_new';
    unLovedTables('sh_temp_ordtran_tfr_fix') := 'sh_temp_ordtran_tfr_fix';
    unLovedTables('sh_temp_rufus_units') := 'sh_temp_rufus_units';
    unLovedTables('sh_temp_unit_comparision_etc') := 'sh_temp_unit_comparision_etc';
    unLovedTables('sh_temp_unit_comparision_shc') := 'sh_temp_unit_comparision_shc';
    unLovedTables('stg_fs3_agents') := 'stg_fs3_agents';
    unLovedTables('stg_fs3_agents_utopia_code') := 'stg_fs3_agents_utopia_code';
    unLovedTables('stg_fs3_inst_investor') := 'stg_fs3_inst_investor';
    unLovedTables('stg_fs3_isa_priv_investor') := 'stg_fs3_isa_priv_investor';
    unLovedTables('stg_fs3_jh_investor') := 'stg_fs3_jh_investor';
    unLovedTables('stg_fs3_oeic_priv_investor') := 'stg_fs3_oeic_priv_investor';
    unLovedTables('stg_thr_tblclient') := 'stg_thr_tblclient';
    unLovedTables('stg_thr_tblclientagreement') := 'stg_thr_tblclientagreement';
    unLovedTables('stg_thr_tblclientholding') := 'stg_thr_tblclientholding';
    unLovedTables('stg_thr_tblcontacts') := 'stg_thr_tblcontacts';
    unLovedTables('stg_thr_tbldetailtran') := 'stg_thr_tbldetailtran';
    unLovedTables('stg_thr_tblfund') := 'stg_thr_tblfund';
    unLovedTables('stg_thr_tblfundamc') := 'stg_thr_tblfundamc';
    unLovedTables('stg_thr_tblfundtype') := 'stg_thr_tblfundtype';
    unLovedTables('stg_thr_tblprice') := 'stg_thr_tblprice';
    unLovedTables('stg_thr_tbltransaction') := 'stg_thr_tbltransaction';
    unLovedTables('stg_thr_tbltranstype') := 'stg_thr_tbltranstype';
    unLovedTables('stg_thr_tblvaldate') := 'stg_thr_tblvaldate';
    unLovedTables('stg_thr_tblwithdrawalallowance') := 'stg_thr_tblwithdrawalallowance';
    unLovedTables('temp_mgm_pre_ifaupd') := 'temp_mgm_pre_ifaupd';
    unLovedTables('temp_mgm_register') := 'temp_mgm_register';
    unLovedTables('temp_midas_bacspay') := 'temp_midas_bacspay';
    unLovedTables('temp_midas_saver') := 'temp_midas_saver';
    unLovedTables('temp_nep_ifa') := 'temp_nep_ifa';
    unLovedTables('temp_nep_inv') := 'temp_nep_inv';
    unLovedTables('temp_nep_reg_noorders') := 'temp_nep_reg_noorders';
    unLovedTables('temp_nepdivpay_37861') := 'temp_nepdivpay_37861';
    unLovedTables('temp_nepsaver_37861') := 'temp_nepsaver_37861';
    unLovedTables('temp_neptune_20050125') := 'temp_neptune_20050125';
    unLovedTables('temp_neptune_20051201') := 'temp_neptune_20051201';
    unLovedTables('temp_neptune_l36128') := 'temp_neptune_l36128';
    unLovedTables('temp_neptune_l36140') := 'temp_neptune_l36140';
    unLovedTables('temp_neptune_l39173') := 'temp_neptune_l39173';
    unLovedTables('temp_rl_migration') := 'temp_rl_migration';
    unLovedTables('thr_int_bankdetails') := 'thr_int_bankdetails';
    unLovedTables('thr_int_clientinvxref') := 'thr_int_clientinvxref';
    unLovedTables('thr_int_contract_emails') := 'thr_int_contract_emails';
    unLovedTables('thr_int_fund_usage') := 'thr_int_fund_usage';
    unLovedTables('thr_int_fundowner') := 'thr_int_fundowner';
    unLovedTables('thr_int_inv_withdrawal_limit') := 'thr_int_inv_withdrawal_limit';
    unLovedTables('thr_int_investor') := 'thr_int_investor';
    unLovedTables('thr_int_investor_manager_pens') := 'thr_int_investor_manager_pens';
    unLovedTables('thr_int_investor_trust_pens') := 'thr_int_investor_trust_pens';
    unLovedTables('thr_int_investorbank') := 'thr_int_investorbank';
    unLovedTables('thr_int_log') := 'thr_int_log';
    unLovedTables('thr_int_manager') := 'thr_int_manager';
    unLovedTables('thr_int_memo') := 'thr_int_memo';
    unLovedTables('thr_int_oeiprice') := 'thr_int_oeiprice';
    unLovedTables('thr_int_ordtran') := 'thr_int_ordtran';
    unLovedTables('thr_int_postrule') := 'thr_int_postrule';
    unLovedTables('thr_int_price_history') := 'thr_int_price_history';
    unLovedTables('thr_int_register') := 'thr_int_register';
    unLovedTables('thr_int_trstcode_xref') := 'thr_int_trstcode_xref';
    unLovedTables('thr_int_trsttype') := 'thr_int_trsttype';
    unLovedTables('thr_int_trust') := 'thr_int_trust';
    unLovedTables('thr_int_trustee') := 'thr_int_trustee';
    unLovedTables('thr_int_unitsinissue') := 'thr_int_unitsinissue';
    unLovedTables('thr_int_unittype') := 'thr_int_unittype';
    unLovedTables('thr_int_valhead') := 'thr_int_valhead';

    -- Then the Category 2 - Accounting tables.
    
    unLovedTables('glacmast') := 'glacmast';
    unLovedTables('glacper') := 'glacper';
    unLovedTables('glbatch') := 'glbatch';
    unLovedTables('glbdalfc') := 'glbdalfc';
    unLovedTables('glbdalms') := 'glbdalms';
    unLovedTables('glbdmast') := 'glbdmast';
    unLovedTables('glbdper') := 'glbdper';
    unLovedTables('glbudtb') := 'glbudtb';
    unLovedTables('glcadef') := 'glcadef';
    unLovedTables('glcalfyp') := 'glcalfyp';
    unLovedTables('glcalfyr') := 'glcalfyr';
    unLovedTables('glcalmast') := 'glcalmast';
    unLovedTables('glcamast') := 'glcamast';
    unLovedTables('glgroup') := 'glgroup';
    unLovedTables('glgroup_lgmast') := 'glgroup_lgmast';
    unLovedTables('glinvs') := 'glinvs';
    unLovedTables('gllegfyp') := 'gllegfyp';
    unLovedTables('gllegfyr') := 'gllegfyr';
    unLovedTables('gllgmast') := 'gllgmast';
    unLovedTables('glposts') := 'glposts';
    unLovedTables('glrbhead') := 'glrbhead';
    unLovedTables('glrddef') := 'glrddef';
    unLovedTables('glrdhead') := 'glrdhead';
    unLovedTables('glrdmast') := 'glrdmast';
    unLovedTables('glrecb') := 'glrecb';
    unLovedTables('glrep') := 'glrep';
    unLovedTables('glsalinv') := 'glsalinv';
    unLovedTables('glsite') := 'glsite';
    unLovedTables('glskelac') := 'glskelac';
    unLovedTables('glskelmast') := 'glskelmast';
    
    -- Then the Category 2 - Fund Accounting tables.
    
    unLovedTables('valxrate') := 'valxrate';

    -- Category 3 - Should never have been created!
    
    unLovedTables('bec_bacspay_441') := 'bec_bacspay_441';
    unLovedTables('bec_dividend_441') := 'bec_dividend_441';
    unLovedTables('bec_divpay_441') := 'bec_divpay_441';
    unLovedTables('bec_oeic_share_class_temp') := 'bec_oeic_share_class_temp';
    unLovedTables('bec_ordtran_441') := 'bec_ordtran_441';
    unLovedTables('bec_register_441') := 'bec_register_441';
    unLovedTables('bec_saver_441') := 'bec_saver_441';
    unLovedTables('bec_signof_441') := 'bec_signof_441';
    unLovedTables('bec_temp_valhead') := 'bec_temp_valhead';
    unLovedTables('bec_temp_valhold') := 'bec_temp_valhold';
    unLovedTables('bec_temp_valxrate') := 'bec_temp_valxrate';
    unLovedTables('bec_tsteerep_441') := 'bec_tsteerep_441';
    unLovedTables('ben_dist_hist') := 'ben_dist_hist';
    unLovedTables('ben_dividend') := 'ben_dividend';
    unLovedTables('ben_prices') := 'ben_prices';
    unLovedTables('ben_register') := 'ben_register';
    unLovedTables('ben_temp_dist_hist') := 'ben_temp_dist_hist';
    unLovedTables('ben_temp_register') := 'ben_temp_register';
    unLovedTables('ben_temp_transaction') := 'ben_temp_transaction';
    unLovedTables('ben_transactions') := 'ben_transactions';
    unLovedTables('ben_transtype') := 'ben_transtype';
    unLovedTables('bev_temp_glacper') := 'bev_temp_glacper';
    unLovedTables('bev_temp_gllegfyr') := 'bev_temp_gllegfyr';
    unLovedTables('bev_temp_glposts') := 'bev_temp_glposts';
    unLovedTables('bev_temp_glposts_changed') := 'bev_temp_glposts_changed';
    unLovedTables('divdiary_17957_backup_27jul') := 'divdiary_17957_backup_27jul';
    unLovedTables('divdiary_17957_bkp_del_28jul') := 'divdiary_17957_bkp_del_28jul';
    unLovedTables('investor_rollback') := 'investor_rollback';
    unLovedTables('muser_backup') := 'muser_backup';
    unLovedTables('oecsdrtp_copy') := 'oecsdrtp_copy';
    unLovedTables('offload_bacspay') := 'offload_bacspay';
    unLovedTables('pricecopy') := 'pricecopy';
    unLovedTables('stpbonyx_temp') := 'stpbonyx_temp';
    unLovedTables('temp_2007_rl_pol_cross_ref') := 'temp_2007_rl_pol_cross_ref';
    unLovedTables('temp_2008_rl_pol_cross_ref') := 'temp_2008_rl_pol_cross_ref';
    unLovedTables('temp_258') := 'temp_258';
    unLovedTables('temp_2900_glacper') := 'temp_2900_glacper';
    unLovedTables('temp_2900_gllegfyr') := 'temp_2900_gllegfyr';
    unLovedTables('temp_2900_glposts') := 'temp_2900_glposts';
    unLovedTables('temp_4000_glacper_y27_210307') := 'temp_4000_glacper_y27_210307';
    unLovedTables('temp_47041') := 'temp_47041';
    unLovedTables('temp_5105_glacper') := 'temp_5105_glacper';
    unLovedTables('temp_5105_glposts') := 'temp_5105_glposts';
    unLovedTables('temp_5105_per_cm') := 'temp_5105_per_cm';
    unLovedTables('temp_595') := 'temp_595';
    unLovedTables('temp_596') := 'temp_596';
    unLovedTables('temp_909_ordtran') := 'temp_909_ordtran';
    unLovedTables('temp_909_register') := 'temp_909_register';
    unLovedTables('temp_aber_jhlinks') := 'temp_aber_jhlinks';
    unLovedTables('temp_account_id_lookup') := 'temp_account_id_lookup';
    unLovedTables('temp_bacs_collection_ac') := 'temp_bacs_collection_ac';
    unLovedTables('temp_bacs_interface_transfer') := 'temp_bacs_interface_transfer';
    unLovedTables('temp_bacs_savers') := 'temp_bacs_savers';
    unLovedTables('temp_bacspay_103') := 'temp_bacspay_103';
    unLovedTables('temp_berkeley_ordtran') := 'temp_berkeley_ordtran';
    unLovedTables('temp_bwd_investors') := 'temp_bwd_investors';
    unLovedTables('temp_bwd_jhlinks') := 'temp_bwd_jhlinks';
    unLovedTables('temp_cav_deals') := 'temp_cav_deals';
    unLovedTables('temp_cav_isaplan') := 'temp_cav_isaplan';
    unLovedTables('temp_cmar_rev') := 'temp_cmar_rev';
    unLovedTables('temp_convert') := 'temp_convert';
    unLovedTables('temp_deminimus_rpt') := 'temp_deminimus_rpt';
    unLovedTables('temp_exchrates') := 'temp_exchrates';
    unLovedTables('temp_glacper_189') := 'temp_glacper_189';
    unLovedTables('temp_glacper_353') := 'temp_glacper_353';
    unLovedTables('temp_glacper_4000_27') := 'temp_glacper_4000_27';
    unLovedTables('temp_glacper_4000_y27') := 'temp_glacper_4000_y27';
    unLovedTables('temp_glacper_4000_y27_2') := 'temp_glacper_4000_y27_2';
    unLovedTables('temp_glacper_427') := 'temp_glacper_427';
    unLovedTables('temp_glacper_5101') := 'temp_glacper_5101';
    unLovedTables('temp_glacper_5101_29_01_07') := 'temp_glacper_5101_29_01_07';
    unLovedTables('temp_glacper_5101_new') := 'temp_glacper_5101_new';
    unLovedTables('temp_glacper_5101_new2') := 'temp_glacper_5101_new2';
    unLovedTables('temp_gllegfyr_4000') := 'temp_gllegfyr_4000';
    unLovedTables('temp_glposts_189') := 'temp_glposts_189';
    unLovedTables('temp_holding_319') := 'temp_holding_319';
    unLovedTables('temp_holding_596') := 'temp_holding_596';
    unLovedTables('temp_ifacomst_2600') := 'temp_ifacomst_2600';
    unLovedTables('temp_iimia_register') := 'temp_iimia_register';
    unLovedTables('temp_income_avail') := 'temp_income_avail';
    unLovedTables('temp_invcoste') := 'temp_invcoste';
    unLovedTables('temp_kb_jhlinks') := 'temp_kb_jhlinks';
    unLovedTables('temp_lt_investor') := 'temp_lt_investor';
    unLovedTables('temp_margetts_register') := 'temp_margetts_register';
    unLovedTables('temp_mboxsummary') := 'temp_mboxsummary';
    unLovedTables('temp_norma_transfers') := 'temp_norma_transfers';
    unLovedTables('temp_oeiprice_148') := 'temp_oeiprice_148';
    unLovedTables('temp_oeiprice_425') := 'temp_oeiprice_425';
    unLovedTables('temp_ordcalc') := 'temp_ordcalc';
    unLovedTables('temp_ordcalc_errors') := 'temp_ordcalc_errors';
    unLovedTables('temp_ordtran_103') := 'temp_ordtran_103';
    unLovedTables('temp_ordtran_1066') := 'temp_ordtran_1066';
    unLovedTables('temp_ordtran_148') := 'temp_ordtran_148';
    unLovedTables('temp_ordtran_191') := 'temp_ordtran_191';
    unLovedTables('temp_ordtran_2401') := 'temp_ordtran_2401';
    unLovedTables('temp_ordtran_352') := 'temp_ordtran_352';
    unLovedTables('temp_ordtran_425') := 'temp_ordtran_425';
    unLovedTables('temp_ordtran_log') := 'temp_ordtran_log';
    unLovedTables('temp_ordtran_mv') := 'temp_ordtran_mv';
    unLovedTables('temp_payment') := 'temp_payment';
    unLovedTables('temp_payment_2') := 'temp_payment_2';
    unLovedTables('temp_payment_24615_24828') := 'temp_payment_24615_24828';
    unLovedTables('temp_payment_transfer') := 'temp_payment_transfer';
    unLovedTables('temp_portfolio') := 'temp_portfolio';
    unLovedTables('temp_prices') := 'temp_prices';
    unLovedTables('temp_problem_deals') := 'temp_problem_deals';
    unLovedTables('temp_rathbone_xls') := 'temp_rathbone_xls';
    unLovedTables('temp_rathbone_xls_address') := 'temp_rathbone_xls_address';
    unLovedTables('temp_register_102') := 'temp_register_102';
    unLovedTables('temp_register_103') := 'temp_register_103';
    unLovedTables('temp_register_106') := 'temp_register_106';
    unLovedTables('temp_register_118') := 'temp_register_118';
    unLovedTables('temp_register_148') := 'temp_register_148';
    unLovedTables('temp_register_154') := 'temp_register_154';
    unLovedTables('temp_register_2401') := 'temp_register_2401';
    unLovedTables('temp_register_352') := 'temp_register_352';
    unLovedTables('temp_register_357') := 'temp_register_357';
    unLovedTables('temp_register_379') := 'temp_register_379';
    unLovedTables('temp_register_407') := 'temp_register_407';
    unLovedTables('temp_register_425') := 'temp_register_425';
    unLovedTables('temp_register_435') := 'temp_register_435';
    unLovedTables('temp_register_436') := 'temp_register_436';
    unLovedTables('temp_register_457231') := 'temp_register_457231';
    unLovedTables('temp_register_log') := 'temp_register_log';
    unLovedTables('temp_rensburg_2606_register') := 'temp_rensburg_2606_register';
    unLovedTables('temp_rensburg_2608_register') := 'temp_rensburg_2608_register';
    unLovedTables('temp_rl_refer') := 'temp_rl_refer';
    unLovedTables('temp_rlglacper_correction') := 'temp_rlglacper_correction';
    unLovedTables('temp_rolepwd') := 'temp_rolepwd';
    unLovedTables('temp_s18') := 'temp_s18';
    unLovedTables('temp_saver_106') := 'temp_saver_106';
    unLovedTables('temp_saver_407') := 'temp_saver_407';
    unLovedTables('temp_saver_435') := 'temp_saver_435';
    unLovedTables('temp_sdrt_errors') := 'temp_sdrt_errors';
    unLovedTables('temp_si_client') := 'temp_si_client';
    unLovedTables('temp_si_portfolio') := 'temp_si_portfolio';
    unLovedTables('temp_signof_103') := 'temp_signof_103';
    unLovedTables('temp_signof_148') := 'temp_signof_148';
    unLovedTables('temp_signof_2401') := 'temp_signof_2401';
    unLovedTables('temp_signof_425') := 'temp_signof_425';
    unLovedTables('temp_stale_prices') := 'temp_stale_prices';
    unLovedTables('temp_topholder') := 'temp_topholder';
    unLovedTables('temp_tot_bacs_trust_post_val') := 'temp_tot_bacs_trust_post_val';
    unLovedTables('temp_transact_319') := 'temp_transact_319';
    unLovedTables('temp_transact_596') := 'temp_transact_596';
    unLovedTables('temp_trust') := 'temp_trust';
    unLovedTables('temp_trust_recon') := 'temp_trust_recon';
    unLovedTables('temp_tsteerep_103') := 'temp_tsteerep_103';
    unLovedTables('temp_tsteerep_148') := 'temp_tsteerep_148';
    unLovedTables('temp_tsteerep_2401') := 'temp_tsteerep_2401';
    unLovedTables('temp_tsteerep_425') := 'temp_tsteerep_425';
    unLovedTables('temp_twohrfmg_boxcon') := 'temp_twohrfmg_boxcon';
    unLovedTables('temp_valhead_103') := 'temp_valhead_103';
    unLovedTables('temp_valhead_148') := 'temp_valhead_148';
    unLovedTables('temp_valhead_2401') := 'temp_valhead_2401';
    unLovedTables('temp_valhead_425') := 'temp_valhead_425';
    unLovedTables('temp2_ritesh_ordtran') := 'temp2_ritesh_ordtran';
    unLovedTables('tempreg427') := 'tempreg427';
    unLovedTables('tempsrri') := 'tempsrri';
    unLovedTables('tmp_glacper_3200_27') := 'tmp_glacper_3200_27';
    unLovedTables('tmp_glacper_3200_28') := 'tmp_glacper_3200_28';
    unLovedTables('tmp_glacper_357101800') := 'tmp_glacper_357101800';
    unLovedTables('tmp_gllegfyr') := 'tmp_gllegfyr';
    unLovedTables('tmp_rl_register') := 'tmp_rl_register';
    unLovedTables('tmp_rl_saver') := 'tmp_rl_saver';
    unLovedTables('tmp_subacrec_ritesh') := 'tmp_subacrec_ritesh';
    unLovedTables('tothld_temp') := 'tothld_temp';
    unLovedTables('tothld_temp_srt') := 'tothld_temp_srt';
    unLovedTables('tothld_temp_srt_t') := 'tothld_temp_srt_t';
    unLovedTables('tothld_value_temp') := 'tothld_value_temp';
    unLovedTables('tothld_value_temp_srt') := 'tothld_value_temp_srt';
    unLovedTables('totifa_temp') := 'totifa_temp';
    unLovedTables('totifa_temp_srt') := 'totifa_temp_srt';
    unLovedTables('uv_offload_bacspay') := 'uv_offload_bacspay';
    unLovedTables('valhead_temp') := 'valhead_temp';
    unLovedTables('valxrate_temp') := 'valxrate_temp';

    -- Category MV - Table created in 9i for Materialised views.
    --               MVIEWs are recreated in 11g, so we don't need these. 

    unLovedTables('investor_cat_mv') := 'investor_cat_mv';
    unLovedTables('ordtran_mv') := 'ordtran_mv';
        
    -- External Tabkles used for an old ThreadNeedle Street takeon. No longer
    -- required.
        
    unLovedTables('ext_thr_tblclient') := 'ext_thr_tblclient';
    unLovedTables('ext_thr_tblclientagreement') := 'ext_thr_tblclientagreement';
    unLovedTables('ext_thr_tblclientholding') := 'ext_thr_tblclientholding';
    unLovedTables('ext_thr_tblcontacts') := 'ext_thr_tblcontacts';
    unLovedTables('ext_thr_tbldetailtran') := 'ext_thr_tbldetailtran';
    unLovedTables('ext_thr_tblfund') := 'ext_thr_tblfund';
    unLovedTables('ext_thr_tblfundamc') := 'ext_thr_tblfundamc';
    unLovedTables('ext_thr_tblfundtype') := 'ext_thr_tblfundtype';
    unLovedTables('ext_thr_tblprice') := 'ext_thr_tblprice';
    unLovedTables('ext_thr_tbltransaction') := 'ext_thr_tbltransaction';
    unLovedTables('ext_thr_tbltranstype') := 'ext_thr_tbltranstype';
    unLovedTables('ext_thr_tblvaldate') := 'ext_thr_tblvaldate';
    unLovedTables('ext_thr_tblwithdrawalallowance') := 'ext_thr_tblwithdrawalallowance';
    
    -- ****************************************************************
    -- The following lists define the tables that might be in each
    -- of the various parameter files for the exports. There might
    -- be table names in the following whihc appear in the above
    -- list of "un loved tables" in which case, they will be omitted 
    -- from the export or the ROW data, but still will be included
    -- in the NOROW data export.
    --
    -- If a table is subsequently found to be needed, it can simply 
    -- be removed from the list above.
    --
    -- After the various imports, the tables should exists, with 
    -- constraints, BUT NO INDEXES as these are created with the 
    -- ROWS imports. Grants and constraints should be present, unless
    -- those rely on an existing index.
    -- ****************************************************************


    -- ****************************************************************
    -- The following MUST all be in lower case.    
    -- ****************************************************************
                
    

    -- Easy stuff now, one table only in each export - the biggies!
    -- And XML_FATCA_REPORTS whicjh we need a separate copy of.
    fcs1Tables('audit_log_detail') := 'audit_log_detail';   
    fcs3Tables('ordtran') := 'ordtran';
    fcs4Tables('stp_messages') := 'stp_messages';
    fcs5Tables('audit_log') := 'audit_log';
    fcs9Tables('xml_fatca_reports') := 'xml_fatca_reports';

    -- Getting harder now, a few tables...
    fcs6Tables('alert_log') := 'alert_log';
    fcs6Tables('audit_log_image') := 'audit_log_image';
    fcs6Tables('divpay') := 'divpay';
    fcs6Tables('emxtrans') := 'emxtrans';
    fcs6Tables('eventlog') := 'eventlog';
    fcs6Tables('fee_documents') := 'fee_documents';
    fcs6Tables('glacper') := 'glacper';
    fcs6Tables('glposts') := 'glposts';
    fcs6Tables('pso_investor_lookup') := 'pso_investor_lookup';
    fcs6Tables('renewal_commission') := 'renewal_commission'; 
    fcs6Tables('rl_valuation1') := 'rl_valuation1';


    -- BEWARE: The next table must be in mixed case. But only the
    --         table name, the collection index is still in lower case.
    --         The tablename must be wrapped in 3 (count them) double quotes.
    fcs8Tables('ukfatcasubmissionfire98_tab') := '"""UKFATCASubmissionFIRe98_TAB"""';
    fcs8Tables('email_attachment') := 'email_attachment';
    
    


    -- And now, a number of tables ...
    fcs7Tables('allocate') := 'allocate';
    fcs7Tables('audit_log_arch') := 'audit_log_arch';
    fcs7Tables('bacs_collection_dd') := 'bacs_collection_dd';
    fcs7Tables('bacs_collection_saver') := 'bacs_collection_saver';
    fcs7Tables('bbpriceimport') := 'bbpriceimport';
    fcs7Tables('cflowdet') := 'cflowdet';
    fcs7Tables('crexprop') := 'crexprop';
    fcs7Tables('emx_control_messages') := 'emx_control_messages';
    fcs7Tables('equalprt') := 'equalprt';
    fcs7Tables('error_log') := 'error_log';
    fcs7Tables('fd_kid_data') := 'fd_kid_data';
    fcs7Tables('fd_price') := 'fd_price';
    fcs7Tables('fd_srri_calc') := 'fd_srri_calc';
    fcs7Tables('fee_calc_detail') := 'fee_calc_detail';
    fcs7Tables('fee_error') := 'fee_error';
    fcs7Tables('fee_valuation') := 'fee_valuation';
    fcs7Tables('fixtrans') := 'fixtrans';
    fcs7Tables('glacmast') := 'glacmast';
    fcs7Tables('incexp_analysis') := 'incexp_analysis';
    fcs7Tables('incexp_analysis_ter') := 'incexp_analysis_ter';
    fcs7Tables('incexpit') := 'incexpit';
    fcs7Tables('ioe_price_import') := 'ioe_price_import';
    fcs7Tables('ir_valhold') := 'ir_valhold';
    fcs7Tables('log_header') := 'log_header';
    fcs7Tables('mansbox') := 'mansbox';
    fcs7Tables('memo') := 'memo';
    fcs7Tables('message_log') := 'message_log';
    fcs7Tables('mlog$_ordtran') := 'mlog$_ordtran';
    fcs7Tables('notific_email_log') := 'notific_email_log';
    fcs7Tables('oeiprice') := 'oeiprice';
    fcs7Tables('ordtran_backup') := 'ordtran_backup';
    fcs7Tables('ordtran_mi') := 'ordtran_mi';
    fcs7Tables('pfin_audit') := 'pfin_audit';
    fcs7Tables('pfout_far') := 'pfout_far';
    fcs7Tables('pricescrub') := 'pricescrub';
    fcs7Tables('psoaudit') := 'psoaudit';
    fcs7Tables('psochange') := 'psochange';
    fcs7Tables('repequal') := 'repequal';
    fcs7Tables('revunits') := 'revunits';
    fcs7Tables('rl_utrn_all') := 'rl_utrn_all';
    fcs7Tables('rl_zchfpf_isatot') := 'rl_zchfpf_isatot';
    fcs7Tables('signof') := 'signof';
    fcs7Tables('statement_investor') := 'statement_investor';
    fcs7Tables('stg_thr_tblclientholding') := 'stg_thr_tblclientholding';
    fcs7Tables('transact') := 'transact';
    fcs7Tables('transf_prog') := 'transf_prog';
    fcs7Tables('uvmes_email_log') := 'uvmes_email_log';
    fcs7Tables('valcheck') := 'valcheck';
    fcs7Tables('valsignof_detail') := 'valsignof_detail';
    fcs7Tables('valxrate') := 'valxrate';
    
    -- And now, the nightmare begins!
    fcs2Tables('abersdrt') := 'abersdrt';
    fcs2Tables('access_audit_log') := 'access_audit_log';
    fcs2Tables('access_error_log') := 'access_error_log';
    fcs2Tables('accrued_interest') := 'accrued_interest';
    fcs2Tables('activity') := 'activity';
    fcs2Tables('acx_extra_data') := 'acx_extra_data';
    fcs2Tables('acx_investor_prefs') := 'acx_investor_prefs';
    fcs2Tables('acx_inv_payment') := 'acx_inv_payment';
    fcs2Tables('acx_inv_payment_head') := 'acx_inv_payment_head';
    fcs2Tables('acx_inv_payment_stats') := 'acx_inv_payment_stats';
    fcs2Tables('acx_letter_file') := 'acx_letter_file';
    fcs2Tables('acx_letter_head') := 'acx_letter_head';
    fcs2Tables('acx_letter_log') := 'acx_letter_log';
    fcs2Tables('acx_letter_type') := 'acx_letter_type';
    fcs2Tables('acx_payment_head') := 'acx_payment_head';
    fcs2Tables('acx_payment_rates') := 'acx_payment_rates';
    fcs2Tables('acx_payment_trust') := 'acx_payment_trust';
    fcs2Tables('acx_register') := 'acx_register';
    fcs2Tables('acx_register_change') := 'acx_register_change';
    fcs2Tables('acx_response') := 'acx_response';
    fcs2Tables('acx_sap_holdings') := 'acx_sap_holdings';
    fcs2Tables('acx_trust_data') := 'acx_trust_data';
    fcs2Tables('ac_calc_detail') := 'ac_calc_detail';
    fcs2Tables('ac_calc_head') := 'ac_calc_head';
    fcs2Tables('ac_min_payment') := 'ac_min_payment';
    fcs2Tables('addcomm') := 'addcomm';
    fcs2Tables('addcomm_params') := 'addcomm_params';
    fcs2Tables('addlabs') := 'addlabs';
    fcs2Tables('address') := 'address';
    fcs2Tables('addressstatuscode') := 'addressstatuscode';
    fcs2Tables('addrpt') := 'addrpt';
    fcs2Tables('adhoc_report') := 'adhoc_report';
    fcs2Tables('adhoc_rep_destination') := 'adhoc_rep_destination';
    fcs2Tables('adhoc_rep_format') := 'adhoc_rep_format';
    fcs2Tables('adhoc_rep_history') := 'adhoc_rep_history';
    fcs2Tables('adhoc_rep_sql') := 'adhoc_rep_sql';
    fcs2Tables('advisercharge') := 'advisercharge';
    fcs2Tables('adviser_charge_history') := 'adviser_charge_history';
    fcs2Tables('adviser_charge_plan') := 'adviser_charge_plan';
    fcs2Tables('adviser_charge_receipts') := 'adviser_charge_receipts';
    fcs2Tables('adviser_charge_stop_reason') := 'adviser_charge_stop_reason';
    fcs2Tables('adviser_charge_supp') := 'adviser_charge_supp';
    fcs2Tables('alert_command') := 'alert_command';
    fcs2Tables('alert_config') := 'alert_config';
    fcs2Tables('alert_notification') := 'alert_notification';
    fcs2Tables('alert_rule') := 'alert_rule';
    fcs2Tables('alert_trigger') := 'alert_trigger';
    fcs2Tables('allfundlist') := 'allfundlist';
    fcs2Tables('amc_rate') := 'amc_rate';
    fcs2Tables('ap_authentication') := 'ap_authentication';
    fcs2Tables('archive_disk') := 'archive_disk';
    fcs2Tables('archive_disktype') := 'archive_disktype';
    fcs2Tables('archive_disk_folder') := 'archive_disk_folder';
    fcs2Tables('archive_folder_detail') := 'archive_folder_detail';
    fcs2Tables('arch_cru_deals_log') := 'arch_cru_deals_log';
    fcs2Tables('arch_cru_investor_prefs') := 'arch_cru_investor_prefs';
    fcs2Tables('arch_cru_letter_head') := 'arch_cru_letter_head';
    fcs2Tables('arch_cru_letter_log') := 'arch_cru_letter_log';
    fcs2Tables('arch_cru_letter_type') := 'arch_cru_letter_type';
    fcs2Tables('arch_cru_payment_head') := 'arch_cru_payment_head';
    fcs2Tables('arch_cru_payment_rate') := 'arch_cru_payment_rate';
    fcs2Tables('arch_cru_payment_rates') := 'arch_cru_payment_rates';
    fcs2Tables('arch_cru_payment_trust') := 'arch_cru_payment_trust';
    fcs2Tables('arch_cru_pay_log') := 'arch_cru_pay_log';
    fcs2Tables('artefact_revoke_reason') := 'artefact_revoke_reason';
    fcs2Tables('audit_log_detail_arch') := 'audit_log_detail_arch';
    fcs2Tables('audit_policies') := 'audit_policies';
    fcs2Tables('audit_tables') := 'audit_tables';
    fcs2Tables('audit_table_columns') := 'audit_table_columns';
    fcs2Tables('audlist') := 'audlist';
    fcs2Tables('auragroup') := 'auragroup';
    fcs2Tables('auragroupobject') := 'auragroupobject';
    fcs2Tables('auraobject') := 'auraobject';
    fcs2Tables('aurauser') := 'aurauser';
    fcs2Tables('aurauserdetail') := 'aurauserdetail';
    fcs2Tables('aurausergroup') := 'aurausergroup';
    fcs2Tables('aurauserobject') := 'aurauserobject';
    fcs2Tables('aura_departments') := 'aura_departments';
    fcs2Tables('aura_department_group') := 'aura_department_group';
    fcs2Tables('aura_logon') := 'aura_logon';
    fcs2Tables('aura_menu_favourite') := 'aura_menu_favourite';
    fcs2Tables('aura_menu_items') := 'aura_menu_items';
    fcs2Tables('aura_menu_profile') := 'aura_menu_profile';
    fcs2Tables('aura_package_debug') := 'aura_package_debug';
    fcs2Tables('aura_service_logs') := 'aura_service_logs';
    fcs2Tables('authmaint') := 'authmaint';
    fcs2Tables('autifprt') := 'autifprt';
    fcs2Tables('bacsacs') := 'bacsacs';
    fcs2Tables('bacsext') := 'bacsext';
    fcs2Tables('bacsext_temp') := 'bacsext_temp';
    fcs2Tables('bacspay') := 'bacspay';
    fcs2Tables('bacspay_173') := 'bacspay_173';
    fcs2Tables('bacspay_536_43466') := 'bacspay_536_43466';
    fcs2Tables('bacspay_702_43466') := 'bacspay_702_43466';
    fcs2Tables('bacs_arudd_deals') := 'bacs_arudd_deals';
    fcs2Tables('bacs_arudd_detail') := 'bacs_arudd_detail';
    fcs2Tables('bacs_arudd_head') := 'bacs_arudd_head';
    fcs2Tables('bacs_auddis_addacs_detail') := 'bacs_auddis_addacs_detail';
    fcs2Tables('bacs_auddis_addacs_head') := 'bacs_auddis_addacs_head';
    fcs2Tables('bacs_auddis_addacs_saver') := 'bacs_auddis_addacs_saver';
    fcs2Tables('bacs_auddis_detail') := 'bacs_auddis_detail';
    fcs2Tables('bacs_auddis_head') := 'bacs_auddis_head';
    fcs2Tables('bacs_auddis_status') := 'bacs_auddis_status';
    fcs2Tables('bacs_bank') := 'bacs_bank';
    fcs2Tables('bacs_collection_head') := 'bacs_collection_head';
    fcs2Tables('bacs_collection_saver_ext') := 'bacs_collection_saver_ext';
    fcs2Tables('bacs_config') := 'bacs_config';
    fcs2Tables('bacs_dd_xml') := 'bacs_dd_xml';
    fcs2Tables('bacs_error_config') := 'bacs_error_config';
    fcs2Tables('bacs_files') := 'bacs_files';
    fcs2Tables('bacs_interface') := 'bacs_interface';
    fcs2Tables('bacs_manager_sun') := 'bacs_manager_sun';
    fcs2Tables('bacs_payment_number') := 'bacs_payment_number';
    fcs2Tables('bacs_reason_codes') := 'bacs_reason_codes';
    fcs2Tables('bacs_sun') := 'bacs_sun';
    fcs2Tables('bai_interface_detail') := 'bai_interface_detail';
    fcs2Tables('bai_interface_header') := 'bai_interface_header';
    fcs2Tables('bai_interface_security') := 'bai_interface_security';
    fcs2Tables('bai_interface_trust') := 'bai_interface_trust';
    fcs2Tables('bankacs') := 'bankacs';
    fcs2Tables('bankofenglandsanctions') := 'bankofenglandsanctions';
    fcs2Tables('bankreceipts') := 'bankreceipts';
    fcs2Tables('bank_account') := 'bank_account';
    fcs2Tables('bank_account_type') := 'bank_account_type';
    fcs2Tables('bank_links') := 'bank_links';
    fcs2Tables('bank_parent_type') := 'bank_parent_type';
    fcs2Tables('bberrors') := 'bberrors';
    fcs2Tables('bbimport') := 'bbimport';
    fcs2Tables('bbmappingruledetail') := 'bbmappingruledetail';
    fcs2Tables('bbmappingruleheader') := 'bbmappingruleheader';
    fcs2Tables('bbovernight_log') := 'bbovernight_log';
    fcs2Tables('bbpricerequest') := 'bbpricerequest';
    fcs2Tables('bbprogramtype') := 'bbprogramtype';
    fcs2Tables('bbrequest') := 'bbrequest';
    fcs2Tables('bbsecurityafterupdate') := 'bbsecurityafterupdate';
    fcs2Tables('bbsecuritybackup') := 'bbsecuritybackup';
    fcs2Tables('bbuploadaudit') := 'bbuploadaudit';
    fcs2Tables('bcontact') := 'bcontact';
    fcs2Tables('bcpltran') := 'bcpltran';
    fcs2Tables('bec_bacspay_441') := 'bec_bacspay_441';
    fcs2Tables('bec_dividend_441') := 'bec_dividend_441';
    fcs2Tables('bec_divpay_441') := 'bec_divpay_441';
    fcs2Tables('bec_oeic_share_class_temp') := 'bec_oeic_share_class_temp';
    fcs2Tables('bec_ordtran_441') := 'bec_ordtran_441';
    fcs2Tables('bec_register_441') := 'bec_register_441';
    fcs2Tables('bec_saver_441') := 'bec_saver_441';
    fcs2Tables('bec_signof_441') := 'bec_signof_441';
    fcs2Tables('bec_temp_valhead') := 'bec_temp_valhead';
    fcs2Tables('bec_temp_valhold') := 'bec_temp_valhold';
    fcs2Tables('bec_temp_valxrate') := 'bec_temp_valxrate';
    fcs2Tables('bec_tsteerep_441') := 'bec_tsteerep_441';
    fcs2Tables('benchmark_details') := 'benchmark_details';
    fcs2Tables('ben_dist_hist') := 'ben_dist_hist';
    fcs2Tables('ben_dividend') := 'ben_dividend';
    fcs2Tables('ben_prices') := 'ben_prices';
    fcs2Tables('ben_register') := 'ben_register';
    fcs2Tables('ben_temp_dist_hist') := 'ben_temp_dist_hist';
    fcs2Tables('ben_temp_register') := 'ben_temp_register';
    fcs2Tables('ben_temp_transaction') := 'ben_temp_transaction';
    fcs2Tables('ben_transactions') := 'ben_transactions';
    fcs2Tables('ben_transtype') := 'ben_transtype';
    fcs2Tables('bevaim') := 'bevaim';
    fcs2Tables('bev_temp_glacper') := 'bev_temp_glacper';
    fcs2Tables('bev_temp_gllegfyr') := 'bev_temp_gllegfyr';
    fcs2Tables('bev_temp_glposts') := 'bev_temp_glposts';
    fcs2Tables('bev_temp_glposts_changed') := 'bev_temp_glposts_changed';
    fcs2Tables('bhols') := 'bhols';
    fcs2Tables('broker') := 'broker';
    fcs2Tables('broker_commission') := 'broker_commission';
    fcs2Tables('broker_detail') := 'broker_detail';
    fcs2Tables('broker_type') := 'broker_type';
    fcs2Tables('broker_was') := 'broker_was';
    fcs2Tables('bulk_stock_transfer_deal') := 'bulk_stock_transfer_deal';
    fcs2Tables('bulk_stock_transfer_detail') := 'bulk_stock_transfer_detail';
    fcs2Tables('bulk_stock_transfer_head') := 'bulk_stock_transfer_head';
    fcs2Tables('bulk_stock_transfer_state') := 'bulk_stock_transfer_state';
    fcs2Tables('business_partner_type') := 'business_partner_type';
    fcs2Tables('bwdclientdata') := 'bwdclientdata';
    fcs2Tables('bwdmsrep') := 'bwdmsrep';
    fcs2Tables('bwdrbill') := 'bwdrbill';
    fcs2Tables('bwdtemp01') := 'bwdtemp01';
    fcs2Tables('bwdtrlbal') := 'bwdtrlbal';
    fcs2Tables('bwd_ledgers') := 'bwd_ledgers';
    fcs2Tables('caevent_detail') := 'caevent_detail';
    fcs2Tables('caevent_header') := 'caevent_header';
    fcs2Tables('caevent_parameters') := 'caevent_parameters';
    fcs2Tables('caevent_update') := 'caevent_update';
    fcs2Tables('calset_failures') := 'calset_failures';
    fcs2Tables('calset_in_detail') := 'calset_in_detail';
    fcs2Tables('calset_in_header') := 'calset_in_header';
    fcs2Tables('canada_life_sectype') := 'canada_life_sectype';
    fcs2Tables('cancellation_rights') := 'cancellation_rights';
    fcs2Tables('capsil_deals') := 'capsil_deals';
    fcs2Tables('capsil_deals_ordtran') := 'capsil_deals_ordtran';
    fcs2Tables('capsil_deal_approvals') := 'capsil_deal_approvals';
    fcs2Tables('cashbkpt') := 'cashbkpt';
    fcs2Tables('cdd_address_type') := 'cdd_address_type';
    fcs2Tables('cdd_artefact') := 'cdd_artefact';
    fcs2Tables('cdd_role') := 'cdd_role';
    fcs2Tables('cdd_subcat_role') := 'cdd_subcat_role';
    fcs2Tables('cdtran') := 'cdtran';
    fcs2Tables('certcnt') := 'certcnt';
    fcs2Tables('certif') := 'certif';
    fcs2Tables('certifpt') := 'certifpt';
    fcs2Tables('cfa_dummy') := 'cfa_dummy';
    fcs2Tables('cflowbf') := 'cflowbf';
    fcs2Tables('cflow_dummy') := 'cflow_dummy';
    fcs2Tables('cfrun') := 'cfrun';
    fcs2Tables('cfsignof') := 'cfsignof';
    fcs2Tables('chaser_details') := 'chaser_details';
    fcs2Tables('chaser_letters') := 'chaser_letters';
    fcs2Tables('chaser_type') := 'chaser_type';
    fcs2Tables('checknames') := 'checknames';
    fcs2Tables('chksupervs') := 'chksupervs';
    fcs2Tables('clprfeed') := 'clprfeed';
    fcs2Tables('cl_takeon_balances') := 'cl_takeon_balances';
    fcs2Tables('cmar_rpt_cached_holdings') := 'cmar_rpt_cached_holdings';
    fcs2Tables('cminv') := 'cminv';
    fcs2Tables('cmsubtab') := 'cmsubtab';
    fcs2Tables('cmtab') := 'cmtab';
    fcs2Tables('cmttee') := 'cmttee';
    fcs2Tables('coa_suppression_log') := 'coa_suppression_log';
    fcs2Tables('codes_definition') := 'codes_definition';
    fcs2Tables('codes_description') := 'codes_description';
    fcs2Tables('comm_advised_status') := 'comm_advised_status';
    fcs2Tables('comtype') := 'comtype';
    fcs2Tables('connmonitor') := 'connmonitor';
    fcs2Tables('consstatementgroup') := 'consstatementgroup';
    fcs2Tables('consstatementholdings') := 'consstatementholdings';
    fcs2Tables('consstatementsnapshot') := 'consstatementsnapshot';
    fcs2Tables('consstatementtransactions') := 'consstatementtransactions';
    fcs2Tables('consstatsinvsprinted') := 'consstatsinvsprinted';
    fcs2Tables('consstatsinvstoprint') := 'consstatsinvstoprint';
    fcs2Tables('constatsexcludeifa') := 'constatsexcludeifa';
    fcs2Tables('contact_details') := 'contact_details';
    fcs2Tables('contact_types') := 'contact_types';
    fcs2Tables('contlist') := 'contlist';
    fcs2Tables('contnote') := 'contnote';
    fcs2Tables('contract_doc_type') := 'contract_doc_type';
    fcs2Tables('contract_output_contacts') := 'contract_output_contacts';
    fcs2Tables('contract_output_prefs') := 'contract_output_prefs';
    fcs2Tables('contract_output_trusts') := 'contract_output_trusts';
    fcs2Tables('contract_run') := 'contract_run';
    fcs2Tables('contract_run_trust') := 'contract_run_trust';
    fcs2Tables('converpt') := 'converpt';
    fcs2Tables('conversion_head') := 'conversion_head';
    fcs2Tables('conversion_in') := 'conversion_in';
    fcs2Tables('country') := 'country';
    fcs2Tables('coveralls') := 'coveralls';
    fcs2Tables('coverall_link_ifa') := 'coverall_link_ifa';
    fcs2Tables('coverall_link_investors') := 'coverall_link_investors';
    fcs2Tables('coverall_link_investors_rb') := 'coverall_link_investors_rb';
    fcs2Tables('coverall_link_trusts') := 'coverall_link_trusts';
    fcs2Tables('coverall_link_trusts_rb') := 'coverall_link_trusts_rb';
    fcs2Tables('crexprop_dup') := 'crexprop_dup';
    fcs2Tables('crexprop_rl_details') := 'crexprop_rl_details';
    fcs2Tables('crexprop_rl_header') := 'crexprop_rl_header';
    fcs2Tables('crexprop_rl_sharetot') := 'crexprop_rl_sharetot';
    fcs2Tables('crexpsum') := 'crexpsum';
    fcs2Tables('crs_classification_inv') := 'crs_classification_inv';
    fcs2Tables('crs_tin_type') := 'crs_tin_type';
    fcs2Tables('cty_agent') := 'cty_agent';
    fcs2Tables('cty_cdd_address_type') := 'cty_cdd_address_type';
    fcs2Tables('cty_cdd_artefact') := 'cty_cdd_artefact';
    fcs2Tables('cty_client') := 'cty_client';
    fcs2Tables('cty_cutas_xref') := 'cty_cutas_xref';
    fcs2Tables('cty_extracts') := 'cty_extracts';
    fcs2Tables('cty_fatca_exception') := 'cty_fatca_exception';
    fcs2Tables('cty_fatca_indicia') := 'cty_fatca_indicia';
    fcs2Tables('cty_holdings') := 'cty_holdings';
    fcs2Tables('cty_holdings_tax_credits') := 'cty_holdings_tax_credits';
    fcs2Tables('cty_indicia_doc_type') := 'cty_indicia_doc_type';
    fcs2Tables('cty_inv_cdd_det_status') := 'cty_inv_cdd_det_status';
    fcs2Tables('cty_isa_subscriptions') := 'cty_isa_subscriptions';
    fcs2Tables('cty_temp_holding') := 'cty_temp_holding';
    fcs2Tables('cty_temp_ifa') := 'cty_temp_ifa';
    fcs2Tables('cty_temp_investor') := 'cty_temp_investor';
    fcs2Tables('curing_doc_type') := 'curing_doc_type';
    fcs2Tables('currency') := 'currency';
    fcs2Tables('daily_fee_month_rept') := 'daily_fee_month_rept';
    fcs2Tables('dba_audit') := 'dba_audit';
    fcs2Tables('dba_audit_ddl') := 'dba_audit_ddl';
    fcs2Tables('dbmonitor') := 'dbmonitor';
    fcs2Tables('dbmonitorprograms') := 'dbmonitorprograms';
    fcs2Tables('deallist') := 'deallist';
    fcs2Tables('deallist_temp') := 'deallist_temp';
    fcs2Tables('deal_checked') := 'deal_checked';
    fcs2Tables('delayed_dealing') := 'delayed_dealing';
    fcs2Tables('departments') := 'departments';
    fcs2Tables('department_letters') := 'department_letters';
    fcs2Tables('dfeed') := 'dfeed';
    fcs2Tables('dillevy') := 'dillevy';
    fcs2Tables('discount') := 'discount';
    fcs2Tables('dist_cons_mast') := 'dist_cons_mast';
    fcs2Tables('dist_cons_noms') := 'dist_cons_noms';
    fcs2Tables('dist_end_of_day') := 'dist_end_of_day';
    fcs2Tables('dist_print_codes') := 'dist_print_codes';
    fcs2Tables('dist_sort_order') := 'dist_sort_order';
    fcs2Tables('dist_stream_calc') := 'dist_stream_calc';
    fcs2Tables('dist_stream_calc_est') := 'dist_stream_calc_est';
    fcs2Tables('dist_stream_rates') := 'dist_stream_rates';
    fcs2Tables('dist_stream_tax') := 'dist_stream_tax';
    fcs2Tables('dist_stream_types') := 'dist_stream_types';
    fcs2Tables('dist_trst_prtcode_sup') := 'dist_trst_prtcode_sup';
    fcs2Tables('dist_variables') := 'dist_variables';
    fcs2Tables('divdiary') := 'divdiary';
    fcs2Tables('divdiary_17957_backup_27jul') := 'divdiary_17957_backup_27jul';
    fcs2Tables('divdiary_17957_bkp_del_28jul') := 'divdiary_17957_bkp_del_28jul';
    fcs2Tables('divfcast') := 'divfcast';
    fcs2Tables('divforec') := 'divforec';
    fcs2Tables('dividend') := 'dividend';
    fcs2Tables('dividend_173') := 'dividend_173';
    fcs2Tables('dividend_536_43466') := 'dividend_536_43466';
    fcs2Tables('dividend_702_43466') := 'dividend_702_43466';
    fcs2Tables('dividend_tax_rate') := 'dividend_tax_rate';
    fcs2Tables('dividend_tax_rate_historic') := 'dividend_tax_rate_historic';
    fcs2Tables('divpay_173') := 'divpay_173';
    fcs2Tables('divpay_536_43466') := 'divpay_536_43466';
    fcs2Tables('divpay_702_43466') := 'divpay_702_43466';
    fcs2Tables('divpay_89848') := 'divpay_89848';
    fcs2Tables('divpay_control') := 'divpay_control';
    fcs2Tables('divpay_est') := 'divpay_est';
    fcs2Tables('divptran') := 'divptran';
    fcs2Tables('di_param_set_value') := 'di_param_set_value';
    fcs2Tables('di_request') := 'di_request';
    fcs2Tables('dldirml_g') := 'dldirml_g';
    fcs2Tables('dlevytab') := 'dlevytab';
    fcs2Tables('document_image') := 'document_image';
    fcs2Tables('document_types') := 'document_types';
    fcs2Tables('doposts_parameter') := 'doposts_parameter';
    fcs2Tables('dummy') := 'dummy';
    fcs2Tables('dytrdrpt') := 'dytrdrpt';
    fcs2Tables('emailaddr') := 'emailaddr';
    fcs2Tables('emailparenttype') := 'emailparenttype';
    fcs2Tables('emailtype') := 'emailtype';
    fcs2Tables('email_domains') := 'email_domains';
    fcs2Tables('email_format') := 'email_format';
    fcs2Tables('email_global_config') := 'email_global_config';
    fcs2Tables('email_history') := 'email_history';
    fcs2Tables('email_log') := 'email_log';
    fcs2Tables('email_logs') := 'email_logs';
    fcs2Tables('email_message') := 'email_message';
    fcs2Tables('email_names') := 'email_names';
    fcs2Tables('emxerrorlist') := 'emxerrorlist';
    fcs2Tables('emxfiles') := 'emxfiles';
    fcs2Tables('emxorderdef') := 'emxorderdef';
    fcs2Tables('emxoriginator') := 'emxoriginator';
    fcs2Tables('emxprovider') := 'emxprovider';
    fcs2Tables('emxvalreq') := 'emxvalreq';
    fcs2Tables('emx_fund_ifa_exceptions') := 'emx_fund_ifa_exceptions';
    fcs2Tables('emx_provider_details') := 'emx_provider_details';
    fcs2Tables('emx_sessions') := 'emx_sessions';
    fcs2Tables('emx_trans_error_log') := 'emx_trans_error_log';
    fcs2Tables('emx_valuation_error_log') := 'emx_valuation_error_log';
    fcs2Tables('eq_trsttype_params') := 'eq_trsttype_params';
    fcs2Tables('eq_trust_params') := 'eq_trust_params';
    fcs2Tables('er_agent') := 'er_agent';
    fcs2Tables('er_client') := 'er_client';
    fcs2Tables('er_deals_019') := 'er_deals_019';
    fcs2Tables('er_holdings') := 'er_holdings';
    fcs2Tables('er_ifa_xref') := 'er_ifa_xref';
    fcs2Tables('er_nominee_xref') := 'er_nominee_xref';
    fcs2Tables('er_price') := 'er_price';
    fcs2Tables('er_temp_holding') := 'er_temp_holding';
    fcs2Tables('er_temp_ifa') := 'er_temp_ifa';
    fcs2Tables('er_temp_investor') := 'er_temp_investor';
    fcs2Tables('eusdpct') := 'eusdpct';
    fcs2Tables('eusdtrsta') := 'eusdtrsta';
    fcs2Tables('eventlogtype') := 'eventlogtype';
    fcs2Tables('eventnumbers') := 'eventnumbers';
    fcs2Tables('eventtype') := 'eventtype';
    fcs2Tables('exception_user_defined') := 'exception_user_defined';
    fcs2Tables('exchrate') := 'exchrate';
    fcs2Tables('exclude_manager_ac') := 'exclude_manager_ac';
    fcs2Tables('exclude_trust') := 'exclude_trust';
    fcs2Tables('exclude_trust_ac') := 'exclude_trust_ac';
    fcs2Tables('executive') := 'executive';
    fcs2Tables('executive_link') := 'executive_link';
    fcs2Tables('exfin') := 'exfin';
    fcs2Tables('exhisreg') := 'exhisreg';
    fcs2Tables('expcash') := 'expcash';
    fcs2Tables('exrate_feed') := 'exrate_feed';
    fcs2Tables('exregist') := 'exregist';
    fcs2Tables('exshsreg') := 'exshsreg';
    fcs2Tables('exsubreg') := 'exsubreg';
    fcs2Tables('extnfundlvl') := 'extnfundlvl';
    fcs2Tables('extninterface') := 'extninterface';
    fcs2Tables('extnsubfund') := 'extnsubfund';
    fcs2Tables('ext_thr_tblclient') := 'ext_thr_tblclient';
    fcs2Tables('ext_thr_tblclientagreement') := 'ext_thr_tblclientagreement';
    fcs2Tables('ext_thr_tblclientholding') := 'ext_thr_tblclientholding';
    fcs2Tables('ext_thr_tblcontacts') := 'ext_thr_tblcontacts';
    fcs2Tables('ext_thr_tbldetailtran') := 'ext_thr_tbldetailtran';
    fcs2Tables('ext_thr_tblfund') := 'ext_thr_tblfund';
    fcs2Tables('ext_thr_tblfundamc') := 'ext_thr_tblfundamc';
    fcs2Tables('ext_thr_tblfundtype') := 'ext_thr_tblfundtype';
    fcs2Tables('ext_thr_tblprice') := 'ext_thr_tblprice';
    fcs2Tables('ext_thr_tbltransaction') := 'ext_thr_tbltransaction';
    fcs2Tables('ext_thr_tbltranstype') := 'ext_thr_tbltranstype';
    fcs2Tables('ext_thr_tblvaldate') := 'ext_thr_tblvaldate';
    fcs2Tables('ext_thr_tblwithdrawalallowance') := 'ext_thr_tblwithdrawalallowance';
    fcs2Tables('failed_bacs_dd') := 'failed_bacs_dd';
    fcs2Tables('far_interface_detail') := 'far_interface_detail';
    fcs2Tables('far_interface_header') := 'far_interface_header';
    fcs2Tables('far_interface_trust') := 'far_interface_trust';
    fcs2Tables('far_tranche') := 'far_tranche';
    fcs2Tables('fatca_accountstructure') := 'fatca_accountstructure';
    fcs2Tables('fatca_address') := 'fatca_address';
    fcs2Tables('fatca_address_favourites') := 'fatca_address_favourites';
    fcs2Tables('fatca_asset_type') := 'fatca_asset_type';
    fcs2Tables('fatca_asset_type_mapping') := 'fatca_asset_type_mapping';
    fcs2Tables('fatca_authorised_prod_type') := 'fatca_authorised_prod_type';
    fcs2Tables('fatca_chaser_frequency') := 'fatca_chaser_frequency';
    fcs2Tables('fatca_classification_inv') := 'fatca_classification_inv';
    fcs2Tables('fatca_contact') := 'fatca_contact';
    fcs2Tables('fatca_curing_letter') := 'fatca_curing_letter';
    fcs2Tables('fatca_deminimus_threshold') := 'fatca_deminimus_threshold';
    fcs2Tables('fatca_distributed_countries') := 'fatca_distributed_countries';
    fcs2Tables('fatca_eligible_markets') := 'fatca_eligible_markets';
    fcs2Tables('fatca_eligible_market_mapping') := 'fatca_eligible_market_mapping';
    fcs2Tables('fatca_extract_audit') := 'fatca_extract_audit';
    fcs2Tables('fatca_extract_fav') := 'fatca_extract_fav';
    fcs2Tables('fatca_fatca_classification') := 'fatca_fatca_classification';
    fcs2Tables('fatca_fatca_indicator') := 'fatca_fatca_indicator';
    fcs2Tables('fatca_file_accountdata') := 'fatca_file_accountdata';
    fcs2Tables('fatca_file_accountdata_amt') := 'fatca_file_accountdata_amt';
    fcs2Tables('fatca_file_fi_return') := 'fatca_file_fi_return';
    fcs2Tables('fatca_file_jurisdiction') := 'fatca_file_jurisdiction';
    fcs2Tables('fatca_file_message_cat') := 'fatca_file_message_cat';
    fcs2Tables('fatca_file_organisation') := 'fatca_file_organisation';
    fcs2Tables('fatca_file_person') := 'fatca_file_person';
    fcs2Tables('fatca_file_status') := 'fatca_file_status';
    fcs2Tables('fatca_file_submission') := 'fatca_file_submission';
    fcs2Tables('fatca_fi_type') := 'fatca_fi_type';
    fcs2Tables('fatca_fund') := 'fatca_fund';
    fcs2Tables('fatca_fund_imd_mapping') := 'fatca_fund_imd_mapping';
    fcs2Tables('fatca_fund_sponsor') := 'fatca_fund_sponsor';
    fcs2Tables('fatca_fund_sponsor_mapping') := 'fatca_fund_sponsor_mapping';
    fcs2Tables('fatca_fund_status') := 'fatca_fund_status';
    fcs2Tables('fatca_ima_sector') := 'fatca_ima_sector';
    fcs2Tables('fatca_indicia') := 'fatca_indicia';
    fcs2Tables('fatca_investment_type') := 'fatca_investment_type';
    fcs2Tables('fatca_investor_docrequests') := 'fatca_investor_docrequests';
    fcs2Tables('fatca_legislation') := 'fatca_legislation';
    fcs2Tables('fatca_letter_sets') := 'fatca_letter_sets';
    fcs2Tables('fatca_letter_sets_detail') := 'fatca_letter_sets_detail';
    fcs2Tables('fatca_reporting_group') := 'fatca_reporting_group';
    fcs2Tables('fatca_reporting_history') := 'fatca_reporting_history';
    fcs2Tables('fatca_reporting_period') := 'fatca_reporting_period';
    fcs2Tables('fatca_reporting_rollback') := 'fatca_reporting_rollback';
    fcs2Tables('fatca_rep_hist_selfcert') := 'fatca_rep_hist_selfcert';
    fcs2Tables('fatca_rep_per_selfcert') := 'fatca_rep_per_selfcert';
    fcs2Tables('fatca_servicemodel') := 'fatca_servicemodel';
    fcs2Tables('fatca_tele_letter') := 'fatca_tele_letter';
    fcs2Tables('fc_classification') := 'fc_classification';
    fcs2Tables('fc_external') := 'fc_external';
    fcs2Tables('fc_share_class_allocation') := 'fc_share_class_allocation';
    fcs2Tables('fc_share_class_value') := 'fc_share_class_value';
    fcs2Tables('fd_attachment') := 'fd_attachment';
    fcs2Tables('fd_benchmark_req_detail') := 'fd_benchmark_req_detail';
    fcs2Tables('fd_benchmark_req_head') := 'fd_benchmark_req_head';
    fcs2Tables('fd_country') := 'fd_country';
    fcs2Tables('fd_distribution') := 'fd_distribution';
    fcs2Tables('fd_distribution_factor') := 'fd_distribution_factor';
    fcs2Tables('fd_field') := 'fd_field';
    fcs2Tables('fd_field_section') := 'fd_field_section';
    fcs2Tables('fd_fund') := 'fd_fund';
    fcs2Tables('fd_fund_action') := 'fd_fund_action';
    fcs2Tables('fd_fund_benchmark') := 'fd_fund_benchmark';
    fcs2Tables('fd_fund_benchmark_link') := 'fd_fund_benchmark_link';
    fcs2Tables('fd_fund_lang') := 'fd_fund_lang';
    fcs2Tables('fd_fund_lang_xref') := 'fd_fund_lang_xref';
    fcs2Tables('fd_fund_prosp_lang_xref') := 'fd_fund_prosp_lang_xref';
    fcs2Tables('fd_host') := 'fd_host';
    fcs2Tables('fd_image') := 'fd_image';
    fcs2Tables('fd_imd') := 'fd_imd';
    fcs2Tables('fd_imd_to_fund_mapping') := 'fd_imd_to_fund_mapping';
    fcs2Tables('fd_kid') := 'fd_kid';
    fcs2Tables('fd_kid_attachment') := 'fd_kid_attachment';
    fcs2Tables('fd_kid_data_struct_graph') := 'fd_kid_data_struct_graph';
    fcs2Tables('fd_kid_data_struct_image') := 'fd_kid_data_struct_image';
    fcs2Tables('fd_kid_data_struct_table') := 'fd_kid_data_struct_table';
    fcs2Tables('fd_kid_head') := 'fd_kid_head';
    fcs2Tables('fd_kid_template') := 'fd_kid_template';
    fcs2Tables('fd_kid_template_type') := 'fd_kid_template_type';
    fcs2Tables('fd_language') := 'fd_language';
    fcs2Tables('fd_manager') := 'fd_manager';
    fcs2Tables('fd_market_index') := 'fd_market_index';
    fcs2Tables('fd_market_index_value') := 'fd_market_index_value';
    fcs2Tables('fd_memo') := 'fd_memo';
    fcs2Tables('fd_paragraph') := 'fd_paragraph';
    fcs2Tables('fd_paragraph_text') := 'fd_paragraph_text';
    fcs2Tables('fd_performance') := 'fd_performance';
    fcs2Tables('fd_platform') := 'fd_platform';
    fcs2Tables('fd_platform_notification') := 'fd_platform_notification';
    fcs2Tables('fd_platform_ntf_state') := 'fd_platform_ntf_state';
    fcs2Tables('fd_platform_status') := 'fd_platform_status';
    fcs2Tables('fd_share_class') := 'fd_share_class';
    fcs2Tables('fd_share_class_benchmark') := 'fd_share_class_benchmark';
    fcs2Tables('fd_share_class_join_d') := 'fd_share_class_join_d';
    fcs2Tables('fd_share_class_join_h') := 'fd_share_class_join_h';
    fcs2Tables('fd_share_class_lang') := 'fd_share_class_lang';
    fcs2Tables('fd_share_class_struct_graph') := 'fd_share_class_struct_graph';
    fcs2Tables('fd_share_class_struct_image') := 'fd_share_class_struct_image';
    fcs2Tables('fd_share_class_struct_table') := 'fd_share_class_struct_table';
    fcs2Tables('fd_srri') := 'fd_srri';
    fcs2Tables('fd_srri_exception') := 'fd_srri_exception';
    fcs2Tables('fd_srri_method') := 'fd_srri_method';
    fcs2Tables('fd_srri_published') := 'fd_srri_published';
    fcs2Tables('fd_ucits_type') := 'fd_ucits_type';
    fcs2Tables('fees') := 'fees';
    fcs2Tables('fees_journal') := 'fees_journal';
    fcs2Tables('fees_range') := 'fees_range';
    fcs2Tables('fees_reference_data') := 'fees_reference_data';
    fcs2Tables('fees_reports') := 'fees_reports';
    fcs2Tables('fees_to_run') := 'fees_to_run';
    fcs2Tables('fee_ac_adjust') := 'fee_ac_adjust';
    fcs2Tables('fee_ac_calc_value') := 'fee_ac_calc_value';
    fcs2Tables('fee_ac_deals') := 'fee_ac_deals';
    fcs2Tables('fee_ac_funds') := 'fee_ac_funds';
    fcs2Tables('fee_ac_master_adj') := 'fee_ac_master_adj';
    fcs2Tables('fee_ac_payment') := 'fee_ac_payment';
    fcs2Tables('fee_ac_rule') := 'fee_ac_rule';
    fcs2Tables('fee_ac_rules') := 'fee_ac_rules';
    fcs2Tables('fee_addcomm') := 'fee_addcomm';
    fcs2Tables('fee_adjust') := 'fee_adjust';
    fcs2Tables('fee_calc') := 'fee_calc';
    fcs2Tables('fee_calc_detail') := 'fee_calc_detail';
    fcs2Tables('fee_calc_detail_08102004') := 'fee_calc_detail_08102004';
    fcs2Tables('fee_calc_detail_test') := 'fee_calc_detail_test';
    fcs2Tables('fee_calc_master') := 'fee_calc_master';
    fcs2Tables('fee_calc_master_test') := 'fee_calc_master_test';
    fcs2Tables('fee_calc_monthly') := 'fee_calc_monthly';
    fcs2Tables('fee_calc_value') := 'fee_calc_value';
    fcs2Tables('fee_history') := 'fee_history';
    fcs2Tables('fee_im') := 'fee_im';
    fcs2Tables('fee_investment_manager') := 'fee_investment_manager';
    fcs2Tables('fee_process') := 'fee_process';
    fcs2Tables('fee_run') := 'fee_run';
    fcs2Tables('fee_run_type') := 'fee_run_type';
    fcs2Tables('fee_scale') := 'fee_scale';
    fcs2Tables('fee_scale_10oct2005') := 'fee_scale_10oct2005';
    fcs2Tables('fee_sponsor') := 'fee_sponsor';
    fcs2Tables('fee_tolerance') := 'fee_tolerance';
    fcs2Tables('fee_trust') := 'fee_trust';
    fcs2Tables('fee_type') := 'fee_type';
    fcs2Tables('fiaccdex') := 'fiaccdex';
    fcs2Tables('fiaccrue') := 'fiaccrue';
    fcs2Tables('file_to_db') := 'file_to_db';
    fcs2Tables('fixyield') := 'fixyield';
    fcs2Tables('fncgroup') := 'fncgroup';
    fcs2Tables('fnfeed') := 'fnfeed';
    fcs2Tables('fof_details') := 'fof_details';
    fcs2Tables('fof_upload_details') := 'fof_upload_details';
    fcs2Tables('fs2_jointholders') := 'fs2_jointholders';
    fcs2Tables('fs2_temp_jointholders') := 'fs2_temp_jointholders';
    fcs2Tables('fs3_int_ifa') := 'fs3_int_ifa';
    fcs2Tables('fs3_int_investor') := 'fs3_int_investor';
    fcs2Tables('fs3_int_isaplan') := 'fs3_int_isaplan';
    fcs2Tables('fs3_int_isatot') := 'fs3_int_isatot';
    fcs2Tables('fs3_int_ordtran') := 'fs3_int_ordtran';
    fcs2Tables('fs3_int_register') := 'fs3_int_register';
    fcs2Tables('fs3_int_saver') := 'fs3_int_saver';
    fcs2Tables('fsa_file_loaded') := 'fsa_file_loaded';
    fcs2Tables('fsa_reg_firm_appointment') := 'fsa_reg_firm_appointment';
    fcs2Tables('fsa_reg_firm_authorisation') := 'fsa_reg_firm_authorisation';
    fcs2Tables('fs_agent') := 'fs_agent';
    fcs2Tables('fs_fund_profile') := 'fs_fund_profile';
    fcs2Tables('fs_holding') := 'fs_holding';
    fcs2Tables('fs_investment_history') := 'fs_investment_history';
    fcs2Tables('fs_investor') := 'fs_investor';
    fcs2Tables('fs_ml_detail') := 'fs_ml_detail';
    fcs2Tables('fs_portfolio') := 'fs_portfolio';
    fcs2Tables('fs_product') := 'fs_product';
    fcs2Tables('fs_regular_investment') := 'fs_regular_investment';
    fcs2Tables('fs_temp_holding') := 'fs_temp_holding';
    fcs2Tables('fs_temp_ifa') := 'fs_temp_ifa';
    fcs2Tables('fs_temp_investor') := 'fs_temp_investor';
    fcs2Tables('fs_temp_isaplan') := 'fs_temp_isaplan';
    fcs2Tables('fs_xref_ifa') := 'fs_xref_ifa';
    fcs2Tables('ftp_login') := 'ftp_login';
    fcs2Tables('ftp_scheduler') := 'ftp_scheduler';
    fcs2Tables('fundowner') := 'fundowner';
    fcs2Tables('fundtotp') := 'fundtotp';
    fcs2Tables('fundtotpr') := 'fundtotpr';
    fcs2Tables('fundval') := 'fundval';
    fcs2Tables('fund_classification') := 'fund_classification';
    fcs2Tables('fund_group_header') := 'fund_group_header';
    fcs2Tables('fund_group_member') := 'fund_group_member';
    fcs2Tables('fund_group_type') := 'fund_group_type';
    fcs2Tables('fund_imst_delegate_manager') := 'fund_imst_delegate_manager';
    fcs2Tables('fund_merger') := 'fund_merger';
    fcs2Tables('fund_offset_day') := 'fund_offset_day';
    fcs2Tables('fund_relationship_manager') := 'fund_relationship_manager';
    fcs2Tables('fund_usage') := 'fund_usage';
    fcs2Tables('fund_val_configuration') := 'fund_val_configuration';
    fcs2Tables('fwdexfin') := 'fwdexfin';
    fcs2Tables('fxfwdclose') := 'fxfwdclose';
    fcs2Tables('fxfwdclose_detail') := 'fxfwdclose_detail';
    fcs2Tables('fxfwdtran') := 'fxfwdtran';
    fcs2Tables('fxfwdtranp') := 'fxfwdtranp';
    fcs2Tables('fxsett') := 'fxsett';
    fcs2Tables('fxtran') := 'fxtran';
    fcs2Tables('glbatch') := 'glbatch';
    fcs2Tables('glbdalfc') := 'glbdalfc';
    fcs2Tables('glbdalms') := 'glbdalms';
    fcs2Tables('glbdmast') := 'glbdmast';
    fcs2Tables('glbdper') := 'glbdper';
    fcs2Tables('glbudtb') := 'glbudtb';
    fcs2Tables('glcadef') := 'glcadef';
    fcs2Tables('glcalfyp') := 'glcalfyp';
    fcs2Tables('glcalfyr') := 'glcalfyr';
    fcs2Tables('glcalmast') := 'glcalmast';
    fcs2Tables('glcamast') := 'glcamast';
    fcs2Tables('glgroup') := 'glgroup';
    fcs2Tables('glgroup_lgmast') := 'glgroup_lgmast';
    fcs2Tables('glinvs') := 'glinvs';
    fcs2Tables('gllegfyp') := 'gllegfyp';
    fcs2Tables('gllegfyr') := 'gllegfyr';
    fcs2Tables('gllgmast') := 'gllgmast';
    fcs2Tables('glrbhead') := 'glrbhead';
    fcs2Tables('glrddef') := 'glrddef';
    fcs2Tables('glrdhead') := 'glrdhead';
    fcs2Tables('glrdmast') := 'glrdmast';
    fcs2Tables('glrecb') := 'glrecb';
    fcs2Tables('glrep') := 'glrep';
    fcs2Tables('glsalinv') := 'glsalinv';
    fcs2Tables('glsite') := 'glsite';
    fcs2Tables('glskelac') := 'glskelac';
    fcs2Tables('glskelmast') := 'glskelmast';
    fcs2Tables('gltbal') := 'gltbal';
    fcs2Tables('gp_datatype') := 'gp_datatype';
    fcs2Tables('gp_globalparam') := 'gp_globalparam';
    fcs2Tables('gp_group') := 'gp_group';
    fcs2Tables('gp_values') := 'gp_values';
    fcs2Tables('gry_valhead') := 'gry_valhead';
    fcs2Tables('gry_valiteration') := 'gry_valiteration';
    fcs2Tables('gry_valperiod') := 'gry_valperiod';
    fcs2Tables('gtt_capsil_uv_order_map') := 'gtt_capsil_uv_order_map';
    fcs2Tables('gtt_fund_exclusion') := 'gtt_fund_exclusion';
    fcs2Tables('helpdesk_user') := 'helpdesk_user';
    fcs2Tables('helphead') := 'helphead';
    fcs2Tables('helptext') := 'helptext';
    fcs2Tables('holderpt') := 'holderpt';
    fcs2Tables('holders') := 'holders';
    fcs2Tables('holding') := 'holding';
    fcs2Tables('iapxtb') := 'iapxtb';
    fcs2Tables('ic_calc_detail') := 'ic_calc_detail';
    fcs2Tables('ic_calc_head') := 'ic_calc_head';
    fcs2Tables('ic_min_payment') := 'ic_min_payment';
    fcs2Tables('ifa') := 'ifa';
    fcs2Tables('ifacomst') := 'ifacomst';
    fcs2Tables('ifacomst_arch') := 'ifacomst_arch';
    fcs2Tables('ifarecom') := 'ifarecom';
    fcs2Tables('ifarecpf') := 'ifarecpf';
    fcs2Tables('ifarenst') := 'ifarenst';
    fcs2Tables('ifarenst_t') := 'ifarenst_t';
    fcs2Tables('ifatemp') := 'ifatemp';
    fcs2Tables('ifatrail') := 'ifatrail';
    fcs2Tables('ifa_bank') := 'ifa_bank';
    fcs2Tables('ifa_dilution_levy_maint') := 'ifa_dilution_levy_maint';
    fcs2Tables('ifa_discounts') := 'ifa_discounts';
    fcs2Tables('ifa_discount_terms') := 'ifa_discount_terms';
    fcs2Tables('ifa_discount_terms_audit') := 'ifa_discount_terms_audit';
    fcs2Tables('ifa_discount_terms_group') := 'ifa_discount_terms_group';
    fcs2Tables('ifa_fundowner') := 'ifa_fundowner';
    fcs2Tables('ifa_large_sales') := 'ifa_large_sales';
    fcs2Tables('ima_temp') := 'ima_temp';
    fcs2Tables('ima_trust') := 'ima_trust';
    fcs2Tables('incexppt') := 'incexppt';
    fcs2Tables('incexptp') := 'incexptp';
    fcs2Tables('incexptp_ter') := 'incexptp_ter';
    fcs2Tables('incexptx') := 'incexptx';
    fcs2Tables('incexp_analysis_audit') := 'incexp_analysis_audit';
    fcs2Tables('incexp_ter_output') := 'incexp_ter_output';
    fcs2Tables('increcd') := 'increcd';
    fcs2Tables('inctax') := 'inctax';
    fcs2Tables('inspecie_takeon') := 'inspecie_takeon';
    fcs2Tables('invadv') := 'invadv';
    fcs2Tables('invcstex') := 'invcstex';
    fcs2Tables('invesco_sedol_xref') := 'invesco_sedol_xref';
    fcs2Tables('investor') := 'investor';
    fcs2Tables('investorbank') := 'investorbank';
    fcs2Tables('investorbanktemp') := 'investorbanktemp';
    fcs2Tables('investorbank_89848') := 'investorbank_89848';
    fcs2Tables('investor_89848') := 'investor_89848';
    fcs2Tables('investor_check') := 'investor_check';
    fcs2Tables('investor_cosr_detail') := 'investor_cosr_detail';
    fcs2Tables('investor_cosr_head') := 'investor_cosr_head';
    fcs2Tables('investor_dup') := 'investor_dup';
    fcs2Tables('investor_edd') := 'investor_edd';
    fcs2Tables('investor_fowner') := 'investor_fowner';
    fcs2Tables('investor_kyc_detail') := 'investor_kyc_detail';
    fcs2Tables('investor_manager_pens') := 'investor_manager_pens';
    fcs2Tables('investor_manager_pwd') := 'investor_manager_pwd';
    fcs2Tables('investor_mandate') := 'investor_mandate';
    fcs2Tables('investor_ref') := 'investor_ref';
    fcs2Tables('investor_rollback') := 'investor_rollback';
    fcs2Tables('investor_taxye') := 'investor_taxye';
    fcs2Tables('investor_territory') := 'investor_territory';
    fcs2Tables('investor_trust_pens') := 'investor_trust_pens';
    fcs2Tables('investor_usage') := 'investor_usage';
    fcs2Tables('investor_withdrawal_limit') := 'investor_withdrawal_limit';
    fcs2Tables('invhist') := 'invhist';
    fcs2Tables('invhldds') := 'invhldds';
    fcs2Tables('invmerge_log') := 'invmerge_log';
    fcs2Tables('invvalpt') := 'invvalpt';
    fcs2Tables('inv_851') := 'inv_851';
    fcs2Tables('inv_adress_tmp') := 'inv_adress_tmp';
    fcs2Tables('inv_agent') := 'inv_agent';
    fcs2Tables('inv_cdd_address') := 'inv_cdd_address';
    fcs2Tables('inv_cdd_artefact_certifier') := 'inv_cdd_artefact_certifier';
    fcs2Tables('inv_cdd_artefact_cort') := 'inv_cdd_artefact_cort';
    fcs2Tables('inv_cdd_artefact_detail') := 'inv_cdd_artefact_detail';
    fcs2Tables('inv_cdd_attorney') := 'inv_cdd_attorney';
    fcs2Tables('inv_cdd_detail') := 'inv_cdd_detail';
    fcs2Tables('inv_cdd_legal_doc') := 'inv_cdd_legal_doc';
    fcs2Tables('inv_cdd_liquidation') := 'inv_cdd_liquidation';
    fcs2Tables('inv_cdd_selfcert') := 'inv_cdd_selfcert';
    fcs2Tables('inv_cdd_territory') := 'inv_cdd_territory';
    fcs2Tables('inv_edd_review') := 'inv_edd_review';
    fcs2Tables('inv_edd_sma') := 'inv_edd_sma';
    fcs2Tables('inv_fatca_indicia') := 'inv_fatca_indicia';
    fcs2Tables('inv_holding') := 'inv_holding';
    fcs2Tables('inv_investor') := 'inv_investor';
    fcs2Tables('inv_memos') := 'inv_memos';
    fcs2Tables('inv_ml_detail') := 'inv_ml_detail';
    fcs2Tables('inv_nominee_xref') := 'inv_nominee_xref';
    fcs2Tables('inv_portfolio') := 'inv_portfolio';
    fcs2Tables('inv_temp_holding') := 'inv_temp_holding';
    fcs2Tables('inv_temp_ifa') := 'inv_temp_ifa';
    fcs2Tables('inv_temp_investor') := 'inv_temp_investor';
    fcs2Tables('inv_temp_transaction') := 'inv_temp_transaction';
    fcs2Tables('inv_transaction_history') := 'inv_transaction_history';
    fcs2Tables('inv_xref_ifa') := 'inv_xref_ifa';
    fcs2Tables('ioe_sdrt_transf') := 'ioe_sdrt_transf';
    fcs2Tables('ioe_transf') := 'ioe_transf';
    fcs2Tables('ioe_transf_conversion') := 'ioe_transf_conversion';
    fcs2Tables('ioe_valfreq') := 'ioe_valfreq';
    fcs2Tables('ir_sdrt_17686') := 'ir_sdrt_17686';
    fcs2Tables('ir_valhead') := 'ir_valhead';
    fcs2Tables('isa14ret') := 'isa14ret';
    fcs2Tables('isa25_details') := 'isa25_details';
    fcs2Tables('isa25_head') := 'isa25_head';
    fcs2Tables('isacom100_details') := 'isacom100_details';
    fcs2Tables('isacom100_head') := 'isacom100_head';
    fcs2Tables('isadiv') := 'isadiv';
    fcs2Tables('isadiv_head') := 'isadiv_head';
    fcs2Tables('isaplan') := 'isaplan';
    fcs2Tables('isaplan_89848') := 'isaplan_89848';
    fcs2Tables('isastat') := 'isastat';
    fcs2Tables('isaten') := 'isaten';
    fcs2Tables('isatot') := 'isatot';
    fcs2Tables('isatot_89848') := 'isatot_89848';
    fcs2Tables('isatot_arch_noinv') := 'isatot_arch_noinv';
    fcs2Tables('isa_jisa_conversion') := 'isa_jisa_conversion';
    fcs2Tables('isa_jisa_conversion_det') := 'isa_jisa_conversion_det';
    fcs2Tables('isa_tfr_out_type') := 'isa_tfr_out_type';
    fcs2Tables('issuespt') := 'issuespt';
    fcs2Tables('iy_valincexp') := 'iy_valincexp';
    fcs2Tables('jisa_birthday_pack') := 'jisa_birthday_pack';
    fcs2Tables('kbprfeed') := 'kbprfeed';
    fcs2Tables('kiid_review_det') := 'kiid_review_det';
    fcs2Tables('labeltab') := 'labeltab';
    fcs2Tables('labext') := 'labext';
    fcs2Tables('large_deal_emails') := 'large_deal_emails';
    fcs2Tables('large_objects') := 'large_objects';
    fcs2Tables('ldg_crexp_tr') := 'ldg_crexp_tr';
    fcs2Tables('ledger_export') := 'ledger_export';
    fcs2Tables('ledger_in_detail') := 'ledger_in_detail';
    fcs2Tables('ledger_in_failure_reasons') := 'ledger_in_failure_reasons';
    fcs2Tables('ledger_in_header') := 'ledger_in_header';
    fcs2Tables('ledger_mapping') := 'ledger_mapping';
    fcs2Tables('ledger_recon') := 'ledger_recon';
    fcs2Tables('ledger_status') := 'ledger_status';
    fcs2Tables('ledgp') := 'ledgp';
    fcs2Tables('let_inv_cdd_det_status') := 'let_inv_cdd_det_status';
    fcs2Tables('linked_deal') := 'linked_deal';
    fcs2Tables('link_audit') := 'link_audit';
    fcs2Tables('listassociation') := 'listassociation';
    fcs2Tables('listcategory') := 'listcategory';
    fcs2Tables('listentity') := 'listentity';
    fcs2Tables('listentitytypedesc') := 'listentitytypedesc';
    fcs2Tables('lnk_legislation_classification') := 'lnk_legislation_classification';
    fcs2Tables('location') := 'location';
    fcs2Tables('location_access') := 'location_access';
    fcs2Tables('logacmast') := 'logacmast';
    fcs2Tables('logbanka') := 'logbanka';
    fcs2Tables('logbcont') := 'logbcont';
    fcs2Tables('logbroke') := 'logbroke';
    fcs2Tables('logbroker_commission') := 'logbroker_commission';
    fcs2Tables('logbroker_detail') := 'logbroker_detail';
    fcs2Tables('logbroke_was') := 'logbroke_was';
    fcs2Tables('logbudget') := 'logbudget';
    fcs2Tables('logcadef') := 'logcadef';
    fcs2Tables('logcalfyp') := 'logcalfyp';
    fcs2Tables('logcalfyr') := 'logcalfyr';
    fcs2Tables('logcalmast') := 'logcalmast';
    fcs2Tables('logcamast') := 'logcamast';
    fcs2Tables('logcanada_life_sectype') := 'logcanada_life_sectype';
    fcs2Tables('logcomtype') := 'logcomtype';
    fcs2Tables('logcount') := 'logcount';
    fcs2Tables('logcurre') := 'logcurre';
    fcs2Tables('logemail_domains') := 'logemail_domains';
    fcs2Tables('logemail_names') := 'logemail_names';
    fcs2Tables('logexchr') := 'logexchr';
    fcs2Tables('logexrate_feed') := 'logexrate_feed';
    fcs2Tables('logfwdexfin') := 'logfwdexfin';
    fcs2Tables('logglgroup') := 'logglgroup';
    fcs2Tables('logglgroup_lgmast') := 'logglgroup_lgmast';
    fcs2Tables('logglsite') := 'logglsite';
    fcs2Tables('logifa') := 'logifa';
    fcs2Tables('loginvadv') := 'loginvadv';
    fcs2Tables('loginves') := 'loginves';
    fcs2Tables('logisaplan') := 'logisaplan';
    fcs2Tables('loglgmast') := 'loglgmast';
    fcs2Tables('logmanager') := 'logmanager';
    fcs2Tables('logmandaddr') := 'logmandaddr';
    fcs2Tables('logmarket') := 'logmarket';
    fcs2Tables('logpepplan') := 'logpepplan';
    fcs2Tables('logplanman') := 'logplanman';
    fcs2Tables('logpostr') := 'logpostr';
    fcs2Tables('logregion') := 'logregion';
    fcs2Tables('logregistrar') := 'logregistrar';
    fcs2Tables('logrepres') := 'logrepres';
    fcs2Tables('logsaver') := 'logsaver';
    fcs2Tables('logsecto') := 'logsecto';
    fcs2Tables('logsecur') := 'logsecur';
    fcs2Tables('logsettmthd') := 'logsettmthd';
    fcs2Tables('logsite') := 'logsite';
    fcs2Tables('logskelac') := 'logskelac';
    fcs2Tables('logskmast') := 'logskmast';
    fcs2Tables('logtaxra') := 'logtaxra';
    fcs2Tables('logtcont') := 'logtcont';
    fcs2Tables('logtrailtst') := 'logtrailtst';
    fcs2Tables('logtrste') := 'logtrste';
    fcs2Tables('logtrsttype') := 'logtrsttype';
    fcs2Tables('logtrust') := 'logtrust';
    fcs2Tables('logtrusta') := 'logtrusta';
    fcs2Tables('logtrust_incexptp') := 'logtrust_incexptp';
    fcs2Tables('logumbrella') := 'logumbrella';
    fcs2Tables('logvatra') := 'logvatra';
    fcs2Tables('log_codes_definition') := 'log_codes_definition';
    fcs2Tables('log_codes_description') := 'log_codes_description';
    fcs2Tables('log_detail') := 'log_detail';
    fcs2Tables('log_dist_cons_mast') := 'log_dist_cons_mast';
    fcs2Tables('log_dist_cons_noms') := 'log_dist_cons_noms';
    fcs2Tables('log_fee_scale') := 'log_fee_scale';
    fcs2Tables('log_fixyield') := 'log_fixyield';
    fcs2Tables('log_fund_group_header') := 'log_fund_group_header';
    fcs2Tables('log_fund_group_member') := 'log_fund_group_member';
    fcs2Tables('log_fund_group_type') := 'log_fund_group_type';
    fcs2Tables('log_manager_salesman_ifa') := 'log_manager_salesman_ifa';
    fcs2Tables('log_market_index') := 'log_market_index';
    fcs2Tables('log_market_index_country') := 'log_market_index_country';
    fcs2Tables('log_oeiprice') := 'log_oeiprice';
    fcs2Tables('log_salesman') := 'log_salesman';
    fcs2Tables('lookup') := 'lookup';
    fcs2Tables('lookup2') := 'lookup2';
    fcs2Tables('lumpsav') := 'lumpsav';
    fcs2Tables('mailext') := 'mailext';
    fcs2Tables('manager') := 'manager';
    fcs2Tables('manager_ic') := 'manager_ic';
    fcs2Tables('manager_ima') := 'manager_ima';
    fcs2Tables('manager_investor') := 'manager_investor';
    fcs2Tables('manager_pwd_prefs') := 'manager_pwd_prefs';
    fcs2Tables('manager_salesman_ifa') := 'manager_salesman_ifa';
    fcs2Tables('manager_trust_subtype') := 'manager_trust_subtype';
    fcs2Tables('manager_usage') := 'manager_usage';
    fcs2Tables('mandaddr') := 'mandaddr';
    fcs2Tables('mandaddr_89848') := 'mandaddr_89848';
    fcs2Tables('manpript') := 'manpript';
    fcs2Tables('mansbox_conversion') := 'mansbox_conversion';
    fcs2Tables('manualpayment_reason') := 'manualpayment_reason';
    fcs2Tables('margetts_opendeals') := 'margetts_opendeals';
    fcs2Tables('market') := 'market';
    fcs2Tables('marketplaceofsetmt') := 'marketplaceofsetmt';
    fcs2Tables('market_index') := 'market_index';
    fcs2Tables('market_index_country') := 'market_index_country';
    fcs2Tables('market_index_values') := 'market_index_values';
    fcs2Tables('matdeals') := 'matdeals';
    fcs2Tables('matinves') := 'matinves';
    fcs2Tables('mboxtopt') := 'mboxtopt';
    fcs2Tables('mdlfunc') := 'mdlfunc';
    fcs2Tables('memosources') := 'memosources';
    fcs2Tables('memotype') := 'memotype';
    fcs2Tables('menulog') := 'menulog';
    fcs2Tables('menus') := 'menus';
    fcs2Tables('merged_files') := 'merged_files';
    fcs2Tables('mergetab') := 'mergetab';
    fcs2Tables('message_definition') := 'message_definition';
    fcs2Tables('message_mapping') := 'message_mapping';
    fcs2Tables('mgmisatd') := 'mgmisatd';
    fcs2Tables('mgm_nominee_orders') := 'mgm_nominee_orders';
    fcs2Tables('mgm_nominee_registers') := 'mgm_nominee_registers';
    fcs2Tables('microsoftdtproperties') := 'microsoftdtproperties';
    fcs2Tables('mlog$_investor') := 'mlog$_investor';
    fcs2Tables('ml_check') := 'ml_check';
    fcs2Tables('ml_checkdocs') := 'ml_checkdocs';
    fcs2Tables('ml_doctype') := 'ml_doctype';
    fcs2Tables('ml_proof') := 'ml_proof';
    fcs2Tables('ml_setup') := 'ml_setup';
    fcs2Tables('monitor_timings') := 'monitor_timings';
    fcs2Tables('mr_shr') := 'mr_shr';
    fcs2Tables('multimanager_split') := 'multimanager_split';
    fcs2Tables('multimanager_split_conv') := 'multimanager_split_conv';
    fcs2Tables('musers') := 'musers';
    fcs2Tables('muser_backup') := 'muser_backup';
    fcs2Tables('musrmdl') := 'musrmdl';
    fcs2Tables('mwdiary') := 'mwdiary';
    fcs2Tables('names') := 'names';
    fcs2Tables('nep_deal_trans') := 'nep_deal_trans';
    fcs2Tables('nep_fxa') := 'nep_fxa';
    fcs2Tables('nep_fxaa') := 'nep_fxaa';
    fcs2Tables('nep_fxb') := 'nep_fxb';
    fcs2Tables('nep_fxc') := 'nep_fxc';
    fcs2Tables('nep_fxd') := 'nep_fxd';
    fcs2Tables('nep_fxdm') := 'nep_fxdm';
    fcs2Tables('nep_fxe') := 'nep_fxe';
    fcs2Tables('nep_fxf') := 'nep_fxf';
    fcs2Tables('nep_fxg') := 'nep_fxg';
    fcs2Tables('nep_fxh') := 'nep_fxh';
    fcs2Tables('nep_fxi') := 'nep_fxi';
    fcs2Tables('nep_fxj') := 'nep_fxj';
    fcs2Tables('nep_fxk') := 'nep_fxk';
    fcs2Tables('nep_fxkm') := 'nep_fxkm';
    fcs2Tables('nep_fxn') := 'nep_fxn';
    fcs2Tables('nep_fxo') := 'nep_fxo';
    fcs2Tables('nep_fxp') := 'nep_fxp';
    fcs2Tables('nep_fxpe') := 'nep_fxpe';
    fcs2Tables('nep_fxpm') := 'nep_fxpm';
    fcs2Tables('nep_fxpn') := 'nep_fxpn';
    fcs2Tables('nep_fxq') := 'nep_fxq';
    fcs2Tables('nep_fxr') := 'nep_fxr';
    fcs2Tables('nep_fxs') := 'nep_fxs';
    fcs2Tables('nep_fxv') := 'nep_fxv';
    fcs2Tables('nep_fxw') := 'nep_fxw';
    fcs2Tables('nep_fxx') := 'nep_fxx';
    fcs2Tables('nep_int_bacspay') := 'nep_int_bacspay';
    fcs2Tables('nep_int_ifa') := 'nep_int_ifa';
    fcs2Tables('nep_int_ifa_bank') := 'nep_int_ifa_bank';
    fcs2Tables('nep_int_investor') := 'nep_int_investor';
    fcs2Tables('nep_int_mandaddr') := 'nep_int_mandaddr';
    fcs2Tables('nep_int_ordtran') := 'nep_int_ordtran';
    fcs2Tables('nep_int_register') := 'nep_int_register';
    fcs2Tables('nep_int_saver') := 'nep_int_saver';
    fcs2Tables('nep_int_trust') := 'nep_int_trust';
    fcs2Tables('nep_temp_investorbank') := 'nep_temp_investorbank';
    fcs2Tables('nep_xref_nominee') := 'nep_xref_nominee';
    fcs2Tables('netappns') := 'netappns';
    fcs2Tables('net_dealing') := 'net_dealing';
    fcs2Tables('net_dealing_exclusion') := 'net_dealing_exclusion';
    fcs2Tables('nominee') := 'nominee';
    fcs2Tables('nominee_address') := 'nominee_address';
    fcs2Tables('nominee_addr_type') := 'nominee_addr_type';
    fcs2Tables('nominee_self_cert_cort') := 'nominee_self_cert_cort';
    fcs2Tables('nominee_self_cert_detail') := 'nominee_self_cert_detail';
    fcs2Tables('nominee_territory') := 'nominee_territory';
    fcs2Tables('nosignofffunds') := 'nosignofffunds';
    fcs2Tables('notice_period_days_type') := 'notice_period_days_type';
    fcs2Tables('npprfeed') := 'npprfeed';
    fcs2Tables('nwutrseq') := 'nwutrseq';
    fcs2Tables('objectlocks') := 'objectlocks';
    fcs2Tables('oecsdrtcc') := 'oecsdrtcc';
    fcs2Tables('oecsdrtl') := 'oecsdrtl';
    fcs2Tables('oecsdrtp') := 'oecsdrtp';
    fcs2Tables('oecsdrtp_copy') := 'oecsdrtp_copy';
    fcs2Tables('oeic_equal_rpt_temp') := 'oeic_equal_rpt_temp';
    fcs2Tables('oeic_fund_temp') := 'oeic_fund_temp';
    fcs2Tables('oeic_share_class_temp') := 'oeic_share_class_temp';
    fcs2Tables('oeiprice_moved') := 'oeiprice_moved';
    fcs2Tables('oeiprice_temp') := 'oeiprice_temp';
    fcs2Tables('oei_functionality') := 'oei_functionality';
    fcs2Tables('oeprvalhead') := 'oeprvalhead';
    fcs2Tables('offload_bacspay') := 'offload_bacspay';
    fcs2Tables('offload_ifa') := 'offload_ifa';
    fcs2Tables('offload_investor') := 'offload_investor';
    fcs2Tables('offload_isatot') := 'offload_isatot';
    fcs2Tables('offload_mandaddr') := 'offload_mandaddr';
    fcs2Tables('offload_others') := 'offload_others';
    fcs2Tables('offload_register') := 'offload_register';
    fcs2Tables('offload_reinvest') := 'offload_reinvest';
    fcs2Tables('old_nep_issrep') := 'old_nep_issrep';
    fcs2Tables('ongoing_adviser_charge_plan') := 'ongoing_adviser_charge_plan';
    fcs2Tables('operation') := 'operation';
    fcs2Tables('ordtran_173') := 'ordtran_173';
    fcs2Tables('ordtran_536_43466') := 'ordtran_536_43466';
    fcs2Tables('ordtran_702_43466') := 'ordtran_702_43466';
    fcs2Tables('ordtran_89848') := 'ordtran_89848';
    fcs2Tables('ordtran_arch_cru') := 'ordtran_arch_cru';
    fcs2Tables('ordtran_checking') := 'ordtran_checking';
    fcs2Tables('ordtran_datefilter') := 'ordtran_datefilter';
    fcs2Tables('ordtran_nominee_deal') := 'ordtran_nominee_deal';
    fcs2Tables('ordtran_nom_agg_detail') := 'ordtran_nom_agg_detail';
    fcs2Tables('ordtran_nom_agg_detail_link') := 'ordtran_nom_agg_detail_link';
    fcs2Tables('ordtran_nom_agg_header') := 'ordtran_nom_agg_header';
    fcs2Tables('ordtran_nom_recon_detail') := 'ordtran_nom_recon_detail';
    fcs2Tables('ordtran_nom_recon_header') := 'ordtran_nom_recon_header';
    fcs2Tables('ordtran_oac_plan') := 'ordtran_oac_plan';
    fcs2Tables('ordtran_qds_cr') := 'ordtran_qds_cr';
    fcs2Tables('ordtran_sap_status') := 'ordtran_sap_status';
    fcs2Tables('ordtran_subtransaction_type') := 'ordtran_subtransaction_type';
    fcs2Tables('ordtran_top10ifa') := 'ordtran_top10ifa';
    fcs2Tables('ordtran_trail_change') := 'ordtran_trail_change';
    fcs2Tables('org_with_staff') := 'org_with_staff';
    fcs2Tables('other_adj') := 'other_adj';
    fcs2Tables('page_head') := 'page_head';
    fcs2Tables('page_item') := 'page_item';
    fcs2Tables('page_literals') := 'page_literals';
    fcs2Tables('page_literals_group') := 'page_literals_group';
    fcs2Tables('param_set_value') := 'param_set_value';
    fcs2Tables('passwords') := 'passwords';
    fcs2Tables('payment') := 'payment';
    fcs2Tables('payment_arch_cru') := 'payment_arch_cru';
    fcs2Tables('payment_lloyds_debits') := 'payment_lloyds_debits';
    fcs2Tables('payment_lloyds_statements') := 'payment_lloyds_statements';
    fcs2Tables('payment_lloyds_statements_hudd') := 'payment_lloyds_statements_hudd';
    fcs2Tables('payment_methods') := 'payment_methods';
    fcs2Tables('payment_spinst') := 'payment_spinst';
    fcs2Tables('paymethod') := 'paymethod';
    fcs2Tables('paytype') := 'paytype';
    fcs2Tables('pcount') := 'pcount';
    fcs2Tables('pensrein') := 'pensrein';
    fcs2Tables('pep14ret') := 'pep14ret';
    fcs2Tables('pepdet') := 'pepdet';
    fcs2Tables('pepdiv') := 'pepdiv';
    fcs2Tables('pepplan') := 'pepplan';
    fcs2Tables('pepplan_89848') := 'pepplan_89848';
    fcs2Tables('pepstat') := 'pepstat';
    fcs2Tables('pepten') := 'pepten';
    fcs2Tables('peptot') := 'peptot';
    fcs2Tables('peptot_89848') := 'peptot_89848';
    fcs2Tables('performance_calc_errorlog') := 'performance_calc_errorlog';
    fcs2Tables('periodic_statement_pref') := 'periodic_statement_pref';
    fcs2Tables('pertrad_crexprop_valhead') := 'pertrad_crexprop_valhead';
    fcs2Tables('pertrad_deal') := 'pertrad_deal';
    fcs2Tables('pertrad_glacper') := 'pertrad_glacper';
    fcs2Tables('pfin') := 'pfin';
    fcs2Tables('pfmifas') := 'pfmifas';
    fcs2Tables('pfout') := 'pfout';
    fcs2Tables('placeofsetmt') := 'placeofsetmt';
    fcs2Tables('planman') := 'planman';
    fcs2Tables('plan_table') := 'plan_table';
    fcs2Tables('plan_table$') := 'plan_table$';
    fcs2Tables('policy') := 'policy';
    fcs2Tables('postrule') := 'postrule';
    fcs2Tables('prelimcg') := 'prelimcg';
    fcs2Tables('pre_auth_email_types') := 'pre_auth_email_types';
    fcs2Tables('pricecopy') := 'pricecopy';
    fcs2Tables('priceerror') := 'priceerror';
    fcs2Tables('pricefundlvl') := 'pricefundlvl';
    fcs2Tables('pricepoint') := 'pricepoint';
    fcs2Tables('pricescrub_temp') := 'pricescrub_temp';
    fcs2Tables('pricescubbingprocessstatus') := 'pricescubbingprocessstatus';
    fcs2Tables('pricesubfund') := 'pricesubfund';
    fcs2Tables('price_params') := 'price_params';
    fcs2Tables('price_yield_download') := 'price_yield_download';
    fcs2Tables('prinexit') := 'prinexit';
    fcs2Tables('prinexpt') := 'prinexpt';
    fcs2Tables('prinextp') := 'prinextp';
    fcs2Tables('printtab') := 'printtab';
    fcs2Tables('print_groups') := 'print_groups';
    fcs2Tables('pritrust') := 'pritrust';
    fcs2Tables('process_messages') := 'process_messages';
    fcs2Tables('prod_group') := 'prod_group';
    fcs2Tables('prod_group_limit') := 'prod_group_limit';
    fcs2Tables('prod_group_link') := 'prod_group_link';
    fcs2Tables('prod_stats') := 'prod_stats';
    fcs2Tables('propgrp') := 'propgrp';
    fcs2Tables('prospectus') := 'prospectus';
    fcs2Tables('psoactive') := 'psoactive';
    fcs2Tables('psofields') := 'psofields';
    fcs2Tables('psoliftdetails') := 'psoliftdetails';
    fcs2Tables('psoremovalattempt') := 'psoremovalattempt';
    fcs2Tables('pso_audit_fields') := 'pso_audit_fields';
    fcs2Tables('pso_audit_fields_dropme') := 'pso_audit_fields_dropme';
    fcs2Tables('pubdet') := 'pubdet';
    fcs2Tables('pursdrep') := 'pursdrep';
    fcs2Tables('pursrep') := 'pursrep';
    fcs2Tables('pursrepx') := 'pursrepx';
    fcs2Tables('quarter_date_switch') := 'quarter_date_switch';
    fcs2Tables('quest_com_products') := 'quest_com_products';
    fcs2Tables('quest_com_products_used_by') := 'quest_com_products_used_by';
    fcs2Tables('quest_com_product_privs') := 'quest_com_product_privs';
    fcs2Tables('quest_com_users') := 'quest_com_users';
    fcs2Tables('quest_com_user_privileges') := 'quest_com_user_privileges';
    fcs2Tables('quest_sl_collection_definition') := 'quest_sl_collection_definition';
    fcs2Tables('quest_sl_collection_def_repos') := 'quest_sl_collection_def_repos';
    fcs2Tables('quest_sl_collection_repository') := 'quest_sl_collection_repository';
    fcs2Tables('quest_sl_errors') := 'quest_sl_errors';
    fcs2Tables('quest_sl_explain') := 'quest_sl_explain';
    fcs2Tables('quest_sl_explain_pick') := 'quest_sl_explain_pick';
    fcs2Tables('quest_sl_query_definitions') := 'quest_sl_query_definitions';
    fcs2Tables('quest_sl_query_def_repository') := 'quest_sl_query_def_repository';
    fcs2Tables('quest_sl_repository_explain') := 'quest_sl_repository_explain';
    fcs2Tables('quest_sl_repository_sqlarea') := 'quest_sl_repository_sqlarea';
    fcs2Tables('quest_sl_repository_sqltext') := 'quest_sl_repository_sqltext';
    fcs2Tables('quest_sl_repository_statistics') := 'quest_sl_repository_statistics';
    fcs2Tables('quest_sl_repository_trans_info') := 'quest_sl_repository_trans_info';
    fcs2Tables('quest_sl_repos_bind_values') := 'quest_sl_repos_bind_values';
    fcs2Tables('quest_sl_repos_lab_details') := 'quest_sl_repos_lab_details';
    fcs2Tables('quest_sl_repos_pick_details') := 'quest_sl_repos_pick_details';
    fcs2Tables('quest_sl_repos_root') := 'quest_sl_repos_root';
    fcs2Tables('quest_sl_repos_sga_details') := 'quest_sl_repos_sga_details';
    fcs2Tables('quest_sl_repos_sga_statistics') := 'quest_sl_repos_sga_statistics';
    fcs2Tables('quest_sl_sqlarea') := 'quest_sl_sqlarea';
    fcs2Tables('quest_sl_sqltext') := 'quest_sl_sqltext';
    fcs2Tables('quest_sl_temp_explain1') := 'quest_sl_temp_explain1';
    fcs2Tables('quest_sl_topsql') := 'quest_sl_topsql';
    fcs2Tables('quest_sl_user') := 'quest_sl_user';
    fcs2Tables('quest_temp_explain') := 'quest_temp_explain';
    fcs2Tables('quilifad') := 'quilifad';
    fcs2Tables('quilstat') := 'quilstat';
    fcs2Tables('quilter_tsteerep_2211') := 'quilter_tsteerep_2211';
    fcs2Tables('rbprfeed') := 'rbprfeed';
    fcs2Tables('reason_code') := 'reason_code';
    fcs2Tables('reason_code_type') := 'reason_code_type';
    fcs2Tables('receipt') := 'receipt';
    fcs2Tables('reconcile_fund') := 'reconcile_fund';
    fcs2Tables('reconcile_investor') := 'reconcile_investor';
    fcs2Tables('reconcile_investor_holding') := 'reconcile_investor_holding';
    fcs2Tables('recon_inv_result') := 'recon_inv_result';
    fcs2Tables('regcomp') := 'regcomp';
    fcs2Tables('regfee') := 'regfee';
    fcs2Tables('region') := 'region';
    fcs2Tables('register') := 'register';
    fcs2Tables('register_173') := 'register_173';
    fcs2Tables('register_536_43466') := 'register_536_43466';
    fcs2Tables('register_702_43466') := 'register_702_43466';
    fcs2Tables('register_89848') := 'register_89848';
    fcs2Tables('register_bad') := 'register_bad';
    fcs2Tables('register_dup') := 'register_dup';
    fcs2Tables('register_history_mismatch') := 'register_history_mismatch';
    fcs2Tables('register_recalc') := 'register_recalc';
    fcs2Tables('register_temp') := 'register_temp';
    fcs2Tables('registrar') := 'registrar';
    fcs2Tables('renburgtransdates') := 'renburgtransdates';
    fcs2Tables('renewal_amc') := 'renewal_amc';
    fcs2Tables('renewal_commission_temp') := 'renewal_commission_temp';
    fcs2Tables('renewal_nocom') := 'renewal_nocom';
    fcs2Tables('renewal_nocom_change') := 'renewal_nocom_change';
    fcs2Tables('renewal_param') := 'renewal_param';
    fcs2Tables('renewal_payment_limits') := 'renewal_payment_limits';
    fcs2Tables('renewal_rates') := 'renewal_rates';
    fcs2Tables('renewal_rates_change') := 'renewal_rates_change';
    fcs2Tables('reports') := 'reports';
    fcs2Tables('report_archive') := 'report_archive';
    fcs2Tables('report_archive_metadata') := 'report_archive_metadata';
    fcs2Tables('report_menu') := 'report_menu';
    fcs2Tables('repres') := 'repres';
    fcs2Tables('repurcpt') := 'repurcpt';
    fcs2Tables('restricted_dealing') := 'restricted_dealing';
    fcs2Tables('reversal_reason') := 'reversal_reason';
    fcs2Tables('revstocktransfer') := 'revstocktransfer';
    fcs2Tables('riskaddress') := 'riskaddress';
    fcs2Tables('riskaddresstemp') := 'riskaddresstemp';
    fcs2Tables('rl_27posts') := 'rl_27posts';
    fcs2Tables('rl_3r_conhist') := 'rl_3r_conhist';
    fcs2Tables('rl_3r_hfax') := 'rl_3r_hfax';
    fcs2Tables('rl_3r_hphone') := 'rl_3r_hphone';
    fcs2Tables('rl_3r_hphone2') := 'rl_3r_hphone2';
    fcs2Tables('rl_3r_wfax') := 'rl_3r_wfax';
    fcs2Tables('rl_3r_wphone') := 'rl_3r_wphone';
    fcs2Tables('rl_babrpf_banknames') := 'rl_babrpf_banknames';
    fcs2Tables('rl_chdrpf_contractheader') := 'rl_chdrpf_contractheader';
    fcs2Tables('rl_chrg_fb') := 'rl_chrg_fb';
    fcs2Tables('rl_chrg_fbpen') := 'rl_chrg_fbpen';
    fcs2Tables('rl_chrg_mvr') := 'rl_chrg_mvr';
    fcs2Tables('rl_chrg_other') := 'rl_chrg_other';
    fcs2Tables('rl_chrg_wc') := 'rl_chrg_wc';
    fcs2Tables('rl_clbapf_bacspay') := 'rl_clbapf_bacspay';
    fcs2Tables('rl_clntpf_investor') := 'rl_clntpf_investor';
    fcs2Tables('rl_clrrpf') := 'rl_clrrpf';
    fcs2Tables('rl_final_bonus_rates') := 'rl_final_bonus_rates';
    fcs2Tables('rl_mandpf_dd') := 'rl_mandpf_dd';
    fcs2Tables('rl_marketing_linda') := 'rl_marketing_linda';
    fcs2Tables('rl_marketing_three') := 'rl_marketing_three';
    fcs2Tables('rl_payrpf') := 'rl_payrpf';
    fcs2Tables('rl_policy_cross_ref') := 'rl_policy_cross_ref';
    fcs2Tables('rl_policy_cross_ref_2009_2010') := 'rl_policy_cross_ref_2009_2010';
    fcs2Tables('rl_policy_status') := 'rl_policy_status';
    fcs2Tables('rl_policy_status_2009_2010') := 'rl_policy_status_2009_2010';
    fcs2Tables('rl_policy_status_temp') := 'rl_policy_status_temp';
    fcs2Tables('rl_prv_count_2009_2010') := 'rl_prv_count_2009_2010';
    fcs2Tables('rl_rounding_audit') := 'rl_rounding_audit';
    fcs2Tables('rl_temp_bacspay') := 'rl_temp_bacspay';
    fcs2Tables('rl_temp_bacspay_issues') := 'rl_temp_bacspay_issues';
    fcs2Tables('rl_temp_cm1') := 'rl_temp_cm1';
    fcs2Tables('rl_temp_cm2') := 'rl_temp_cm2';
    fcs2Tables('rl_temp_corraddress') := 'rl_temp_corraddress';
    fcs2Tables('rl_temp_dd_import') := 'rl_temp_dd_import';
    fcs2Tables('rl_temp_divpay') := 'rl_temp_divpay';
    fcs2Tables('rl_temp_divpay_date') := 'rl_temp_divpay_date';
    fcs2Tables('rl_temp_fb') := 'rl_temp_fb';
    fcs2Tables('rl_temp_fbdeals') := 'rl_temp_fbdeals';
    fcs2Tables('rl_temp_fbpen') := 'rl_temp_fbpen';
    fcs2Tables('rl_temp_fbpendeals') := 'rl_temp_fbpendeals';
    fcs2Tables('rl_temp_fundswitch') := 'rl_temp_fundswitch';
    fcs2Tables('rl_temp_goneaways') := 'rl_temp_goneaways';
    fcs2Tables('rl_temp_inchlder_other') := 'rl_temp_inchlder_other';
    fcs2Tables('rl_temp_inchldr_dtype') := 'rl_temp_inchldr_dtype';
    fcs2Tables('rl_temp_invalid_clients') := 'rl_temp_invalid_clients';
    fcs2Tables('rl_temp_investor') := 'rl_temp_investor';
    fcs2Tables('rl_temp_investorbank') := 'rl_temp_investorbank';
    fcs2Tables('rl_temp_investor_corresaddr') := 'rl_temp_investor_corresaddr';
    fcs2Tables('rl_temp_investor_dblspace') := 'rl_temp_investor_dblspace';
    fcs2Tables('rl_temp_isadate') := 'rl_temp_isadate';
    fcs2Tables('rl_temp_isaplan') := 'rl_temp_isaplan';
    fcs2Tables('rl_temp_merged_policies') := 'rl_temp_merged_policies';
    fcs2Tables('rl_temp_missingaddress') := 'rl_temp_missingaddress';
    fcs2Tables('rl_temp_mvr') := 'rl_temp_mvr';
    fcs2Tables('rl_temp_mvrdeals') := 'rl_temp_mvrdeals';
    fcs2Tables('rl_temp_register') := 'rl_temp_register';
    fcs2Tables('rl_temp_reinvestor') := 'rl_temp_reinvestor';
    fcs2Tables('rl_temp_saver') := 'rl_temp_saver';
    fcs2Tables('rl_temp_saversplit') := 'rl_temp_saversplit';
    fcs2Tables('rl_temp_saver_commas') := 'rl_temp_saver_commas';
    fcs2Tables('rl_temp_saver_issues') := 'rl_temp_saver_issues';
    fcs2Tables('rl_temp_saver_mand') := 'rl_temp_saver_mand';
    fcs2Tables('rl_temp_saver_old') := 'rl_temp_saver_old';
    fcs2Tables('rl_temp_trust') := 'rl_temp_trust';
    fcs2Tables('rl_temp_warrant_investors') := 'rl_temp_warrant_investors';
    fcs2Tables('rl_temp_wc') := 'rl_temp_wc';
    fcs2Tables('rl_temp_wcdeals') := 'rl_temp_wcdeals';
    fcs2Tables('rl_tmp_da') := 'rl_tmp_da';
    fcs2Tables('rl_tmp_dispatchaddr_clients') := 'rl_tmp_dispatchaddr_clients';
    fcs2Tables('rl_tmp_ow') := 'rl_tmp_ow';
    fcs2Tables('rl_tmp_registconsol') := 'rl_tmp_registconsol';
    fcs2Tables('rl_tmp_stat_anniversaries') := 'rl_tmp_stat_anniversaries';
    fcs2Tables('rl_ufndpf') := 'rl_ufndpf';
    fcs2Tables('rl_ulnkpf') := 'rl_ulnkpf';
    fcs2Tables('rl_ulnkpf_issues') := 'rl_ulnkpf_issues';
    fcs2Tables('rl_uswdpf') := 'rl_uswdpf';
    fcs2Tables('rl_utrn2000') := 'rl_utrn2000';
    fcs2Tables('rl_utrn2001') := 'rl_utrn2001';
    fcs2Tables('rl_utrn2002') := 'rl_utrn2002';
    fcs2Tables('rl_utrn2003') := 'rl_utrn2003';
    fcs2Tables('rl_utrn2004') := 'rl_utrn2004';
    fcs2Tables('rl_utrn2005') := 'rl_utrn2005';
    fcs2Tables('rl_utrn2006') := 'rl_utrn2006';
    fcs2Tables('rl_utrn2007') := 'rl_utrn2007';
    fcs2Tables('rl_utrn_unset') := 'rl_utrn_unset';
    fcs2Tables('rl_utrspf_register') := 'rl_utrspf_register';
    fcs2Tables('rl_val1_supplied') := 'rl_val1_supplied';
    fcs2Tables('rl_valrep1') := 'rl_valrep1';
    fcs2Tables('rl_val_fixes') := 'rl_val_fixes';
    fcs2Tables('rl_vprcpf_price') := 'rl_vprcpf_price';
    fcs2Tables('rl_vw_temp_reg') := 'rl_vw_temp_reg';
    fcs2Tables('rl_vw_temp_regb') := 'rl_vw_temp_regb';
    fcs2Tables('rl_vw_temp_regc') := 'rl_vw_temp_regc';
    fcs2Tables('rl_zaudpf_bacsref') := 'rl_zaudpf_bacsref';
    fcs2Tables('rl_zcsppf') := 'rl_zcsppf';
    fcs2Tables('rl_zdhfpf_divpay') := 'rl_zdhfpf_divpay';
    fcs2Tables('rl_zdifpf_disinc') := 'rl_zdifpf_disinc';
    fcs2Tables('rl_zdrfpf_dividend') := 'rl_zdrfpf_dividend';
    fcs2Tables('rl_ziatpf') := 'rl_ziatpf';
    fcs2Tables('rl_zv1cpf') := 'rl_zv1cpf';
    fcs2Tables('rl_zv1cpf_uv') := 'rl_zv1cpf_uv';
    fcs2Tables('rupd$_investor') := 'rupd$_investor';
    fcs2Tables('rupd$_ordtran') := 'rupd$_ordtran';
    fcs2Tables('s18retoi') := 's18retoi';
    fcs2Tables('s18_detail') := 's18_detail';
    fcs2Tables('s18_head') := 's18_head';
    fcs2Tables('s18_item') := 's18_item';
    fcs2Tables('salesman') := 'salesman';
    fcs2Tables('sap_payment_method') := 'sap_payment_method';
    fcs2Tables('sap_status_transition') := 'sap_status_transition';
    fcs2Tables('sap_sub_type_mapping') := 'sap_sub_type_mapping';
    fcs2Tables('saver') := 'saver';
    fcs2Tables('saverpf') := 'saverpf';
    fcs2Tables('saver_173') := 'saver_173';
    fcs2Tables('saver_536_43466') := 'saver_536_43466';
    fcs2Tables('saver_702_43466') := 'saver_702_43466';
    fcs2Tables('saver_89848') := 'saver_89848';
    fcs2Tables('saver_advised') := 'saver_advised';
    fcs2Tables('saver_advised_change') := 'saver_advised_change';
    fcs2Tables('savstext') := 'savstext';
    fcs2Tables('scheduledholding') := 'scheduledholding';
    fcs2Tables('scheduledholdingreport') := 'scheduledholdingreport';
    fcs2Tables('scheduled_parameter_list') := 'scheduled_parameter_list';
    fcs2Tables('scheduled_report') := 'scheduled_report';
    fcs2Tables('scheduled_report_run') := 'scheduled_report_run';
    fcs2Tables('scheduled_task') := 'scheduled_task';
    fcs2Tables('scheduler_log') := 'scheduler_log';
    fcs2Tables('scheduler_status') := 'scheduler_status';
    fcs2Tables('schedule_method_def') := 'schedule_method_def';
    fcs2Tables('schedule_task_param') := 'schedule_task_param';
    fcs2Tables('scheme') := 'scheme';
    fcs2Tables('sdrt') := 'sdrt';
    fcs2Tables('sdrt_7year_spread') := 'sdrt_7year_spread';
    fcs2Tables('sdrt_calculation') := 'sdrt_calculation';
    fcs2Tables('sdrt_calculation_sub') := 'sdrt_calculation_sub';
    fcs2Tables('sdrt_derivatives') := 'sdrt_derivatives';
    fcs2Tables('sdrt_exempt') := 'sdrt_exempt';
    fcs2Tables('sdrt_exempt_investor') := 'sdrt_exempt_investor';
    fcs2Tables('sdrt_exempt_monthly') := 'sdrt_exempt_monthly';
    fcs2Tables('sdrt_temp') := 'sdrt_temp';
    fcs2Tables('sdrt_temp_dates') := 'sdrt_temp_dates';
    fcs2Tables('sdrt_unittype') := 'sdrt_unittype';
    fcs2Tables('searchfields') := 'searchfields';
    fcs2Tables('searchsets') := 'searchsets';
    fcs2Tables('secoride') := 'secoride';
    fcs2Tables('secsort') := 'secsort';
    fcs2Tables('sector') := 'sector';
    fcs2Tables('security') := 'security';
    fcs2Tables('security_linda') := 'security_linda';
    fcs2Tables('security_old') := 'security_old';
    fcs2Tables('security_type') := 'security_type';
    fcs2Tables('security_type_tolerance') := 'security_type_tolerance';
    fcs2Tables('sedol_description') := 'sedol_description';
    fcs2Tables('sedtemp') := 'sedtemp';
    fcs2Tables('sedtrust') := 'sedtrust';
    fcs2Tables('selfcert_chaser_freq') := 'selfcert_chaser_freq';
    fcs2Tables('sequencelink') := 'sequencelink';
    fcs2Tables('service_access') := 'service_access';
    fcs2Tables('service_actions') := 'service_actions';
    fcs2Tables('service_action_errors') := 'service_action_errors';
    fcs2Tables('service_action_progress') := 'service_action_progress';
    fcs2Tables('service_allowed_instances') := 'service_allowed_instances';
    fcs2Tables('service_clients') := 'service_clients';
    fcs2Tables('service_config') := 'service_config';
    fcs2Tables('service_messages') := 'service_messages';
    fcs2Tables('settinst') := 'settinst';
    fcs2Tables('settle') := 'settle';
    fcs2Tables('settlement_date_rule') := 'settlement_date_rule';
    fcs2Tables('settlem_activity') := 'settlem_activity';
    fcs2Tables('settle_no_cash') := 'settle_no_cash';
    fcs2Tables('settmthd') := 'settmthd';
    fcs2Tables('sfautowf') := 'sfautowf';
    fcs2Tables('sftp_file_history') := 'sftp_file_history';
    fcs2Tables('sh_agent') := 'sh_agent';
    fcs2Tables('sh_cavendish_isaplan') := 'sh_cavendish_isaplan';
    fcs2Tables('sh_cavendish__pepplan') := 'sh_cavendish__pepplan';
    fcs2Tables('sh_client') := 'sh_client';
    fcs2Tables('sh_declaration') := 'sh_declaration';
    fcs2Tables('sh_distribution_history') := 'sh_distribution_history';
    fcs2Tables('sh_dividend') := 'sh_dividend';
    fcs2Tables('sh_funds') := 'sh_funds';
    fcs2Tables('sh_fund_profile') := 'sh_fund_profile';
    fcs2Tables('sh_holding') := 'sh_holding';
    fcs2Tables('sh_investment_history') := 'sh_investment_history';
    fcs2Tables('sh_ord_correction') := 'sh_ord_correction';
    fcs2Tables('sh_ord_correction_etc') := 'sh_ord_correction_etc';
    fcs2Tables('sh_ord_correction_original') := 'sh_ord_correction_original';
    fcs2Tables('sh_ord_correction_original_etc') := 'sh_ord_correction_original_etc';
    fcs2Tables('sh_plan_transfer') := 'sh_plan_transfer';
    fcs2Tables('sh_portfolio') := 'sh_portfolio';
    fcs2Tables('sh_price') := 'sh_price';
    fcs2Tables('sh_product') := 'sh_product';
    fcs2Tables('sh_region') := 'sh_region';
    fcs2Tables('sh_regular_investment') := 'sh_regular_investment';
    fcs2Tables('sh_temp_dividend') := 'sh_temp_dividend';
    fcs2Tables('sh_temp_dividend_timetable') := 'sh_temp_dividend_timetable';
    fcs2Tables('sh_temp_divpay') := 'sh_temp_divpay';
    fcs2Tables('sh_temp_investorbank') := 'sh_temp_investorbank';
    fcs2Tables('sh_temp_investor_etc') := 'sh_temp_investor_etc';
    fcs2Tables('sh_temp_investor_shc') := 'sh_temp_investor_shc';
    fcs2Tables('sh_temp_isatot_b4_update') := 'sh_temp_isatot_b4_update';
    fcs2Tables('sh_temp_oeiprice') := 'sh_temp_oeiprice';
    fcs2Tables('sh_temp_ordtran_etc') := 'sh_temp_ordtran_etc';
    fcs2Tables('sh_temp_ordtran_shc') := 'sh_temp_ordtran_shc';
    fcs2Tables('sh_temp_ordtran_shc_new') := 'sh_temp_ordtran_shc_new';
    fcs2Tables('sh_temp_ordtran_tfr_fix') := 'sh_temp_ordtran_tfr_fix';
    fcs2Tables('sh_temp_rufus_units') := 'sh_temp_rufus_units';
    fcs2Tables('sh_temp_unit_comparision_etc') := 'sh_temp_unit_comparision_etc';
    fcs2Tables('sh_temp_unit_comparision_shc') := 'sh_temp_unit_comparision_shc';
    fcs2Tables('sh_tmp_oeicchrge_sett') := 'sh_tmp_oeicchrge_sett';
    fcs2Tables('sh_tmp_oeicchrge_unsett') := 'sh_tmp_oeicchrge_unsett';
    fcs2Tables('sh_tmp_osdeals') := 'sh_tmp_osdeals';
    fcs2Tables('sh_tmp_unsettled') := 'sh_tmp_unsettled';
    fcs2Tables('sh_transaction_charge') := 'sh_transaction_charge';
    fcs2Tables('sh_transaction_history') := 'sh_transaction_history';
    fcs2Tables('sh_xref_ifa') := 'sh_xref_ifa';
    fcs2Tables('sh_xref_nominee') := 'sh_xref_nominee';
    fcs2Tables('sh_xref_planman') := 'sh_xref_planman';
    fcs2Tables('sidealpte') := 'sidealpte';
    fcs2Tables('sidlysum_tot') := 'sidlysum_tot';
    fcs2Tables('sinhldpt') := 'sinhldpt';
    fcs2Tables('sisource') := 'sisource';
    fcs2Tables('site') := 'site';
    fcs2Tables('sladistributionrateslog') := 'sladistributionrateslog';
    fcs2Tables('slaproformalog') := 'slaproformalog';
    fcs2Tables('source') := 'source';
    fcs2Tables('sources') := 'sources';
    fcs2Tables('sources_group') := 'sources_group';
    fcs2Tables('sources_xref') := 'sources_xref';
    fcs2Tables('source_control') := 'source_control';
    fcs2Tables('source_control_log') := 'source_control_log';
    fcs2Tables('source_control_program') := 'source_control_program';
    fcs2Tables('stampdat') := 'stampdat';
    fcs2Tables('stamppay') := 'stamppay';
    fcs2Tables('statement_by_type') := 'statement_by_type';
    fcs2Tables('statement_deal_desc') := 'statement_deal_desc';
    fcs2Tables('statement_footnotes') := 'statement_footnotes';
    fcs2Tables('statement_head') := 'statement_head';
    fcs2Tables('statement_holding') := 'statement_holding';
    fcs2Tables('statement_prod_group') := 'statement_prod_group';
    fcs2Tables('statement_prod_link') := 'statement_prod_link';
    fcs2Tables('statement_recc_counts') := 'statement_recc_counts';
    fcs2Tables('statement_run_file') := 'statement_run_file';
    fcs2Tables('statement_sections') := 'statement_sections';
    fcs2Tables('statement_sections_fo') := 'statement_sections_fo';
    fcs2Tables('statement_stationary_code') := 'statement_stationary_code';
    fcs2Tables('statement_type') := 'statement_type';
    fcs2Tables('state_st_odmon') := 'state_st_odmon';
    fcs2Tables('staticsecurities') := 'staticsecurities';
    fcs2Tables('statpro') := 'statpro';
    fcs2Tables('statprodataextracts') := 'statprodataextracts';
    fcs2Tables('statpro_adjusted_nav') := 'statpro_adjusted_nav';
    fcs2Tables('statpro_mantra_account') := 'statpro_mantra_account';
    fcs2Tables('statpro_mantra_accountclass') := 'statpro_mantra_accountclass';
    fcs2Tables('status_message_detail') := 'status_message_detail';
    fcs2Tables('status_message_header') := 'status_message_header';
    fcs2Tables('status_message_trailer') := 'status_message_trailer';
    fcs2Tables('stg_fs3_agents') := 'stg_fs3_agents';
    fcs2Tables('stg_fs3_agents_utopia_code') := 'stg_fs3_agents_utopia_code';
    fcs2Tables('stg_fs3_inst_investor') := 'stg_fs3_inst_investor';
    fcs2Tables('stg_fs3_isa_priv_investor') := 'stg_fs3_isa_priv_investor';
    fcs2Tables('stg_fs3_jh_investor') := 'stg_fs3_jh_investor';
    fcs2Tables('stg_fs3_oeic_priv_investor') := 'stg_fs3_oeic_priv_investor';
    fcs2Tables('stg_thr_tblclient') := 'stg_thr_tblclient';
    fcs2Tables('stg_thr_tblclientagreement') := 'stg_thr_tblclientagreement';
    fcs2Tables('stg_thr_tblcontacts') := 'stg_thr_tblcontacts';
    fcs2Tables('stg_thr_tbldetailtran') := 'stg_thr_tbldetailtran';
    fcs2Tables('stg_thr_tblfund') := 'stg_thr_tblfund';
    fcs2Tables('stg_thr_tblfundamc') := 'stg_thr_tblfundamc';
    fcs2Tables('stg_thr_tblfundtype') := 'stg_thr_tblfundtype';
    fcs2Tables('stg_thr_tblprice') := 'stg_thr_tblprice';
    fcs2Tables('stg_thr_tbltransaction') := 'stg_thr_tbltransaction';
    fcs2Tables('stg_thr_tbltranstype') := 'stg_thr_tbltranstype';
    fcs2Tables('stg_thr_tblvaldate') := 'stg_thr_tblvaldate';
    fcs2Tables('stg_thr_tblwithdrawalallowance') := 'stg_thr_tblwithdrawalallowance';
    fcs2Tables('stletter') := 'stletter';
    fcs2Tables('stlettp') := 'stlettp';
    fcs2Tables('stlettp_groups') := 'stlettp_groups';
    fcs2Tables('stlettp_xref') := 'stlettp_xref';
    fcs2Tables('stock_transfer') := 'stock_transfer';
    fcs2Tables('stock_trans_email') := 'stock_trans_email';
    fcs2Tables('stored_sdrt') := 'stored_sdrt';
    fcs2Tables('stpbonyx_temp') := 'stpbonyx_temp';
    fcs2Tables('stp_dealing') := 'stp_dealing';
    fcs2Tables('stp_dealing_error_log') := 'stp_dealing_error_log';
    fcs2Tables('stp_external_fund') := 'stp_external_fund';
    fcs2Tables('stp_platforms') := 'stp_platforms';
    fcs2Tables('stp_platform_fund_setup') := 'stp_platform_fund_setup';
    fcs2Tables('stp_platform_ifa_setup') := 'stp_platform_ifa_setup';
    fcs2Tables('subacnom') := 'subacnom';
    fcs2Tables('subactp') := 'subactp';
    fcs2Tables('subcat') := 'subcat';
    fcs2Tables('subgroup_trusts') := 'subgroup_trusts';
    fcs2Tables('subord') := 'subord';
    fcs2Tables('subparam') := 'subparam';
    fcs2Tables('subreg') := 'subreg';
    fcs2Tables('subsaddr') := 'subsaddr';
    fcs2Tables('subsdet') := 'subsdet';
    fcs2Tables('subsextr') := 'subsextr';
    fcs2Tables('subtab') := 'subtab';
    fcs2Tables('subtransaction_capability') := 'subtransaction_capability';
    fcs2Tables('subtransaction_type') := 'subtransaction_type';
    fcs2Tables('subtransaction_type_capability') := 'subtransaction_type_capability';
    fcs2Tables('subtransaction_type_trancode') := 'subtransaction_type_trancode';
    fcs2Tables('supervisor') := 'supervisor';
    fcs2Tables('supervisor_requests') := 'supervisor_requests';
    fcs2Tables('swcadv') := 'swcadv';
    fcs2Tables('switch_convert_log') := 'switch_convert_log';
    fcs2Tables('switch_head') := 'switch_head';
    fcs2Tables('switch_in') := 'switch_in';
    fcs2Tables('switch_out') := 'switch_out';
    fcs2Tables('switch_run') := 'switch_run';
    fcs2Tables('switch_trust_pair') := 'switch_trust_pair';
    fcs2Tables('system_parameter') := 'system_parameter';
    fcs2Tables('table_lc') := 'table_lc';
    fcs2Tables('take_off') := 'take_off';
    fcs2Tables('take_off_audit') := 'take_off_audit';
    fcs2Tables('take_off_stats') := 'take_off_stats';
    fcs2Tables('take_off_trusts') := 'take_off_trusts';
    fcs2Tables('take_on') := 'take_on';
    fcs2Tables('tamprovider') := 'tamprovider';
    fcs2Tables('tam_dd_check') := 'tam_dd_check';
    fcs2Tables('tam_export_deals') := 'tam_export_deals';
    fcs2Tables('tam_export_deals_head') := 'tam_export_deals_head';
    fcs2Tables('tam_export_manager_deals') := 'tam_export_manager_deals';
    fcs2Tables('tam_export_manager_head') := 'tam_export_manager_head';
    fcs2Tables('tam_files') := 'tam_files';
    fcs2Tables('tam_trans') := 'tam_trans';
    fcs2Tables('taxdisc') := 'taxdisc';
    fcs2Tables('taxrate') := 'taxrate';
    fcs2Tables('tcontact') := 'tcontact';
    fcs2Tables('temp2_ritesh_ordtran') := 'temp2_ritesh_ordtran';
    fcs2Tables('tempreg427') := 'tempreg427';
    fcs2Tables('tempsrri') := 'tempsrri';
    fcs2Tables('temp_2007_rl_pol_cross_ref') := 'temp_2007_rl_pol_cross_ref';
    fcs2Tables('temp_2008_rl_pol_cross_ref') := 'temp_2008_rl_pol_cross_ref';
    fcs2Tables('temp_258') := 'temp_258';
    fcs2Tables('temp_2900_glacper') := 'temp_2900_glacper';
    fcs2Tables('temp_2900_gllegfyr') := 'temp_2900_gllegfyr';
    fcs2Tables('temp_2900_glposts') := 'temp_2900_glposts';
    fcs2Tables('temp_4000_glacper_y27_210307') := 'temp_4000_glacper_y27_210307';
    fcs2Tables('temp_47041') := 'temp_47041';
    fcs2Tables('temp_5105_glacper') := 'temp_5105_glacper';
    fcs2Tables('temp_5105_glposts') := 'temp_5105_glposts';
    fcs2Tables('temp_5105_per_cm') := 'temp_5105_per_cm';
    fcs2Tables('temp_595') := 'temp_595';
    fcs2Tables('temp_596') := 'temp_596';
    fcs2Tables('temp_909_ordtran') := 'temp_909_ordtran';
    fcs2Tables('temp_909_register') := 'temp_909_register';
    fcs2Tables('temp_aber_jhlinks') := 'temp_aber_jhlinks';
    fcs2Tables('temp_account_id_lookup') := 'temp_account_id_lookup';
    fcs2Tables('temp_bacspay_103') := 'temp_bacspay_103';
    fcs2Tables('temp_bacs_collection_ac') := 'temp_bacs_collection_ac';
    fcs2Tables('temp_bacs_interface_transfer') := 'temp_bacs_interface_transfer';
    fcs2Tables('temp_bacs_savers') := 'temp_bacs_savers';
    fcs2Tables('temp_berkeley_ordtran') := 'temp_berkeley_ordtran';
    fcs2Tables('temp_bwd_investors') := 'temp_bwd_investors';
    fcs2Tables('temp_bwd_jhlinks') := 'temp_bwd_jhlinks';
    fcs2Tables('temp_cav_deals') := 'temp_cav_deals';
    fcs2Tables('temp_cav_isaplan') := 'temp_cav_isaplan';
    fcs2Tables('temp_cmar_rev') := 'temp_cmar_rev';
    fcs2Tables('temp_convert') := 'temp_convert';
    fcs2Tables('temp_deminimus_rpt') := 'temp_deminimus_rpt';
    fcs2Tables('temp_exchrates') := 'temp_exchrates';
    fcs2Tables('temp_glacper_189') := 'temp_glacper_189';
    fcs2Tables('temp_glacper_353') := 'temp_glacper_353';
    fcs2Tables('temp_glacper_4000_27') := 'temp_glacper_4000_27';
    fcs2Tables('temp_glacper_4000_y27') := 'temp_glacper_4000_y27';
    fcs2Tables('temp_glacper_4000_y27_2') := 'temp_glacper_4000_y27_2';
    fcs2Tables('temp_glacper_427') := 'temp_glacper_427';
    fcs2Tables('temp_glacper_5101') := 'temp_glacper_5101';
    fcs2Tables('temp_glacper_5101_29_01_07') := 'temp_glacper_5101_29_01_07';
    fcs2Tables('temp_glacper_5101_new') := 'temp_glacper_5101_new';
    fcs2Tables('temp_glacper_5101_new2') := 'temp_glacper_5101_new2';
    fcs2Tables('temp_gllegfyr_4000') := 'temp_gllegfyr_4000';
    fcs2Tables('temp_glposts_189') := 'temp_glposts_189';
    fcs2Tables('temp_holding_319') := 'temp_holding_319';
    fcs2Tables('temp_holding_596') := 'temp_holding_596';
    fcs2Tables('temp_ifacomst_2600') := 'temp_ifacomst_2600';
    fcs2Tables('temp_iimia_register') := 'temp_iimia_register';
    fcs2Tables('temp_income_avail') := 'temp_income_avail';
    fcs2Tables('temp_invcoste') := 'temp_invcoste';
    fcs2Tables('temp_kb_jhlinks') := 'temp_kb_jhlinks';
    fcs2Tables('temp_lt_investor') := 'temp_lt_investor';
    fcs2Tables('temp_margetts_register') := 'temp_margetts_register';
    fcs2Tables('temp_mboxsummary') := 'temp_mboxsummary';
    fcs2Tables('temp_mgm_pre_ifaupd') := 'temp_mgm_pre_ifaupd';
    fcs2Tables('temp_mgm_register') := 'temp_mgm_register';
    fcs2Tables('temp_midas_bacspay') := 'temp_midas_bacspay';
    fcs2Tables('temp_midas_saver') := 'temp_midas_saver';
    fcs2Tables('temp_nepdivpay_37861') := 'temp_nepdivpay_37861';
    fcs2Tables('temp_nepsaver_37861') := 'temp_nepsaver_37861';
    fcs2Tables('temp_neptune_20050125') := 'temp_neptune_20050125';
    fcs2Tables('temp_neptune_20051201') := 'temp_neptune_20051201';
    fcs2Tables('temp_neptune_l36128') := 'temp_neptune_l36128';
    fcs2Tables('temp_neptune_l36140') := 'temp_neptune_l36140';
    fcs2Tables('temp_neptune_l39173') := 'temp_neptune_l39173';
    fcs2Tables('temp_nep_ifa') := 'temp_nep_ifa';
    fcs2Tables('temp_nep_inv') := 'temp_nep_inv';
    fcs2Tables('temp_nep_reg_noorders') := 'temp_nep_reg_noorders';
    fcs2Tables('temp_norma_transfers') := 'temp_norma_transfers';
    fcs2Tables('temp_oeiprice_148') := 'temp_oeiprice_148';
    fcs2Tables('temp_oeiprice_425') := 'temp_oeiprice_425';
    fcs2Tables('temp_ordcalc') := 'temp_ordcalc';
    fcs2Tables('temp_ordcalc_errors') := 'temp_ordcalc_errors';
    fcs2Tables('temp_ordtran_103') := 'temp_ordtran_103';
    fcs2Tables('temp_ordtran_1066') := 'temp_ordtran_1066';
    fcs2Tables('temp_ordtran_148') := 'temp_ordtran_148';
    fcs2Tables('temp_ordtran_191') := 'temp_ordtran_191';
    fcs2Tables('temp_ordtran_2401') := 'temp_ordtran_2401';
    fcs2Tables('temp_ordtran_352') := 'temp_ordtran_352';
    fcs2Tables('temp_ordtran_425') := 'temp_ordtran_425';
    fcs2Tables('temp_ordtran_log') := 'temp_ordtran_log';
    fcs2Tables('temp_ordtran_mv') := 'temp_ordtran_mv';
    fcs2Tables('temp_payment') := 'temp_payment';
    fcs2Tables('temp_payment_2') := 'temp_payment_2';
    fcs2Tables('temp_payment_24615_24828') := 'temp_payment_24615_24828';
    fcs2Tables('temp_payment_transfer') := 'temp_payment_transfer';
    fcs2Tables('temp_portfolio') := 'temp_portfolio';
    fcs2Tables('temp_prices') := 'temp_prices';
    fcs2Tables('temp_problem_deals') := 'temp_problem_deals';
    fcs2Tables('temp_rathbone_xls') := 'temp_rathbone_xls';
    fcs2Tables('temp_rathbone_xls_address') := 'temp_rathbone_xls_address';
    fcs2Tables('temp_register_102') := 'temp_register_102';
    fcs2Tables('temp_register_103') := 'temp_register_103';
    fcs2Tables('temp_register_106') := 'temp_register_106';
    fcs2Tables('temp_register_118') := 'temp_register_118';
    fcs2Tables('temp_register_148') := 'temp_register_148';
    fcs2Tables('temp_register_154') := 'temp_register_154';
    fcs2Tables('temp_register_2401') := 'temp_register_2401';
    fcs2Tables('temp_register_352') := 'temp_register_352';
    fcs2Tables('temp_register_357') := 'temp_register_357';
    fcs2Tables('temp_register_379') := 'temp_register_379';
    fcs2Tables('temp_register_407') := 'temp_register_407';
    fcs2Tables('temp_register_425') := 'temp_register_425';
    fcs2Tables('temp_register_435') := 'temp_register_435';
    fcs2Tables('temp_register_436') := 'temp_register_436';
    fcs2Tables('temp_register_457231') := 'temp_register_457231';
    fcs2Tables('temp_register_log') := 'temp_register_log';
    fcs2Tables('temp_rensburg_2606_register') := 'temp_rensburg_2606_register';
    fcs2Tables('temp_rensburg_2608_register') := 'temp_rensburg_2608_register';
    fcs2Tables('temp_rlglacper_correction') := 'temp_rlglacper_correction';
    fcs2Tables('temp_rl_migration') := 'temp_rl_migration';
    fcs2Tables('temp_rl_refer') := 'temp_rl_refer';
    fcs2Tables('temp_rolepwd') := 'temp_rolepwd';
    fcs2Tables('temp_s18') := 'temp_s18';
    fcs2Tables('temp_saver_106') := 'temp_saver_106';
    fcs2Tables('temp_saver_407') := 'temp_saver_407';
    fcs2Tables('temp_saver_435') := 'temp_saver_435';
    fcs2Tables('temp_sdrt_errors') := 'temp_sdrt_errors';
    fcs2Tables('temp_signof_103') := 'temp_signof_103';
    fcs2Tables('temp_signof_148') := 'temp_signof_148';
    fcs2Tables('temp_signof_2401') := 'temp_signof_2401';
    fcs2Tables('temp_signof_425') := 'temp_signof_425';
    fcs2Tables('temp_si_client') := 'temp_si_client';
    fcs2Tables('temp_si_portfolio') := 'temp_si_portfolio';
    fcs2Tables('temp_stale_prices') := 'temp_stale_prices';
    fcs2Tables('temp_topholder') := 'temp_topholder';
    fcs2Tables('temp_tot_bacs_trust_post_val') := 'temp_tot_bacs_trust_post_val';
    fcs2Tables('temp_transact_319') := 'temp_transact_319';
    fcs2Tables('temp_transact_596') := 'temp_transact_596';
    fcs2Tables('temp_trust') := 'temp_trust';
    fcs2Tables('temp_trust_recon') := 'temp_trust_recon';
    fcs2Tables('temp_tsteerep_103') := 'temp_tsteerep_103';
    fcs2Tables('temp_tsteerep_148') := 'temp_tsteerep_148';
    fcs2Tables('temp_tsteerep_2401') := 'temp_tsteerep_2401';
    fcs2Tables('temp_tsteerep_425') := 'temp_tsteerep_425';
    fcs2Tables('temp_twohrfmg_boxcon') := 'temp_twohrfmg_boxcon';
    fcs2Tables('temp_valhead_103') := 'temp_valhead_103';
    fcs2Tables('temp_valhead_148') := 'temp_valhead_148';
    fcs2Tables('temp_valhead_2401') := 'temp_valhead_2401';
    fcs2Tables('temp_valhead_425') := 'temp_valhead_425';
    fcs2Tables('territory') := 'territory';
    fcs2Tables('tfr_detail') := 'tfr_detail';
    fcs2Tables('tfr_header') := 'tfr_header';
    fcs2Tables('threshold_checks') := 'threshold_checks';
    fcs2Tables('thretpt') := 'thretpt';
    fcs2Tables('thretpt_rl') := 'thretpt_rl';
    fcs2Tables('thr_int_bankdetails') := 'thr_int_bankdetails';
    fcs2Tables('thr_int_clientinvxref') := 'thr_int_clientinvxref';
    fcs2Tables('thr_int_contract_emails') := 'thr_int_contract_emails';
    fcs2Tables('thr_int_fundowner') := 'thr_int_fundowner';
    fcs2Tables('thr_int_fund_usage') := 'thr_int_fund_usage';
    fcs2Tables('thr_int_investor') := 'thr_int_investor';
    fcs2Tables('thr_int_investorbank') := 'thr_int_investorbank';
    fcs2Tables('thr_int_investor_manager_pens') := 'thr_int_investor_manager_pens';
    fcs2Tables('thr_int_investor_trust_pens') := 'thr_int_investor_trust_pens';
    fcs2Tables('thr_int_inv_withdrawal_limit') := 'thr_int_inv_withdrawal_limit';
    fcs2Tables('thr_int_log') := 'thr_int_log';
    fcs2Tables('thr_int_manager') := 'thr_int_manager';
    fcs2Tables('thr_int_memo') := 'thr_int_memo';
    fcs2Tables('thr_int_oeiprice') := 'thr_int_oeiprice';
    fcs2Tables('thr_int_ordtran') := 'thr_int_ordtran';
    fcs2Tables('thr_int_postrule') := 'thr_int_postrule';
    fcs2Tables('thr_int_price_history') := 'thr_int_price_history';
    fcs2Tables('thr_int_register') := 'thr_int_register';
    fcs2Tables('thr_int_trstcode_xref') := 'thr_int_trstcode_xref';
    fcs2Tables('thr_int_trsttype') := 'thr_int_trsttype';
    fcs2Tables('thr_int_trust') := 'thr_int_trust';
    fcs2Tables('thr_int_trustee') := 'thr_int_trustee';
    fcs2Tables('thr_int_unitsinissue') := 'thr_int_unitsinissue';
    fcs2Tables('thr_int_unittype') := 'thr_int_unittype';
    fcs2Tables('thr_int_valhead') := 'thr_int_valhead';
    fcs2Tables('titles') := 'titles';
    fcs2Tables('tmpinvestorholding') := 'tmpinvestorholding';
    fcs2Tables('tmp_agentsales') := 'tmp_agentsales';
    fcs2Tables('tmp_agent_addresses') := 'tmp_agent_addresses';
    fcs2Tables('tmp_cav_isatot') := 'tmp_cav_isatot';
    fcs2Tables('tmp_cg_fix') := 'tmp_cg_fix';
    fcs2Tables('tmp_find_linked_issues') := 'tmp_find_linked_issues';
    fcs2Tables('tmp_glacper_3200_27') := 'tmp_glacper_3200_27';
    fcs2Tables('tmp_glacper_3200_28') := 'tmp_glacper_3200_28';
    fcs2Tables('tmp_glacper_357101800') := 'tmp_glacper_357101800';
    fcs2Tables('tmp_gllegfyr') := 'tmp_gllegfyr';
    fcs2Tables('tmp_invstat_amc') := 'tmp_invstat_amc';
    fcs2Tables('tmp_invstat_benchmark') := 'tmp_invstat_benchmark';
    fcs2Tables('tmp_invstat_dividends') := 'tmp_invstat_dividends';
    fcs2Tables('tmp_l52588') := 'tmp_l52588';
    fcs2Tables('tmp_log138506_miton') := 'tmp_log138506_miton';
    fcs2Tables('tmp_mgm_reinvestors') := 'tmp_mgm_reinvestors';
    fcs2Tables('tmp_neptune_dividend') := 'tmp_neptune_dividend';
    fcs2Tables('tmp_neptune_ifa') := 'tmp_neptune_ifa';
    fcs2Tables('tmp_neptune_investor') := 'tmp_neptune_investor';
    fcs2Tables('tmp_network_bank') := 'tmp_network_bank';
    fcs2Tables('tmp_renregister') := 'tmp_renregister';
    fcs2Tables('tmp_rensburg_addresses') := 'tmp_rensburg_addresses';
    fcs2Tables('tmp_rensburg_ifa') := 'tmp_rensburg_ifa';
    fcs2Tables('tmp_rensburg_inspecietransfers') := 'tmp_rensburg_inspecietransfers';
    fcs2Tables('tmp_rensburg_memo') := 'tmp_rensburg_memo';
    fcs2Tables('tmp_rensburg_networks') := 'tmp_rensburg_networks';
    fcs2Tables('tmp_rensifaaddress') := 'tmp_rensifaaddress';
    fcs2Tables('tmp_rensifadiarynotes') := 'tmp_rensifadiarynotes';
    fcs2Tables('tmp_rensifas') := 'tmp_rensifas';
    fcs2Tables('tmp_rensinvcountry') := 'tmp_rensinvcountry';
    fcs2Tables('tmp_rensinvestors') := 'tmp_rensinvestors';
    fcs2Tables('tmp_renstransactions') := 'tmp_renstransactions';
    fcs2Tables('tmp_rens_savers') := 'tmp_rens_savers';
    fcs2Tables('tmp_rl_register') := 'tmp_rl_register';
    fcs2Tables('tmp_rl_saver') := 'tmp_rl_saver';
    fcs2Tables('tmp_subacrec_ritesh') := 'tmp_subacrec_ritesh';
    fcs2Tables('tmp_twohrfmg_boxcon') := 'tmp_twohrfmg_boxcon';
    fcs2Tables('tmp_wc_holdings') := 'tmp_wc_holdings';
    fcs2Tables('tmp_wc_transactions') := 'tmp_wc_transactions';
    fcs2Tables('toad_plan_table') := 'toad_plan_table';
    fcs2Tables('topdirpt') := 'topdirpt';
    fcs2Tables('topifapt') := 'topifapt';
    fcs2Tables('topsec') := 'topsec';
    fcs2Tables('tothld_temp') := 'tothld_temp';
    fcs2Tables('tothld_temp_srt') := 'tothld_temp_srt';
    fcs2Tables('tothld_temp_srt_t') := 'tothld_temp_srt_t';
    fcs2Tables('tothld_value_temp') := 'tothld_value_temp';
    fcs2Tables('tothld_value_temp_srt') := 'tothld_value_temp_srt';
    fcs2Tables('totifa_temp') := 'totifa_temp';
    fcs2Tables('totifa_temp_srt') := 'totifa_temp_srt';
    fcs2Tables('totpropvl') := 'totpropvl';
    fcs2Tables('totpropvlo') := 'totpropvlo';
    fcs2Tables('trailifa') := 'trailifa';
    fcs2Tables('trailinv') := 'trailinv';
    fcs2Tables('trailtst') := 'trailtst';
    fcs2Tables('trancode') := 'trancode';
    fcs2Tables('transfer_let') := 'transfer_let';
    fcs2Tables('transf_file') := 'transf_file';
    fcs2Tables('transpt') := 'transpt';
    fcs2Tables('trcntex') := 'trcntex';
    fcs2Tables('trcsdrtp') := 'trcsdrtp';
    fcs2Tables('tregdisp') := 'tregdisp';
    fcs2Tables('trepext') := 'trepext';
    fcs2Tables('trstsort') := 'trstsort';
    fcs2Tables('trsttype') := 'trsttype';
    fcs2Tables('trtsteyv') := 'trtsteyv';
    fcs2Tables('trust') := 'trust';
    fcs2Tables('trustee') := 'trustee';
    fcs2Tables('trustee_interest_rate') := 'trustee_interest_rate';
    fcs2Tables('trust_cutoff') := 'trust_cutoff';
    fcs2Tables('trust_delayed_dealing') := 'trust_delayed_dealing';
    fcs2Tables('trust_group') := 'trust_group';
    fcs2Tables('trust_ic') := 'trust_ic';
    fcs2Tables('trust_ima') := 'trust_ima';
    fcs2Tables('trust_incexptp') := 'trust_incexptp';
    fcs2Tables('trust_openmkts') := 'trust_openmkts';
    fcs2Tables('trust_price_link') := 'trust_price_link';
    fcs2Tables('trust_report_maintenance') := 'trust_report_maintenance';
    fcs2Tables('trust_subgroup') := 'trust_subgroup';
    fcs2Tables('truvextb') := 'truvextb';
    fcs2Tables('tsteerep') := 'tsteerep';
    fcs2Tables('tsteerep_breakdown') := 'tsteerep_breakdown';
    fcs2Tables('tsteerep_conversion') := 'tsteerep_conversion';
    fcs2Tables('tteefout') := 'tteefout';
    fcs2Tables('twohourreturn') := 'twohourreturn';
    fcs2Tables('twohourreturn_rl') := 'twohourreturn_rl';
    fcs2Tables('umat') := 'umat';
    fcs2Tables('umat_audit') := 'umat_audit';
    fcs2Tables('umbrella') := 'umbrella';
    fcs2Tables('unitred') := 'unitred';
    fcs2Tables('unitset') := 'unitset';
    fcs2Tables('unittran') := 'unittran';
    fcs2Tables('unittype') := 'unittype';
    fcs2Tables('unit_trust_reconciliation') := 'unit_trust_reconciliation';
    fcs2Tables('universe') := 'universe';
    fcs2Tables('uploadedstaticsedol') := 'uploadedstaticsedol';
    fcs2Tables('userguide') := 'userguide';
    fcs2Tables('userguidecategory') := 'userguidecategory';
    fcs2Tables('uses_csm') := 'uses_csm';
    fcs2Tables('use_old_pricing') := 'use_old_pricing';
    fcs2Tables('utred') := 'utred';
    fcs2Tables('utredseq') := 'utredseq';
    fcs2Tables('uvmes_email_body') := 'uvmes_email_body';
    fcs2Tables('uv_offload_bacspay') := 'uv_offload_bacspay';
    fcs2Tables('uv_offload_ifa') := 'uv_offload_ifa';
    fcs2Tables('uv_offload_investor') := 'uv_offload_investor';
    fcs2Tables('uv_offload_isatot') := 'uv_offload_isatot';
    fcs2Tables('uv_offload_mandaddr') := 'uv_offload_mandaddr';
    fcs2Tables('uv_offload_others') := 'uv_offload_others';
    fcs2Tables('uv_offload_register') := 'uv_offload_register';
    fcs2Tables('uv_offload_reinvest') := 'uv_offload_reinvest';
    fcs2Tables('valcdhold') := 'valcdhold';
    fcs2Tables('valdiary') := 'valdiary';
    fcs2Tables('valdue') := 'valdue';
    fcs2Tables('valfxhold') := 'valfxhold';
    fcs2Tables('valhead') := 'valhead';
    fcs2Tables('valhead_ioe') := 'valhead_ioe';
    fcs2Tables('valhead_max') := 'valhead_max';
    fcs2Tables('valhead_temp') := 'valhead_temp';
    fcs2Tables('valhold') := 'valhold';
    fcs2Tables('valhold_ioe') := 'valhold_ioe';
    fcs2Tables('valpex') := 'valpex';
    fcs2Tables('valsignof') := 'valsignof';
    fcs2Tables('valsignof_notes') := 'valsignof_notes';
    fcs2Tables('valsignof_question') := 'valsignof_question';
    fcs2Tables('valsignof_section') := 'valsignof_section';
    fcs2Tables('valxrate_temp') := 'valxrate_temp';
    fcs2Tables('val_moved') := 'val_moved';
    fcs2Tables('vatrate') := 'vatrate';
    fcs2Tables('virtual') := 'virtual';
    fcs2Tables('void_detail') := 'void_detail';
    fcs2Tables('waiver_detail') := 'waiver_detail';
    fcs2Tables('waiver_header') := 'waiver_header';
    fcs2Tables('waiver_type') := 'waiver_type';
    fcs2Tables('warrant') := 'warrant';
    fcs2Tables('web_portal_coa') := 'web_portal_coa';
    fcs2Tables('web_portal_coa_detail') := 'web_portal_coa_detail';
    fcs2Tables('web_portal_companies') := 'web_portal_companies';
    fcs2Tables('web_portal_letter_request') := 'web_portal_letter_request';
    fcs2Tables('web_portal_registration') := 'web_portal_registration';
    fcs2Tables('web_portal_registration_det') := 'web_portal_registration_det';
    fcs2Tables('web_portal_trust') := 'web_portal_trust';
    fcs2Tables('web_portal_trust_sclass') := 'web_portal_trust_sclass';
    fcs2Tables('web_portal_user_investor') := 'web_portal_user_investor';
    fcs2Tables('web_portal_user_type') := 'web_portal_user_type';
    fcs2Tables('web_services_user') := 'web_services_user';
    fcs2Tables('wf_action') := 'wf_action';
    fcs2Tables('wf_control') := 'wf_control';
    fcs2Tables('wf_instance') := 'wf_instance';
    fcs2Tables('wf_response') := 'wf_response';
    fcs2Tables('wf_role') := 'wf_role';
    fcs2Tables('wf_role_user') := 'wf_role_user';
    fcs2Tables('wf_template') := 'wf_template';
    fcs2Tables('wf_template_response') := 'wf_template_response';
    fcs2Tables('wf_template_step') := 'wf_template_step';
    fcs2Tables('wf_trust_ovr') := 'wf_trust_ovr';
    fcs2Tables('wf_trust_type_ovr') := 'wf_trust_type_ovr';
    fcs2Tables('which_country') := 'which_country';
    fcs2Tables('withdrawal_details') := 'withdrawal_details';
    fcs2Tables('withdrawal_frequency') := 'withdrawal_frequency';
    fcs2Tables('withdrawal_plan') := 'withdrawal_plan';
    fcs2Tables('withdrawal_yield') := 'withdrawal_yield';
    fcs2Tables('workdays') := 'workdays';
    fcs2Tables('ws_client') := 'ws_client';
    fcs2Tables('ws_client_ifa') := 'ws_client_ifa';
    fcs2Tables('ws_error_definition') := 'ws_error_definition';
    fcs2Tables('ws_fund_authorisation') := 'ws_fund_authorisation';
    fcs2Tables('ws_message_event') := 'ws_message_event';
    fcs2Tables('ws_message_history') := 'ws_message_history';
    fcs2Tables('ws_message_operation') := 'ws_message_operation';
    fcs2Tables('ws_message_type') := 'ws_message_type';
    fcs2Tables('ws_notifications') := 'ws_notifications';
    fcs2Tables('ws_service_operation') := 'ws_service_operation';
    fcs2Tables('ws_systems') := 'ws_systems';
    fcs2Tables('ws_system_client') := 'ws_system_client';
    fcs2Tables('xml_status_temp') := 'xml_status_temp';
    
    
    -- Everything else. This catches any new tables added since
    -- initial testing extracted the above lists of tables.
    -- Temporary and external tables are omitted of course.
    for TableNameIndex in (
        select lower(table_name) as table_name
        from dba_tables
        where owner = 'FCS'
        and temporary <> 'Y'
        and (owner,table_name) not in (select owner, table_name from dba_external_tables)
        order by 1) loop
        
        -- If the table name already exists in a collection, ignore it
        -- which will be the case most often, otherwise, tag it on to
        -- the fcs7Table list.
        -- Existing tables are most likely to be found in fcs2Tables
        -- fcs7Tables or fcs6Tables as the rest are small table lists.
        currentTable := TableNameIndex.table_name;
        if (fcs2Tables.exists(currentTable) or
            fcs7Tables.exists(currentTable) or
            fcs6Tables.exists(currentTable) or
            fcs1Tables.exists(currentTable) or
            fcs3Tables.exists(currentTable) or
            fcs4Tables.exists(currentTable) or
            fcs5Tables.exists(currentTable) or
            fcs8Tables.exists(currentTable) or
            fcs9Tables.exists(currentTable)) then
            
            -- Ignore this one.
            null;
        else
            -- New table, add it to fcs7Tables.
            fcs7Tables(currentTable) := currentTable;   
        end if;
    end loop; 
    
    -- We have our list of existing tables, all happily waiting
    -- to be written to an export parameter file. However, some
    -- tables are simply not wanted in the new regime. This is
    -- where we get rid of the unloved tables from the above lists.
    tableIndexer := unLovedTables.first;
    
    while (tableIndexer is not null) loop
        currentTable := unlovedTables(tableIndexer);
        
        -- Scan each list, removing the currentTable
        -- from it, if found. We assume that the table
        -- can only be present in one list.
        if (fcs1Tables.exists(currentTable)) then
            fcs1Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs2Tables.exists(currentTable)) then
            fcs2Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs3Tables.exists(currentTable)) then
            fcs3Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs4Tables.exists(currentTable)) then
            fcs4Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs5Tables.exists(currentTable)) then
            fcs5Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs6Tables.exists(currentTable)) then
            fcs6Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs7Tables.exists(currentTable)) then
            fcs7Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs8Tables.exists(currentTable)) then
            fcs8Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        if (fcs9Tables.exists(currentTable)) then
            fcs9Tables.delete(unLovedTables(tableIndexer));
            tableIndexer := unLovedTables.next(tableIndexer);
            --continue;
            goto end_loop;
        end if;

        -- If we get here, the unlovedTable isn't in any of the
        -- lists. What  to do? Do we barf? We are ignoring the
        -- table after al, and it's not found. Should be ok!
        -- Famous last words.
        -- However, we will continue searching for others.
        tableIndexer := unLovedTables.next(tableIndexer);
        
        -- 9i can't do "continue" so we need a label and a goto.
        -- And a goto label needs an executable statement, hence NULL;
    <<end_loop>>
        null;
        
    end loop;

end;
/    
