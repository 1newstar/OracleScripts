set lines 2000 pages 2000 trimspool on
set define off

spool materialised_views.lst


DROP MATERIALIZED VIEW LOG ON FCS.INVESTOR;
DROP snapshot LOG ON FCS.INVESTOR;

DROP MATERIALIZED VIEW FCS.INVESTOR_CAT_MV;
DROP TABLE FCS.INVESTOR_CAT_MV cascade constraints;


CREATE MATERIALIZED VIEW LOG ON FCS.INVESTOR
TABLESPACE UVDATA01
PCTUSED    0
PCTFREE    60
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOCACHE
LOGGING
NOPARALLEL
WITH ROWID, PRIMARY KEY
EXCLUDING NEW VALUES;



CREATE MATERIALIZED VIEW FCS.INVESTOR_CAT_MV 
TABLESPACE UVDATA01
PCTUSED    0
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOCACHE
LOGGING
NOPARALLEL
BUILD IMMEDIATE
USING INDEX
            TABLESPACE CFA
            PCTFREE    10
            INITRANS   2
            MAXTRANS   255
            STORAGE    (
                        INITIAL          1M
                        MINEXTENTS       1
                        MAXEXTENTS       UNLIMITED
                        PCTINCREASE      0
                        BUFFER_POOL      DEFAULT
                       )
REFRESH FAST ON COMMIT
WITH PRIMARY KEY
ENABLE QUERY REWRITE
AS 
/* Formatted on 2017/01/27 13:27:12 (QP5 v5.256.13226.35538) */
SELECT /*+APPEND*/
      invcode,
       /*
       Precedence is
       1; Deceased  (deceased = Y)
       2. Gone Away (GoneAwqy = Y)
       3. Overseas  (UK res = N)
       4. Nominee   (Nominee ID > 0)
       5. UK
       */
       CASE
          WHEN NVL (i.deceased, 'N') = 'Y'
          THEN
             'DC'
          WHEN NVL (i.goneaway, 'N') = 'Y'
          THEN
             'GA'
          WHEN ( (f_is_uk_postage (i.corri,
                                   i.lpcode,
                                   i.rpcode,
                                   'N')) = 'N')
          THEN
             'OS'
          WHEN NVL (i.nomineeid, 0) <> 0
          THEN
             'NM'
          -- Skip "CO" Care Off stuff cos it points to Huddersfield
          --         WHEN (    NVL (corri, 'N') = 'Y'
          --              AND UPPER (ladl1 || ladl2 || ladl3 || ladl4 || ladl5 || lpcode) LIKE '%HOUSE%'
          --             AND UPPER (ladl1 || ladl2 || ladl3 || ladl4 || ladl5 || lpcode) LIKE '%NORTHERN%'
          --            AND UPPER (ladl1 || ladl2 || ladl3 || ladl4 || ladl5 || lpcode) LIKE '%HD8%')
          --          OR (    NVL (corri, 'N') = 'N'
          --             AND UPPER (radl1 || radl2 || radl3 || radl4 || radl5 || rpcode) LIKE '%HOUSE%'
          --            AND UPPER (radl1 || radl2 || radl3 || radl4 || radl5 || rpcode) LIKE '%NORTHERN%'
          --           AND UPPER (radl1 || radl2 || radl3 || radl4 || radl5 || rpcode) LIKE '%HD8%') THEN
          --    'CO'
          ELSE
             'UK'
       END
          CATEGORY,
       -- Set a DO_NOT_USE flag. (First char of full name has a Full Stop)
       CASE WHEN ifname LIKE '.%' THEN 'Y' ELSE 'N' END DO_NOT_USE
  FROM investor i;


COMMENT ON TABLE FCS.INVESTOR_CAT_MV IS 'snapshot table for snapshot FCS.INVESTOR_CAT_MV';

CREATE OR REPLACE PUBLIC SYNONYM INVESTOR_CAT_MV FOR FCS.INVESTOR_CAT_MV;



