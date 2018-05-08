-- Create the table first.
CREATE TABLE DBA_USER.DAILY_STATS_EXCLUSIONS (
    USERNAME VARCHAR2(20 BYTE) NOT NULL ENABLE   
) TABLESPACE USERS;

-- Add a primary key.
ALTER TABLE  DBA_USER.DAILY_STATS_EXCLUSIONS
ADD CONSTRAINT DAILY_STATS_EXCLUSIONS_PK PRIMARY KEY (USERNAME)
USING INDEX 
TABLESPACE USERS ;

-- What's it all about then?
COMMENT ON TABLE DBA_USER.DAILY_STATS_EXCLUSIONS  IS 'This table holds a list of usernames. These usernames are to be specifically excluded from the semi-automatic processing carried out by DBA_USER.PKG_DAILYSTATS. ';
COMMENT ON COLUMN DBA_USER.DAILY_STATS_EXCLUSIONS.USERNAME IS 'Username to be excluded from PKG_DAILYSTATS processing.';

-- Make sure the username is always upper case.
CREATE OR REPLACE TRIGGER DBA_USER.DAILY_STATS_EXCLUSIONS_TRG 
before insert or update on dba_user.daily_stats_exclusions 
for each row
begin
    -- Just uppercase the username.
    :new.username := upper(:new.username);
end;
/

ALTER TRIGGER DBA_USER.TRIGGER1 ENABLE;

