create or replace package normSearch  as

    -- Pipelined functions need a table type to return results.
    type tSqlStatement is table of varchar2(1024);
    
    -- Text search function. Only CHAR, VARCHAR2 or NVARCHAR2 columns
    -- are searched.
    --
    -- CALLING CONVENTIONS:
    --
    --      select * from table(normsearch.textsearch('USER1', 'ABXZY'));
    --
    --      select * from table(normsearch.textsearch('USER1', 'ABXZY'), '%LIKE_ME%');
    --
    --      select * from table(normsearch.textsearch('USER1', 'ABXZY', '%LIKE_ME%', 'Y'));
    --
    -- NOTES:
    --
    -- ALL_TABLES is searched for table_names. ALL_TAB_COLUMNS is searched
    -- for column names, so you can search another user's tables, however, 
    -- your calling user must have SELECT privilege granted otherwise they
    -- won't be found in ALL_TABLES/ALL_TAB_COLUMNS. (At least, SELECT that
    -- is.)
    --
    -- OWNER is NOT case sensitive. It will be uppercased by the code.
    --       It cannot be NULL. If it is, error code -20000 will be raised.
    --
    -- SEARCHFOR cannot be NULL. It IS case sensitive. Any textual
    --       column in the database that CONTAINS this text will be
    --       returned. Error code -20001 is returned if the search text
    --       is NULL.
    --
    -- TABLEFILTER is NOT case sensitive, in case you have lower and/or
    --       mixed case table names. Sigh! This is not a wildcard filter
    --       whatever you type here will be used to filter table names
    --       so if you want a wildcard, then you supply the '%' as you
    --       reguire. The default is ALL tables.
    --
    -- DEBUG is NOT case sensitive but it must be Y or  or NULL. NULL is
    --       considered to be the same as N. Setting this to Y will cause
    --       lots of useful(?) debugging information to be output using
    --       DBMS_OUTPUT. Up to 1 million chracters are permitted.
    --       -20002 is returned if the value is not Y or N.
    --       The default is no debugging (N).
    
    function textSearch(    
        pOwner in all_tables.owner%type,
        pSearchFor in varchar2,
        pTableFilter in varchar2 default '%',
        pDebug in varchar2 default 'N'
    ) return tSqlStatement pipelined;    

end;
/
