select d.file_name, f.* 
from v$filestat f
join dba_data_files d on (d.file_id = f.file#)
order by f.phyrds+f.phywrts desc;
