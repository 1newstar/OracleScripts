-- Total number of fragmented tables (i.e. full blocks % <= 50): 19
------------ List of Tables ------------
-- TABLE:      D_PCLSHP_DPOT_SERVICE             % Full Blocks:   20.03
-- TABLE:      F_DRVR_ETRY                       
-- PARTITION:  F_DRVR_ETRY_201801                % Full Blocks:   39.16
-- TABLE:      A_CLN_ENTRY                       
-- PARTITION:  A_CLN_ENTRY_201801                % Full Blocks:   46.80
-- TABLE:      A_NETWORK_ENTRY                   
-- PARTITION:  A_NETWORK_ENTRY_201802            % Full Blocks:   49.55
-- TABLE:      A_UPP_DEPOT_END_TO_END            
-- PARTITION:  A_UPP_DEPOT_END_TO_END_201801     % Full Blocks:   44.74
-- TABLE:      F_CLT_INT                         
-- PARTITION:  F_CLT_INT_201802                  % Full Blocks:   28.72
-- TABLE:      MV_A_OSOS_DPOT_ENTRY              
-- PARTITION:  MV_A_OSOS_DPOT_ENTRY_201801       % Full Blocks:   37.98
-- TABLE:      F_C2C_C2B_SOS                     
-- PARTITION:  F_C2C_C2B_SOS_201802              % Full Blocks:   20.42
-- TABLE:      F_PCLSHP_OVERALL_SOS              
-- PARTITION:  F_PCLSHP_OVERALL_SOS_201802       % Full Blocks:   17.75
-- TABLE:      A_PREADV_ENTRY_AGG                
-- PARTITION:  A_PREADV_ENTRY_AGG_201802         % Full Blocks:   21.25
-- TABLE:      MV_A_SOS_COURIER                  
-- PARTITION:  MV_A_SOS_COURIER_201801           % Full Blocks:   34.70
-- TABLE:      F_PCLSHP_ETRY                     
-- PARTITION:  F_PCLSHP_ETRY_201802              % Full Blocks:   12.20
-- TABLE:      MV_A_CLN_ENTRY                    
-- PARTITION:  MV_A_CLN_ENTRY_201801             % Full Blocks:   35.22
-- TABLE:      F_DELIVERY_PARCEL_SO              
-- PARTITION:  F_DELIVERY_PARCEL_SO_201802       % Full Blocks:   22.25
-- TABLE:      D_COURIER_RND_DETAILS             % Full Blocks:   20.00
-- TABLE:      F_PCLSHP_RTRN_VOL                 
-- PARTITION:  F_PCLSHP_RTRN_VOL_201802          % Full Blocks:    0.00
-- TABLE:      F_PCLSHP_RTRN_INV                 
-- PARTITION:  F_PCLSHP_RTRN_INV_201802          % Full Blocks:    0.00
-- TABLE:      F_C2B_INV                         
-- PARTITION:  F_C2B_INV_201802                  % Full Blocks:   22.41
-- TABLE:      F_PCLSHP_OVRALL_SOS_B2C           
-- PARTITION:  F_PCLSHP_OVRALL_SOS_B2C_201802    % Full Blocks:   46.99
-----------------------------------------------------------------------
set serverout on size unlimited
set feedback off