CREATE UNIQUE INDEX FCS.INVCODE_PK1 ON FCS.INVESTOR_CAT_MV
(INVCODE)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.INVESTOR_CAT_MV_IX01 ON FCS.INVESTOR_CAT_MV
(INVCODE, CATEGORY, DO_NOT_USE)
LOGGING
TABLESPACE UVDATA01_INDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.INVESTOR_CAT_MV_IX02 ON FCS.INVESTOR_CAT_MV
(DO_NOT_USE, CATEGORY, INVCODE)
LOGGING
TABLESPACE UVDATA01_INDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.INVESTOR_CAT_MV_IX03 ON FCS.INVESTOR_CAT_MV
(CATEGORY, DO_NOT_USE, INVCODE)
LOGGING
TABLESPACE UVDATA01_INDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

GRANT DELETE, INSERT, SELECT, UPDATE ON FCS.INVESTOR_CAT_MV TO DATA_UPDATE_ONLY;

GRANT DELETE, INSERT, SELECT, UPDATE ON FCS.INVESTOR_CAT_MV TO NORMAL_USER_NON_CONFIG;





DROP MATERIALIZED VIEW FCS.ORDTRAN_MV;
DROP MATERIALIZED VIEW LOG ON FCS.ORDTRAN;
DROP snapshot LOG ON FCS.ORDTRAN;

DROP table FCS.ORDTRAN_MV cascade constraints;

CREATE MATERIALIZED VIEW LOG ON FCS.ORDTRAN
TABLESPACE CFA
PCTUSED    0
PCTFREE    60
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOCACHE
LOGGING
NOPARALLEL
WITH ROWID, PRIMARY KEY
EXCLUDING NEW VALUES;


CREATE MATERIALIZED VIEW FCS.ORDTRAN_MV 
TABLESPACE CFA
PCTUSED    0
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOCACHE
LOGGING
NOPARALLEL
BUILD IMMEDIATE
USING INDEX
            TABLESPACE CFA
            PCTFREE    10
            INITRANS   2
            MAXTRANS   255
            STORAGE    (
                        INITIAL          64K
                        MINEXTENTS       1
                        MAXEXTENTS       UNLIMITED
                        PCTINCREASE      0
                        BUFFER_POOL      DEFAULT
                       )
