create or replace PACKAGE hermes_mi_admin.PKG_FRAG AS 

    --========================================================================================
    -- PKG_FRAG: A new package to assist in automating the FRAGO daily defragmentation task.
    --========================================================================================
    -- Author: Norman Dunbar - based on original code by Yogesh Mistry.
    -- Date: 26/01/2018
    --========================================================================================
    --
    -- Types, package variables etc. You'll need these!
    TYPE frag_list IS TABLE OF frag_view%ROWTYPE;
    TYPE sql_commands is TABLE OF VARCHAR2(4000) index by pls_integer;
    
    -- Two collections of SQL commands. One to do the reorganisations, one to 
    -- gather stats afterwards. Kept separate so that we can, in emergencies,
    -- abort the stats gathering but ensure all reorganisations are done.
    gReorgSQL sql_commands;
    gReorgIndex pls_integer;
    
    gStatsSQL sql_commands;
    gStatsIndex pls_integer;
    
    -- Collection of data from the FRAG_VIEW view.
    gFragList frag_list;
    
    -- Boolean to determine how progress is reported.
    gExecuteCommands boolean;
    
    -- Boolean to capture if errors occurred.
    gErrorsDetected boolean;
    
    -- A separator line for the reorg scripts generated.
    gLineFeed constant char(1) := chr(10);
    gSepLine constant varchar2(120) := rpad('-', 71, '-');
    
    -- Publically visible procedures etc in the package.
    procedure frag_report;
    procedure frag_control(piExecuteCommands in boolean default false);

END PKG_FRAG;