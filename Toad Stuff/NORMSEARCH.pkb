create or replace package body normSearch as

    function textSearch(
        
        pOwner in all_tables.owner%type,
        pSearchFor in varchar2,
        pTableFilter in varchar2 default '%',
        pDebug in varchar2 default 'N'
        
    ) return tSqlStatement pipelined as
    
        -- Owner of the tables to be searched.        
        vOwner all_tables.owner%type;    
        
        -- List of textual columns in each table.
        vColumns clob;
        
        -- WHERE clause for the search.
        vWhereClause clob;
        
        -- A cursor to list columns where the text is found.
        vSearchCursor sys_refcursor;
        
        -- A single column where the text was found.
        vColumnName varchar2(4000);
        
        -- A filter to restrict tables to be searched.
        vTableFilter varchar2(1024);
        
        -- Are we debugging?
        vDebug boolean;
        
        -- A dynamic SQL statement.
        -- Change the size if something barfs!
        --vSQL varchar2(4096);
        vSQL clob;

    begin
        -- Validation first.
        -- Table owner cannot be NULL.The owner might not actually
        -- exist, but that's your problem! ;-)
        if (pOwner is null) then
            raise_application_error(-20000, 'Owner cannot be NULL');
        end if;
        vOwner := upper(pOwner);
            
        -- The search text cannot be NULL either.
        if (pSearchFor is null) then
            raise_application_error(-20001, 'Search text cannot be NULL');
        end if;
        
        -- The table name filter can be NULL though.
        -- We DO NOT uppercase the tablename filter in case we have
        -- case sensitive table names!
        vTableFilter := pTableFilter;
        if (vTableFilter is null) then
            vTableFilter := '%';
        end if;
        
        -- Debugging shouldn't be NULL.
        if (pDebug is null) then
            vDebug := false;
        else            
            if (upper(pDebug) not in ('Y', 'N')) then
                raise_application_error(-20002, 'Debug must be ''Y'' or ''N''.');
            end if;
            
            if (upper(pDebug) = 'Y') then
                vDebug := true;
            end if;        
        end if;
        
        -- Validation is ok, carry on and search. I suspect Tom Kyte is
        -- showing off here! ;-) What's wrong with a plain old VARCHAR2?           
        dbms_application_info.set_client_info( '%' || pSearchFor || '%' );

        if (vDebug) then
            dbms_output.enable(1000000);
            dbms_output.put_line('SEARCH TEXT: ''%' || pSearchFor || '%''');
            dbms_output.put_line('TABLE OWNER: ''' || pOwner || '%''');
            dbms_output.put_line('TABLE NAME FILTER: ''' || vTableFilter || '''');
            dbms_output.put_line(' ');
        end if;
        
        -- Get a list of tables owned by the requested owner.
        for x in ( select   table_name 
                   from     all_tables 
                   where    owner = vOwner
                   and      table_name like vTableFilter
                   order by table_name ) 
        loop 
            -- Loop around each table, building a list of column names
            -- which are of a textual nature, and build a SQL statement to
            -- search each one for the supplied text. This is case sensitive.
            vColumns := q'<case when 1=0 then 'x' >';
            vWhereClause := ' where ( 1=0 ';
            
            if (vDebug) then
                dbms_output.put_line('TABLE: ' || x.table_name);
            end if;

            for y in ( select   column_name 
                       from     all_tab_columns
                       where    table_name = x.table_name
                       and      owner = vOwner
                       and      (data_type in ( 'CHAR', 'NVARCHAR2', 'VARCHAR2' )))
            loop 
                vColumns := vColumns || ' when ' || y.column_name ||
                q'< like sys_context('userenv','client_info') then >' ||
                q'< '>' || y.column_name || q'<'>';
                vWhereClause := vWhereClause || ' or ' || y.column_name || 
                               q'< like sys_context('userenv','client_info') >';
                
                if (vDebug) then
                    dbms_output.put_line('    COLUMN: ' || y.column_name);
                end if;
                
            end loop;
            
            -- Build the SQL...
            vSQL := 'select distinct ' || vColumns || 
                    ' else null end cname from ' || vOwner || '.' ||
                    x.table_name || vWhereClause || ')'; 

            
            if (vDebug) then
                dbms_output.put_line('        QUERY: ' || vSQL);
            end if;
            
             

            -- We have SQL, execute it in a cursor to grab a list of any
            -- column in the current table, which has the required search
            -- text present in it.
            open vSearchCursor for vSQL; 

            -- Loop around the results, returning a single column name 
            -- each time. If we have any results, return an SQL statement
            -- along the lines of:
            -- SELECT * FROM USER.TABLE_NAME WHERE COLUMN_NAME LIKE SEARCH_TEXT;
            loop
                fetch vSearchCursor into vColumnName;
                exit when vSearchCursor%notfound;

                -- This is the bit I love, return the statement as a table row!
                pipe row('select * from "' || vOwner || '"."' || x.table_name || '" where "' || vColumnName || q'<" like '%>' || pSearchFor || q'<%';>');

            end loop;

            close vSearchCursor;
            
            if (vDebug) then
                dbms_output.put_line(' ');
            end if;

        end loop;

    end;

end;
/



