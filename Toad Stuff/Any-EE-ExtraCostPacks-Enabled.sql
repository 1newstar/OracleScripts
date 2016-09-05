-- Which EE Management Packs are in use?
-- AWR = Diagnostic Pack.
-- These options, if installed/used, cost extra!
SELECT name,       
       detected_usages detected,
       total_samples   samples,
       currently_used  used,
       to_char(last_sample_date,'DD/MM/YYYY HH24:MI') last_sample,
       sample_interval interval
  FROM dba_feature_usage_statistics
 WHERE name = 'Automatic Workload Repository'     
 OR    name like 'SQL%'
 order by name;
 
 