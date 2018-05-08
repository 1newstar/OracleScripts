-- Create the table first.
CREATE TABLE DBA_USER.DAILY_STATS_LOG
(
    ID                 NUMBER(9), 
    OWNER              VARCHAR2(30 BYTE),
    TABLE_NAME         VARCHAR2(30 BYTE),
    PARTITION_NAME     VARCHAR2(30 BYTE),
    SUBPARTITION_NAME  VARCHAR2(30 BYTE),
    OBJECT_TYPE        VARCHAR2(12 BYTE),
    STARTTIME          DATE,
    ENDTIME            DATE,
    ERROR_MESSAGE      VARCHAR2(200)
)
TABLESPACE USERS;

-- What's it all about then?
COMMENT ON TABLE DBA_USER.DAILY_STATS_LOG  IS 'This table holds a list of objects that have recently had their stats gathered as part of the daily stats regime. Data can be purged using PKG_DAILYTATS.HOUSEKEEPSTATS with a suitable number of days to retain.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.ID IS 'A sequence generated primarry key for the table.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.OWNER IS 'The owner of the object having stats gathered.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.TABLE_NAME is 'The table name having stats gathered for itself, a partition or a subpartition of itself. Always present.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.PARTITION_NAME is 'The partition name having stats gathered for itself. May be NULL if TABLE or SUBPARTITION being processed.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.SUBPARTITION_NAME is 'The subpartition name having stats gathered.  May be NULL if TABLE or PARTITION being processed.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.OBJECT_TYPE is 'TABLE, PARTITION or SUBPARTITION, depending on the object having stats gathered.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.STARTTIME is 'Date and time the call to DBMS_STATS began.';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.ENDTIME is 'Date and time the call to DBMS_STATS ended after gathering stats. May be NULL if still running';

COMMENT ON COLUMN DBA_USER.DAILY_STATS_LOG.ERROR_MESSAGE IS 'The error message from the call to DBMS_STATS, or NULL if no errors occurred.';

-- Add a primary key.
ALTER TABLE  DBA_USER.DAILY_STATS_LOG
ADD CONSTRAINT DAILY_STATS_LOG_PK PRIMARY KEY (ID)
USING INDEX 
TABLESPACE USERS ;

-- The table needs a sequence. We cycle this one as we
-- delete old data in house keeping.
CREATE SEQUENCE DBA_USER.DAILY_STATS_LOG_SEQ
START WITH 1
INCREMENT BY 1
MINVALUE 0
MAXVALUE 999999999
NOCACHE 
CYCLE 
ORDER;



-- Make sure the ID is always populated.
CREATE OR REPLACE TRIGGER DBA_USER.DAILY_STATS_LOG_TRG 
before insert on dba_user.daily_stats_log 
for each row
begin
    -- Just uppercase the username.
    :new.id := dba_user.daily_stats_log_seq.nextval;
end;
/

ALTER TRIGGER DBA_USER.DAILY_STATS_LOG_TRG ENABLE;

