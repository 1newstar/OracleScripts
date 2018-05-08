-- Total number of fragmented tables (i.e. full blocks % <= 50): 29
------------ List of Tables ------------
-- TABLE:      D_PCLSHP_DPOT_SERVICE             % Full Blocks:    8.33
-- TABLE:      A_NETWORK_ENTRY                   
-- PARTITION:  A_NETWORK_ENTRY_201603            % Full Blocks:   34.47
-- TABLE:      A_LAST_MANIFEST                   
-- PARTITION:  A_LAST_MANIFEST_201603            % Full Blocks:   45.21
-- TABLE:      A_COURIER_POSTCODE                
-- PARTITION:  A_COURIER_POSTCODE_201603         % Full Blocks:   39.23
-- TABLE:      A_SOS_AGGR                        
-- PARTITION:  A_SOS_AGGR_201603                 % Full Blocks:   46.03
-- TABLE:      F_C2C_C2B_SOS                     
-- PARTITION:  F_C2C_C2B_SOS_201603              % Full Blocks:   21.29
-- TABLE:      A_PREADV_ENTRY_AGG                
-- PARTITION:  A_PREADV_ENTRY_AGG_201603         % Full Blocks:   46.71
-- TABLE:      F_DRVR_ETRY                       
-- PARTITION:  F_DRVR_ETRY_201603                % Full Blocks:   32.99
-- TABLE:      F_PCLSHP_ETRY                     
-- PARTITION:  F_PCLSHP_ETRY_201603              % Full Blocks:   44.81
-- TABLE:      F_PCLSHP_OVRALL_SOS_B2C           
-- PARTITION:  F_PCLSHP_OVRALL_SOS_B2C_201603    % Full Blocks:   40.37
-- TABLE:      A_CLN_PCL_SOS                     
-- PARTITION:  A_CLN_PCL_SOS_201603              % Full Blocks:   48.15
-- TABLE:      A_OSOS_FIRST_CR_COLLECT           
-- PARTITION:  OSOS_FST_COU_COLL_201603          % Full Blocks:   47.09
-- TABLE:      A_COURIER_TO_UPP_DEPOT            
-- PARTITION:  A_COURIER_TO_UPP_DEPOT_201603     % Full Blocks:   36.08
-- TABLE:      A_CLN_PCL_HERMES_CR_ENTRY         
-- PARTITION:  A_CLN_PCL_HER_CR_ENTRY_201603     % Full Blocks:   47.02
-- TABLE:      A_CLN_PCL_RND_CR_ENTRY            
-- PARTITION:  A_CLN_PCL_RND_CR_ENTRY_201603     % Full Blocks:   47.10
-- TABLE:      S_PCL_PROG_NO_PCL                 % Full Blocks:   30.93
-- TABLE:      F_PCLSHP_DPOT_OUT_B2C             
-- PARTITION:  F_PCLSHP_DPOT_OUT_B2C_201603      % Full Blocks:   41.80
-- TABLE:      A_UPP_DEPOT_END_TO_END            
-- PARTITION:  A_UPP_DEPOT_END_TO_END_201603     % Full Blocks:   34.18
-- TABLE:      D_COURIER_RND_DETAILS             % Full Blocks:    7.92
-- TABLE:      F_PCLSHP_MISSING_B2C              
-- PARTITION:  F_PCLSHP_MISSING_B2C_201603       % Full Blocks:   44.11
-- TABLE:      D_TRACK_POINT                     % Full Blocks:    8.33
-- TABLE:      D_PARCELSHOP_HIERARCHY            % Full Blocks:   25.78
-- TABLE:      D_DEPOT_VAN_ROUND                 % Full Blocks:    8.33
-- TABLE:      A_CLT_INT_NTWRK                   
-- PARTITION:  A_CLT_INT_NTWRK_201603            % Full Blocks:   20.38
-- TABLE:      A_CLT_INT_PREADVICE               
-- PARTITION:  A_CLT_INT_PREADVICE_201603        % Full Blocks:   19.75
-- TABLE:      D_MANAGER                         % Full Blocks:    1.82
-- TABLE:      D_ALL_CLIENT_SO_COLLECTION_SLA    % Full Blocks:    2.56
-- TABLE:      D_ALL_ENQUIRY_SLA                 % Full Blocks:    1.82
-- TABLE:      A_BUSINESS_VOL_DAILY              
-- PARTITION:  A_BUSINESS_VOL_DAILY_201603       % Full Blocks:   32.08
-----------------------------------------------------------------------
set serverout on size unlimited
set feedback off

