=====================================
MISD Courier Parcel Events - Problems
=====================================

Introduction
============

This job is now taking over one hours to process and as it runs every hour, it is overlapping itself and causing other scheduling problems.

The job is effectively a single INSERT - see `Appendix A <#appendix-a---the-problem-sql-statement>`_ for details - however, it does spend a lot of time logging numerous errors etc, as well as other recursive SQL statements. The job also suffers from Parallel Query downgrading where the requested 32 parallel slaves are being started, then converted to a single sequential query instead. No reason is given in the 'other' column of the execution plan as to why the downgrade took place.

Tracing
=======

James enabled a trace of the INSERT statement's execution (1.1 billion lines in the trace file) and from that we can see a number of error records are being logged to the error table, as well as the various waits for the INSERT statement itself.


WAITS
=====

The following are the various wait events encountered by the INSERT, without considering any recursive statements.

+--------------------------------------------------+---------------------+
| WAITS (for the actual INSERT Statement)          |  uSeconds           |
+==================================================+=====================+
| Disk file operations I/O                         |       128           |
+--------------------------------------------------+---------------------+
| PX Deq: Execute Reply                            |    778,439          |
+--------------------------------------------------+---------------------+
| PX Deq: Join ACK                                 |       883           |
+--------------------------------------------------+---------------------+
| PX Deq: Parse Reply                              |     14,102          |
+--------------------------------------------------+---------------------+
| PX Deq: Signal ACK EXT                           |     31,474          |
+--------------------------------------------------+---------------------+
| PX Deq: Slave Session Stats                      |      1,764          |
+--------------------------------------------------+---------------------+
| SQL*Net message from client                      |    218,460          |
+--------------------------------------------------+---------------------+
| SQL*Net message to client                        |         2           |
+--------------------------------------------------+---------------------+
| buffer busy waits                                |         3           |
+--------------------------------------------------+---------------------+
| db file sequential read                          | 850,498,973         |
+--------------------------------------------------+---------------------+
| enq: KO - fast object checkpoint                 |     61,493          |
+--------------------------------------------------+---------------------+
| latch free                                       |     13,062          |
+--------------------------------------------------+---------------------+
| latch: cache buffers chains                      |       728           |
+--------------------------------------------------+---------------------+
| latch: redo allocation                           |       326           |
+--------------------------------------------------+---------------------+
| log file switch (checkpoint incomplete)          |    847,895          |
+--------------------------------------------------+---------------------+
| log file switch (private strand flush incomplete)|    212,334          |
+--------------------------------------------------+---------------------+
| log file switch completion                       |    356,854          |
+--------------------------------------------------+---------------------+
| log file sync                                    |      3,444          |
+--------------------------------------------------+---------------------+
| log file sync: SCN ordering                      |      2,025          |
+--------------------------------------------------+---------------------+
| reliable message                                 |        90           |
+--------------------------------------------------+---------------------+
| resmgr:pq queued                                 |        65           |
+--------------------------------------------------+---------------------+
| **TOTAL  (INSERT ONLY)**                         | 853,040,519         |
+--------------------------------------------------+---------------------+

The following is a summary of all wait events in the trace file, this includes the above, plus all recursive SQL statements:

+--------------------------------------------------+---------------------+
| Total Waits in Trace File (ALL)                  | 994,683,679         |
+--------------------------------------------------+---------------------+
| Difference   (ERROR + RECURSIVE)                 | 141,643,160         |
+--------------------------------------------------+---------------------+

Finally, the trace file cover's the following times - these are in microseconds from 'a suitable epoch', which differs according to the operating system in use at the time. 

+--------------------------------------------------+---------------------+
| Start 'tim'                                      | 140,042,318,785,913 |
+--------------------------------------------------+---------------------+
| End 'tim'                                        | 140,045,744,608,916 |
+--------------------------------------------------+---------------------+
| Duration (uSeconds)                              | 3,425,823,003       |
+--------------------------------------------------+---------------------+

Execution Summary
=================

