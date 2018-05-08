create or replace PROCEDURE hermes_mi_admin.frag_rebuild (
    -- p_run_stats char default 'N',
    p_execute_commands char default 'N')
IS
    -- ---------------------------------------------------------------------------
    -- Author: Yogesh Mistry
    -- Date:  16/03/2016
    -- Aim:  To generate rebuild/gather stats scripts for tables/indexes which 
    --       require rebuilds 
    -- Dependencies:  procedure:  hermes_mi_admin.frag_analysis  ( run this first)
    --                function: hermes_mi_admin.current_month
    --                tables:   hermes_mi_admin.frag_report (& frag_report_analysis) 
    --                view:     hermes_mi_admin.frag_view
    -- ---------------------------------------------------------------------------
    -- Date:   26/01/2018
    -- Author: Norman Dunbar (Contract DBA) 
    -- Aim:    Tidy up code.
    --         Always generate GATHER_STATS commands.
    --         Execute generated SQL automatically, on request.
    -- ---------------------------------------------------------------------------

    TYPE frag_list IS TABLE OF frag_view%ROWTYPE;
    TYPE part_type is TABLE OF DBA_TAB_PARTITIONS%ROWTYPE;
    TYPE table_type is TABLE OF DBA_TABLES%ROWTYPE;    
    TYPE sql_commands is TABLE OF VARCHAR2(4000) index by pls_integer;

    l_frag frag_list;
    global_indexes_count    NUMBER;
    l_stats_list sql_commands;
    l_stats_index pls_integer;
    l_reorg_commands sql_commands;
    l_reorg_index pls_integer;
    --l_run_stats CHAR(1);
    l_execute_commands char(1);

    -- Some tabs for the report. Not sure why?
    twoTabs CHAR(2) := chr(9) || chr(9);
    nineTabs CHAR(9) := twoTabs || twoTabs || twoTabs || twoTabs || chr(9);

    -- A separator line for the reorg scripts generated.
    lineFeed constant char(1) := chr(10);
    sepLine constant varchar2(71) := rpad('-', 69, '-');

--==============================================================================================================================

    -- -------------------------------------------------------------------------
    -- A couple of useful "helper" procedures, split out from the main code
    -- for better readability. They do one thing each.
    -- -------------------------------------------------------------------------

--==============================================================================================================================

    -- -------------------------------------------------------------------------
    -- Produce the fragmentation report based on a passed in rows from the
    -- FRAG_VIEW view.
    -- -------------------------------------------------------------------------
    procedure listFragmentation(piList in frag_list)
    is
    begin
        DBMS_OUTPUT.put_line ('-- Total number of fragmented tables (i.e. full blocks % <= 50): ' || piList.COUNT);

        dbms_output.put_line('------------ List of Tables ------------');
        FOR tab in 1 .. piList.COUNT
        LOOP

            if (piList(tab).segment_type='TABLE') then
                dbms_output.put_line('-- '
                                     || piList(tab).SEGMENT_TYPE
                                     || ': ' 
                                     || piList(tab).TABNAME
                                     || nineTabs
                                     || '  %Full Blocks: '
                                     || piList(tab)."% FULL BLOCKS");

                /*
                dbms_output.put_line(piList(tab).SEGMENT_TYPE 
                                    || ': '
                                    || piList(tab).TABNAME
                                    || '  %Full Blocks: '
                                    || piList(tab)."% FULL BLOCKS");
                */

                else
                dbms_output.put_line('-- TABLE: ' 
                                    || piList(tab).TABNAME);
                                      
                dbms_output.put_line('-- PARTITION:  ' 
                                    || piList(tab).PARTNAME 
                                    || twoTabs 
                                    || '  %Full Blocks: ' 
                                    || piList(tab)."% FULL BLOCKS");
            end if;

        END LOOP;
        dbms_output.put_line(sepLine || lineFeed);
    end;

