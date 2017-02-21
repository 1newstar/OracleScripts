create or replace package sys.solaris_cronjobs 
as

    -- Variables and types that we might need.
    
    -- Array of table_names.
    type tTableList is table of dba_tables.table_name%type    
        index by dba_tables.table_name%type;
        
    -- Moves various data from SYS.AUD$ to the FCS.DBA_AUDIT table
    -- in this database, and also to the DBA_AUDIT table on the far
    -- end of the CFGAUDIT database link.
    procedure endofday_audit;
    
    
    -- Truncate various tables at the end of each day.
    procedure endofday_utmsodrm;    
    
    
    -- EXPIRE all accounts where the password has expired but the status is
    -- OPEN or EXPIRED(GRACE).
    -- Also, LOCK if the expired password not changed in iLockAfterExpiryDays.
    procedure expire_passwords(iProfile in dba_profiles.profile%type default 'APP_USER',
                               iLockAfterExpiryDays in number default 30,
                               iDefaultGraceTime in number default 30); 
    
                               
    -- Gather Table Stats as required.
    -- Not strictly required in 11g as we have an automated task to
    -- gather stats on any stale, or stats-free tables, which runs
    -- under SYS in the background.
    procedure statsgen;
                                                                 
end;    