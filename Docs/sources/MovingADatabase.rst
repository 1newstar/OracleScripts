=================
Moving a Database
=================

How to move the database azfs215 from the ``F:`` drive to the ``G:`` drive.

Briefly:

-	Create a script to rename the datafiles, temp files and redo files:

	..	code-block:: sql
	
		set lines 2000 pages 2000 trimspool on
		set feed off
		set echo off
		set define off
		set head off

		spool c:\temp\rename_files.sql

		select 'alter database rename file ''' || file_name || ''' to ''g:\' || substr(file_name, 4) || ''';'
		from dba_data_files
		--
		union all
		--
		select 'alter database rename file ''' || file_name || ''' to ''g:\' || substr(file_name, 4) || ''';'
		from dba_temp_files
		--
		union all
		--
		select 'alter database rename file ''' || member || ''' to ''g:\' || substr(member, 4) || ''';'
		from v$logfile
		--
		order by 1
		/

		spool off

-	Create a pfile from the running spfile:

	..	code-block:: sql
	
		create pfile='c:\temp\initAZFS215.ora' from spfile;
		
-	Disable flashback. You *will* need to drop all restore points.

	..	code-block:: sql
	
		alter database flashback off;
		
-	Shutdown the database *cleanly*. (``shutdown immediate``, ``startup restrict``, ``shutdown`` if necessary or ``shutdown`` doesn't work due to services etc being connected.)
-	Edit the pfile to specify:
	-	Controlfile names.
	-	FRA location.
	-	Etc.
	
-	Copy the ``f:\mnt\fast_recovery_area\azfs215`` folder for the database to the new ``G:`` drive.	
-	Copy the ``f:\mnt\oradata\azfs215`` folder for the database to the new ``G:`` drive. (This will take a while!)
-	..	code-block:: sql

		Startup MOUNT pfile='c:\temp\initAZFS215.ora';
		
-	Execute the rename script;

	..	code-block:: sql
	
		@c:\temp\rename_files.sql

-	Check ``v$datafiles``, ``v$tempfile``, ``v$logfile`` and ``v$controlfile`` to ensure all files are correctly in the new location. Correct the individual ``alter database rename...`` commands as appropriate to fix any problems.

-	Check startup parameters:

	-	show parameter recovery_file_dest
	-	show parameter log_archive_dest_1
	-	show parameter name_convert
	
		
-	Restart the database:

	..	code-block:: sql

		Alter database open;
		
-	Create a new spfile from the running pfile:

	..	code-block:: sql
	
		create spfile='?\database spfileAZFS215.ora' from pfile='c:\temp\initAZFS215.ora';
		
-	Restart the database to pick up the new spfile:

	..	code-block:: sql

		startup force;

-	Enable flashback:

	..	code-block:: sql

		 Alter database flashback on;
		 
-	Edit the ``f:\builds\azfs215\clone_azfs215.rman`` script to reflect the new ``G:`` drive location. Ready for the next refresh of the database.

Once *absolutely* certain that all is well, and all files in the database are being used from the new location, you may remove the old location and the files within.

Once good check to make sure all is well and that nothing is still using t he old location is simply, check the dates and times that the files there were last used. When a database is opened and closed all the files, except temp ones, get marked with the time that the open or close happened. If you see any non-temp files that are obviously out of date, then check them and fix accordingly.

