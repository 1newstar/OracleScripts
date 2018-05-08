create or replace PACKAGE BODY                                                                                                 PKG_FRAG AS

--==============================================================================================================================    
-- Internal use only - not callable from outside the package.
--==============================================================================================================================    

    -----------------------------------------------
    -- Call DBMS_OUTPUT. Saves typing all the time!
    -----------------------------------------------
    procedure pl(piMessage in varchar2)
    is
    begin
        dbms_output.put_line(piMessage);
    end;



    ------------------------------------------------------------------------------
    -- Helper to determine if stats are locked for a table or partition. Returns a
    -- comment  if locked '-- LOCKED STATS: ' and NULL if otherwise. The comment
    -- will be tagged onto the front of the stats gathering SQL to prevent any
    -- attempt to gather stats for locked tables or partitions. It will also be
    -- listed in the output, so the DBA will be aware.
    ------------------------------------------------------------------------------
    function getLockedStats(
        piOwner in frag_view.owner%type,
        piTabname in frag_view.tabname%type,
        piPartname in frag_view.partname%type default null)
    return varchar2
    is
        vResult varchar2(20);
    begin
        if (piPartname is not null) then
            -- Are the partition statistics locked?
            select  case
                    when stattype_locked is null then null
                    else '-- LOCKED STATS '
                    end
            into    vResult
            from    DBA_TAB_STATISTICS
            where   owner = piOwner
            and     table_name = piTabname
            and     partition_name = piPartname;
        else
            -- Are the table statistics locked?
            select  case 
                    when stattype_locked is null then null
                    else '-- LOCKED STATS '
                    end
            into    vResult
            from    DBA_TAB_STATISTICS
            where   owner = piOwner
            and     table_name = piTabname;
        end if;
        
        return vResult;
        
    exception
        -- None of these should happen!
        when no_data_found then
            return null;
        when others then 
            return null;
    end;
    
    
    ------------------------------------------------------------------------------
    -- A helper routine to send an email to the HUK.DBA group if an SQL fails to
    -- execute. Note, linefeeeds *must* be in Windows format. CHR(10) || CHR(13).
    ------------------------------------------------------------------------------
    procedure sendEmail
    is
        vSender constant varchar2(100) := 'huk.dba@hermes-europe.co.uk';
        vRecipients constant varchar2(100) := 'huk.dba@hermes-europe.co.uk';
        -- vRecipients constant varchar2(100) := 'norman.dunbar@hermes-europe.co.uk';
        vCC constant varchar2(200) := null;
        vSubject constant varchar2(200) := 'FRAGO reorganisation - failures, please investigate ASAP';
        vPriority constant varchar2(10) := 1;
        vMessage varchar2(4000) := 'One or more SQL statements failed to execute when being run under the FRAGO system:'
                                   || gLineFeed || chr(13)
                                   || 'Please ascertain who has run this today, and investigate the log to ensure that '
                                   || 'all SQL statements have executed successfully, or that any failures are able to '
                                   || 'be ignored until later.';
    begin
        -----------------------------------------------------------------------------------
        -- WARNING:
        -----------------------------------------------------------------------------------
        -- ORA-06502: PL/SQL: numeric or value error
        -- ORA-06512: at "SYS.UTL_MAIL", line 662
        -- ORA-06512: at "SYS.UTL_MAIL", line 679
        --
        -- If the databases parameter 'smtp_out_server' is not set to a valid SMTP server.
        -----------------------------------------------------------------------------------
        utl_mail.send(sender => vSender,
                      recipients => vRecipients,
                      cc => vCC,
                      subject => vSubject,
                      message => vMessage,
                      priority => vPriority);
    exception
        when others then 
            -- Display actual error message & code.
            pl(sqlerrm);
            pl(gLineFeed);
            
            -- Display how we got to the error.
            pl(dbms_utility.format_error_backtrace);
            pl(gLineFeed);
            pl(dbms_utility.format_error_stack);
            pl(gLineFeed);
    end;
            


    ------------------------------------------------------------------------------
    -- Helper to either execute the passed SQL command, or simply display it 
    -- according to the second parameter passed.
    -- We do not attempt to execute comments.
    -- SQL statements will fail if we execute with a trailing ';', however, PL/SQL
    -- will fail if we don't have one.
    ------------------------------------------------------------------------------
    procedure execOrDisplay(
        piCommand in varchar2,
        piExecute in boolean)
    is
        vTableName varchar2(64);
        vDot number;
        vMove number;
    begin
        -- Did we get something to execute?
        if (piCommand is null) then
            return;
        end if;
        
        -- We have the SQL now. 
        -- Display and optionally execute.
        if (piExecute) then
            -- We wish to execute the generated SQL commands.
            
            if (piCommand not like '_-%') then
                -- We don't attempt to execute comment/linefeed lines.
                
                -- Try to report progress - on change of table name. This is
                -- hard(ISH) as we only have 64 characters to play with in 
                -- V$SESSION.ACTION so just doing the tablename, not the owner.
                if (piCommand like 'ALTER TABLE%') then
                    vDot := instr(piCommand, '.') + 1;
                    vMove := instr(piCommand, ' MOVE');
                    vTableName := substr(piCommand, vDot, vMove - vDot);
                    dbms_application_info.set_action('R: ' || vTableName);
                end if;
                
                -- Trim off trailing semicolons before execution.
                -- Display the SQL before executing so we can see 
                -- which SQL caused errors - in the unlikely event!
                begin
                    if (piCommand not like 'begin%') then
                        -- SQL cannot have trailing ';'
                        pl('EXECUTING: ' || rtrim(piCommand, ';')); 
                        execute immediate rtrim(piCommand, ';');
                    else
                        -- PL/SQL needs trailing ';'
                        pl('EXECUTING: ' || piCommand); 
                        execute immediate piCommand;
                    end if;
                exception
                    when others then 
                        -- Display actual error message & code.
                        pl(sqlerrm);
                        pl(gLineFeed);
                        
                        -- Display how we got to the error.
                        pl(dbms_utility.format_error_backtrace);
                        pl(gLineFeed);
                        pl(dbms_utility.format_error_stack);
                        pl(gLineFeed);
                        
                        -- Set global flag.
                        gErrorsDetected := true;
                end;
                
            else
                -- Just list the comment lines.
                pl(piCommand);
            end if;
        else
            -- Just display the code we will run manually.
            -- Trailing semicolons are left on here as it makes for
            -- an easier manual copy & paste.
            pl(piCommand);
        end if;       
    end;

    
    
    ---------------------------------------------------
    -- Helper to append SQL to the reorg commands list.
    ---------------------------------------------------
    procedure appendSQL(
        piSQL in varchar2,
        piAppendSemi in boolean := true)
    is
    begin
        if (piAppendSemi) then
            gReorgSQL(gReorgIndex) := piSQL || ';';
        else
            gReorgSQL(gReorgIndex) := piSQL;
        end if;
        
        gReorgIndex := gReorgIndex + 1;
    end;
    


    ----------------------------------------------------------
    -- Helper to append SQL to the gather stats commands list.
    ----------------------------------------------------------
    procedure appendStatsSQL(
        piSQL in varchar2,
        piAppendSemi in boolean := true)       
    is
    begin
        if (piAppendSemi) then
            gStatsSQL(gStatsIndex) := piSQL || ';';
        else
            gStatsSQL(gStatsIndex) := piSQL;
        end if;

        gStatsIndex := gStatsIndex + 1;
        
        -------------------------------------------------------
        -- If we are not executing, we need a '/' on a new line
        -- after every 'begin ...' line. But not after any of
        -- the locked stats lines, which begin with a '--'.
        -------------------------------------------------------
        if (not gExecuteCommands) then
            if (not piSQL like '--%') then
                gStatsSQL(gStatsIndex) := '/';
                gStatsIndex := gStatsIndex + 1;
            end if;
        end if;
