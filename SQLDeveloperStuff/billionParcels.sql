-- Substitute the name of the table and the name of the partition
-- in TWO PLACES in the code below. Both places are marked.
--
-- Norman Dunbar
-- 29th March 2018.
--
declare
    -- We need this type first...
    type rowidTable is table of rowid 
        index by pls_integer;
    
    -- Then this table of the type.
    pclRowids rowidTable;
    
    -- And this cursor.
    cursor cPclImg is select rowid as r from pnet.PCL_IMG       -- CHANGE
                      partition (PCLIMG_PART_201602);           -- CHANGE
    -- How many rows deleted so far?
    vRows number := 0;
    
begin
    -- Progress initialisation.
    dbms_application_info.set_module('BillionParcels', 'Initialisation');
    
    open cPclImg;
    
    loop
        -- Progress report.
        dbms_application_info.set_action(trim(to_char(vRows, '999,999,999')) || ' rows deleted so far.');
        
        -- Read the next 100,000 rowids from the partition.
        fetch cPclImg
        bulk collect
        into pclRowids
        limit 1e5;          -- 100,000 * 10 bytes = 1e6 bytes = roughly 1 Mb RAM used.
        

        -- Update row counter.
        vRows := vRows + pclRowids.count;
        
        -- Delete all 100,000 rows from the partition.
        forall pclRow in pclRowids.first .. pclRowids.last
            delete from pnet.PCL_IMG                            -- CHANGE ...
            partition (PCLIMG_PART_201602)                      -- CHANGE ...
            where rowid = pclRowids(pclRow);
        
        commit;
        
        -- Got anything? We MUST do this
        -- here or the last few rows don't
        -- get deleted!
        exit when cPclImg%notfound;
        

    end loop;

    dbms_application_info.set_action(trim(to_char(vRows, '999,999,999')) || ' rows deleted in total.');
    close cPclImg;
    dbms_application_info.set_module(null, null);
    
exception
    when others then raise;
end;
