select 'alter database rename file ''' ||
name || ''' to ''' ||
trim(replace(name,'\AZPPD03B\','\AZPPD03\')) || ''';'
from v$datafile
--
union all
--
select 'alter database rename file ''' ||
member || ''' to ''' ||
trim(replace(member,'\AZPPD03B\','\AZPPD03\')) || ''';'
from v$logfile
order by 1
--
union all
--
select 'alter database rename file ''' ||
name || ''' to ''' ||
trim(replace(name,'\AZPPD03B\','\AZPPD03\')) || ''';'
from v$tempfile;

