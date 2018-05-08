create or replace package pnet.billionParcel as

    -- A function to return the partition name for a given date.
    -- All (?) PNET tables are partitioned on a date or timestamp column
    -- so this works.
    --
    -- WARNING: If there are no rows in the partition that the data should
    -- be placed in, "*****" will be returned. A minor niggle.
    function getPartitionForKey(
        piTableName in all_tables.table_name%type,
        piDateKey in varchar2 := 'dd/mm/yyyy'
    ) return varchar2;



    -- A procedure to delete anything older than a certain number of months ago "this 
    -- week". This will delete the rows from the partitioned tables ONLY. 
    --
    -- This should be run **daily**, as there are around 6.5 million rows per day, off 
    -- peak, in the PCL_PROG table itself. During Peak this rises to 115 million per day. 
    procedure housekeepPartitions(
        piMonthsToKeep in number := 13,
        piExecute in boolean := true
    );

end;
