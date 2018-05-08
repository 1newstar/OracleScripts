create or replace package body pnet.billionParcel as

    --====================================================================================
    -- INTERNAL FUNCTIONS - only callable from getPartitionByKey() below.
    --====================================================================================
    
    --------------------------------------------------------------------------------------
    -- An internal function to return the partition name for a given date.
    -- All (?) PNET tables are partitioned on a date or timestamp column
    -- so this works.
    --
    -- The code used brute force to attempt to determine the partition by comparing
    -- the date required against the HIGH_VALUE for each partition on the table. The
    -- first partition with a HIGH_VALUE value greater than the date required is the
    -- partition we need.
    --
    -- Called internally when getPartitionForKey(), below, fails due to there being 
    -- no rows in the appropriate partition.
    --------------------------------------------------------------------------------------    
    function getPartitionForKeyUsingForce(
        piTableName in all_tables.table_name%type,
        piDateKey in varchar2 := 'dd/mm/yyyy'
    ) 
    return varchar2
    as
        -- Convert the partition HIGH_VALUE into a DATE.
        vHighValue      date;
        
        -- The date we are interested in. Conversion of
        -- piDateKey to an actual DATE.        
        vDate           date;
        
        -- Varchar used to 'convert' the HIGH_VALUE from a LONG data
        -- type to a VARCHAR we can slice and dice etc.
        vLongToVarchar  varchar2(200);
        
        -- An SQL statement that converts vLongToVarchar from text to
        -- a DATE in vHighValue.
        vSQL            varchar2(500);
        
    begin
        -- Convert the requested date, once, not in a loop.
        vDate := to_date(piDateKey, 'dd/mm/yyyy');
        
        -- Get the partitions for the table we are looking at.
        for thisPartition in (
            select  partition_name, high_value
            from    dba_tab_partitions
            where   table_owner = 'PNET'
            and     table_name = piTableName
            order   by partition_position)
        loop
            -- Convert a LONG to a VARCHAR2 for testing. We can do this easily
            -- in PL/SQL, but not, sadly, in plain SQL. Sigh.
            vLongToVarchar := thisPartition.high_value;
            
            -- Only those with TO_DATE or TIMESTAMP as the high value.
            if (vLongToVarchar not like 'TO_DATE%' and
                vLongToVarchar not like 'TIMESTAMP%') then
                continue;
            end if;
            
            -- TIMESTAMP needs to be 'TO_DATE' and brackets adding.
            -- So, TIMESTAMP' 2017-09-01 00:00:00' ... 
            -- ... becomes TO_DATE('2017-09-01', 'yyyy-mm-dd')
            if (vLongToVarchar like 'TIMESTAMP%') then 
                -- Lose the time part and add the date format string.
                vLongToVarchar := replace(vLongToVarchar, ' 00:00:00', ''', ''yyyy-mm-dd');

                -- 'TO_DATE', opening and closing brackets.
                vLongToVarchar := replace(vLongToVarchar, 'TIMESTAMP'' ', 'TO_DATE(''') || ')';
            end if;
                                 
            -- Convert high_value to a date or a timestamp.
            begin
                vSQL := 'select ' || vLongToVarchar || ' from dual';
                execute immediate vSQL into vHighValue;
                
            exception
                -- re-raise exceptions explicitly.
                when others then raise;
            end;
                
            -- We have a date, check it out. If the partition's HIGH_VALUE is
            -- higher than our date, then this is our partition.
            if (vHighValue > vDate) then
                -- Result! We have a partition for our date.
                return thisPartition.partition_name;
            end if;
        end loop;
        
        -- No partition found, getPartitionForKey() handles NULLs.
        return NULL;
    end;

    
    --====================================================================================
    -- PUBLICALLY VISIBLE, AND CALLABLE, FUNCTIONS
    --====================================================================================
    

    --------------------------------------------------------------------------------------
    -- A function to return the partition name for a given date.
    -- All (?) PNET tables are partitioned on a date or timestamp column
    -- so this works.
    --
    -- The code tries to do it via a rowid, which is efficient, but if that doesn't
    -- work because a partition has zero rows in it, we resort to brute force! If that
    -- also fails "*****" will be returned.
    --------------------------------------------------------------------------------------
    
    function getPartitionForKey(
        piTableName in all_tables.table_name%type,
        piDateKey in varchar2 := 'dd/mm/yyyy'
    ) 
    return varchar2
    as
        vTableName          all_tables.table_name%type;
        vPartitionId        all_objects.data_object_id%type;
        vPartitionedColumn  all_part_key_columns.column_name%type;
        vPartitionName      all_objects.subobject_name%type;
        vPartitionKeyCount  number;
        vSQL                varchar2(500);
        
    begin
        -- Bale out if the table or date is null.
        if (piDateKey is null or piDateKey = 'dd/mm/yyyy' or piTableName is null ) then
            raise_application_error(-20001, 'Date or tablename cannot be null.');
        end if;
        
        -- Make sure the tablename is uppercase.
        vTableName := upper(piTableName);
        
        -- Get the column that the table is partitioned on.
        -- First, the count, we can't cope with multi-columns.
        select  count(*)
        into    vPartitionKeyCount
        from    all_part_key_columns
        where   owner = 'PNET'
        and     name = vTableName;
        
        -- One column only allowed. Not less, not more.
        if (vPartitionKeyCount <> 1) then
            raise_application_error(-20002, 'Too many columns (' || to_char(vPartitionKeyCount) || ').');
        end if;
        
        -- Get the column we are partitioned on.
        select  column_name
        into    vPartitionedColumn
        from    all_part_key_columns
        where   owner = 'PNET'
        and     name = vTableName;
        
        -- Build a statement to get the partition Id.
        vSQL := 'select dbms_rowid.rowid_object(rowid)' ||
                ' from pnet.' || vTableName  ||
                ' partition for (to_date(''' || piDateKey || ''', ''dd/mm/yyyy''))' ||
                ' where rownum = 1';
              
        -- Execute it. Raise exception on errors.
        -- If there are no rows in the proposed partition, NO_DATA_FOUND will
        -- be raised.
        begin
            execute immediate vSQL
            into vPartitionId;
        exception
            -- Proposed partition has no rows.
            when no_data_found then
                -- Try brute force! Partition has no rows therefore, no rowids.
                -- If we get NULL back, we have no idea what partition to delete from.
                vPartitionName := getPartitionForKeyUsingForce(
                    piTableName => vTableName,
                    piDateKey => piDateKey
                );
                
                if(vPartitionName is null) then
                    return '*****';
                end if;
                
                -- We have a partition.
                return vPartitionName;
                
            -- Anything else is bad news.
            when others then
                raise;
        end;
        
        -- Fetch the actual partition name.
        select  subobject_name
        into    vPartitionName
        from    all_objects
        where   owner = 'PNET'
        and     object_name = vTableName
        and     data_object_id = vPartitionId;
        
        -- Send it back to the caller.
        return vPartitionName;
    end;
   
    
    --------------------------------------------------------------------------------------
    -- A procedure to delete anything older than a certain number of months ago "this 
    -- week". This will delete the rows from the partitioned tables ONLY. 
    --
    -- This should be run weekly, as there are around 9-10 million rows per week, off 
    -- peak, in the PCL table itself. PCL_PROG has many more than this. Peak is obviously
    -- a lot higher. 
    --------------------------------------------------------------------------------------

    procedure housekeepPartitions(
        piMonthsToKeep in number := 13,
        piExecute in boolean := true
    )
    as
        -- Exactly 13 months ago from the start of "this" week.
        vFirstDayToKeep     date;
        
        -- Exactly 13 months and one day ago from the start of "this" week.
        vLastDayToDelete    date;
        
        -- Which table are we deleting data from?
        vDeleteTable        all_tables.table_name%type;
        
        -- Which partition on the table will we delete from. This is the
        -- one in which vLastDayToDelete lives.
        vDeletePartition    all_tab_partitions.partition_name%type;
        
        -- Which partition on the table will we not be deleting from. This is the
        -- one in which vFirstDayToKeep lives.
        vKeepPartition      all_tab_partitions.partition_name%type;
        
        -- How many columns is the table partitioned on?
        vPartitionColumns   number;
        
        -- Which column is the table partitioned on?
        vPartitionKey       all_part_key_columns.column_name%type;
        
        -- WHERE clause for the DELETE statement, if required. It will be required
        -- if vDeletePartition is the same as vKeepPartition, which it will be most
        -- of the time. The first week in the month shouldn't need one if the 
        -- partition holds a single month only. Some don't, and have more months.
        vDeleteWhere        varchar2(100);
        
        -- The full DELETE statement that will be executed.
        vDeleteStatement    varchar2(500);
        
        -- The start of the DELETE SQL Statement. Because PNET.PCL uses a weird index
        -- to read the rows to delete, we force a full scan (much quicker) and
        -- use 10 parallel sessions, if applicable.
        vDeleteSQL          constant varchar2(100) := 
                'delete /*+ full(t) parallel(t, 10) */ from pnet.';
         
    begin
        -- Calculate the first date to be kept and the last date to be deleted.
        -- We keep everything from 13 months ago "this week" by default and 
        -- delete everything up to and including the day previous to that date.
        --vFirstDayToKeep := add_months(trunc(sysdate, 'MON'), -(piMonthsToKeep));
        vFirstDayToKeep := add_months(trunc(sysdate, 'W'), -(piMonthsToKeep));
        vLastDayToDelete := vFirstDayToKeep -1;
        
        -- Tell the user what's going on. (If they are interested!)
        dbms_output.put_line('Deleting all rows up to, and including: ' || to_char(vLastDayToDelete, 'dd/mm/yyyy'));
        
        -- Get a list of PNET owned tables where there is a PCL_ID column
        -- and the table is partitioned, and not in the recycle bin, and
        -- is not an error table for bulk loads (MERGEs) etc. 
        for fTable in (
            select  c.table_name
            from    dba_tab_columns c
            join    dba_tables t
                on (t.owner = c.owner and t.table_name = c.table_name)
            where   c.column_name = 'PCL_ID'
            and     c.owner = 'PNET'
            and     c.table_name not like 'BIN$%'
            and     c.table_name not like 'ERR$%'
            and     t.partitioned = 'YES'
            order   by 1)
        loop
            -- Grab the table name.
            vDeleteTable := fTable.table_name;
            
            begin
                -- Find the partition we are keeping.
                vKeepPartition := getPartitionForKey(
                    piTableName => vDeleteTable,
                    piDateKey =>  to_char(vFirstDayToKeep, 'dd/mm/yyyy')
                );
                
                -- Find the one we are deleting from.
                vDeletePartition := getPartitionForKey(
                    piTableName => vDeleteTable,
                    piDateKey =>  to_char(vLastDayToDelete, 'dd/mm/yyyy')
                );
            
            exception
                -- Explicitly propogate the exception out to our caller.
                when others then
                    dbms_output.put_line(sqlerrm);
                    raise;
            end;

            -- We got here safely then!
            -- Are any of the partitions devoid of rows?
            if (vKeepPartition = '*****' or
                vDeletePartition = '*****') then
                dbms_output.put_line(
                    'The ''keep'' or ''delete'' partition for ' || 
                    to_char(vFirstDayToKeep, 'dd/mm/yyyy') ||
                    ' has no rows and therefore cannot be obtained.'
                 );
                 
                 -- Ignore this table if we cannot get a partition.
                 continue;                 
            end if;
            
            -- Different partitions don't need a WHERE clause.
            -- Assume this to be the case.            
            vdeleteWhere := ';';
            
            -- But check anyway!
            if (vKeepPartition = vDeletePartition) then
                -- We need a WHERE clause that refers to the partition key
                -- column, singular! We cannot do this if there are more
                -- than one partition key column.
                select  count(*)
                into    vPartitionColumns
                from    all_part_key_columns
                where   owner = 'PNET'
                and     name = vDeleteTable;    -- Yes, 'name', not 'table_name'!
                
                -- Only 1 column?
                if (vPartitionColumns <> 1) then
                    dbms_output.put_line(
                        vDeleteTable || ' is partitioned on ' ||
                        to_char(vPartitionColumns) || ' columns. ' ||
                        ' Cannot continue with this table.' 
                    );
                    
                    -- Ignore this table.
                    continue;                    
                end if;
                
                -- One column is good. Which one is it?
                select  column_name
                into    vPartitionKey
                from    all_part_key_columns
                where   owner = 'PNET'
                and     name = vDeleteTable;    -- See above!
                
                -- Build a WHERE clause. I know that vFirstDayToKeep
                -- is a DATE, but I can't pass a DATE into a statement, so I need
                -- to convert (here) to a string and back (there) to a DATE again.
                vDeleteWhere := ' where ' || vPartitionKey ||
                                ' < to_date(''' || 
                                to_char(vFirstDayToKeep, 'dd/mm/yyyy') || 
                                ''', ''dd/mm/yyyy'');';
            end if;
            
            -- Build the SQL to do the deletions.
            vDeleteStatement := vDeleteSQL || vDeleteTable ||
                                ' partition (' || vDeletePartition || ') t' ||
                                vDeleteWhere;
                                
            -- And finally, execute it, if required.
            if (piExecute) then
                begin
                    execute immediate vDeleteStatement;
                exception
                    -- Explicitly re-raise any exceptions.
                    when others then raise;
                end;
            else    
                -- Otherwise, just display the SQL.
                dbms_output.put_line(vDeleteStatement);
            end if;
            
        end loop;
        
    end;
end;