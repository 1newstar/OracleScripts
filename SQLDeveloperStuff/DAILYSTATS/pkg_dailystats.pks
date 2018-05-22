CREATE OR REPLACE package DBA_USER.pkg_DailyStats

    -- Make sure that EVERYTHING runs as DBA_USER, regardless of who calls it.
    AUTHID DEFINER
as
    --====================================================================================
    -- PKG_DAILYSTATS: A package to assist in automating the daily statistics gathering
    --                 task which is currently run on a manual basis by the DBA team.
    --====================================================================================
    -- Author: Norman Dunbar
    -- Date: 22/02/2018
    --====================================================================================
    -- HISTORY
    --
    -- Author: Norman Dunbar
    -- Date:   21/03/2018
    -- Change: Added progress reporting via V$SESSION.ACTION.
    --         Added internal analyse & logging procedures.
    --         All databases now submit jobs, not just MISA.
    --         Pretty much a rewrite, in other words!
    --====================================================================================
    --
    -- Types, package variables etc. You'll need these!
    TYPE sql_commands is TABLE OF VARCHAR2(500) 
            index by pls_integer;
            
    SUBTYPE sql_statement is varchar2(500);
    
    TYPE sql_array is table of sql_commands 
            index by pls_integer;
            
    TYPE table_array is table of all_tables.table_name%type
            index by pls_integer;

    -- A collection of SQL commands to gather stats for all appropriate objects.
    -- Also, an index for the next free entry. These commands are
    -- DBMS_STATS.GATHER_XXX_STATS(); only. No BEGIN or END.
    -- Those are added at the execution or display phase.
    gStatsSQL sql_commands;
    gStatsIndex pls_integer;
    
    -- Tables etc that need special handling.
    gSpecialTablesFound boolean;
    gStatsSQLExceptions sql_commands;
    gStatsSpecialIndex pls_integer;
    
    -- List of tables to be treated in a special manner.
    gSpecialTables table_array;
    

    -- There has to be a limit on the number of MISA jobs
    -- that get  created and submitted.

    --------------------------------------------------------------------------------------
    -- Change this value if necessary, but if you make it bigger, you will
    -- need to beware of killing the database with too many jobs.
    --------------------------------------------------------------------------------------
    gMaxMISAJob number := 18;

    --------------------------------------------------------------------------------------
    -- Collections to hold the code lines for each of the scheduler jobs' called
    -- procedures. The load is spread over gMaxMisaJob procedures each of which will have
    -- a number of lines of SQL to execute. The array here holds the commands for each
    -- one of those procedures. (3d Arry?).
    --------------------------------------------------------------------------------------
    ProcedureCode sql_array;

    -- Job and procedure names that we build and submit.
    gJobName constant varchar2(25) := 'DailyStats';
    gProcName constant varchar2(25) := 'DailyStatsProc_';

    gSpecialJobName constant varchar2(25) := 'DailyStatsSpecial';
    gSpecialProcName constant varchar2(25) := 'DailyStatsSpecialProc_';


    -- A procedure to display or execute the gatherings.
    procedure statsControl(
        piDatabase in varchar2,
        piDisplayOnly boolean default false,
        piEnableJobs boolean default false
    );

    -- The procedure that does the actual analysis.
    procedure statsAnalyse(
        piOwner in dba_tab_statistics.owner%type,
        piTableName in dba_tab_statistics.table_name%type,
        piObjectType in dba_tab_statistics.object_type%type,
        piPartitionName in dba_tab_statistics.partition_name%type := null,
        piCascade in boolean := true,
        piDegree in number := 2
    );
    
    -- A procedure to list commands to be run in an emergency to prevent ETL3 overruns.
    procedure emergencyAnalyse(
        piStuckJobname in dba_scheduler_jobs.job_name%type := 'DAILYSTATS000'        
    );

    -- A procedure to exclude a username.
    procedure excludeUsername(
        piUsername in all_users.username%type
    );

    -- A procedure to include a username.
    procedure includeUsername(
        piUsername in all_users.username%type
    );

    -- A procedure to exclude a username.
    procedure reportExcludedUsers;

    -- A procedure to housekeep the daily_stats_log table.
    procedure housekeepStats(
        piDaysToKeep in number := 31
    );
end;
/