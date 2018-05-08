CREATE OR REPLACE package body DBA_USER.pkg_DailyStats as
    --====================================================================================
    -- PKG_DAILYSTATS: A package to assist in automating the daily statistics gathering 
    --                 task which is currently run on a manual basis by the DBA team.
    --====================================================================================
    -- Author: Norman Dunbar
    -- Date:   22/02/2018
    --====================================================================================
    -- HISTORY
    --
    -- Author: Norman Dunbar
    -- Date:   13/03/2018
    -- Change: Added progress reporting via V$SESSION.ACTION.
    --         Added internal analyse & logging procedures.
    --         All databases now submit jobs, not just MISA.
    --         Pretty much a rewrite, in other words!
    --
    -- Author: Norman Dunbar
    -- Date:   19/04/2018
    -- Change: Table F_C2C_C2B_SOS takes forever as it has 82 indices. If this
    --         table is selected for stats gathering, run it as a separate job
    --         with a higher parallelism. Suggest 8 to begin with.            
    --====================================================================================

    --====================================================================================
    -- Helper procedures and functions that cannot be called from outside of the body.
    --====================================================================================

    --------------------------------------------------------------------------------------
    -- Quick, low typing overhead, method to call DBMS_OUTPUT.
    --------------------------------------------------------------------------------------
    procedure pl(
        piMessage in varchar2 default null
    )
    is
    begin
        dbms_output.put_line(piMessage);
    end;

    --------------------------------------------------------------------------------------
    -- A procedure to (autonomously) log the details of the just analysed object to a log
    -- table for reference. Hopefully (!) housekeeping will keep around 31 days of data in
    -- the log table.
    --------------------------------------------------------------------------------------
    function logStats(
        piStatsLogRecord in daily_stats_log%rowtype
    )
        return number
    is        
        pragma autonomous_transaction;

        vAction varchar2(20);
        vId dba_user.daily_stats_log.id%type;

    begin
        if (piStatsLogRecord.id is null) then
            -- If ID is NULL then we should be INSERTing. return
            -- the new ID to the caller.
            vAction := 'INSERT';
            
            insert  into dba_user.daily_stats_log
            values  piStatsLogRecord
            returning id into vId;
        
        else
            -- We have an ID, it's an UPDATE. return the current 
            -- ID to the caller.
            vAction := 'UPDATE ID = ' || trim(to_char(piStatsLogRecord.id)); 

            update dba_user.daily_stats_log
            set endtime = piStatsLogRecord.endtime,
                error_message = piStatsLogRecord.error_message
            where id = piStatsLogRecord.id
            returning id into vId;
        end if;
        
        -- INSERT or UPDATE worked. Return ID to caller.
        commit;
        return vId;
        
    exception
        when others then 
            pl('LOGSTATS(' || vAction || '): ' || sqlerrm);
            raise;
    end;


    --------------------------------------------------------------------------------------
    -- A function to return true if a table name passed is one of the ones that are to be
    -- treated in a special manner. These tables take far too long to run, so, are to be 
    -- submitted by themselves, as separate jobs. They also get 8 degrees of parallelism
    -- in generateTableSQL().
    --------------------------------------------------------------------------------------
    function isSpecialTable(
        piTableName in all_tables.table_name%type
    ) return boolean
    is
    begin
        for i in gSpecialTables.first .. gSpecialTables.last loop
            if (piTableName = gSpecialTables(i)) then
                return true;
            end if;
        end loop;
        
        -- Nothing special here!
        return false;

    end;    


    --------------------------------------------------------------------------------------
    -- Generate the start of a STATSANALYSE command.
    -- NOTE: We do not wrap the command in BEGIN-END here, that's done later to save PGA.
    --------------------------------------------------------------------------------------
    function generateSQL(    
        piOwner in all_tables.owner%type,
        piTable in all_tables.table_name%type
    ) return sql_statement
    is
    begin
        return 'dba_user.pkg_dailystats.statsAnalyse(piOwner => ''' || piOwner || '''' ||
                                                  ', piTableName => ''' || piTable || '''';
    end;

    --------------------------------------------------------------------------------------
    -- Generates the complete STATSANALYSE command for a table.
    -- NOTE: We do not wrap the command in BEGIN-END here, that's done later to save PGA.
    --
    -- 29/03/2018 F_DELIVERY_PARCEL special case added, needs more than 2 degrees.
    -- 19/04/2018 Special tables added. These get submitted one per job as they take
    --            far too long to run in front of other tables - they overrun usually.
    --------------------------------------------------------------------------------------
    function generateTableSQL(    
        piOwner in all_tables.owner%type,
        piTable in all_tables.table_name%type
    ) return sql_statement
    is
    begin
        -- Special tables need special handling.
        if (isSpecialTable(piTable)) then
            return generateSQL(piOwner, piTable) || ', piObjectType => ''TABLE'', piDegree => 8);';
        end if;

        -- Normal tables are just, well, normal!
        return generateSQL(piOwner, piTable) || ', piObjectType => ''TABLE'');';
    end;


    --------------------------------------------------------------------------------------
    -- Generates the complete STATSANALYSE command for a partition or subpartition.
    -- NOTE: We do not wrap the command in BEGIN-END here, that's done later to save PGA.
    --------------------------------------------------------------------------------------
    function generatePartitionSQL(    
        piOwner in all_tables.owner%type,
        piTable in all_tables.table_name%type,
        piPartition in all_tab_partitions.partition_name%type,
        piGranularity in varchar2
    ) return sql_statement
    is
    begin
        return generateSQL(piOwner, piTable) ||
            ', piPartitionName => ''' ||  piPartition || '''' ||
            ', piObjectType => ''' || piGranularity || ''');';
    end;


    --------------------------------------------------------------------------------------
    -- This is where we build the list of SQL commands to be displayed or executed as
    -- procedures called via some DBMS_SCHEDULER jobs.
    --------------------------------------------------------------------------------------
    procedure buildSQLList(
        piDatabase in varchar2
    )
    is
        vDatabase varchar2(10);
        vSQL sql_statement;
    begin
        -- Is the database present? And correct?
        vDatabase := trim(upper(nvl(piDatabase, 'WRONG_DB!')));
        if (vDatabase not in ('MISA','MYHERMES','RTT','PNET')) then
            raise_application_error(-20000, 'Database name ''' || piDatabase || 
                ''' is incorrect. ''MISA'',''MYHERMES'',''RTT'' or ''PNET'' only.');
        end if;

        -- Make sure we know where the SQL commands will go!
        gStatsIndex := 0;
        gStatsSpecialIndex := 0;
        
        -- Grab a list of tables, partitions and subpartitions that need statistics gathering.
        -- This will select some tables that RTT does not want. This will be remedied below.
        for x in (
            select  owner, table_name, partition_name, subpartition_name, object_type
            from    dba_tab_statistics
            where   object_type in ('TABLE','PARTITION','SUBPARTITION')
            and     stale_stats = 'YES'
            -- Don't try to gather stats on objects with locked stats!
            and     stattype_locked is null                               --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            -- And ignore deleted items.
            and     table_name not like 'BIN$%'
            and     owner not in (
                        select  username
                        from    dba_user.daily_stats_exclusions
                   )
            -- Sort order is by blocks. Biggest first. We will spread the load
            -- later by assigning the SQL to multiple procedures/jobs. (MISA)
            order   by blocks desc
        ) loop
            -- If this is RTT/PNET then we do not want tables with 
            -- 'TRKG' in their names.
            if (vDatabase in  ('RTT','PNET')) then
                if (x.table_name like '%TRKG%') then
                    pl(vDatabase || ': Ignoring: ' || x.owner || '.' || x.table_name);
                    continue;
                end if;
            end if;
            
            -- For any database, if the partition_name is 'NO' then
            -- we don't want this row. This could have gone in the query
            -- above, but was never applied to tables originally, just
            -- partitions and subpartitions. Sticking to old methods!
            if (x.partition_name = 'NO') then
                pl(vDatabase || ': Ignoring partition ' ||  x.owner || '.' || x.table_name || '.' || x.partition_name);
                continue;
            end if;
            
            -- What type of object are we dealing with?
            if (x.object_type = 'TABLE') then
                vSQL := generateTableSQL(piOwner => x.owner, 
                                         piTable => x.table_name);
            else
                -- Can only be PARTITION or SUBPARTITION. 
                vSQL := generatePartitionSQL(piOwner => x.owner, 
                                             piTable => x.table_name, 
                                             piPartition => case when x.object_type
                                                                = 'PARTITION' then x.partition_name
                                                                else x.subpartition_name
                                                            end,
                                             piGranularity => x.object_type                                            
                                             );
            end if;
            
            -- We have the SQL, add it to the appropriate list.
            -- Add to the list of commands to execute for TABLES.
            -- Of course, we might not be executing the code just yet.
            --
            -- CHANGE 19/04/2018 - Handle special tables here.
            if (isSpecialTable(x.table_name)) then
                -- Add it to the exceptions list for special processing.
                gStatsSQLExceptions(gStatsSpecialIndex) := vSQL;
                gStatsSpecialIndex := gStatsSpecialIndex + 1;
                
                -- Set the special table(s) detected flag.
                gSpecialTablesFound := true;
            else
                -- Just a normal table.
                gStatsSQL(gStatsIndex) := vSQL;
                gStatsIndex := gStatsIndex + 1;
            end if; 
        end loop;
        
        pl('There is/are ' || gStatsSQL.count || ' object(s) with stale statistics.' || chr(10));
    end;


    --------------------------------------------------------------------------------------
    -- Job creation. Builds a single DBMS_SCHEDULER jobs to be run 'now' if if the 
    -- enabled parameter is passed in as true. If a job already exists, it will be dropped.
    --------------------------------------------------------------------------------------
    procedure createJob(
        piJobname in varchar2,
        piAction in clob,
        piJobType in varchar2 default 'PLSQL_BLOCK',
        piEnabled in boolean default false
    )
    is 
    begin
        -- Make sure we can create this job. It cannot already exist. We tend to leave the
        -- jobs around as this means that we can see if any errors occurred. Until the
        -- next run, where we drop it of course.
        begin
            dbms_scheduler.drop_job(job_name => piJobname,
                                    force => true);
            pl(piJobname || ' - old job successfully dropped from scheduler.');
        exception
            when others then
                -- Normally frowned upon. But ok here. We don't care if
                -- a job couldn't be dropped because it didn't exist.
                null;                
        end;
        
        -- We are good to create a new job now. Normally a one-off job will drop itself
        -- after execution, however, that means that the run log goes as well. As we
        -- drop the job before the next execution, we leave it around so that the logs
        -- can be checked.
        dbms_scheduler.create_job (
            job_name      =>  piJobname,
            job_type      =>  piJobType,  
            job_action    =>  piAction,  
            start_date    =>  systimestamp at time zone 'UTC',  
            enabled       =>  piEnabled,  
            auto_drop     =>  false,            -- Don't kill the job on completion.
            comments      =>  'Job for daily stats gathering'
        );
        
        if (piEnabled) then
            -- Jobe will be executing right now.
            pl(piJobname || ' Created and submitted for immediate execution.');
        else
            -- Job won't execute until enabled.
            pl(piJobname || ' Created and submitted but execution is suspended until enabled with:');
            pl('exec DBMS_SCHEDULER.ENABLE(''DBA_USER.' || piJobName || ''');'); 
        end if;
    end;
           
           
    --------------------------------------------------------------------------------------
    -- Create a single procedure, and a single job, to execute the stats gathering for ALL
    -- affected objects in RTT/PNET or MYHERMES databases. MISA has its own handling of
    -- this task as it needs a number of jobs due to the volume of changes.
    -- The list of commands is in the gStatsSQL global collection.
    --------------------------------------------------------------------------------------
    procedure createProcedure (
        piProcName in varchar2,
        piJobName in varchar2,
        piList in sql_commands,
        piEnableJobs in boolean := false
    )
    is
            vCPCreate constant varchar2(40) := 'create or replace procedure dba_user.';
            vCPBegin constant varchar2(45) := chr(10) || 'is' || chr(10) || 
                                              '   vErrors boolean := false;' || chr(10) ||
                                              'BEGIN' || chr(10) || '--';
            vCPRunOnly constant varchar2(35) := chr(10) || '-- RUN ONLY FROM SCHEDULER JOB: ';
            vCPDontRun constant varchar2(40) := '-- DO NOT RUN THIS PROCEDURE MANUALLY.' || chr(10);
            vCPCreated constant varchar2(25) := '-- It was created on ';
            vCPReCreated constant varchar2(40) := ' and will be recreated ''tomorrow''' || chr(10) || '--';

            vJobCode clob;
            vProcCode clob;
    begin
        -- Preamble.
        vProcCode := vCPCreate || piProcName ||
                     vCPBegin ||
                     vCPRunOnly || piJobName || '.' || chr(10) ||
                     vCPDontRun ||
                     vCPCreated || to_char(sysdate, 'dd/mm/yyyy') ||
                     ' at ' || to_char(systimestamp at time zone 'utc', 'hh24:mi:ss') ||  
                     vCPReCreated ||
                     '    -- We need a big buffer if there will be (many) errors.' || chr(10) ||
                     '    dbms_output.enable(9e6);' || chr(10); 
                         
        -- The meat and bones of the code. Each call to analyse an object
        -- is wrapped in a begin-exception-end block to enable failures to 
        -- report the problem, but the job will carry on and attempt to 
        -- analyse the remaining objects.
        for task in piList.first .. piList.Last loop
            vProcCode := vProcCode || chr(10) ||
                         '    begin' || chr(10) ||
                         '        ' || piList(task) || chr(10) ||
                         '    exception' || chr(10) ||
                         '        when others then' || chr(10) ||
                         '            dbms_output.put_line(sqlerrm);' || chr(10) ||
                         '            -- Set the error flag to show we hit problems' || chr(10) ||
                         '            vErrors := true;' || chr(10) ||
                         '    end;' || chr(10);
        end loop;    
        
        -- Postamble.
        vProcCode := vProcCode || chr(10) ||
                     '    if (vErrors) then' || chr(10) ||
                     '        raise_application_error(-20003, ''One or more failures in ''''' || piProcName || '''''.'');' || chr(10) ||
                     '    end if;' || chr(10) || chr(10) ||
                     'end;' || chr(10);
                     
                     
        -- Compile the procedure, hopefully there are no errors.
        execute immediate vProcCode;

        -- Create the job to execute the new procedure.
        vJobCode := 'begin ' || chr(10) || 
                    piProcName || '; ' || chr(10) || 
                    'end;' || chr(10);
                      
        createJob(piJobname => piJobName,
                  piAction  => vJobCode,
                  piJobType => 'PLSQL_BLOCK',
                  piEnabled => piEnableJobs);

                      
    exception
        when others then
            pl('CreateProcedure(): ' || sqlerrm);
            raise;
    end;

    --------------------------------------------------------------------------------------
    -- Procedure builder. Builds a temporary procedure that will execute a large
    -- number of SQL commands. These are then called from a scheduler job and 
    -- after execution, are replaced tomorrow.
    -- This is necessary when the SQL commands exceed 4000 characters - the maximum that
    -- a scheduler job is allowed in its command string.
    --------------------------------------------------------------------------------------
    procedure ProcedureBuilder(
        piProcName in varchar2,
        piJobName in varchar2,
        piList in sql_commands,
        piEnableJobs in boolean default false
    )
    is
    begin
        -- Build the job &  procedure code. The entire list is included.
        createProcedure(piProcName => piProcName,
                        piJobName => piJobName,
                        piList => piList,
                        piEnableJobs => piEnableJobs);

    exception
        when others then
            pl('ProcedureBuilder(): ' || sqlerrm);
            raise_application_error(-20002, 'Failed to create one or more procedures');
    end;
        

    --------------------------------------------------------------------------------------
    -- MISA (only) procedure builder. Builds temporary procedures that will execute a
    -- large number of SQL commands. These are then called from a job and after execution,
    -- are deleted. This is necessary when the SQL commands exceed 4000 characters.
    --------------------------------------------------------------------------------------
    procedure misaProcBuilder(
        piEnableJobs in boolean default false
    )
    is
        vHowManyTasks number;
        vHowManyProcs number;
        vHowManyJobs number;
        vMISAJobName varchar2(25);
        vMISAProcName varchar2(30);
        vCreateErrors boolean;
        
        -- We need to have a number of procedures each execution a portion of
        -- The entire list for MISA. The next three variables help in that respect.
        vProcedure number;
        vProcedureTask number;
        vProcedureSQL sql_statement;

    begin
        -- How many tasks are required? And how many jobs/procedures will 
        -- be required? (If there are fewer tasks than gMaxMisaJob.)
        vHowManyTasks := gStatsSQL.count;
        vHowManyProcs := floor(vHowManyTasks / gMaxMISAJob);
        
        -- How many jobs will we need?
        if (vHowManyProcs = 0) then
            -- We have less tasks than gMaxMisaJob, how many jobs?
            -- Obviously, only 1.
            vHowManyJobs := 1;
        else
            -- We definitely have gMaxMisaJob procedures and jobs.
            vHowManyJobs := gMaxMisaJob;
        end if;
        
        
        -- Split into 'gMaxMISAJob' separate jobs and flag no errors, yet!
        --vJobTasks := floor(vHowManyTasks / gMaxMISAJob);   -- Tasks per each job.
        --vSpareTasks := mod(vHowManyTasks, gMaxMISAJob);    -- Spare tasks in final jobs.
        vCreateErrors := false;
        
        -- The tasks are in descending blocks order. Biggest first in other words.
        -- Put the biggest in procedure 0, the next biggest in procedure 1 etc. This
        -- way we can (hopefully) spread the load relatively evenly across all the 
        -- procedures (and scheduler jobs) and avoid overrunning the ETL.
        -- It's a good plan anyway.
        --
        -- Task = running index into the entire list.
        -- vProcedure = running procedure number.
        -- vProcedureTask = running index of SQL within the vProcedure.
        --
        -- EG: with gMaxMisaJob set to 18.
        --
        -- Task 0 goes into Procedure 0 at line 0.
        -- Task 1 ...
        -- Task 17 goes into Procedure 17 at line 0.
        -- ...
        -- Task 18 goes into Procedure 0 at line 1.
        -- Task 19 ...
        -- Task 25 goes into Procedure 2 at line 1.
        --
        -- And so on.
        --
        -- However, if we have less procs/jobs than the max number of jobs,
        -- Then everything goes into job 0.
        if (vHowManyProcs > 0) then
            -- We obviously have more than zero procs/jobs. Split the
            -- task list over the maximum number of jobs.
            pl('MISA: Creating ' || to_char(gMaxMISAJob) || ' procedures and jobs.');
            for task in gStatsSQL.first .. gStatsSQL.last loop
                vProcedure := mod(task, gMaxMisaJob);
                vProcedureTask := floor(task/gMaxMisaJob);
                vProcedureSQL := gStatsSQL(task);
                ProcedureCode(vProcedure)(vProcedureTask) := vProcedureSQL;        
                -- dbms_output.put_line(vProcedureSQL);        
            end loop;
        else
            -- We have less tasks than max jobs, so do everything in one.
            pl('MISA: Creating 1 (only) procedure and job.');
            for task in gStatsSQL.first .. gStatsSQL.last loop
                ProcedureCode(0)(task) := gStatsSQL(task);        
                -- dbms_output.put_line(gStatsSQL(task));        
            end loop;          
        end if;
        
        -- Create procedures and jobs to run them.
        -- Make sure that we had enough tasks to make all the procedures.
        -- EG:
        -- With 18 jobs max, and 9 tasks, we only have 9 procs/jobs.
        -- With 18 jobs max, and 19 tasks, we have 18 procs/jobs.
        -- Now we can build the procedures and submit jobs.
        for thisProcedure in 0 .. vHowManyJobs - 1 loop
                vMISAJobName := gJobName || ltrim(to_char(thisProcedure, '099'));
                vMISAProcName := gProcName || ltrim(to_char(thisProcedure, '099'));    
                pl(chr(10) || 'Creating Procedure/Job: ' || 
                   vMISAProcName || '/' || vMISAJobName);              
                begin 
                    procedureBuilder(
                        piProcName => vMISAProcName,
                        piJobName => vMISAJobName,
                        piList => ProcedureCode(thisProcedure),
                        piEnableJobs => piEnableJobs
                    );
                    
                    pl('Created.');
                exception
                    when others then
                        -- On Exceptions, set a flag, but keep going with other jobs.
                        pl('FAILED.');
                        pl('MisaProcBuilder(): ' || sqlerrm);
                        vCreateErrors := true;
                end;
        end loop; 
                
        -- Were there any errors? If so, raise an exception which
        -- the caller can handle.
        if (vCreateErrors) then
            raise_application_error(-20002, 'Failed to create one or more MISA Proc(s)');
        end if;
    end;


    --************************************************************************************
    --************************************************************************************
    --               The main publicly visible procedures start here.
    --************************************************************************************
    --************************************************************************************

    
    --====================================================================================
    -- USER EXCLUSION/INCLUSION MAINTENACE
    --====================================================================================

    --------------------------------------------------------------------------------------
    -- A procedure to exclude a username from the system. It simply adds the username to
    -- the exclusions table.
    --------------------------------------------------------------------------------------
    procedure excludeUsername(
        piUsername in all_users.username%type
    )
    is
        vUsername all_users.username%type;
    begin
        if (piUsername is not null) then        
            -- Make sure messages are visible.
            dbms_output.enable(6e6);
            
            vUsername := upper(piUsername);
            
            insert  into dba_user.daily_stats_exclusions
            values  (vUsername);
            
            commit;
            
            -- It worked.
            pl(vUsername || ' has been added to the exclusions table.');
        end if;

    exception
        when DUP_VAL_ON_INDEX then
            -- Record already exists.
            pl(vUsername || ' already existed in the exclusions table.');
        when others then raise;
    end;
    
    --------------------------------------------------------------------------------------
    -- A procedure to include a username in the system. It simply deletes the username
    -- from the exclusions table and if it is not there, ignores the error.
    --------------------------------------------------------------------------------------
    procedure includeUsername(
        piUsername in all_users.username%type
    )
    is
        vUsername all_users.username%type;
    begin
        if (piUsername is not null) then
            -- Make sure messages are visible.
            dbms_output.enable(6e6);

            vUsername := upper(piUsername);
            
            delete  from  dba_user.daily_stats_exclusions
            where   username = vUsername;
            
            if sql%notfound then
                -- Nothing deleted
                pl(vUsername || ' was not found in the exclusions table.');
            else
                -- It worked.
                pl(vUsername || ' has been removed from the exclusions table.');
                commit;
            end if;
        end if;

    exception
        when others then raise;
    end;

    --------------------------------------------------------------------------------------
    -- A procedure to list the usernames which are currently excluded from the system.
    --------------------------------------------------------------------------------------
    procedure reportExcludedUsers
    is
    begin
        -- We need to set a big enough buffer here.
        dbms_output.enable(6e6);
        
        for x in (select username
                  from   dba_user.daily_stats_exclusions
                  order  by username)
        loop
            pl(x.username || ' is excluded from the dba_user.pkg_dailyStats processing.');
        end loop;
    end;

    --====================================================================================
    -- STATISTICS GATHERING.
    --====================================================================================

    --------------------------------------------------------------------------------------
    -- A procedure to housekeep the daily stats logging table to keep 31 days of data.
    --------------------------------------------------------------------------------------
    procedure housekeepStats(
        piDaysToKeep in number := 31
    )
    is
        pragma autonomous_transaction;
        vUntil date;
    begin
        vUntil := trunc(sysdate) - piDaysToKeep;
        
        delete  from dba_user.daily_stats_log
        where   startTime < vUntil;
        
        commit;
    exception
        when others then 
            pl('HousekeepStats(): ' || sqlerrm);
            raise;
    end;