end;
    
    
    
    --------------------------------------------------------------------------
    -- Helper to report on progress through the list of objects to reorganise.
    --------------------------------------------------------------------------
    procedure reportProgress(
        piCurrentIndex in number, 
        piTotal in number)
    is
        vMessage varchar2(64);
    begin
        vMessage := 'Done ' || to_char(piCurrentindex) || ' out of ' || to_char(piTotal);
        if (gExecuteCommands) then
            -- When executing, report back to V$SESSION
            dbms_application_info.set_action(vMessage);
        else
            -- Otherwise, generate some code only.
            appendSQL('exec dbms_output.put_line('''
                      || vMessage
                      || ''')' );
        end if;
    end;
    


    ------------------------------------------------------------------------------
    -- Generates the SQL to rebuild any affected indexes for a table that has been
    -- reorganised.
    ------------------------------------------------------------------------------
    procedure generateTableIndexSQL(
        piOwner in frag_view.owner%type, 
        piTabname in frag_view.tabname%type)
    is
        vSQL varchar2(4000);
        
    begin
        for ix in (
            select  i.owner,
                    i.index_name,
                    i.degree
            from    dba_indexes i
            where   i.table_name = piTabname
            and     i.owner = piOwner)
        loop
            appendSQL('alter index ' || ix.owner || '.' || ix.index_name || ' rebuild parallel '
                      || case
                            when trim(ix.degree) <> 'DEFAULT' 
                            then
                                trim(ix.degree)
                            else
                                null
                         end
                       || ' online'  
                       );
        end loop;
        
    end;



    ------------------------------------------------------------------------------
    -- Generates the reorg and gather stats commands for a complete TABLE. Also
    -- creates suitable SQL to rebuild affected indexes. In keeping with the old
    -- system, some comment lines are also generated. These will not be executed
    -- though!
    ------------------------------------------------------------------------------
    procedure generateTableSQL(piRow in frag_view%rowtype)
    is
        vSQL varchar2(4000);
        
    begin
        appendSQL(gLineFeed || gSepLine, false);
        appendSQL('-- TABLE: ' || piRow.tabname, false);
        appendSQL(gSepLine, false);
        appendSQL('-- TABLE: ' || piRow.tabname || ' -- Size (MB): ' || piRow."SIZE (MB)", false);
        appendSQL('-- Partially used blocks: ' || piRow."PARTIALLY_USED BLOCKS", false);
        appendSQL('-- Percentage of highly fragmented blocks: ' || piRow.weight || '%', false);
        appendSQL('-- Formatted Blocks: ' || piRow.FORMATTED_BLOCKS, false);
        appendSQL('-- Full Blocks: ' || piRow.full_blocks || ' -- %Full Blocks: ' || piRow."% FULL BLOCKS", false);
        appendSQL(gSepLine, false); 
        
        appendSQL('ALTER TABLE ' || piRow.OWNER || '.' || piRow.tabname || ' MOVE PARALLEL');
        appendSQL('-- ', false);
        
        -- Generate the gather stats SQL for this table. Because it's PL/SQL
        -- we need to wrap this in begin end - exec will not work. If the stats
        -- for the table are locked, prefix with a comment to avoid errors.
        appendStatsSQL(getLockedStats(piOwner => piRow.owner, piTabname => piRow.tabname, piPartname => null)
                       || 'begin dbms_stats.gather_table_stats(ownname => ''' 
                       || piRow.owner 
                       || ''', tabname => ''' 
                       || piRow.tabname 
                       || ''', cascade => true, degree => 2); end;', false );

        -- Append the appropriate INDEX reorg SQL.
        generateTableIndexSQL(piOwner => piRow.owner,
                              piTabname => piRow.tabname);        
    end;



    ------------------------------------------------------------------------------
    -- Generates the SQL to rebuild any affected indexes for a table that has been
    -- reorganised. Only partitioned indexes are rebuilt here.
    ------------------------------------------------------------------------------
    procedure generateGlobalIndexSQL(
        piOwner in frag_view.owner%type, 
        piTabname in frag_view.tabname%type)
    is
        vSQL varchar2(4000);
        
    begin
        for ix in (
            select  i.owner , i.index_name, i.degree
            from    dba_tab_partitions tp, 
                    dba_indexes i
            where   i.table_name = tp.table_name 
            and     i.table_owner = tp.table_owner
            and     tp.partition_name in (
                        select  partname 
                        from    frag_view 
                        where   tabname = piTabname 
                        and     owner = piOwner)
            and     i.partitioned='NO')
        loop
            appendSQL('alter index ' || ix.owner || '.' || ix.index_name || ' rebuild parallel '
                      || case
                            when trim(ix.degree) <> 'DEFAULT' 
                            then
                                trim(ix.degree)
                            else
                                null
                         end
                       || ' online'  
                       );
        end loop;
    end;



    ------------------------------------------------------------------------------
    -- Generates the SQL to rebuild any affected indexes for a table that has been
    -- reorganised. Only partitioned indexes are rebuilt here.
    ------------------------------------------------------------------------------
    procedure generatePartitionIndexSQL(
        piOwner in frag_view.owner%type, 
        piTabname in frag_view.tabname%type)
    is
        vSQL varchar2(4000);
        
    begin
        appendSQL(gSepLine, false);
        appendSQL('-- Partitioned Indexes.', false);
        
        for ix in (
            select  ip.index_owner, ip.partition_name, ip.index_name, i.degree
            from    dba_tab_partitions tp, 
                    dba_ind_partitions ip, 
                    dba_indexes i
            where   i.owner = ip.index_owner 
            and     i.index_name = ip.index_name 
            and     i.table_name = tp.table_name 
            and     i.table_owner = tp.table_owner
            and     ip.partition_name = tp.partition_name
            and     ip.partition_name in (
                    select  partname 
                    from    frag_view 
                    where   segment_type = 'TABLE PARTITION' 
                    and     tabname = piTabname 
                    and     owner = piOwner)
            )
        loop
            appendSQL('alter index ' || ix.index_owner || '.' || ix.index_name || ' rebuild partition ' || ix.partition_name || ' parallel '
                      || case
                            when trim(ix.degree) <> 'DEFAULT' 
                            then
                                trim(ix.degree)
                            else
                                null
                         end
                       || ' online'  
                       );
        end loop;
        
        appendSQL(gSepLine, false);
        appendSQL('-- Global Indexes.', false);
        
        -- Any global indexes here?
        generateGlobalIndexSQL(piOwner => piOwner,
                               piTabname => piTabname);

        appendSQL(gSepLine, false);        
    end;



    ------------------------------------------------------------------------------
    -- Generates the reorg and gather stats commands for a complete TABLE. Also
    -- creates suitable SQL to rebuild affected indexes. In keeping with the old
    -- system, some comment lines are also generated. These will not be executed
    -- though!
    ------------------------------------------------------------------------------
    procedure generatePartitionSQL(piRow in frag_view%rowtype)
    is
        vSQL varchar2(4000);
        
    begin
        appendSQL(gLineFeed || gSepLine, false);
        appendSQL('-- TABLE: ' || piRow.tabname || '     PARTITION: ' || piRow.partname, false);
        appendSQL(gSepLine, false);
        appendSQL('-- TABLE: ' || piRow.tabname || ' -- Size (MB): ' || piRow."SIZE (MB)", false);
        appendSQL('-- Partially used blocks: ' || piRow."PARTIALLY_USED BLOCKS", false);
        appendSQL('-- Percentage of highly fragmented blocks: ' || piRow.weight || '%', false);
        appendSQL('-- Formatted Blocks: ' || piRow.FORMATTED_BLOCKS, false);
        appendSQL('-- Full Blocks: ' || piRow.full_blocks || ' -- %Full Blocks: ' || piRow."% FULL BLOCKS", false);
        appendSQL(gSepLine, false); 
        
        appendSQL('ALTER TABLE ' || piRow.OWNER || '.' || piRow.tabname || ' MOVE partition ' || piRow.partname || ' PARALLEL');
        appendSQL('-- ', false);
        
        -- Generate the gather stats SQL for this table. We have to use begin .. end
        -- as exec doesn't work in execute immediate. If the stats
        -- for the table are locked, prefix with a comment to avoid errors.
        appendStatsSQL(getLockedStats(piOwner => piRow.owner, piTabname => piRow.tabname, piPartname => piRow.partname)
                       || 'begin dbms_stats.gather_table_stats(ownname => ''' 
                       || piRow.owner 
                       || ''', tabname => ''' 
                       || piRow.tabname 
                       || ''', partname => ''' 
                       || piRow.partname 
                       || ''', granularity => ''PARTITION'', cascade => true, degree => 2); end;', false );

        -- Append the appropriate INDEX reorg SQL.
        generatePartitionIndexSQL(piOwner => piRow.owner,
                              piTabname => piRow.tabname);        
    end;



    ------------------------------------------------------------------------------
    -- Helper routine to control the generation of SQL commands to reorg either
    -- a complete TABLE or just one or more PARTITIONs for a table. Indexes will
    -- be reorganised as necessary - including local or global indexes.
    --
    -- Progress is reported using DBMS_APPLICTION calls.
    ------------------------------------------------------------------------------
    procedure generateSQL
    is
    begin
        -- Initialise the two collection indexes to point at the current free slot.
        gReorgIndex := 0;
        gStatsIndex := 0;
        
        -- If we are just displaying output for the DBA, we need serverout on.
        if (not gExecuteCommands) then
            appendSQL('set serverout on size unlimited', false);
            appendSQL('set feedback on', false);
            appendSQL('set timing on', false);
        end if;
        
        -- Generate the SQL commands as required.
        FOR indx IN gFragList.first .. gFragList.last
        LOOP
            if (gFragList(indx).segment_type='TABLE') then
                -- Generate code to reorg a full table.
                generateTableSQL(piRow => gFragList(indx));
                reportProgress(piCurrentIndex => indx, piTotal => gFragList.count);
            elsif (gFragList(indx).segment_type='TABLE PARTITION') then 
                -- Generate code to reorg a table partition.
                generatePartitionSQL(piRow => gFragList(indx));
                reportProgress(piCurrentIndex => indx, piTotal => gFragList.count);
            else
                -- Hmm, we don't appear to do these!
                dbms_output.put_line('Subpartition: ' );
            end if;
        END LOOP;
    end;
    
    
--          *******************************************************************************************
--          ** All the code from here on down is publically visible and callable. All the code above **
--          ** here is internal to this package body and cannot be called from anywhere else.        **
--          *******************************************************************************************


--==============================================================================================================================    
-- This procedure reports on the various tables and partitions which have been deemed to 
-- be fragmented.
--==============================================================================================================================    
    procedure frag_report
    is
        -------------------------------------------------------------
        -- Helper procedure which generates an output line with the
        -- object name in column 16 and the message in column 50.
        -------------------------------------------------------------
        procedure formatLine(piObjectType in varchar2 default NULL,
                             piObjectName in varchar2 default NULL,
                             piMessage in varchar2 default NULL)
        is
            vMessage varchar2(4000);
            vSpaces constant varchar2(50) := rpad(' ', 49, ' ');
        begin
            vMessage := substr(
                            -- The outer substr controls the position of the message
                            -- at column 50.
                            substr(
                                -- The inner substr controls the position of the object name
                                -- at column 16.
                                '-- ' || piObjectType || ':  ' || vSpaces, 1, 15
                            ) || piObjectName || vSpaces, 1, 49
                        ) || piMessage;
                        
            -- Print the formatted line.
            pl(vMessage);
        end;
        
        
    begin
        ----------------------------------------------------------------
        -- Grab all the rows from frag_view into a collection. This
        -- populates gFragList in the global area and makes it available
        -- to the other procedures etc.
        ----------------------------------------------------------------
        select  * bulk collect 
        into    gFragList 
        from    frag_view;

        pl('-- Total number of fragmented tables (i.e. full blocks % <= 50): ' || gFragList.COUNT);

        dbms_output.put_line('------------ List of Tables ------------');
        FOR tab in gFragList.first .. gFragList.last
        LOOP
            if (gFragList(tab).segment_type = 'TABLE') then
                -- Generate a TABLE report line.
                formatLine(piObjectType => gFragList(tab).segment_type,
                           piObjectName => gFragList(tab).tabname,
                           piMessage    => '% Full Blocks: ' 
                                           || to_char(gFragList(tab)."% FULL BLOCKS", '990.99'));
                           
            else
                -- Generate a PARTITION report line pair.
                formatLine(piObjectType => 'TABLE',
                           piObjectName => gFragList(tab).tabname);
                
                formatLine(piObjectType => 'PARTITION',
                           piObjectName => gFragList(tab).partname,
                           piMessage    => '% Full Blocks: ' 
                                           || to_char(gFragList(tab)."% FULL BLOCKS", '990.99'));
            end if;

        END LOOP;
        dbms_output.put_line(gSepLine || gLineFeed);        
    end;
    

    
--==============================================================================================================================    
-- This is the main control procedure for the package. Call here to list any fragmentation, 
-- generate SQL commands to defrag the tables, partitions and indexes - local or global and
-- to gather stats on the objects after reqorganising. The generated SQL commands can optionally
-- be executed automatically, or, listed for manual execution by the DBA.
--==============================================================================================================================    
    procedure frag_control(piExecuteCommands in boolean default false)
    is
    begin
        -- Validate parameter(s).
        if (piExecuteCommands is null) then
            gExecuteCommands := false;
        else
            gExecuteCommands := piExecuteCommands;
        end if;
        
        -- Make sure we don't run out of buffer space for listing our output.
        dbms_output.enable(4000000);
        
        -- Display the Fragmentation Report first.
        dbms_application_info.set_module('FRAGO', 'FRAG_REPORT');
        frag_report;
        dbms_application_info.set_action('FRAG_REPORT Complete');

        -- Showe no errors have occurred.
        gErrorsDetected := false;
        
        -- Generate the SQL to reorganise the tables and partitions.
        -- Also generates code to gather stats on the affected objects.
        -- The SQL is not executed yet, only written to the two lists.
        dbms_application_info.set_action('SQL Generation');
        generateSQL;
        dbms_application_info.set_action('SQL Generation Complete');

        -- Execute (or not) the reorg commands first:
        for indx in gReorgSQL.first .. gReorgSQL.last 
        loop
            execOrDisplay(piCommand => gReorgSQL(indx),
                          piExecute => gExecuteCommands);
        end loop;
        
        pl(gLineFeed || gSepLine || gLineFeed);
        
        -- Show that the reorg is completed, but stats are gathering.
        dbms_application_info.set_action('Reorg Complete. Now gathering Stats');
        
        
        -- Execute (or not) the gather stats commands in a block.
        for indx in gStatsSQL.first .. gStatsSQL.last 
        loop
            execOrDisplay(piCommand => gStatsSQL(indx),
                          piExecute => gExecuteCommands);
        end loop;     
        
        -- Finish reporting progress.
        dbms_application_info.set_module(NULL, NULL);
        
        -- Any Errors?
        if (gErrorsDetected) then
            pl(gLineFeed || gSepLine);
            pl('ERRORS DETECTED: Please check output log for details.');
            pl(gSepLine || gLineFeed);   
            
            -- Send an email
            sendEmail;
        end if;

    end;
    
--==============================================================================================================================    
    
END PKG_FRAG;