REFRESH FAST ON COMMIT
WITH PRIMARY KEY
ENABLE QUERY REWRITE
AS 
/* Formatted on 2017/01/27 13:30:32 (QP5 v5.256.13226.35538) */
SELECT /*+APPEND*/
      o.orduid,
       o.invcode,
       o.trstcode,
       o.unittype,
       NVL (SUBSTR (o.transfer, 1, 1), 'N') product,
       o.issrep,
       NVL (o.quantity, 0.00) quantity,
       NVL (o.amtdue, 0.00) amtdue,
       NVL (o.consid, 0.00) Consid,
       NVL (o.price, 0.0000) price,
       dealdt,
       indate,
       mbdat,
       CASE
          WHEN NVL (o.convert2, 'XX') IN ('T', 'C', 'S')
          THEN
             NVL (Indate, TRUNC (Createddate)) -- C as 2012/10/22 - RDR Changed to use indate first
          -- NVL (TRUNC (o.createddate), NVL (indate, NVL (mbdat, dealdt)))
          ELSE
             NVL (dealdt, NVL (indate, NVL (mbdat, TRUNC (o.createddate))))
       END
          dod, -- The Deal date (used to determin the date the deal is effective from)
       NVL (o.precharge, 0.0000) initsc,
       NVL (o.discrate, 0.0000) discrate,
       NVL (o.disc, 0.00) disc,
       NVL (o.dillevPC, 0.0000) dillevPC,
       NVL (o.dillevy, 0.00) dillevy,
       NVL (o.comrate, 0.0000) comrate,
       NVL (o.comm, 0.00) comm,
       NVL (o.ocomm, 0.00) ocomm,
       NVL (o.charges, 0.00) charges,
       NVL (o.convert2, 'X') convert2,
       NVL (o.CONVERT, 'XX') CONVERT,
       NVL (o.trancode, 0) trancode,
       NVL (o.spract, 0) spract,
       NVL (o.spract2, 0) spract2,
       NVL (o.sprice, 0) sprice,                      -- C AS 2012/1/5 - Added
       o.snarr,
       o.Setondt,                                         -- Date Deal Settled
       o.agcode,                                                   -- Deal IFA
       o.mancode,                                              -- Manager Code
       NVL (o.createddate, indate) createddate,
       CASE WHEN conptdt IS NULL THEN 'N' ELSE 'Y' END Contract_printed, -- Has the Contract note Been Printed
       O.ISSCCY CCY,                               -- The Currency Of The Deal
       NVL (o.Deceased_Sell, 'N') Deceased_Sell,
       NVL (o.Final_Bonus, 0.00) Final_Bonus,
       NVL (o.Final_Bonus_PEN, 0.00) Final_Bonus_PEN,
       NVL (o.WITHDRAWAL_CHG, 0.00) WITHDRAWAL_CHG,
       NVL (o.MVR, 0.00) MVR,
       NVL (o.REGULAR_BONUS_COST, 0.00) REGULAR_BONUS_COST,
       NVL (o.TERMINAL_BONUS_COST, 0.00) TERMINAL_BONUS_COST
  FROM ordtran o
 WHERE     o.proc = 'Y'
       AND NVL (o.reversed, 'N') != 'Y'
       AND NVL (CONVERT, 'XX') != 'TO'
       --  AND NVL (CONVERT, 'XX') != 'TB'
       AND NVL (o.ifatransfer, 'N') = 'N' -- Used as part of MULTIIFA (Rensburge) BUT there are no ordtran records where this is Y and NOT reversed.
;


COMMENT ON TABLE FCS.ORDTRAN_MV IS 'Rationalised/Indexed View of (Primarily) Statement Fields From table ORDTRAN';

COMMENT ON COLUMN FCS.ORDTRAN_MV.AGCODE IS 'IFA code';

COMMENT ON COLUMN FCS.ORDTRAN_MV.AMTDUE IS 'Amount Due';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CCY IS 'Deal currency';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CHARGES IS 'OEIC Charge Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.COMM IS 'Commission Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.COMRATE IS 'Commission rate %';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CONSID IS 'Consideration';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CONTRACT_PRINTED IS 'Has a contract note been printed';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CONVERT IS 'TO=Take on (not a real deal, system ignores it)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CONVERT2 IS 'C=Unit holder conversion (UT income to acc or acc to inc in same fund) , T=  Stock transfer (Units moved from one investor to another)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.CREATEDDATE IS 'Date ordtran record created';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DEALDT IS 'Deal date (price date)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DECEASED_SELL IS 'RL - Y/N Is the repurchase a deceased sell (selling of dead investors)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DILLEVPC IS 'Dilution Levy %';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DILLEVY IS 'Dilution Levy Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DISC IS 'Discount Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DISCRATE IS 'Discount Rate %';

COMMENT ON COLUMN FCS.ORDTRAN_MV.DOD IS 'Date Of Deal (this is the deal date for most deals, for stock transfers and uit holder conversions this would be the indate, used to determin the date the deal is effective from)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.FINAL_BONUS IS 'RL-Units  *price* final bonus % applicable for date range of deals';

COMMENT ON COLUMN FCS.ORDTRAN_MV.FINAL_BONUS_PEN IS 'RL-If the investor has held the units less than 5 years, we deduct some of the final bonus';

COMMENT ON COLUMN FCS.ORDTRAN_MV.INDATE IS 'Date Record Created';