The above gives us the following summary of the entire trace file:

+----------------------+---------+----------+
| Description          | Seconds | hh:mm:ss |
+======================+=========+==========+
| Total Duration       | 3,425.8 | 00:57:05 |
+----------------------+---------+----------+
| Wait Time            | 994.7   | 00:16:34 |
+----------------------+---------+----------+
| Of which, recursive  | 141.6   | 00:02:21 |
+----------------------+---------+----------+
| CPU Time             | 2,431.1 | 00:40:31 |
+----------------------+---------+----------+


From this we can see that the vast majority of the run time is burning CPU - this is done when filtering rows from scans, comparing columns with desired values, decompressing data to be able to do the above (the data in the table are compressed) and so on.


    

Appendix A - The Problem SQL Statement
======================================

Somewhat tidied up from that as generated by BO.

..  code-block:: sql

    INSERT /*+ FULL PARALLEL (HEDW_STG_COURIER_PROG 32) */ 
    INTO hedw_edw.courier_parcel_events (
        tmestp, locn_typ, locn_cde, addl_info, pcl_cre_tmestp, 
        clng_card_ref, crrd_fwd_to_dte,
        db_row_tmestp, ffm_txt, gps_lgtde, gps_lttde, 
        hht_evt_tmestp, if_tmestp, mfst_itm_id,
        mfst_nbr, mfst_pg_nbr, mfst_sctn_id, pcl_addr_ln_1, 
        pcl_addr_ln_2, pcl_addr_ln_3,
        pcl_addr_ln_4, pcl_addr_ln_5, pcl_addr_ln_6, pcl_nme, 
        pcl_pstcde, sgtry_addr_ln_1,
        sgtry_addr_ln_2, sgtry_addr_ln_3, sgtry_addr_ln_4, 
        sgtry_addr_ln_5, sgtry_addr_ln_6,
        sgtry_nme, sgtry_pstcde, gps_durn, 
        tracking_points_trkg_pnt_id, md_load_date,
        couriers_cr_id, parcels_pcl_id, inst_upd_seq, hub_id, 
        dpot_id, hermes_wrt_tmestp, edw_ins_upd_seq
    )
        SELECT
            tmestp, locn_typ, locn_cde, addl_info, pcl_cre_tmestp, 
            clng_card_ref, crrd_fwd_to_dte,
            db_row_tmestp, ffm_txt, gps_lgtde, gps_lttde, 
            hht_evt_tmestp, if_tmestp, mfst_itm_id,
            mfst_nbr, mfst_pg_nbr, mfst_sctn_id, pcl_addr_ln_1, 
            pcl_addr_ln_2, pcl_addr_ln_3,
            pcl_addr_ln_4, pcl_addr_ln_5, pcl_addr_ln_6, pcl_nme, 
            pcl_pstcde, sgtry_addr_ln_1,
            sgtry_addr_ln_2, sgtry_addr_ln_3, sgtry_addr_ln_4, 
            sgtry_addr_ln_5, sgtry_addr_ln_6,
            sgtry_nme, sgtry_pstcde, gps_durn, 
            tracking_points_trkg_pnt_id, md_load_date,
            couriers_cr_id, parcels_pcl_id, inst_upd_seq, hub_id, 
            dpot_id, hermes_wrt_tmestp,
            hedw_edw.seq_edw_pte_ins_upd.nextval
        FROM
            (
                SELECT
                    hedw_stg_courier_prog.tmestp tmestp, 
                    hedw_stg_courier_prog.locn_typ locn_typ,
                    hedw_stg_courier_prog.locn_cde locn_cde, 
                    hedw_stg_courier_prog.addl_info addl_info,
                    hedw_stg_courier_prog.pcl_cre_tmestp pcl_cre_tmestp, 
                    hedw_stg_courier_prog.clng_card_ref clng_card_ref,
                    hedw_stg_courier_prog.crrd_fwd_to_dte crrd_fwd_to_dte, 
                    hedw_stg_courier_prog.db_row_tmestp db_row_tmestp,
                    hedw_stg_courier_prog.ffm_txt ffm_txt, 
                    hedw_stg_courier_prog.gps_lgtde gps_lgtde,
                    hedw_stg_courier_prog.gps_lttde gps_lttde,
                    ( nvl(hedw_stg_courier_prog.hht_evt_tmestp, 
                          hedw_stg_courier_prog.tmestp) ) hht_evt_tmestp,
                    hedw_stg_courier_prog.if_tmestp if_tmestp, 
                    hedw_stg_courier_prog.mfst_itm_id mfst_itm_id,
                    hedw_stg_courier_prog.mfst_nbr mfst_nbr, 
                    hedw_stg_courier_prog.mfst_pg_nbr mfst_pg_nbr,
                    hedw_stg_courier_prog.mfst_sctn_id mfst_sctn_id, 
                    hedw_stg_courier_prog.pcl_addr_ln_1 pcl_addr_ln_1,
                    hedw_stg_courier_prog.pcl_addr_ln_2 pcl_addr_ln_2, 
                    hedw_stg_courier_prog.pcl_addr_ln_3 pcl_addr_ln_3,
                    hedw_stg_courier_prog.pcl_addr_ln_4 pcl_addr_ln_4, 
                    hedw_stg_courier_prog.pcl_addr_ln_5 pcl_addr_ln_5,
                    hedw_stg_courier_prog.pcl_addr_ln_6 pcl_addr_ln_6, 
                    hedw_stg_courier_prog.pcl_nme pcl_nme,
                    hedw_stg_courier_prog.pcl_pstcde pcl_pstcde, 
                    hedw_stg_courier_prog.sgtry_addr_ln_1 sgtry_addr_ln_1,
                    hedw_stg_courier_prog.sgtry_addr_ln_2 sgtry_addr_ln_2, 
                    hedw_stg_courier_prog.sgtry_addr_ln_3 sgtry_addr_ln_3,
                    hedw_stg_courier_prog.sgtry_addr_ln_4 sgtry_addr_ln_4, 
                    hedw_stg_courier_prog.sgtry_addr_ln_5 sgtry_addr_ln_5,
                    hedw_stg_courier_prog.sgtry_addr_ln_6 sgtry_addr_ln_6, 
                    hedw_stg_courier_prog.sgtry_nme sgtry_nme,
                    hedw_stg_courier_prog.sgtry_pstcde sgtry_pstcde, 
                    hedw_stg_courier_prog.gps_durn gps_durn,
                    hedw_stg_courier_prog.trkg_pnt_id tracking_points_trkg_pnt_id,
                    SYSDATE md_load_date,
                    nvl( ( (
                        SELECT
                            couriers.cr_id cr_id
                        FROM (
                            SELECT couriers.cr_id cr_id, 
                            -- EVERYTHING FROM THE COURIERS TABLE GOES HERE!
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
                        FROM (
                            SELECT hub.hub_id hub_id, 
                            -- EVERYTHING FROM THE HUB TABLE GOES HERE!
                            FROM
                               hedw_edw.hub hub
                            ) hub
                        WHERE (
                            hedw_stg_courier_prog.locn_typ = 'HUB'
                            AND   hedw_stg_courier_prog.locn_cde = hub.hub_id
                        ) AND   (ROWNUM = 1)
                    ) ),'XX') hub_id,
                    nvl( ( (
                        SELECT
                            depot.dpot_id dpot_id
                        FROM (
                            SELECT depot.dpot_id dpot_id, 
                            -- EVERYTHING FROM THE DEPOT TABLE GOES HERE!
                            FROM
                               hedw_edw.depot depot
                            ) depot
                        WHERE (
                            hedw_stg_courier_prog.locn_typ = 'DEP'
                        AND hedw_stg_courier_prog.locn_cde = depot.dpot_id
                        ) AND (ROWNUM = 1)
                    ) ),'XX') dpot_id,
                    hedw_stg_courier_prog.hermes_wrt_tmestp hermes_wrt_tmestp
                FROM
                    hedw_stage.hedw_stg_courier_prog hedw_stg_courier_prog
                WHERE
                    ( 1 = 1 )
                    AND ((
                      hedw_stg_courier_prog.locn_typ = 'COU'
                      AND hedw_stg_courier_prog.inst_upd_seq > 11647306184
                      AND hedw_stg_courier_prog.md_load_date > SYSDATE - 10
                    ) OR (
                      hedw_stg_courier_prog.locn_typ = 'COU'
                      AND hedw_stg_courier_prog.md_load_status = 2
                      AND hedw_stg_courier_prog.md_load_date > SYSDATE - 10
                    ))
            )
        LOG ERRORS INTO hedw_edw.err$_courier_parcel_events 
        REJECT LIMIT UNLIMITED;
        
Appendix B - Execution Plan
===========================

The following shows the execution plan, as extracted from the trace file. This shows what Oracle actually *did* do, as opposed to what an Explain Plan says that it *might* do.  
    
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
| ID    | ROWS      | PARENT | POS   | OBJ_ID  | OPERATION               | OBJECT                                       | COSTS Etc                                                   |
+=======+===========+========+=======+=========+=========================+==============================================+=============================================================+
|    1  | 0         |     0  |  1    | 0       | LOAD TABLE CONVENTIONAL | COURIER_PARCEL_EVENTS                        | cr=2721848 pr=110020 pw=0 time=3280921044                   |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    2  | 723,036   |     1  |  2    | 0       | COUNT STOPKEY           |                                              | cr=1690108 pr=380 pw=0 time=21757287                        |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    3  | 723,036   |     2  |  1    | 106,894 | INDEX UNIQUE SCAN       | COURIERS_PK                                  | cr=1690108 pr=380 pw=0 time=19910077 cost=1 size=7 card=1   |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    4  | 0         |     1  |  3    | 0       | COUNT STOPKEY           |                                              | cr=0 pr=0 pw=0 time=9                                       |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    5  | 0         |     4  |  1    | 0       | FILTER                  |                                              | cr=0 pr=0 pw=0 time=2                                       |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    6  | 0         |     5  |  1    | 107,100 | INDEX UNIQUE SCAN       | HUB_PK                                       | cr=0 pr=0 pw=0 time=0 cost=0 size=3 card=1                  |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    7  | 0         |     1  |  4    | 0       | COUNT STOPKEY           |                                              | cr=0 pr=0 pw=0 time=3                                       |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    8  | 0         |     7  |  1    | 0       | FILTER                  |                                              | cr=0 pr=0 pw=0 time=1                                       |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    9  | 0         |     8  |  1    | 107,098 | INDEX UNIQUE SCAN       | DEPOT_PK                                     | cr=0 pr=0 pw=0 time=0 cost=0 size=3 card=1                  |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    10 | 1,595,215 |     1  |  1    | 136,114 | SEQUENCE                | SEQ_EDW_PTE_INS_UPD                          | cr=15963 pr=1 pw=0 time=26922240                            |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    11 | 1,595,215 |     10 |  1    | 0       | PX COORDINATOR          |                                              | cr=10 pr=0 pw=0 time=13201156                               |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    12 | 0         |     11 |  1    | 0       | PX SEND QC (RANDOM)     | :TQ10000                                     | cr=0 pr=0 pw=0 time=0 cost=18363 size=207594816 card=998052 |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    13 | 0         |     12 |  1    | 0       | PX BLOCK ITERATOR       | PARTITION: KEY 1048575                       | cr=0 pr=0 pw=0 time=0 cost=18363 size=207594816 card=998052 |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
|    14 | 0         |     13 |  1    | 106,413 | TABLE ACCESS FULL       | HEDW_STG_COURIER_PROG PARTITION: KEY 1048575 | cr=0 pr=0 pw=0 time=0 cost=18363 size=207594816 card=998052 |
+-------+-----------+--------+-------+---------+-------------------------+----------------------------------------------+-------------------------------------------------------------+