-----------------------------------------------------------------------
-- TABLE: D_PCLSHP_DPOT_SERVICE
-----------------------------------------------------------------------
-- TABLE: D_PCLSHP_DPOT_SERVICE -- Size (MB): 5321
-- Partially used blocks: 543765
-- Percentage of highly fragmented blocks: 99.22%
-- Formatted Blocks: 679927
-- Full Blocks: 136162 -- %Full Blocks: 20.03
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_IDX_1 rebuild parallel  online;
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_PK rebuild parallel  online;
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_IDX_RNG rebuild parallel 1 online;
exec dbms_output.put_line('Done 1 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_DRVR_ETRY     PARTITION: F_DRVR_ETRY_201801
-----------------------------------------------------------------------
-- TABLE: F_DRVR_ETRY -- Size (MB): 564.81
-- Partially used blocks: 41661
-- Percentage of highly fragmented blocks: 91.3%
-- Formatted Blocks: 68476
-- Full Blocks: 26815 -- %Full Blocks: 39.16
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_DRVR_ETRY MOVE partition F_DRVR_ETRY_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.XPKFDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF1FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF2FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF3FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF7FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF9FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF10FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF11FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF13FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF14FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF15FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF16FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.XIF17FDE rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDE_PCL_TME_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDI_ENTER_PCLSHP_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDE_DSGTD_PCLSHP_ID rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDE_PCLSHP_DPOT_SERVICE_KEY rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDE_C2C_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDE_C2B_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDI_HAS_HUB_SCAN_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDI_HAS_DPOT_SCAN_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
alter index HERMES_MI_MART.FDI_HAS_CR_DELIV_SCAN_IND_I rebuild partition F_DRVR_ETRY_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 2 out of 19');

-----------------------------------------------------------------------
-- TABLE: A_CLN_ENTRY     PARTITION: A_CLN_ENTRY_201801
-----------------------------------------------------------------------
-- TABLE: A_CLN_ENTRY -- Size (MB): 181
-- Partially used blocks: 11746
-- Percentage of highly fragmented blocks: 57.83%
-- Formatted Blocks: 22081
-- Full Blocks: 10335 -- %Full Blocks: 46.8
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLN_ENTRY MOVE partition A_CLN_ENTRY_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.ACE_SCHEDULED_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_STATED_DAY_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_PICKUP_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_PARCEL_COLLECTED_RIGHT_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_PM_COLLECTION_REQUESTED_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_RE_MANIFEST_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_LATEST_CR_RND_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_HHT_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_DLY_MTHD_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_FIRST_DPOT_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_MFST_DPOT_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_LATEST_CR_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_COLLECTED_NO_CHARGE_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_LATEST_CR_DATE_FBI rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_PAPER_MANIFEST_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_CR_ONLINE_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_AM_COLLECTION_REQUESTED_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_LATEST_DPOT_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_CLT_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_CAR_ID_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_CLN_TME_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.A_CLN_ENTRY_PAR_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.ACE_STATED_TIME_IND_I rebuild partition A_CLN_ENTRY_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 3 out of 19');

-----------------------------------------------------------------------
-- TABLE: A_NETWORK_ENTRY     PARTITION: A_NETWORK_ENTRY_201802
-----------------------------------------------------------------------
-- TABLE: A_NETWORK_ENTRY -- Size (MB): 79
-- Partially used blocks: 5010
-- Percentage of highly fragmented blocks: 88.18%
-- Formatted Blocks: 9931
-- Full Blocks: 4921 -- %Full Blocks: 49.55
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_NETWORK_ENTRY MOVE partition A_NETWORK_ENTRY_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FNE_PCL_CLT_ID_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_LATEST_CR_RND_ID_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_LATEST_CR_ID_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_PCL_TME_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_PCL_DLY_MTHD_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_OUTLYING_AREA_CODE_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.A_NETWORK_ENTRY_PAR_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_INV_IND_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.FNE_SO_SRVC_ID_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.ANE_C2C_IND_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
alter index HERMES_MI_MART.ANE_C2B_IND_I rebuild partition A_NETWORK_ENTRY_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 4 out of 19');

-----------------------------------------------------------------------
-- TABLE: A_UPP_DEPOT_END_TO_END     PARTITION: A_UPP_DEPOT_END_TO_END_201801
-----------------------------------------------------------------------
-- TABLE: A_UPP_DEPOT_END_TO_END -- Size (MB): 48
-- Partially used blocks: 2870
-- Percentage of highly fragmented blocks: 62.6%
-- Formatted Blocks: 5194
-- Full Blocks: 2324 -- %Full Blocks: 44.74
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_UPP_DEPOT_END_TO_END MOVE partition A_UPP_DEPOT_END_TO_END_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.AUDE_PCL_SAFE_PLACE_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_CLT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_DLY_MTHD_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_LATEST_CR_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_LATEST_CR_RND_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_TME_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_TYP_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_LAST_HUB_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_FIRST_HUB_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_LAST_DPOT_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_DESIGNATED_DPOT_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_OUTLYING_AREA_CODE_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_PCL_CAR_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_LAST_SEEN_TRKG_PNT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_DEFAULT_CLT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_LATEST_CR_DATE_FBI rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.A_UPP_DEPOT_END_TO_END_PAR_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_UPP_CR_END_IND_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_UPP_DPOT_END_IND_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_C2C_IND_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_FIRSTUPP_CE_TRKG_PNT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_FIRSTUPP_DE_TRKG_PNT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_FIRST_CR_ID rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_C2B_IND_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_RTRN_CLT_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_INV_IND_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_FINANCE_AREA_CDE_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
alter index HERMES_MI_MART.AUDE_SO_SRVC_ID_I rebuild partition A_UPP_DEPOT_END_TO_END_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 5 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_CLT_INT     PARTITION: F_CLT_INT_201802
-----------------------------------------------------------------------
-- TABLE: F_CLT_INT -- Size (MB): 46.56
-- Partially used blocks: 4162
-- Percentage of highly fragmented blocks: 94.59%
-- Formatted Blocks: 5839
-- Full Blocks: 1677 -- %Full Blocks: 28.72
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_CLT_INT MOVE partition F_CLT_INT_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.F_CLT_INT_PK rebuild partition F_CLT_INT_201802 parallel  online;
alter index HERMES_MI_MART.FCI_PCL_CLT_ID_I rebuild partition F_CLT_INT_201802 parallel  online;
alter index HERMES_MI_MART.F_CLT_INT_PAR_I rebuild partition F_CLT_INT_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 6 out of 19');

-----------------------------------------------------------------------
-- TABLE: MV_A_OSOS_DPOT_ENTRY     PARTITION: MV_A_OSOS_DPOT_ENTRY_201801
-----------------------------------------------------------------------
-- TABLE: MV_A_OSOS_DPOT_ENTRY -- Size (MB): 40
-- Partially used blocks: 3095
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 4990
-- Full Blocks: 1895 -- %Full Blocks: 37.98
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.MV_A_OSOS_DPOT_ENTRY MOVE partition MV_A_OSOS_DPOT_ENTRY_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.MV_A_OSOS_DPOT_ENTRY_PAR_I rebuild partition MV_A_OSOS_DPOT_ENTRY_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 7 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_C2C_C2B_SOS     PARTITION: F_C2C_C2B_SOS_201802
-----------------------------------------------------------------------
-- TABLE: F_C2C_C2B_SOS -- Size (MB): 33.31
-- Partially used blocks: 3312
-- Percentage of highly fragmented blocks: 88.93%
-- Formatted Blocks: 4162
-- Full Blocks: 850 -- %Full Blocks: 20.42
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_C2C_C2B_SOS MOVE partition F_C2C_C2B_SOS_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FCCS_CR_COLLATT_TRKG_PNT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CR_COLLECTED_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_PCKP_MFST_RQST_CR_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_PCKP_MFST_RQST_TR_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DEL_ENTRY_DATE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DEL_ENTRY_POINT_LE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_CLT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_CUST_PSTCDE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_INBND_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_COLLECTED_AM_IN_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_COLLECTED_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_LATEST_CR_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_LATEST_CR_RND_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DEL_END_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DEL_END_TRKG_PNT_I_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_CR_INBND_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_ETRY_PCLSHP_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_ETRY_PCLSHP_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_DUP_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_ENTER_CR_INBND_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_ENTER_DRVR_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_PCLSHP_DRVR_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HAS_CR_INBND_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HAS_PCKP_MFST_RQST_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CR_ATTEMPT_TRKG_PNT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CR_COL_PREADVICE_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HAS_SOS_HUB_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HER_COLLECT_SLA_SUCCES_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HAS_SOS_CR_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_HAS_SOS_DPOT_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_DSGTD_CR_RND_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_ENTER_INB_DPOT_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_COLLECTED_PM_IN_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_ENTER_PCLSHP_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FIRST_PRE_ADVICE_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_DLY_MTHD_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_DSGTD_DPOT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_IN_DPOT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_FIRST_HUB_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FIRST_SEEN_TRKG_PNT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_IN_DPOT_RCPT_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_LAST_CR_HER_CLATT_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_LAST_SEEN_TRKG_PNT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_C2B_END_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_COLLECTED_RIGHT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_C2B_HUB_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_CR_INBND_CR_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_CAR_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_OTBND_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_LAST_DPOT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_LAST_HUB_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_TYP_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PCL_WT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PM_COLLECTION_REQUESTE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_RTRN_CLT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_FRST_CR_INBND_CR_RND_I_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_OUTLYING_AREA_CDE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_CLC_WRONG_DAY_E_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_PARCEL_CLC_WRONG_DAY_L_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CLN_DLY_MTHD_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CNCT_CNTR_PCL_CNCL_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_C2C_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CLI_COL_PREADVICE_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CLN_PSTCDE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SAME_DPOT_C2C_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_CR_ENTRY_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XPKF_C2C_C2B_SOS rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XPKF_PNET_BCDE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CR_NOT_COLLECTED_TRKG_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_DFLT_CLT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_BFPO_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_C2B_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_CUSTOMER_NUMBER_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_AM_COLLECTION_REQUESTE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DPOT_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_HUB_ENTRY_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_HUB_ID_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_STATED_DAY_IND_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FIRST_NTWRK_CLEAN_DATE_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DEL_ENTRY_TRKG_PNT_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FCCS_SOS_DPOT_ENTRY_TRKG_PN_I rebuild partition F_C2C_C2B_SOS_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 8 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVERALL_SOS     PARTITION: F_PCLSHP_OVERALL_SOS_201802
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVERALL_SOS -- Size (MB): 29.06
-- Partially used blocks: 2984
-- Percentage of highly fragmented blocks: 91.41%
-- Formatted Blocks: 3628
-- Full Blocks: 644 -- %Full Blocks: 17.75
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_OVERALL_SOS MOVE partition F_PCLSHP_OVERALL_SOS_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.XPKFPOSS_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XIF1FPOSS rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XIF9FPOSS rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XIF7FPOSS rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XIF10FPOSS rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPOS_PCL_TME_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPOS_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPOS_PCLSHP_DPOT_SERVICE_KEY rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FRST_ETRY_PCLSHP_ID_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPPO_HAS_SHOP_SCN_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPPO_HAS_DRVR_SCN_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPOS_C2C_IND_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.FPOS_C2B_IND_I rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel  online;
alter index HERMES_MI_MART.XPKFPOSS rebuild partition F_PCLSHP_OVERALL_SOS_201802 parallel 1 online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 9 out of 19');

-----------------------------------------------------------------------
-- TABLE: A_PREADV_ENTRY_AGG     PARTITION: A_PREADV_ENTRY_AGG_201802
-----------------------------------------------------------------------
-- TABLE: A_PREADV_ENTRY_AGG -- Size (MB): 28
-- Partially used blocks: 2754
-- Percentage of highly fragmented blocks: 98.28%
-- Formatted Blocks: 3497
-- Full Blocks: 743 -- %Full Blocks: 21.25
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_PREADV_ENTRY_AGG MOVE partition A_PREADV_ENTRY_AGG_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.APE_PCL_TME_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_LATEST_CR_RND_ID_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_PCL_CLT_ID_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_PCL_DLY_MTHD_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_OUTLYING_AREA_CODE_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.A_PREADV_ENTRY_AGG_PAR_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_C2B_IND_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_INV_IND_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_SO_SRVC_ID_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
alter index HERMES_MI_MART.APE_C2C_IND_I rebuild partition A_PREADV_ENTRY_AGG_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 10 out of 19');

-----------------------------------------------------------------------
-- TABLE: MV_A_SOS_COURIER     PARTITION: MV_A_SOS_COURIER_201801
-----------------------------------------------------------------------
-- TABLE: MV_A_SOS_COURIER -- Size (MB): 26
-- Partially used blocks: 2138
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 3274
-- Full Blocks: 1136 -- %Full Blocks: 34.7
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.MV_A_SOS_COURIER MOVE partition MV_A_SOS_COURIER_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.MV_A_SOS_COURIER_PAR_I rebuild partition MV_A_SOS_COURIER_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 11 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_ETRY     PARTITION: F_PCLSHP_ETRY_201802
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_ETRY -- Size (MB): 25.75
-- Partially used blocks: 2820
-- Percentage of highly fragmented blocks: 94.56%
-- Formatted Blocks: 3212
-- Full Blocks: 392 -- %Full Blocks: 12.2
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_ETRY MOVE partition F_PCLSHP_ETRY_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FPE_C2C_IND_I rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.XPKFPE rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.XIF1FPE rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.XIF11FPE rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.XIF17FPE rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.FPE_PCL_TME_I rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.FPE_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.FPE_PCLSHP_DPOT_SERVICE_KEY rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
alter index HERMES_MI_MART.FPE_C2B_IND_I rebuild partition F_PCLSHP_ETRY_201802 parallel 8 online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 12 out of 19');

-----------------------------------------------------------------------
-- TABLE: MV_A_CLN_ENTRY     PARTITION: MV_A_CLN_ENTRY_201801
-----------------------------------------------------------------------
-- TABLE: MV_A_CLN_ENTRY -- Size (MB): 15
-- Partially used blocks: 1192
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 1840
-- Full Blocks: 648 -- %Full Blocks: 35.22
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.MV_A_CLN_ENTRY MOVE partition MV_A_CLN_ENTRY_201801 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.MV_A_CLN_ENTRY_PAR_I rebuild partition MV_A_CLN_ENTRY_201801 parallel  online;
alter index HERMES_MI_MART.MV_A_CLN_ENTRY2_PAR_I rebuild partition MV_A_CLN_ENTRY_201801 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 13 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_DELIVERY_PARCEL_SO     PARTITION: F_DELIVERY_PARCEL_SO_201802
-----------------------------------------------------------------------
-- TABLE: F_DELIVERY_PARCEL_SO -- Size (MB): 10.69
-- Partially used blocks: 1024
-- Percentage of highly fragmented blocks: 99.71%
-- Formatted Blocks: 1317
-- Full Blocks: 293 -- %Full Blocks: 22.25
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_DELIVERY_PARCEL_SO MOVE partition F_DELIVERY_PARCEL_SO_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.F_DELIVERY_PARCEL_SO_UK rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_4 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_6 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_5 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_1 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_2 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_3 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
alter index HERMES_MI_MART.FDPSO_SRVC_ID_7 rebuild partition F_DELIVERY_PARCEL_SO_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 14 out of 19');

-----------------------------------------------------------------------
-- TABLE: D_COURIER_RND_DETAILS
-----------------------------------------------------------------------
-- TABLE: D_COURIER_RND_DETAILS -- Size (MB): 9
-- Partially used blocks: 884
-- Percentage of highly fragmented blocks: 74.83%
-- Formatted Blocks: 1105
-- Full Blocks: 221 -- %Full Blocks: 20
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_COURIER_RND_DETAILS MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_COURIER_RND_DETAILS_PKI rebuild parallel  online;
exec dbms_output.put_line('Done 15 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_RTRN_VOL     PARTITION: F_PCLSHP_RTRN_VOL_201802
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_RTRN_VOL -- Size (MB): 8
-- Partially used blocks: 16
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 16
-- Full Blocks: 0 -- %Full Blocks: 0
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_RTRN_VOL MOVE partition F_PCLSHP_RTRN_VOL_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.XIF0FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF1FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF5FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF8FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF9FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF12FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF15FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF18FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF21FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF24FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF25FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF26FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF27FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF28FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF29FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF30FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF31FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF32FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF33FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XIF34FPSV rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
alter index HERMES_MI_MART.XPKFPSVI rebuild partition F_PCLSHP_RTRN_VOL_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 16 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_RTRN_INV     PARTITION: F_PCLSHP_RTRN_INV_201802
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_RTRN_INV -- Size (MB): 8
-- Partially used blocks: 30
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 30
-- Full Blocks: 0 -- %Full Blocks: 0
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_RTRN_INV MOVE partition F_PCLSHP_RTRN_INV_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.XPKFPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF3FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF4FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF0FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF1FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF2FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF5FPRI rebuild partition F_PCLSHP_RTRN_INV_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 17 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_C2B_INV     PARTITION: F_C2B_INV_201802
-----------------------------------------------------------------------
-- TABLE: F_C2B_INV -- Size (MB): 8
-- Partially used blocks: 45
-- Percentage of highly fragmented blocks: 98.89%
-- Formatted Blocks: 58
-- Full Blocks: 13 -- %Full Blocks: 22.41
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_C2B_INV MOVE partition F_C2B_INV_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.XPKFC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF2FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF5FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF10FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF13FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF14FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF18FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF27FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF28FC2B rebuild partition F_C2B_INV_201802 parallel  online;
alter index HERMES_MI_MART.XIF29FC2B rebuild partition F_C2B_INV_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 18 out of 19');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVRALL_SOS_B2C     PARTITION: F_PCLSHP_OVRALL_SOS_B2C_201802
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVRALL_SOS_B2C -- Size (MB): 8
-- Partially used blocks: 132
-- Percentage of highly fragmented blocks: 71.78%
-- Formatted Blocks: 249
-- Full Blocks: 117 -- %Full Blocks: 46.99
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C MOVE partition F_PCLSHP_OVRALL_SOS_B2C_201802 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FPO_FRST_UDLD_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_UDLD_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_IN_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_IN_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_IN_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_IN_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FST_CLT_ETRY_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_OUT_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_OUT_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FST_OUT_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LST_OUT_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_OUT_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_OUT_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_OUT_UDLD_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_OUT_UDLD_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_ETRY_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_ETRY_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_CUST_ATMPD_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_CUST_ATMPD_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_PIN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_PIN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_SIG_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_SIG_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_REP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_REP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLNATT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLNATT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_IN_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_IN_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_SEEN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_DRVR_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_DRVR_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_PCLSHP_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_PCLSHP_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_ETRY_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LST_ETRY_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_UDLD_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_UDLD_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_PSHP_MISS_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_PSHP_UNMFST_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_LAST_PSHP_UNMFST_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_DEL_ENTRY_DTE rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PADV_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_PSHP_MISS_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C_PKI rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPOSBIDX1 rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_SOS_DEL_ETRY_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_SOS_DEL_END_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_GEN_NTWK_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_GEN_HUB_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_GEN_DPOT_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCLSHP_RCPT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_MISSORT_BY_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_MISSORT_AT_DPOT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_DRVR_PCL_UNMFST_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCLSHP_PCL_UNMFST_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_MISSING_AT_DPOT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_MISSING_BY_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_MISSING_AT_PCLSHP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_PCLSHP_PADV_NOT_RCVD_I rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUT_DRVR_PADV_NOT_RCVD_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_FRAUD_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_CLT_REQ_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_SHOP_CLOSURE_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_DELETED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_ACTN_PCLSHP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_STOP_RTRN_ACTION_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCLSHP_UDLD_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_DRVR_UDLD_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCLSHP_REFUSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCLSHP_CLOSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_ROAD_CLOSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_BAD_WEATHER_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_VEHICLE_BREAKDOWN_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_DRVR_REFUSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_SHOP_HHT_ERROR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_ATMPD_DLY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_CUST_CLN_PIN_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_CUST_CLN_SIG_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_CUST_CLN_REP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_TYP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_CAR_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_DLY_MTHD rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_FRST_OUT_DPOT_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_DSGTD_DPOT rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_OUTLYING_AREA_CDE rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_PCL_CLT_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
alter index HERMES_MI_MART.FPO_DSGTD_CR_RND_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201802 parallel  online;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 19 out of 19');

-----------------------------------------------------------------------
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_PCLSHP_DPOT_SERVICE', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_DRVR_ETRY', partname => 'F_DRVR_ETRY_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLN_ENTRY', partname => 'A_CLN_ENTRY_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_NETWORK_ENTRY', partname => 'A_NETWORK_ENTRY_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_UPP_DEPOT_END_TO_END', partname => 'A_UPP_DEPOT_END_TO_END_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_CLT_INT', partname => 'F_CLT_INT_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'MV_A_OSOS_DPOT_ENTRY', partname => 'MV_A_OSOS_DPOT_ENTRY_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_C2C_C2B_SOS', partname => 'F_C2C_C2B_SOS_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_OVERALL_SOS', partname => 'F_PCLSHP_OVERALL_SOS_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_PREADV_ENTRY_AGG', partname => 'A_PREADV_ENTRY_AGG_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'MV_A_SOS_COURIER', partname => 'MV_A_SOS_COURIER_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_ETRY', partname => 'F_PCLSHP_ETRY_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'MV_A_CLN_ENTRY', partname => 'MV_A_CLN_ENTRY_201801', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_DELIVERY_PARCEL_SO', partname => 'F_DELIVERY_PARCEL_SO_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_COURIER_RND_DETAILS', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_RTRN_VOL', partname => 'F_PCLSHP_RTRN_VOL_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_RTRN_INV', partname => 'F_PCLSHP_RTRN_INV_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_C2B_INV', partname => 'F_C2B_INV_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_OVRALL_SOS_B2C', partname => 'F_PCLSHP_OVRALL_SOS_B2C_201802', granularity => 'PARTITION', cascade => true, degree => 2); end;