COMMENT ON COLUMN FCS.ORDTRAN_MV.INITSC IS 'Initial Charge Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.INVCODE IS 'Investor Code';

COMMENT ON COLUMN FCS.ORDTRAN_MV.ISSREP IS 'I=Issues, R=repurchase';

COMMENT ON COLUMN FCS.ORDTRAN_MV.MANCODE IS 'MAnager Code';

COMMENT ON COLUMN FCS.ORDTRAN_MV.MBDAT IS 'Managers Box Date (date deal processed)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.MVR IS 'RL-If not ISA started before 6/4/2001 or Deceased Sale then another charge (Market Value Reduction)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.OCOMM IS 'Oeic Commission Value';

COMMENT ON COLUMN FCS.ORDTRAN_MV.ORDUID IS 'Deal ref';

COMMENT ON COLUMN FCS.ORDTRAN_MV.PRICE IS 'Price of the deal';

COMMENT ON COLUMN FCS.ORDTRAN_MV.PRODUCT IS 'Producd, based on 1st character of ordtran.transfer column (where NULL = N)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.QUANTITY IS 'Deal quantity';

COMMENT ON COLUMN FCS.ORDTRAN_MV.REGULAR_BONUS_COST IS 'RL';

COMMENT ON COLUMN FCS.ORDTRAN_MV.SETONDT IS 'Date Deal settled';

COMMENT ON COLUMN FCS.ORDTRAN_MV.SNARR IS 'System Narrative';

COMMENT ON COLUMN FCS.ORDTRAN_MV.SPRACT IS 'Price Basis (before deal processed)';

COMMENT ON COLUMN FCS.ORDTRAN_MV.SPRACT2 IS 'Price Basis (After Deal Processed) 999=Cancellation Basis, 901 = ';

COMMENT ON COLUMN FCS.ORDTRAN_MV.TERMINAL_BONUS_COST IS 'RL';

COMMENT ON COLUMN FCS.ORDTRAN_MV.TRANCODE IS 'The transaction code';

COMMENT ON COLUMN FCS.ORDTRAN_MV.TRSTCODE IS 'Trust Code';

COMMENT ON COLUMN FCS.ORDTRAN_MV.UNITTYPE IS 'Unit type';

COMMENT ON COLUMN FCS.ORDTRAN_MV.WITHDRAWAL_CHG IS 'RL';

CREATE OR REPLACE PUBLIC SYNONYM ORDTRAN_MV FOR FCS.ORDTRAN_MV;

CREATE UNIQUE INDEX FCS.ORDTRAN_PK1 ON FCS.ORDTRAN_MV
(ORDUID)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX01 ON FCS.ORDTRAN_MV
(INVCODE, DOD)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX02 ON FCS.ORDTRAN_MV
(DOD)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX03 ON FCS.ORDTRAN_MV
(TRSTCODE, UNITTYPE, PRODUCT, INVCODE)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX04 ON FCS.ORDTRAN_MV
(INVCODE, TRSTCODE, UNITTYPE, PRODUCT, DOD)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX05 ON FCS.ORDTRAN_MV
(SETONDT)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

CREATE INDEX FCS.ORDTRAN_MV_IX06 ON FCS.ORDTRAN_MV
(INVCODE, ISSREP, DEALDT)
LOGGING
TABLESPACE CFA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

GRANT SELECT ON FCS.ORDTRAN_MV TO DATABASE_READER_UV;

GRANT DELETE, INSERT, SELECT, UPDATE ON FCS.ORDTRAN_MV TO DATA_UPDATE_ONLY;

GRANT DELETE, INSERT, SELECT, UPDATE ON FCS.ORDTRAN_MV TO NORMAL_USER;

GRANT DELETE, INSERT, SELECT, UPDATE ON FCS.ORDTRAN_MV TO NORMAL_USER_NON_CONFIG;

GRANT SELECT, FLASHBACK ON FCS.ORDTRAN_MV TO READONLY_ROLE;


spool off

set define on
