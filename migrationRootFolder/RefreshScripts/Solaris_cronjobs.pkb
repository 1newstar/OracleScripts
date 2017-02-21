create or replace package body sys.solaris_cronjobs 
as

    --=========================================================================
    -- HELPER ROUTINES
    --=========================================================================
    -- A few helper routines to make typing less "intense" ;-)
    --=========================================================================

    -- Putline. Should be commented out in production as running under the
    -- sheduler means output simply vanishes.
    procedure PutLine(iMessage in varchar2)
    as
    begin
        dbms_output.put_line(iMessage);
        null;
    end;
    
    
    
    
    --=========================================================================
    -- PROCEDURE STATSGEN
    --=========================================================================
    -- Gather Table Stats as required.
    -- Not strictly required in 11g as we have an automated task to
    -- gather stats on any stale, or stats-free tables, which runs
    -- under SYS in the background. IF, and ONLY IF the DIAGNOSTIC package is
    -- enabled. (We haven't enabled it, extra cost option.)
    --=========================================================================
    -- This script will log details to V$SESSION.MODULE and V$SESSION.ACTION as
    -- it progresses. You can check progress by:
    -- 
    -- select module, action
    -- from   v$session
    -- where  module = 'STATSGEN';
    --=========================================================================
    -- If an analysis fails, details are logged to SYS.STASGEN_ERRORS which is
    -- truncated on every execution of this procedure.
    --=========================================================================
    procedure statsgen
    as
        vAnalyseSQL varchar2(500);
        vSQL varchar2(500);
        vNeedToRaiseException boolean := false;
        
        -- LogError, internal helper.
        procedure LogError(iOwner in dba_tables.owner%type,
                           iTableName in dba_tables.table_name%type,
                           iErrorCode in number,
                           iErrorText in varchar2)
        as
                           
            pragma autonomous_transaction;
            
        begin
            insert into sys.statsgen_errors
            values (iOwner, iTableName, iErrorCode, iErrorText);
            
            -- This won't affect other stuff that is uncommitted. If any!
            commit;
        end;
    

    begin
        -- Sign on.
        dbms_application_info.set_module (module_name => 'STATSGEN', 
                                          action_name => 'Initialising ...');

        vAnalyseSQL := 'begin ' ||
                       'DBMS_STATS.GATHER_TABLE_STATS(OWNNAME => ''%owner%'', ' ||
                       'TABNAME => ''%table_name%'', ' ||
                       'Method_Opt => ''FOR ALL INDEXED COLUMNS SIZE AUTO'', ' ||
                       'Degree => 4, Cascade => TRUE, No_Invalidate => FALSE);' ||
                       'end;';
        
        -- Truncate the error messages from the previous run.
        begin
            execute immediate 'truncate table sys.statsgen_errors';
        exception
            -- Kick off, big time if this goes wrong.
            when others then
                raise;
        end;
        
        -- Only analyse FCS and OEIC_RECALC tables, and no external ones.               
        for x in (select owner, table_name
                  from   dba_tables
                  where  owner in ('FCS','OEIC_RECALC')
                  and    (owner,table_name) not in (
                            select owner, table_name
                            from   dba_external_tables
                            where  owner in ('FCS','OEIC_RECALC')
                         )
                 order by owner, table_name)
        loop
        
            begin
                dbms_application_info.set_action (action_name => x.owner || '.'|| x.table_name);
                
                vSQL := replace(replace(vAnalyseSQL, '%owner%', x.owner), '%table_name%', x.table_name);
                PutLine(vSQL);
                execute immediate vSQL;
                
            exception
                when others then
                    -- Log failure details and raise an exception later.
                    PutLine('Analyse Failed: ' || x.owner || '.' || x.table_name);
                    vNeedToRaiseException := true;
                    logError(x.owner, x.table_name, sqlcode, sqlerrm);
            end;
            
        end loop;         
                          
        -- Sign off.
        dbms_application_info.set_module (module_name => NULL, 
                                          action_name => NULL);
                                          
        -- Blow up if there were failures.
        if (vNeedToRaiseException)
        then
            raise_application_error(-20000, 'Analyse Failed. See SYS.STATSGEN_ERRORS table.');
        end if;
        
    end;
        

    --=========================================================================
    -- PROCEDURE EXPIRE_PASSWORDS
    --=========================================================================
    -- EXPIRE all accounts where the password has expired but the status is
    -- OPEN or EXPIRED(GRACE).
    -- Also, LOCK if the expired password not changed in iLockAfterExpiryDays.
    --=========================================================================
    -- This script will log details to V$SESSION.MODULE and V$SESSION.ACTION as
    -- it progresses. You can check progress by:
    -- 
    -- select module, action
    -- from   v$session
    -- where  module = 'EXPIRE_PASSWORDS';
    --=========================================================================

    procedure expire_passwords(iProfile in dba_profiles.profile%type default 'APP_USER',
                               iLockAfterExpiryDays in number default 30,
                               iDefaultGraceTime in number default 30)                               
    as
    
        vLockSQL varchar2(250);
        vNeedToRaiseException boolean := false;
    
        -- LogError, internal helper.
        procedure LogMessage(iUsername in dba_users.username%type,
                             iaction in varchar2,
                             iErrorCode in number,
                             iErrorText in varchar2)
        as
                           
            pragma autonomous_transaction;
            
        begin
            insert into sys.expire_password_log
            values (iUsername, iAction, iErrorCode, iErrorText);
            
            -- This won't affect other stuff that is uncommitted. If any!
            commit;
        end;
    

        -- Expire a user account.
        procedure expireUserAccount(iUsername in dba_users.username%type)
        as
            vExpireSQL varchar2(250);
        begin
            vExpireSQL := 'alter user ' || iUsername || ' password expire';
            PutLine(vExpireSql);
            dbms_application_info.set_action (action_name => 'Expiring: ' || iUsername);
            execute immediate vExpireSQL;
                   
        exception
            when others then
                raise;
                
        end;
        
        
        -- Lock a user account.
        procedure lockUserAccount(iUsername in dba_users.username%type)
        as
            vLockSQL varchar2(250);
        begin
            vLockSQL := 'alter user ' || iUsername || ' account lock password expire';
            PutLine(vLockSQL);
            dbms_application_info.set_action (action_name => 'Locking: ' || iUsername);
            execute immediate vLockSQL;
                   
        exception
            when others then
                raise;
                
        end;


    begin
    
        -- Sign on ...
        dbms_application_info.set_module (module_name => 'EXPIRE_PASSWORDS', 
                                          action_name => 'Initialising ...');

        -- Truncate the messages from the previous run.
        begin
            execute immediate 'truncate table sys.expire_password_log';
        exception
            -- Kick off, big time if this goes wrong.
            when others then
                raise;
        end;
        
        -- Failsafe check.
        if (iLockAfterExpiryDays + iDefaultGraceTime < 30) then
            PutLine('Early exit.');
            LogMessage('EXPIRE ACCOUNTS','EARLY EXIT', 0, null);
            return;
        end if;
        
        -- Do the deed!
        for x in (select username,
                         account_status,
                         nvl(expiry_date, created + iLockAfterExpiryDays) expiry_date
                  from   dba_users
                  where  profile = iProfile
                  and    account_status <> 'EXPIRED & LOCKED'
                  and    username not in ('SYS','SYSTEM')
                  order  by username, account_status) 
        Loop
            -- What's happening?
            dbms_application_info.set_action (action_name => 'Checking: ' || x.username);
            PutLine(x.username || ': ' || x.account_status || ', ' || x.expiry_date);
            LogMessage(x.username, 'Checking',0, null);
            
        
            -- EXPIRE any locked accounts.
            if (x.account_status = 'LOCKED') 
            then
                LogMessage(x.username, 'Expiring',0, null);
                begin
                    expireUserAccount(x.username);
                exception
                    when others then
                        vNeedToRaiseException := true;
                end;
                
                continue;   -- No further processing required.
            end if;
                
            -- EXPIRE any OPEN or EXPIRED(GRACE) accounts but only if
            -- the expiry date is too far back in time.
            if (((x.account_status = 'OPEN') OR
                 (x.account_status like 'EXPIRED(GRACE)%'))
                AND (sysdate - x.expiry_date > iDefaultGraceTime))                
            then
                LogMessage(x.username, 'Expiring',0, null);
                begin
                    expireUserAccount(x.username);
                exception
                    when others then
                        vNeedToRaiseException := true;
                end;
                
                continue;   -- No further processing required.
            end if;
            
            -- LOCK accounts where the account is EXPIRED and the expiry
            -- date was more than iLockAfterExpiryDays days ago. But,
            -- only if the account is also LOCKED(TIMED) or is not
            -- already LOCKED.
            if ((x.account_status like 'EXPIRED%') AND 
                (sysdate - x.expiry_date > iLockAfterExpiryDays))
            then
                if ((instr(x.account_status, 'LOCKED(TIMED)') > 0) OR
                    (instr(x.account_status, 'LOCKED') = 0))
                then
                    LogMessage(x.username, 'Locking',0, null);
                    begin
                        lockUserAccount(x.username);
                    exception
                        when others then
                            vNeedToRaiseException := true;
                    end;
                end if;
            end if;

            -- And lets go round again!            
        end loop;
        
        -- Sign off.
        dbms_application_info.set_module (module_name => NULL, 
                                          action_name => NULL);
    
        -- Blow up if there were failures.
        if (vNeedToRaiseException)
        then
            raise_application_error(-20000, 'Expire Accounts Failed. See SYS.EXPIRE_PASSWORD_LOG table.');
        end if;
        
    end;



    --=========================================================================
    -- PROCEDURE ENDOFDAY_AUDIT
    --=========================================================================
    -- Copy DDL entries from SYS.AUD$ into FCS.DBA_AUDIT.
    -- Delete those copied rows from SYS.AUD$.
    -- Copy LOGON LOGOFF entries from SYS.AUD$ into FCS.DBA_AUDIT@CFGAUDIT.
    -- And delete them from SYS.AUD$.
    --
    -- This script will log details to V$SESSION.MODULE and V$SESSION.ACTION as
    -- it progresses. You can check progress by:
    -- 
    -- select module, action
    -- from   v$session
    -- where  module = 'ENDOFDAY_AUDIT';
    --=========================================================================
    -- PROBLEM AREAS:
    --
    -- 1. TIMESTAMP# in SYS.AUD$ is not used in 11g. It is NULL. The column
    --    NTIMESTAP# is used instead. However, it's a TIMESTAMP(6) not a DATE.
    --    We have to "CAST(NTIMESTAMP# as DATE) as TIMESTAMP#" in the code so
    --    that the data types match our own DBA_AUDIT table.
    --
    -- 2. SYS.AUD$ has additional columns at 11g from those in 9i. We have had
    --    to SELECT and INSERT only those old columns as the DBA_AUDIT table
    --    matches the 9i layout, not the 11g layout.
    --=========================================================================
    
    

    procedure endofday_audit
    as

        -- If we run past midnight for some reason, we won't be inserting the
        -- same rows that we will be deleting. This is not good. Make sure that
        -- it cannot happen - however minimal the possibility that audited actions
        -- could have happened after midnight.
        vTruncSysdate TIMESTAMP(6);

    begin

        -- Sign on ...
        dbms_application_info.set_module (module_name => 'ENDOFDAY_AUDIT', 
                                          action_name => 'Initialising ...');

        vTruncSysdate := trunc(systimestamp);

        dbms_application_info.set_action(action_name => 'Copy DDL -> DBA_AUDIT');

        -- The DBA_AUDIT table is a clone of a 9i SYS.AUD$ table. At 11g
        -- and probably 10g too, new columns were added. These are not
        -- used, so we have to supply a list of columns that match the
        -- old 9i layout now. Note the casting on NTIMESTAMP# too.
        insert into fcs.dba_audit (ACTION#, AUTH$GRANTEE, AUTH$PRIVILEGES, CLIENTID, 
                                   COMMENT$TEXT, ENTRYID, LOGOFF$DEAD, LOGOFF$LREAD, 
                                   LOGOFF$LWRITE, LOGOFF$PREAD, LOGOFF$TIME, NEW$NAME, 
                                   NEW$OWNER, OBJ$CREATOR, OBJ$LABEL, OBJ$NAME, PRIV$USED, 
                                   RETURNCODE, SES$ACTIONS, SES$LABEL, SES$TID, SESSIONCPU, 
                                   SESSIONID, SPARE1, SPARE2, STATEMENT, TERMINAL, 
                                   TIMESTAMP#, USERHOST, USERID
                                   )
        (        
            select s.ACTION#, s.AUTH$GRANTEE, s.AUTH$PRIVILEGES, s.CLIENTID, 
                   s.COMMENT$TEXT, s.ENTRYID, s.LOGOFF$DEAD, s.LOGOFF$LREAD, 
                   s.LOGOFF$LWRITE, s.LOGOFF$PREAD, s.LOGOFF$TIME, s.NEW$NAME, 
                   s.NEW$OWNER, s.OBJ$CREATOR, s.OBJ$LABEL, s.OBJ$NAME, s.PRIV$USED, 
                   s.RETURNCODE, s.SES$ACTIONS, s.SES$LABEL, s.SES$TID, s.SESSIONCPU, 
                   s.SESSIONID, s.SPARE1, s.SPARE2, s.STATEMENT, s.TERMINAL, 
                   cast(s.NTIMESTAMP# as date) as timestamp#, s.USERHOST, s.USERID 
            from   sys.aud$ s, 
                   sys.audit_actions a
            where  s.action# = a.action
            and trunc(ntimestamp#) < vTruncSysdate
            and (
                a.name    like 'ALTER%'
                or a.name like 'CREATE%'
                or a.name like 'TRUNCATE%'
                or a.name like 'DROP%'
            )
        );


        dbms_application_info.set_action(action_name => 'Delete DDL from SYS.AUD$');

        delete from sys.aud$  
        where trunc(ntimestamp#) < vTruncSysdate
        and action# in (
            select action from sys.audit_actions a
            where  a.name like 'ALTER%'
            or     a.name like 'CREATE%'
            or     a.name like 'TRUNCATE%'
            or     a.name like 'DROP%'
        );
        

        dbms_application_info.set_action(action_name => 'Copy LOGON/OFF -> CFGAUDIT');

/*+++++
        -- The DBA_AUDIT table is a clone of a 9i SYS.AUD$ table. At 11g
        -- and probably 10g too, new columns were added. These are not
        -- used, so we have to supply a list of columns that match the
        -- old 9i layout now. Note the casting on NTIMESTAMP# too.
        insert into dba_audit@CFGAUDIT_LINK (
            ACTION#, AUTH$GRANTEE, AUTH$PRIVILEGES, CLIENTID, 
            COMMENT$TEXT, ENTRYID, LOGOFF$DEAD, LOGOFF$LREAD, 
            LOGOFF$LWRITE, LOGOFF$PREAD, LOGOFF$TIME, NEW$NAME, 
            NEW$OWNER, OBJ$CREATOR, OBJ$LABEL, OBJ$NAME, PRIV$USED, 
            RETURNCODE, SES$ACTIONS, SES$LABEL, SES$TID, SESSIONCPU, 
            SESSIONID, SPARE1, SPARE2, STATEMENT, TERMINAL, 
            TIMESTAMP#, USERHOST, USERID)
        (
            select s.ACTION#, s.AUTH$GRANTEE, s.AUTH$PRIVILEGES, s.CLIENTID, 
                   s.COMMENT$TEXT, s.ENTRYID, s.LOGOFF$DEAD, s.LOGOFF$LREAD, 
                   s.LOGOFF$LWRITE, s.LOGOFF$PREAD, s.LOGOFF$TIME, s.NEW$NAME, 
                   s.NEW$OWNER, s.OBJ$CREATOR, s.OBJ$LABEL, s.OBJ$NAME, s.PRIV$USED, 
                   s.RETURNCODE, s.SES$ACTIONS, s.SES$LABEL, s.SES$TID, s.SESSIONCPU, 
                   s.SESSIONID, s.SPARE1, s.SPARE2, s.STATEMENT, s.TERMINAL, 
                   cast(s.NTIMESTAMP# as date) as timestamp#, s.USERHOST, s.USERID 
            from   sys.aud$ s, 
                   sys.audit_actions a
            where  s.action# = a.action
            and    trunc(timestamp#) < vTruncSysdate
            and    a.name like 'LOG%'
        );


        dbms_application_info.set_action(action_name => 'Delete LOGON/OFF from SYS.AUD$');

        delete from sys.aud$
        where trunc(timestamp#) < vTruncSysdate
        and action# in (
            select action 
            from   sys.audit_actions a
            where  a.name like 'LOG%'
        );
++++*/

        commit;

        -- Sign off.
        dbms_application_info.set_module (module_name => NULL, 
                                          action_name => NULL);

    exception
        -- Propogate any exceptions back to the caller.
        when others then
            raise;
    end;



    --=========================================================================
    -- PROCEDURE ENDOFDAY_AUDIT
    --=========================================================================
    -- Truncate various tables at the end of each day.
    --=========================================================================

    procedure endofday_utmsodrm 
    as
    
        vTruncateTheseTables tTableList;   
        vThisTable dba_tables.table_name%type;
        vNeedToRaiseException boolean := false;
        vSQL varchar2(250); 

            -- LogMessage, internal helper.
        procedure LogMessage(iOwner in dba_tables.owner%type,
                             iTableName in dba_tables.table_name%type,
                             iErrorCode in number,
                             iErrorText in varchar2)
        as
                           
            pragma autonomous_transaction;
            
        begin
            insert into sys.utmsodrm_errors
            values (iOwner, iTableName, iErrorCode, iErrorText);
            
            -- This won't affect other stuff that is uncommitted. If any!
            commit;
        end;
    
begin
        
        -- List of (FCS) tables to be truncated. Make sure that
        -- they are in upper case. If the tablename is one of the
        -- "miXEDCase" tables, there are a couple, then they DON'T 
        -- need to be enclosed in double quotes, as per:
        --
        -- TruncateTheseTables('MixedCaseTableName') := 'MixedCaseTableName';
        --
        -- ALL TABLES ARE ASSUMED TO LIVE IN FCS!
        --
        vTruncateTheseTables('REGISTER_HISTORY_MISMATCH') := 'REGISTER_HISTORY_MISMATCH';

        -- Truncate the messages from the previous run.
        begin
            execute immediate 'truncate table sys.utmsodrm_errors';
        exception
            -- Kick off, big time if this goes wrong.
            when others then
                raise;
        end;
        
                
        vThisTable := vTruncateTheseTables.first;
        
        if (vThisTable is NULL) then
            -- Nothing to do
            return;
        end if;
        
        while (vThisTable is not null) loop
            begin
                vSQL := 'truncate table fcs."'|| vThisTable || '"';
                LogMessage('FCS', vThisTable, 0, NULL);
                execute immediate vSQL;
            exception
                when others then
                    -- Note the problem and we will complain later!
                    LogMessage('FCS', vThisTable, sqlcode, sqlerrm);
                    vNeedToRaiseException := true;
                    
            end;
            
            vThisTable := vTruncateTheseTables.next(vThisTable);
            
        end loop;
    
        -- Blow up if there were failures.
        if (vNeedToRaiseException)
        then
            raise_application_error(-20000, 'Endofday_utmsodrm Failed. See table SYS.UTMSODRM_ERRORS for details.');
        end if;
        
    end;        

end;
/    