-----------------------------------------------------------------------
-- TABLE: D_PCLSHP_DPOT_SERVICE
-----------------------------------------------------------------------
-- TABLE: D_PCLSHP_DPOT_SERVICE -- Size (MB): 6401
-- Partially used blocks: 749808
-- Percentage of highly fragmented blocks: 99.94%
-- Formatted Blocks: 817979
-- Full Blocks: 68171 -- %Full Blocks: 8.33
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_IDX_1 rebuild parallel ;
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_PK rebuild parallel ;
alter index HERMES_MI_MART.D_PCLSHP_DPOT_SERVICE_IDX_RNG rebuild parallel 1;
exec dbms_output.put_line('Done 1 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_NETWORK_ENTRY     PARTITION: A_NETWORK_ENTRY_201603
-----------------------------------------------------------------------
-- TABLE: A_NETWORK_ENTRY -- Size (MB): 4555.5
-- Partially used blocks: 380813
-- Percentage of highly fragmented blocks: 90.59%
-- Formatted Blocks: 581168
-- Full Blocks: 200355 -- %Full Blocks: 34.47
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_NETWORK_ENTRY MOVE partition A_NETWORK_ENTRY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 2 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_LAST_MANIFEST     PARTITION: A_LAST_MANIFEST_201603
-----------------------------------------------------------------------
-- TABLE: A_LAST_MANIFEST -- Size (MB): 3738.38
-- Partially used blocks: 261017
-- Percentage of highly fragmented blocks: 93.65%
-- Formatted Blocks: 476416
-- Full Blocks: 215399 -- %Full Blocks: 45.21
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_LAST_MANIFEST MOVE partition A_LAST_MANIFEST_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 3 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_COURIER_POSTCODE     PARTITION: A_COURIER_POSTCODE_201603
-----------------------------------------------------------------------
-- TABLE: A_COURIER_POSTCODE -- Size (MB): 3712.06
-- Partially used blocks: 287780
-- Percentage of highly fragmented blocks: 92.62%
-- Formatted Blocks: 473566
-- Full Blocks: 185786 -- %Full Blocks: 39.23
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_COURIER_POSTCODE MOVE partition A_COURIER_POSTCODE_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 4 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_SOS_AGGR     PARTITION: A_SOS_AGGR_201603
-----------------------------------------------------------------------
-- TABLE: A_SOS_AGGR -- Size (MB): 3484.38
-- Partially used blocks: 239722
-- Percentage of highly fragmented blocks: 86.31%
-- Formatted Blocks: 444192
-- Full Blocks: 204470 -- %Full Blocks: 46.03
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_SOS_AGGR MOVE partition A_SOS_AGGR_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 5 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_C2C_C2B_SOS     PARTITION: F_C2C_C2B_SOS_201603
-----------------------------------------------------------------------
-- TABLE: F_C2C_C2B_SOS -- Size (MB): 2960.13
-- Partially used blocks: 297438
-- Percentage of highly fragmented blocks: 96.16%
-- Formatted Blocks: 377912
-- Full Blocks: 80474 -- %Full Blocks: 21.29
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_C2C_C2B_SOS MOVE partition F_C2C_C2B_SOS_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
alter index HERMES_MI_MART.FCCS_PCL_ID_I rebuild parallel 1;
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 6 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_PREADV_ENTRY_AGG     PARTITION: A_PREADV_ENTRY_AGG_201603
-----------------------------------------------------------------------
-- TABLE: A_PREADV_ENTRY_AGG -- Size (MB): 2624.44
-- Partially used blocks: 178292
-- Percentage of highly fragmented blocks: 82.56%
-- Formatted Blocks: 334562
-- Full Blocks: 156270 -- %Full Blocks: 46.71
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_PREADV_ENTRY_AGG MOVE partition A_PREADV_ENTRY_AGG_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 7 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_DRVR_ETRY     PARTITION: F_DRVR_ETRY_201603
-----------------------------------------------------------------------
-- TABLE: F_DRVR_ETRY -- Size (MB): 413.13
-- Partially used blocks: 35016
-- Percentage of highly fragmented blocks: 92.99%
-- Formatted Blocks: 52258
-- Full Blocks: 17242 -- %Full Blocks: 32.99
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_DRVR_ETRY MOVE partition F_DRVR_ETRY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 8 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_ETRY     PARTITION: F_PCLSHP_ETRY_201603
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_ETRY -- Size (MB): 266
-- Partially used blocks: 18632
-- Percentage of highly fragmented blocks: 84.77%
-- Formatted Blocks: 33760
-- Full Blocks: 15128 -- %Full Blocks: 44.81
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_ETRY MOVE partition F_PCLSHP_ETRY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 9 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVRALL_SOS_B2C     PARTITION: F_PCLSHP_OVRALL_SOS_B2C_201603
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_OVRALL_SOS_B2C -- Size (MB): 120
-- Partially used blocks: 8950
-- Percentage of highly fragmented blocks: 74%
-- Formatted Blocks: 15009
-- Full Blocks: 6059 -- %Full Blocks: 40.37
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C MOVE partition F_PCLSHP_OVRALL_SOS_B2C_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_REP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_CLT_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_MISSING_AT_DPOT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_MISSING_BY_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_PSHP_MISS_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_PCLSHP_PADV_NOT_RCVD_I rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_GEN_HUB_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_UDLD_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_PCLSHP_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_GEN_NTWK_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_IN_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_DRVR_PADV_NOT_RCVD_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_IN_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_IN_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_CUST_ATMPD_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_ACTN_PCLSHP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_CLT_REQ_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_ACTION_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCLSHP_UDLD_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCLSHP_CLOSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_DLY_MTHD rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_IN_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCLSHP_REFUSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_UDLD_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_IN_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_DRVR_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_OUT_DPOT_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_FRAUD_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_DRVR_UDLD_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_MISSORT_AT_DPOT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_PSHP_MISS_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCLSHP_RCPT_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PADV_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_VEHICLE_BREAKDOWN_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_BAD_WEATHER_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_SHOP_HHT_ERROR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_DRVR_REFUSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_CUST_CLN_PIN_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_CUST_CLN_REP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_CUST_CLN_SIG_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_TYP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_ROAD_CLOSED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUTLYING_AREA_CDE rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_PSHP_UNMFST_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_SEEN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_UDLD_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LST_ETRY_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_DRVR_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_UDLD_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_PIN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_ETRY_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_ETRY_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FST_CLT_ETRY_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FST_OUT_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_OUT_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_ETRY_PCLSHP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_ATMPD_DLY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_REP_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_OUT_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_GEN_DPOT_ETRY_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_SOS_DEL_ETRY_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_PIN_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLN_SIG_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_OUT_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_CUST_ATMPD_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_SOS_DEL_END_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPOSBIDX1 rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_CAR_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_PCLSHP_UNMFST_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLNATT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_CUST_CLNATT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_MISSORT_BY_DRVR_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_PSHP_UNMFST_PSHP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_OUT_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCLSHP_PCL_UNMFST_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_OUT_UDLD_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_DEL_ENTRY_DTE rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_OUT_MISSING_AT_PCLSHP_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_DSGTD_CR_RND_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_PCL_DSGTD_DPOT rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_CUST_CLN_SIG_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_SHOP_CLOSURE_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_STOP_RTRN_DELETED_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LST_OUT_DPOT_RCPT_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_LAST_OUT_UDLD_DRVR_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_DRVR_PCL_UNMFST_IND rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPO_FRST_IN_HUB_TP_ID rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
alter index HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C_PKI rebuild partition F_PCLSHP_OVRALL_SOS_B2C_201603 parallel ;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 10 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_SOS     PARTITION: A_CLN_PCL_SOS_201603
-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_SOS -- Size (MB): 40
-- Partially used blocks: 2157
-- Percentage of highly fragmented blocks: 50.95%
-- Formatted Blocks: 4160
-- Full Blocks: 2003 -- %Full Blocks: 48.15
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLN_PCL_SOS MOVE partition A_CLN_PCL_SOS_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 11 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_OSOS_FIRST_CR_COLLECT     PARTITION: OSOS_FST_COU_COLL_201603
-----------------------------------------------------------------------
-- TABLE: A_OSOS_FIRST_CR_COLLECT -- Size (MB): 33
-- Partially used blocks: 2109
-- Percentage of highly fragmented blocks: 51.17%
-- Formatted Blocks: 3986
-- Full Blocks: 1877 -- %Full Blocks: 47.09
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_OSOS_FIRST_CR_COLLECT MOVE partition OSOS_FST_COU_COLL_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 12 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_COURIER_TO_UPP_DEPOT     PARTITION: A_COURIER_TO_UPP_DEPOT_201603
-----------------------------------------------------------------------
-- TABLE: A_COURIER_TO_UPP_DEPOT -- Size (MB): 32
-- Partially used blocks: 2409
-- Percentage of highly fragmented blocks: 63.4%
-- Formatted Blocks: 3769
-- Full Blocks: 1360 -- %Full Blocks: 36.08
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_COURIER_TO_UPP_DEPOT MOVE partition A_COURIER_TO_UPP_DEPOT_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 13 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_HERMES_CR_ENTRY     PARTITION: A_CLN_PCL_HER_CR_ENTRY_201603
-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_HERMES_CR_ENTRY -- Size (MB): 32
-- Partially used blocks: 2083
-- Percentage of highly fragmented blocks: 51.32%
-- Formatted Blocks: 3932
-- Full Blocks: 1849 -- %Full Blocks: 47.02
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLN_PCL_HERMES_CR_ENTRY MOVE partition A_CLN_PCL_HER_CR_ENTRY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 14 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_RND_CR_ENTRY     PARTITION: A_CLN_PCL_RND_CR_ENTRY_201603
-----------------------------------------------------------------------
-- TABLE: A_CLN_PCL_RND_CR_ENTRY -- Size (MB): 32
-- Partially used blocks: 2100
-- Percentage of highly fragmented blocks: 51.2%
-- Formatted Blocks: 3970
-- Full Blocks: 1870 -- %Full Blocks: 47.1
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLN_PCL_RND_CR_ENTRY MOVE partition A_CLN_PCL_RND_CR_ENTRY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 15 out of 29');

-----------------------------------------------------------------------
-- TABLE: S_PCL_PROG_NO_PCL
-----------------------------------------------------------------------
-- TABLE: S_PCL_PROG_NO_PCL -- Size (MB): 32
-- Partially used blocks: 2744
-- Percentage of highly fragmented blocks: 98.85%
-- Formatted Blocks: 3973
-- Full Blocks: 1229 -- %Full Blocks: 30.93
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_STAGE.S_PCL_PROG_NO_PCL MOVE PARALLEL;
-- 
alter index HERMES_MI_STAGE.S_PCL_PROG_NO_PCL_PK rebuild parallel ;
alter index HERMES_MI_STAGE.SPPNP_PROC_BATCH_I rebuild parallel ;
exec dbms_output.put_line('Done 16 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_DPOT_OUT_B2C     PARTITION: F_PCLSHP_DPOT_OUT_B2C_201603
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_DPOT_OUT_B2C -- Size (MB): 24
-- Partially used blocks: 1345
-- Percentage of highly fragmented blocks: 61.13%
-- Formatted Blocks: 2311
-- Full Blocks: 966 -- %Full Blocks: 41.8
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_DPOT_OUT_B2C MOVE partition F_PCLSHP_DPOT_OUT_B2C_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FPD_PCLSHP_RCPT_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STOP_RTRN_CLT_REQ_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STP_RTN_ACN_PCLSHP_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_CUST_CLN_REP_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_DRVR_UDLD_ETRY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_MISSING_AT_DPOT_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_CAR_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PADV_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.F_PCLSHP_DPOT_OUT_B2C_PKI rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_GEN_DPOT_ETRY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.XIF1FPDOB rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_GEN_NTWK_ETRY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_LAST_OUT_DRVR_TRKG_PNT rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_LODR_TP_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_MISSORT_AT_DPOT_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_MISSORT_BY_DRVR_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUTLYING_AREA_CDE rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_DRVR_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_DRVR_PADVNOT_RCVD_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_MISSING_AT_PCLSHP_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_MISSING_BY_DRVR_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_OUT_PCLSHP_PADVNOT_RCVD_I rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCLSHP_CLOSED_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCLSHP_PCL_UNMFST_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCLSHP_REFUSED_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCLSHP_UDLD_ETRY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_CLT_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_DLY_MTHD rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_DSGTD_DPOT rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_FODCDTE rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_PCL_TYP_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_ROAD_CLOSED_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_GEN_HUB_ETRY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_SHOP_HHT_ERROR_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STOP_RTRN_ACTION_DRVR_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STOP_RTRN_DELETED_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STOP_RTRN_FRAUD_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_STOP_RTRN_SHOP_CLOSURE_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_VEHICLE_BREAKDOWN_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_ATMPD_DLY_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_BAD_WEATHER_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_CUST_CLN_PIN_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_CUST_CLN_SIG_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_DRVR_PCL_UNMFST_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_DRVR_REFUSED_IND rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_FODR_TP_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_FRST_OUT_DPOT_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_DSGTD_CR_RND_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_FRST_OUT_DRVR_TRKG_PNT rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPD_LAST_SEEN_TRKG_PNT_ID rebuild partition F_PCLSHP_DPOT_OUT_B2C_201603 parallel ;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 17 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_UPP_DEPOT_END_TO_END     PARTITION: A_UPP_DEPOT_END_TO_END_201603
-----------------------------------------------------------------------
-- TABLE: A_UPP_DEPOT_END_TO_END -- Size (MB): 24
-- Partially used blocks: 1668
-- Percentage of highly fragmented blocks: 62.72%
-- Formatted Blocks: 2534
-- Full Blocks: 866 -- %Full Blocks: 34.18
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_UPP_DEPOT_END_TO_END MOVE partition A_UPP_DEPOT_END_TO_END_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 18 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_COURIER_RND_DETAILS
-----------------------------------------------------------------------
-- TABLE: D_COURIER_RND_DETAILS -- Size (MB): 9
-- Partially used blocks: 977
-- Percentage of highly fragmented blocks: 75.23%
-- Formatted Blocks: 1061
-- Full Blocks: 84 -- %Full Blocks: 7.92
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_COURIER_RND_DETAILS MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_COURIER_RND_DETAILS_PKI rebuild parallel ;
exec dbms_output.put_line('Done 19 out of 29');

-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_MISSING_B2C     PARTITION: F_PCLSHP_MISSING_B2C_201603
-----------------------------------------------------------------------
-- TABLE: F_PCLSHP_MISSING_B2C -- Size (MB): 8
-- Partially used blocks: 147
-- Percentage of highly fragmented blocks: 54.25%
-- Formatted Blocks: 263
-- Full Blocks: 116 -- %Full Blocks: 44.11
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.F_PCLSHP_MISSING_B2C MOVE partition F_PCLSHP_MISSING_B2C_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
alter index HERMES_MI_MART.FPM_FST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_SHOP_HHT_ERROR_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_GEN_HUB_ETRY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_GEN_NTWK_ETRY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_DRVR_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_VEHICLE_BREAKDOWN_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCLSHP_UDLD_ETRY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_CUST_CLN_PIN_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_TYP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_ROAD_CLOSED_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_DSGTD_DPOT rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_DRVR_UDLD_ETRY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_PCLSHP_PADV_NOT_RCVD_I rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_BAD_WEATHER_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_CUST_CLN_SIG_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_CAR_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_MISSING_AT_PCLSHP_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_SHOP_CLOSURE_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCLSHP_CLOSED_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_MISSING_AT_DPOT_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_GEN_DPOT_ETRY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_MISSORT_AT_DPOT_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_LST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_LAST_SEEN_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_LST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_FST_DPOT_MISS_PCL_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_ID_HRM_DT rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_CLT_REQ_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_DELETED_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.XIF1FPMB rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_DSGTD_CR_RND_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_DSGTD_PCLSHP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_MISSORT_BY_DRVR_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUTLYING_AREA_CDE rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.F_PCLSHP_MISSING_B2C_PKI rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCLSHP_REFUSED_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_CUST_CLN_REP_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PADV_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_ATMPD_DLY_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_DRVR_REFUSED_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_DRVR_PADV_NOT_RCVD_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_OUT_MISSING_BY_DRVR_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_DRVR_PCL_UNMFST_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCLSHP_PCL_UNMFST_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCLSHP_RCPT_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_ACTN_PCLSHP_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_ACTION_DRVR_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_LST_PCLSHP_MISS_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_FPST_DRVR_MISS_TP_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_STOP_RTRN_FRAUD_IND rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_CLT_ID rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
alter index HERMES_MI_MART.FPM_PCL_DLY_MTHD rebuild partition F_PCLSHP_MISSING_B2C_201603 parallel ;
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 20 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_TRACK_POINT
-----------------------------------------------------------------------
-- TABLE: D_TRACK_POINT -- Size (MB): 5
-- Partially used blocks: 517
-- Percentage of highly fragmented blocks: 71.81%
-- Formatted Blocks: 564
-- Full Blocks: 47 -- %Full Blocks: 8.33
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_TRACK_POINT MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_TRACK_POINT_I3 rebuild parallel ;
alter index HERMES_MI_MART.D_TRACK_POINT_PK rebuild parallel ;
alter index HERMES_MI_MART.D_TRACK_POINT_I1 rebuild parallel ;
exec dbms_output.put_line('Done 21 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_PARCELSHOP_HIERARCHY
-----------------------------------------------------------------------
-- TABLE: D_PARCELSHOP_HIERARCHY -- Size (MB): 5
-- Partially used blocks: 95
-- Percentage of highly fragmented blocks: 76.05%
-- Formatted Blocks: 128
-- Full Blocks: 33 -- %Full Blocks: 25.78
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_PARCELSHOP_HIERARCHY MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.DPSHFK1 rebuild parallel ;
alter index HERMES_MI_MART.DPSHFK3 rebuild parallel ;
alter index HERMES_MI_MART.DPSHFK2 rebuild parallel ;
alter index HERMES_MI_MART.DPSHPKI rebuild parallel ;
alter index HERMES_MI_MART.DPH_PCLSHP_TYP rebuild parallel ;
exec dbms_output.put_line('Done 22 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_DEPOT_VAN_ROUND
-----------------------------------------------------------------------
-- TABLE: D_DEPOT_VAN_ROUND -- Size (MB): 5
-- Partially used blocks: 572
-- Percentage of highly fragmented blocks: 93.23%
-- Formatted Blocks: 624
-- Full Blocks: 52 -- %Full Blocks: 8.33
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_DEPOT_VAN_ROUND MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_DEPOT_VAN_ROUND_PK rebuild parallel ;
exec dbms_output.put_line('Done 23 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_CLT_INT_NTWRK     PARTITION: A_CLT_INT_NTWRK_201603
-----------------------------------------------------------------------
-- TABLE: A_CLT_INT_NTWRK -- Size (MB): 4.13
-- Partially used blocks: 125
-- Percentage of highly fragmented blocks: 95.2%
-- Formatted Blocks: 157
-- Full Blocks: 32 -- %Full Blocks: 20.38
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLT_INT_NTWRK MOVE partition A_CLT_INT_NTWRK_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 24 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_CLT_INT_PREADVICE     PARTITION: A_CLT_INT_PREADVICE_201603
-----------------------------------------------------------------------
-- TABLE: A_CLT_INT_PREADVICE -- Size (MB): 4.13
-- Partially used blocks: 126
-- Percentage of highly fragmented blocks: 95.83%
-- Formatted Blocks: 157
-- Full Blocks: 31 -- %Full Blocks: 19.75
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_CLT_INT_PREADVICE MOVE partition A_CLT_INT_PREADVICE_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 25 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_MANAGER
-----------------------------------------------------------------------
-- TABLE: D_MANAGER -- Size (MB): 4
-- Partially used blocks: 432
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 440
-- Full Blocks: 8 -- %Full Blocks: 1.82
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_MANAGER MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_MANAGER_PK rebuild parallel ;
exec dbms_output.put_line('Done 26 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_ALL_CLIENT_SO_COLLECTION_SLA
-----------------------------------------------------------------------
-- TABLE: D_ALL_CLIENT_SO_COLLECTION_SLA -- Size (MB): 4
-- Partially used blocks: 456
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 468
-- Full Blocks: 12 -- %Full Blocks: 2.56
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_ALL_CLIENT_SO_COLLECTION_SLA MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.D_ALL_CLIENT_SO_CLN_SLA_PK rebuild parallel ;
exec dbms_output.put_line('Done 27 out of 29');

-----------------------------------------------------------------------
-- TABLE: D_ALL_ENQUIRY_SLA
-----------------------------------------------------------------------
-- TABLE: D_ALL_ENQUIRY_SLA -- Size (MB): 4
-- Partially used blocks: 432
-- Percentage of highly fragmented blocks: 78.13%
-- Formatted Blocks: 440
-- Full Blocks: 8 -- %Full Blocks: 1.82
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.D_ALL_ENQUIRY_SLA MOVE PARALLEL;
-- 
alter index HERMES_MI_MART.ALL_ENQUIRY_SLA_PK rebuild parallel ;
exec dbms_output.put_line('Done 28 out of 29');

-----------------------------------------------------------------------
-- TABLE: A_BUSINESS_VOL_DAILY     PARTITION: A_BUSINESS_VOL_DAILY_201603
-----------------------------------------------------------------------
-- TABLE: A_BUSINESS_VOL_DAILY -- Size (MB): 3.38
-- Partially used blocks: 108
-- Percentage of highly fragmented blocks: 100%
-- Formatted Blocks: 159
-- Full Blocks: 51 -- %Full Blocks: 32.08
-----------------------------------------------------------------------
ALTER TABLE HERMES_MI_MART.A_BUSINESS_VOL_DAILY MOVE partition A_BUSINESS_VOL_DAILY_201603 PARALLEL;
-- 
-----------------------------------------------------------------------
-- Partitioned Indexes.
-----------------------------------------------------------------------
-- Global Indexes.
-----------------------------------------------------------------------
exec dbms_output.put_line('Done 29 out of 29');

-----------------------------------------------------------------------
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_PCLSHP_DPOT_SERVICE', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_NETWORK_ENTRY', partname => 'A_NETWORK_ENTRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_LAST_MANIFEST', partname => 'A_LAST_MANIFEST_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_COURIER_POSTCODE', partname => 'A_COURIER_POSTCODE_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_SOS_AGGR', partname => 'A_SOS_AGGR_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_C2C_C2B_SOS', partname => 'F_C2C_C2B_SOS_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_PREADV_ENTRY_AGG', partname => 'A_PREADV_ENTRY_AGG_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_DRVR_ETRY', partname => 'F_DRVR_ETRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_ETRY', partname => 'F_PCLSHP_ETRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_OVRALL_SOS_B2C', partname => 'F_PCLSHP_OVRALL_SOS_B2C_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLN_PCL_SOS', partname => 'A_CLN_PCL_SOS_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_OSOS_FIRST_CR_COLLECT', partname => 'OSOS_FST_COU_COLL_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_COURIER_TO_UPP_DEPOT', partname => 'A_COURIER_TO_UPP_DEPOT_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLN_PCL_HERMES_CR_ENTRY', partname => 'A_CLN_PCL_HER_CR_ENTRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLN_PCL_RND_CR_ENTRY', partname => 'A_CLN_PCL_RND_CR_ENTRY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_STAGE', tabname => 'S_PCL_PROG_NO_PCL', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_DPOT_OUT_B2C', partname => 'F_PCLSHP_DPOT_OUT_B2C_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_UPP_DEPOT_END_TO_END', partname => 'A_UPP_DEPOT_END_TO_END_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_COURIER_RND_DETAILS', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'F_PCLSHP_MISSING_B2C', partname => 'F_PCLSHP_MISSING_B2C_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_TRACK_POINT', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_PARCELSHOP_HIERARCHY', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_DEPOT_VAN_ROUND', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLT_INT_NTWRK', partname => 'A_CLT_INT_NTWRK_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_CLT_INT_PREADVICE', partname => 'A_CLT_INT_PREADVICE_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_MANAGER', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_ALL_CLIENT_SO_COLLECTION_SLA', cascade => true, degree => 2); end;
-- LOCKED STATS begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'D_ALL_ENQUIRY_SLA', cascade => true, degree => 2); end;
begin dbms_stats.gather_table_stats(ownname => 'HERMES_MI_MART', tabname => 'A_BUSINESS_VOL_DAILY', partname => 'A_BUSINESS_VOL_DAILY_201603', granularity => 'PARTITION', cascade => true, degree => 2); end;
