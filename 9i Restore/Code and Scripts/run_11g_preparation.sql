@@deferred_segments.sql

set lines 2000 pages 2000 trimspool on
spool run_11g_preparation.lst

drop snapshot log on fcs.investor;
drop snapshot log on fcs.ordtran;

drop materialized view fcs.investor_cat_mv;
drop materialized view ordtran_mv;

CREATE OR REPLACE VIEW exu9defpswitches ( 
    compflgs, nlslensem 
) AS 
    SELECT  a.value, b.value 
    FROM    sys.v$parameter a, sys.v$parameter b 
    WHERE   a.name = 'plsql_code_type' 
    AND     b.name = 'nls_length_semantics';
    
    
spool off;