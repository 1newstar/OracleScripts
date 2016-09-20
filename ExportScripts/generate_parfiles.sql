
set serverout on size 1000000
set lines 2000 trimspool on pages 2000
set echo off feed off

spool exp_NOROWS.par
exec xxnd_parfiles.buildNOROWS('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_NOFCS.par
exec xxnd_parfiles.buildNOFCS('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS1.par
exec xxnd_parfiles.buildFCS1('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS2D.par
exec xxnd_parfiles.buildFCS2D('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS3.par
exec xxnd_parfiles.buildFCS3('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS4.par
exec xxnd_parfiles.buildFCS4('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS5.par
exec xxnd_parfiles.buildFCS5('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS6.par
exec xxnd_parfiles.buildFCS6('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS7.par
exec xxnd_parfiles.buildFCS7('&&Output_directory_for_dumpfiles');
spool off

spool exp_ROWS_FCS8.par
exec xxnd_parfiles.buildFCS8('&&Output_directory_for_dumpfiles');
spool off




