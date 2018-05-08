--========================================================================================================
-- Testing on PNET01D1 - Login as DUNBARNOR.
--========================================================================================================


-- ORACLE TEXT installed? (Yes.)
SELECT * FROM ctxsys.ctx_version;

--========================================================================================================

-- Create a copy of the pcl table for testing.
drop table mypcl cascade constraints purge;
create table mypcl as select * from pnet.pcl;

-- Check row counts ...
-- 3,938,801 in 4.32 seconds.
select count(*) from mypcl;

-- 14,883 in 3.538 seconds.
select count(*) from mypcl where eml_addr <> lower(eml_addr);

-- 3,234,788 in 3.032 seconds.
select count(*) from mypcl where eml_addr is null;

--========================================================================================================

-- Create a CONTEXT index on the email address.
drop index mypcl_context;
create index mypcl_context on mypcl(eml_addr) indextype is ctxsys.context;

--========================================================================================================

-- Create a CONTEXT index on the email address and auto sync it every hour. (Example.)
-- create index mypcl_context on mypcl(eml_addr) indextype is ctxsys.context
--        parameters ('SYNC (EVERY "SYSDATE+1/24")');

--========================================================================================================

-- Putting this here as an update for Oracle 12C users. If you use the index in real time mode, then it 
-- keeps items in memory, and periodicially pushes to the main tables, which keeps fragmentation down 
-- and enables NRT search on streaming content. Here's how to set it up

-- exec ctx_ddl.drop_preference ( 'your_tablespace' );
-- exec ctx_ddl.create_preference( 'your_tablespace', 'BASIC_STORAGE' );
-- exec ctx_ddl.set_attribute ( 'your_tablespace', 'STAGE_ITAB', 'true' );
-- create index  some_text_idx on your_table(text_col)  indextype is ctxsys.context 
--        PARAMETERS ('storage your_tablespace sync (on commit)')

--========================================================================================================

-- Some scans...

-- 0.216 seconds for 199 rows. MiXeD case is ok too :-)
-- Virgin.net only.
select eml_addr from mypcl WHERE contains(eml_addr, 'virGIn.net')> 0;

-- 6.148 seconds for 199 rows. 
-- Force virgin.net only.
select eml_addr from mypcl WHERE lower(eml_addr) like '%virgin.net%';

-- Who at Virgin is not at virgin.net?
-- 5 rows in 0.096 seconds.
-- Shows virgin.com and fly.virgin.com.
select eml_addr from mypcl WHERE contains(eml_addr, 'virGIn')> 0
minus
select eml_addr from mypcl WHERE contains(eml_addr, 'virGIn.net')> 0;

-- 11 rows in 0.111 seconds.   
-- Only 'ball's...
select eml_addr from mypcl WHERE contains(eml_addr, 'BALL')> 0;

-- 155 rows in 0.952 seconds.   
-- Anything with ball in.
select eml_addr from mypcl WHERE contains(eml_addr, '%BALL%')> 0;

-- Anyone called 'm.something', 'something.m.something', 'something.m'
-- 565 rows in 0.557 seconds.
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, '.m.')> 0;

-- 44 rows in 0.198 seconds.   
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norman')> 0;

-- One specific email address
-- 1 row in 0.076 seconds
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norman@dunbar-it.co.uk')> 0;


--========================================================================================================

-- Change some data - the index cannot find the changes until resynchronised.
update mypcl set eml_addr = 'norman@dunbar-it.co.uk' where pcl_id = 2060319;
commit;

-- Resynchronise the index after changes. 0.121 seconds
exec ctx_ddl.sync_index('mypcl_context', '2m');

--========================================================================================================

-- Some scans...

-- Upper, lower, mixed case:
-- 1 row in 0.041 seconds, or less!
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norman@dunbar')> 0;
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'NORMAN@dunbar')> 0;
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'NORMAN@DUNBAR')> 0;
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norman@dunbar-it.co.uk')> 0;

-- Any virgin media users?
-- 205 rows in 0.3666 seconds.
select count(*) from mypcl WHERE contains(eml_addr, '@virgin')> 0;

-- Any 'ba's at Virgin media?
--
-- NOTE: You must search for more than one character! 
--       ORA-29902 "Error in executing ODCIIndexStart() routine" will result.
--
-- NOTE: The index splits the "words" of the email address at punctuation. 
--       So, if you want to look for someone with 'ba' in their name then
--       You still need the '%' wildcard flags, as below, or you get no hits.
select pcl_id,eml_addr from mypcl 
WHERE contains(eml_addr, 'virgin')> 0
and contains(eml_addr, '%ba%')> 0;

-- Look for any one called Norm. Will not find Norman though.
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norm')> 0;

-- But this will - amongst other stuff though.
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, '%norm%')> 0;

-- Just norman. Finds normans with punctuation too - norman_, _norman, .norman. etc.
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'norman')> 0;

-- Any Smiths? Smyths, smythes etc?
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'smith')> 0; -- 180 rows
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'smithe')> 0; -- 0 rows
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'smyth')> 0; -- 8 rows
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'smythe')> 0; -- 1 row

-- As above, but with a wildcard for the 'i' or 'y' in the middle.
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'sm_th')> 0; -- 188 rows

-- What about sm?th? where '?' is any single character?
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'sm_th_')> 0; -- 21 rows

-- What about sm?th? where '?' is any single character and '*' is many?
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'sm_th%')> 0; -- 412 rows

-- HOtmail users?
select pcl_id,eml_addr from mypcl WHERE contains(eml_addr, 'hotmail')> 0; -- 43,622 rows in 45 seconds!

--========================================================================================================

-- PL/SQL *might* need execute privs granted directly to the user as the access is
-- currently via the CTXAPP role. Although from 11g on, this is not necessary (the role).
--
-- If needed, then:
--
-- grant execute on ctxsys.<whatever> to <username>;
--
-- Where <whatever> is each of the following:
--
-- CTX_CLS    CTX_DDL    CTX_DOC    CTX_OUTPUT
-- CTX_QUERY  CTX_REPORT CTX_ULEXER CTX_THES
---
create or replace function mySearch (pText in varchar2)
return number
as
    vCount number;
begin
    if (pText is null) then return NULL; end if;
    
    if length(pText) < 2 then return -1; end if;
    
    select count(*)
    into vCount
    from mypcl 
    where contains(eml_addr, pText)> 0;
    
    return vCount;

exception
    when others then raise;
    
end;
/

-- Call the function.
select mySearch('virgin') from dual;
select mySearch('norman') from dual;
select mySearch('hotmail') from dual;
select mySearch('%norm%') from dual;

