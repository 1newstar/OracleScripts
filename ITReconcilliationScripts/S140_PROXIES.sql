PROMPT : 
PROMPT : Note : Only users whose account is NOT EXPIRED & LOCKED are being migrated to the new 11g Database. 
PROMPT :        Therefore the same condition has to be imposed on this SQL statement, using "PROXY_USERS". 
PROMPT : 

SELECT 'ALTER USER ' || CLIENT || ' GRANT CONNECT THROUGH ' || PROXY || ';' 
FROM proxy_users pu, 
     dba_users du
WHERE pu.client = du.username
AND   du.account_status != 'EXPIRED ' || CHR(38) || ' LOCKED'

set head off feedback off lines 500 pages 2000 trimspool on

spool T140_CREATE_PROXIES.sql
/
spool off
