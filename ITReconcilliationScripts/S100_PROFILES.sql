select 'create profile ' || profile || ' limit ' || rtrim (xmlagg (xmlelement (e, RESOURCE_NAME || ' ' ||  LIMIT  || ' ')).extract ('//text()'), ',') || ';'
from dba_profiles
where profile not in ('DEFAULT')
group by PROFILE

set head off lines 500 pages 2000 feedback off trimspool on

spool T100_CREATE_PROFILES.sql
/
spool off

select 'alter profile "DEFAULT" limit ' || rtrim (xmlagg (xmlelement (e, RESOURCE_NAME || decode(RESOURCE_NAME,'PASSWORD_VERIFY_FUNCTION',' NULL ',' UNLIMITED ') )).extract ('//text()'), ',') || ';'
from dba_profiles
where profile = 'DEFAULT'
group by PROFILE

spool T100_CREATE_PROFILES.sql append
/
spool off