--------------------------------------------------------------------------------------
    -- A procedure to update the progress in V$SESSION.ACTION detailing what object we are
    -- in the process of analysing, to do the analysis and to log start and stop times for
    -- the object in the logging table.
    --
    -- Because this is internal, there's no need for validation as all the parameters are
    -- taken from DBA_TAB_STATISTICS and are NOT user supplied.
    --
    -- This code is called from the DBMS_SCHEDULER job, via the one-off Procedure that
    -- was created to execute numerous object statistics gathering. It is NOT called
    -- directly by the interactive session that builds the jobs etc. ALL statistics are
    -- gathered in the scheduler job only.
    --------------------------------------------------------------------------------------
    procedure statsAnalyse(
        piOwner in dba_tab_statistics.owner%type,
        piTableName in dba_tab_statistics.table_name%type,
        piObjectType in dba_tab_statistics.object_type%type,
        piPartitionName in dba_tab_statistics.partition_name%type := null,
        piCascade in boolean := true,
        piDegree in number := 2
    )
    is
        vStatsRecord daily_stats_log%rowtype;
        vOneChar char(1);
        vObjectName varchar2(100);
        vCommand sql_statement;
        
    begin
        -- Object type is T, P or S. Saves typing later on! ;-)
        vOneChar := substr(piObjectType, 1, 1);

        -- We always do this bit...
        vCommand := 'dbms_stats.gather_table_stats(ownname => ''' || piOwner || '''' ||
                                                  ', tabname => ''' || piTableName || ''''; 
        
        -- Build the logging record for the starting time.
        vStatsRecord.ID := null;
        vStatsRecord.owner := piOwner;
        vStatsRecord.table_name := piTableName;
        vStatsRecord.object_type := piObjectType;
        vStatsRecord.partition_name := null; 
        vStatsRecord.subpartition_name := null;
        vStatsRecord.error_message := null;
        vStatsRecord.endtime := null;
        
        -- Figure out what object we are doing.
        if (vOneChar = 'T') Then
            -- It's a Table. No more SQL command to do here.
            vObjectName := piTableName;
        else 
            -- It's a Partition or SubPartition. Update the SQL command.
            vObjectName := piPartitionName;
            vCommand := vCommand || ', partname => ''' || vObjectName || '''' ||
                                    ', granularity => ''' || piObjectType || '''';
                                    
            -- And the logging record.
            if (vOneChar = 'P') then
                vStatsRecord.partition_name := vObjectName;
            else
                vStatsRecord.subpartition_name := vObjectName;
            end if;
        end if;
        
        -- Add on cascade and degree parameters.
        vCommand := vCommand || ', degree => ' || to_char(piDegree) || 
                                ', cascade => ';
        if (piCascade) then
            vCommand := vCommand || 'true);';
        else
            vCommand := vCommand || 'false);';
        end if;
                   
        -- Show the object in the progress indicator.
        dbms_application_info.set_action(vOneChar || ': ' || vObjectName);
        
        -- Get analysis start time.
        vStatsRecord.startTime := sysdate;
        
        -- Log details and start time. Gets back the ID for later.
        vStatsRecord.id := logStats(piStatsLogRecord => vStatsRecord);

        -- Analyse the object. The command will be one or other of the following,
        -- with CASCADE => TRUE and DEGREE => 2:
        --
        -- dbms_stats.gather_table_stats('OWNER', 'TABLE_NAME');
        -- dbms_stats.gather_table_stats('OWNER', 'TABLE_NAME', 'PARTITION_NAME', granularity => 'PARTITION');
        -- dbms_stats.gather_table_stats('OWNER', 'TABLE_NAME', 'SUBPARTITION_NAME', granularity => 'SUBPARTITION');
        --
        pl('EXECUTING: ' || vCommand);
        begin
            execute immediate('BEGIN ' || vCommand || ' end;');
        exception
            when others then
                -- Log the error 
                vStatsRecord.error_message := sqlerrm;
        end;

        -- Get Stop time and log details.
        vStatsRecord.endTime := sysdate;
        vStatsRecord.id := logStats(piStatsLogRecord => vStatsRecord);

    exception
        -- The procedure that called here will catch this.
        when others then
            vStatsRecord.error_message := sqlerrm;
            pl('StatsAnalyse(): ' || vStatsRecord.error_message);
            pl('FAILED: ' || vCommand);
            raise;
    end;


    --------------------------------------------------------------------------------------
    -- The main control code for this package. It works like this:
    --
    -- Build a list of objects that have stale statistics.
    --
    -- If there are none, output a message and exit.
    --
    -- If we are running in manual mode, display the list of commands and exit.
    --
    -- If this is RTT or MYHERMES, submit one job to run a newly created procedure to
    -- gather statistics for the list of affected objects.
    --
    -- If this is MISA, submit numerous jobs to run a newly created procedure each, to
    -- gather statistics for the list of MISA objects.
    --------------------------------------------------------------------------------------
    procedure statsControl(
        piDatabase in varchar2, 
        piDisplayOnly boolean default false,
        piEnableJobs boolean default false
    )
    is
        vDatabase varchar2(10);
    begin
    
        -- Initialise the progress indicator.
        dbms_application_info.set_module('DAILY STATS', 'Initialisation');

        -- Run some initialisation & house keeping.
        housekeepStats;
        vDatabase := trim(upper(piDatabase));
        
        -- CHANGE: 19/04/2018.
        -- Build the list of special tables to be handled separately.
        -- Make sure that the index numbers are consecutive, or carnage will ensue!
        gSpecialTables(0) := 'F_DELIVERY_PARCEL';       -- MISA
        gSpecialTables(1) := 'F_C2C_C2B_SOS';           -- MISA
        gSpecialTables(2) := 'PCL_PROG';                -- RTT

        -- Build the list of 'pkg_dailyStats.statsAnalyse()' commands.
        -- The list is created in the package global gStatSSQL.
        begin
            gSpecialTablesFound := false;
            buildSQLList(piDatabase);
        exception
            when others then
                raise;
        end;
        
        -- Anything to do? 
        if (gStatsSQL.count = 0) then
            pl(piDatabase || ': Nothing to do today.');
            return;
        end if;
        
        
        -- If we are running in display mode, just list the commands.
        if (piDisplayOnly) then
            -- Normally handled objects ...
            for task in gStatsSQL.first .. gStatsSQL.last loop
                begin
                    pl('BEGIN ' || gStatsSQL(task) || ' end;');
                end;
            end loop;   
             
            if (gSpecialTablesFound) then
                -- And special handling required objects ...
                pl(' ');
                for task in gStatsSQLExceptions.first .. gStatsSQLExceptions.last loop
                    begin
                        pl('BEGIN ' || gStatsSQLExceptions(task) || ' end;');
                    end;
                end loop;   
            end if;
             
            return;
        end if;
        
        -- We must be executing, submit one job for RTT/PNET or MYHERMES.
        if (vDatabase <> 'MISA') then
            procedureBuilder(
                piProcName => gProcName || '000',
                piJobName => gJobName || '000',
                piList => gStatsSQL,
                piEnableJobs => piEnableJobs
            );
        else        
            -- We must be in MISA - submit many jobs to do the statistics gathering.
            misaProcBuilder(
                piEnableJobs => piEnableJobs
            );
        end if;
        
        -- Any special jobs? These need handling one by one.
        if (gSpecialTablesFound) then
            pl(' ');
            pl(chr(10) || 'Submitting an additional ' || 
               to_char(gStatsSQLExceptions.count) || 
               ' special job(s) for large tables.' || chr(10));
            pl(' ');
               
            for task in gStatsSQLExceptions.first .. gStatsSQLExceptions.last loop
                declare
                    -- Needs a list for createProcedure.
                    tempList sql_commands;
                    
                begin
                -- Create one procedure for each entry.
                tempList(0) := gStatsSQLExceptions(task);
                createProcedure (
                    piProcName => gSpecialProcName || trim(to_char(task, '009')),
                    piJobName => gSpecialJobName || trim(to_char(task, '009')),
                    piList => tempList,
                    piEnableJobs => piEnableJobs
                );
                end;
            end loop;
        end if;
        
        -- Shut down the progress indicator.
        dbms_application_info.set_module(null, null);

    exception
        when others then
            -- Display actual error message & code.
            pl('StatsControl(): ' || sqlerrm);
            pl(' ');
            
            -- Display how we got to the error.
            pl(dbms_utility.format_error_backtrace);
            pl(' ');
            pl(dbms_utility.format_error_stack);
            pl(' '); 
    end;
    
end;
/