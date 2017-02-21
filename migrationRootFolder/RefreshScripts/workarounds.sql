SET lines 2000 PAGES 3000 echo on trimspool on

spool workarounds.lst


-- DROP MATERIALIZED VIEWS
-- UPDATE 12/08/2016 - DO NOT DELETE THESE!
-- drop materialized view FCS.ordtran_mv;
-- drop materialized view FCS.investor_cat_mv;

-- DISABLE constraint RENEWAL_COMMISSION_C04 to work around duplicates

--alter table fcs.renewal_commission disable constraint renewal_commission_c04; 

GRANT DATA_UPDATE_ONLY TO EMX_USER;
ALTER USER EMX_USER DEFAULT ROLE ALL;


alter system set UNDO_RETENTION=0 scope = both;


spool off