--==============================================================================================================================

    -- -------------------------------------------------------------------------
    -- Create's an SQL statement to reorganise a table.
    -- -------------------------------------------------------------------------
    procedure reorgTable (piRow in frag_view%ROWTYPE)
    is
        -- SQL statement to do the reorg and/or stats gathering.
        vSQL varchar2(4000);

    begin
        dbms_output.put_line('-- TABLE: '
                 || piRow.tabname);
                 
        dbms_output.put_line(sepLine || lineFeed);

        dbms_output.put_line('-- Table: '
                 || piRow.tabname
                 || ' -- Size (MB): '
                 || piRow."SIZE (MB)");

        /*                             
        dbms_output.put_line('-- Weighting: '
                 || piRow.weight
                 || ' -- % Partially Empty Blocks: '
                 || piRow."% OF PARTIALLY EMPTY BLOCKS");
        */

        dbms_output.put_line('-- Partially used blocks: '
                 || piRow."PARTIALLY_USED BLOCKS");
                 
        dbms_output.put_line('-- Percentage of highly fragmented blocks: '
                 || piRow.weight
                 || '%');
                 
        dbms_output.put_line('-- Formatted Blocks: '
                 || piRow.FORMATTED_BLOCKS);
                 
        dbms_output.put_line('-- Full Blocks: '
                 || piRow.full_blocks
                 || ' -- %Full Blocks: '
                 || piRow."% FULL BLOCKS");
                 
        dbms_output.put_line(sepLine);

        -----------------------------------------------------
        -- Build the statement to do the reorg of the table.
        -----------------------------------------------------
        vSQL := ('ALTER TABLE '
                || piRow.OWNER
                || '.'
                || piRow.tabname
                || ' MOVE PARALLEL ;'
                || chr(10)
                || ' ');

        ----------------------------------------------
        -- Display & Append the reorg SQL to the list.
        ----------------------------------------------
        dbms_output.put_line(vSQL);
        l_reorg_commands(l_reorg_index) := vSQL;
        l_reorg_index := l_reorg_index + 1;

        ------------------------------------
        -- And then do any affected indexes.
        ------------------------------------
        FOR i_part in (  
        SELECT  I.OWNER,
                I.INDEX_NAME,
                DEGREE
        from    DBA_INDEXES I
        where   table_name = piRow.tabname 
        and     owner = piRow.OWNER)
        LOOP
            vSQL := 'ALTER INDEX '
            || i_part.OWNER
            || '.'
            || i_part.INDEX_NAME
            || ' REBUILD PARALLEL '
            || case 
                  when trim(i_part.DEGREE) <> 'DEFAULT' 
                       then trim(i_part.DEGREE) 
                  else '' 
               end
            || ';';

            ----------------------------------------------
            -- Display & Append the reorg SQL to the list.
            ----------------------------------------------
            dbms_output.put_line(vSQL);
            l_reorg_commands(l_reorg_index) := vSQL;
            l_reorg_index := l_reorg_index + 1;
        END LOOP;

       -- IF l_run_stats = 'Y' THEN           
            vSQL := 'exec dbms_stats.gather_table_stats(ownname => '''
            || piRow.OWNER
            || ''' ,tabname => '''
            || piRow.tabname
            || ''', cascade => TRUE, degree => 2);';

            ----------------------------------------------
            -- Append the stats gathering SQL to the list.
            ----------------------------------------------
            l_stats_list(l_stats_index) := vSQL;
            l_stats_index := l_stats_index + 1;
           -- END IF;
    end;

--==============================================================================================================================

    -- -------------------------------------------------------------------------
    -- Create's an SQL statement to reorganise a table's partition.
    -- -------------------------------------------------------------------------
    procedure reorgPartition (piRow in frag_view%ROWTYPE)
    is
        -- SQL statement to do the stats gathering.
        vSQL varchar2(4000);

    begin
        dbms_output.put_line(chr(10)
                 || '-- TABLE: '
                 || piRow.tabname
                 || '    PARTITION: '
                 || piRow.partname);
                 
        dbms_output.put_line(sepLine || lineFeed);

        dbms_output.put_line('-- Table Partition: '
                 || piRow.tabname
                 || ' -- Size (MB): '
                 || piRow."SIZE (MB)");
        /*                             
        dbms_output.put_line('-- Weighting: '
                 || piRow.weight
                 || ' -- % Partially Empty Blocks: '
                 || piRow."% OF PARTIALLY EMPTY BLOCKS");
        */        
        dbms_output.put_line('-- Partially used blocks: '
                 || piRow."PARTIALLY_USED BLOCKS");
                 
        dbms_output.put_line('-- Percentage of highly fragmented blocks: '
                 || piRow.weight||'%');
                 
        dbms_output.put_line('-- Formatted Blocks: '
                 || piRow.FORMATTED_BLOCKS);
                 
        dbms_output.put_line('-- Full Blocks: '
                 || piRow.full_blocks
                 || ' -- %Full Blocks: '
                 || piRow."% FULL BLOCKS");
                 
        dbms_output.put_line(sepLine || lineFeed);

        -------------------------------------------------
        -- Build an SQL statement to reorg the partition.
        -------------------------------------------------
        vSQL := 'ALTER TABLE '
        || piRow.owner
        || '.'
        || piRow.tabname
        || ' MOVE PARTITION '
        || piRow.partname 
        || ' parallel ;'
        || chr(10)
        || ' ';

        ----------------------------------------------
        -- Display & Append the reorg SQL to the list.
        ----------------------------------------------
        dbms_output.put_line(vSQL);
        l_reorg_commands(l_reorg_index) := vSQL;
        l_reorg_index := l_reorg_index + 1;

        ------------------------------------
        -- And then do any affected indexes.
        ------------------------------------
        FOR i_part in (   select  ip.index_owner, ip.partition_name, ip.index_name, degree
                from    DBA_TAB_PARTITIONS TP, 
                        DBA_IND_PARTITIONS IP, 
                        DBA_INDEXES I
                where   I.OWNER = IP.INDEX_OWNER 
                AND     I.INDEX_NAME = IP.INDEX_NAME 
                AND     I.TABLE_NAME = TP.TABLE_NAME 
                AND     I.TABLE_OWNER = TP.TABLE_OWNER
                and     ip.partition_name = tp.partition_name
                and     ip.partition_name in (
                        select  partname 
                        from    frag_view 
                        where   segment_type = 'TABLE PARTITION' 
                        and     tabname = piRow.tabname 
                        and     owner = piRow.owner)
            )        
        LOOP
            vSQL := 'ALTER INDEX '
                 || i_part.index_owner 
                 || '.'
                 || i_part.index_name
                 || ' REBUILD PARTITION '
                 || i_part.partition_name
                 || ' parallel '
                 || case 
                       when trim(i_part.DEGREE) <> 'DEFAULT' 
                            then trim(i_part.DEGREE) 
                       else '' 
                    end  
                 || ';';  

            ----------------------------------------------
            -- Display & Append the reorg SQL to the list.
            ----------------------------------------------
            dbms_output.put_line(vSQL);
            l_reorg_commands(l_reorg_index) := vSQL;
            l_reorg_index := l_reorg_index + 1;
        END LOOP;

        select  count(*) 
        into    global_indexes_count    
        from    dba_indexes
        where   table_name in ( 
        select  tabname 
        from    frag_view 
        where   tabname = piRow.tabname 
        and     owner = piRow.owner) 
        and     partitioned='NO';

        if (global_indexes_count >0) then
            dbms_output.put_line('sepLine');
            dbms_output.put_line(chr(13)
                            || '----------------------------------------');
            dbms_output.put_line('-- Global Index Partitions --');
            dbms_output.put_line('----------------------------------------');

            FOR g_part in (
                select  I.OWNER ,i.INDEX_NAME,DEGREE
                from    DBA_TAB_PARTITIONS TP, DBA_INDEXES I
                where   I.TABLE_NAME = TP.TABLE_NAME AND I.TABLE_OWNER = TP.TABLE_OWNER
                and     tp.partition_name in (
                            select  partname 
                            from    frag_view 
                            where   tabname = piRow.tabname 
                            and     owner = piRow.owner)
                and     i.partitioned='NO')
            LOOP
                vSQL := 'ALTER INDEX '
                         || g_part.OWNER 
                         || '.'
                         || g_part.INDEX_NAME
                         || ' REBUILD PARALLEL '
                         || case
                                when trim(g_part.DEGREE) <> 'DEFAULT' 
                                     then trim(g_part.DEGREE) 
                                else '' 
                            end  
                         || ';';

                ----------------------------------------------
                -- Display & Append the reorg SQL to the list.
                ----------------------------------------------
                dbms_output.put_line(vSQL);
                l_reorg_commands(l_reorg_index) := vSQL;
                l_reorg_index := l_reorg_index + 1;
            END LOOP;
        end if;      

        --IF l_run_stats ='Y' THEN
            vSQL := 'exec dbms_stats.gather_table_stats(ownname => '''
                  || piRow.owner
                  || ''' ,tabname => '''
                  || piRow.tabname
                  || ''' ,partname => '''
                  || piRow.partname
                  || ''',  granularity => ''PARTITION'', degree => 2);';

            ----------------------------------------------
            -- Append the stats gathering SQL to the list.
            ----------------------------------------------
            l_stats_list(l_stats_index) := vSQL;
            l_stats_index := l_stats_index + 1;
        --END IF; 
    end;

--==============================================================================================================================

    ------------------------------------------------------------------------------
    -- Helper to either execute the passed SQL command, or simply display it 
    -- according to the second parameter passed.
    ------------------------------------------------------------------------------
    procedure execOrDisplay(
        pCommand in varchar2,
        pExecute in char)
    is
        vExecute char(1);
    begin
        -- Did we get something to execute?
        if (pCommand is null) then
            return;
        end if;
            
        -- If pExecute is null, make it 'N'. If it's not in YN
        -- then make it N.
        vExecute := substr(upper(nvl(pExecute, 'N')), 1, 1);
        if (vExecute not in ('Y','N')) then
            vExecute := 'N';
        end if;
        
        -- Display and optionally execute.
        dbms_output.put_line(pCommand);
        if (vExecute = 'Y') then
            -- execute immediate pCommand;
            dbms_output.put_line('EXECUTED: ' || pCommand);
        end if;
        
    exception
        when others then raise;
    end;

--==============================================================================================================================

-- ==============================================================================
-- The main code starts here.
-- ==============================================================================
BEGIN
    ----------------------------------------------------------------------------
    -- Make sure we have a big enough output buffer. From 10g this can be set to
    -- greater than 1 million. Maximum of 1 million BYTES prior to that.
    -- This saves this code from falling over and not generating enough output! 
    ----------------------------------------------------------------------------
    dbms_output.enable(2000000);

    ----------------------------------------------------------------------------
    -- Check run_stats parameter and make upper case. If not = 'Y' and not  'N'
    -- then make it 'N' - the deafult.
    ----------------------------------------------------------------------------
    /*
    l_run_stats := substr(upper(nvl(p_run_stats, 'N')), 1, 1);
    if l_run_stats not in ('Y','N') then
        l_run_stats := 'N';
    end if;
    */

    ----------------------------------------------------------------------------
    -- Check execute_commands parameter and make upper case. If not = 'Y' and 
    -- not  'N' then make it 'N' - the deafult.
    ----------------------------------------------------------------------------
    l_execute_commands := substr(upper(nvl(p_execute_commands, 'N')), 1, 1);
    if l_execute_commands not in ('Y','N') then
        l_execute_commands := 'N';
    end if;

    --------------------------------------------------------------
    -- Grab all rows at once into a collection.
    --------------------------------------------------------------
    SELECT * BULK COLLECT INTO l_frag FROM frag_view ;

    ---------------------------------------------------------------------------- 
    -- First, produce the report listing the various fragmented objects.
    ---------------------------------------------------------------------------- 
    listFragmentation(piList => l_frag);

    ---------------------------------------------------------------------------- 
    -- Make sure the generated script has a big enough buffer for the output.
    ---------------------------------------------------------------------------- 
    dbms_output.put_line('set serveroutput on size unlimited');
    dbms_output.put_line('set feedback off');

    ---------------------------------------------------------------------------- 
    -- Generate code for the table and partition reorgs. Note that fragmented
    -- sub-partitions are not reorganised.
    ---------------------------------------------------------------------------- 
    l_stats_index := 0;     -- Next free slot for stats gathering SQL statements.
    l_reorg_index := 0;     -- Ditto for next reorg SQL statement.

    --FOR indx IN 1 .. l_frag.COUNT
    FOR indx IN l_frag.first .. l_frag.last
    LOOP
        if (l_frag(indx).segment_type='TABLE') then
            reorgTable(piRow => l_frag(indx));
            dbms_output.put_line('exec dbms_output.put_line(''Done '
                         || indx
                         || ' out of '
                         || l_frag.COUNT
                         || ''');');
        elsif (l_frag(indx).segment_type='TABLE PARTITION') then 
            reorgPartition(piRow => l_frag(indx));
            dbms_output.put_line('exec dbms_output.put_line(''Done '
                         || indx
                         || ' out of '
                         || l_frag.COUNT
                         || ''');');
        else
            dbms_output.put_line('Subpartition: ' );
        end if;
    END LOOP;

    --------------------------------------------------------------------------------
    -- Check if we need to run the SQL commands and stats gathering post reorganise.
    --------------------------------------------------------------------------------
    dbms_output.put_line(lineFeed || sepLine || lineFeed);
    if (l_execute_commands = 'Y') then
        -- We wish to execute the generated commands.
        dbms_output.put_line('-- EXECUTING THE FOLLOWING COMMANDS:');
    else
        -- The DBA will execute the generated commands.
        dbms_output.put_line('-- THE FOLLOWING COMMANDS MUST BE EXECUTED MANUALLY:');
    end if;
    dbms_output.put_line(lineFeed || sepLine || lineFeed);

    --
    -- Execute or display the desired SQL statements.
    -- First, the reorganisation SQL commands.
    --
    for indx in l_reorg_commands.first .. l_reorg_commands.last
    loop
        execOrDisplay(l_reorg_commands(indx), l_execute_commands);
    end loop;
    
    --
    -- Then the stats gathering SQL commands.
    --
    for indx in l_stats_list.first .. l_stats_list.last
    loop
        execOrDisplay(l_reorg_commands(indx), l_execute_commands);
    end loop;
END;