@echo off
Rem   ================================================================
Rem  | Clone an existing Oracle Database from an existing database,   |
Rem  | with RMAN active database cloning. This requires 11g to work.  |
Rem  |                                                                |
Rem  | Norman Dunbar.                                                 |
Rem  | June 2016.                                                     |
Rem   ================================================================
Rem 
Rem 
Rem   =================================================================
Rem  | USAGE:                                                          |
Rem  |                                                                 | 
Rem  | dbClone  src_db src_pw dst_db dst_pw check                      | 
Rem  | dbClone  help                                                   | 
Rem  |                                                                 |
Rem  | src_db  - Database to be cloned.                                |
Rem  | src_pw  - SYS password for the source database.                 |
Rem  | dst_db  - Database to be refreshed from source.                 |
Rem  | dst_pw  - SYS password for the destination database.            |
Rem  |                                                                 |
Rem  | help    - Just display's usage details.                         |
Rem   =================================================================
Rem 
Rem 
Rem   ================================================================
Rem  | ASSUMPTIONS:                                                   |
Rem  |                                                                |
Rem  | * The databases have all their files on a single drive.        |
Rem  | * The structures are:                                          |
Rem  |                                                                |
Rem  |   DRIVE:\mnt\oradata\                                          |
Rem  |   DRIVE:\mnt\fast_recovery_area                                |
Rem  |                                                                |
Rem  | * Both databases already exist. This is a refresh after all.   |
Rem   ================================================================
Rem 
Rem
Rem   ================================================================
Rem  | This is hard to believe. We need the next line because Windows |
Rem  | evaluates variable values, and substitutes them into the code  |
Rem  | when it reads the statement in, not at execution time. WTH?    |
Rem  | Someone designed this, approved it, coded it, and tested it!   |
Rem  | And they thought it was a good idea? JFC.                      |
Rem  | So the following line is a fix for that problem in that it     |
Rem  | stops this stupidity, and makes the variable values and their  |
Rem  | substitution into the code, be done at execution time, or as   |
Rem  | we would say, correctly!                                       |
Rem   ================================================================
setlocal EnableDelayedExpansion


Rem   ================================================================
Rem  | Internal Variables.                                            |
Rem   ================================================================
set VERSION=1.00
set SCRIPTS_LOCATION=rman_scripts
set RMAN_SCRIPT=%SCRIPTS_LOCATION%\clone_database.rman
set RMAN_UNREGISTER_SCRIPT=%SCRIPTS_LOCATION%\unregister_database.rman
set RMAN_REREGISTER_SCRIPT=%SCRIPTS_LOCATION%\reregister_database.rman
set MYLOG=%0.log
set TEMPFILES_SCRIPT=%SCRIPTS_LOCATION%\dbClone_tempfiles.sql
set DB_PARAMS_SCRIPT=%SCRIPTS_LOCATION%\db_params.sql
set DRIVE_LETTER_SCRIPT=%SCRIPTS_LOCATION%\getDriveLetter.sql
set SERVER_NAME_SCRIPT=%SCRIPTS_LOCATION%\getHostName.sql
set SPFILE_NAME_SCRIPT=%SCRIPTS_LOCATION%\getSpfileName.sql
set CREATE_PFILE_SCRIPT=%SCRIPTS_LOCATION%\createPfile.sql
set STARTUP_PFILE_SCRIPT=%SCRIPTS_LOCATION%\startupPfile.sql

set TARGET_DRIVE=
set AUXILIARY_DRIVE=
set TARGET_SERVER=
set AUXILIARY_SERVER=
set NOFILENAMECHECK=
set SPFILE_NAME=
set PFILE_NAME=

Rem   ================================================================
Rem  | YOU MUST CHANGE THE FOLLOWING AS AND WHEN IT CHANGES ON THE    |
Rem  | RMAN CATALOG DATABASE AZRMN01 ON SERVER ORCDEVOPRC03.          |
Rem   ================================================================
set RMAN_PASSWORD=rman11gcatalog


Rem   ================================================================
Rem  | Clear any existing logfile.                                    |
Rem   ================================================================
Rem 
del %MYLOG% > nul 2>&1

call :log %0 - v%VERSION% : Logging to %MYLOG%
call :log Executing: %0 %*


Rem   ================================================================
Rem  | Commandline Parameters.                                        |
Rem   ================================================================
set TARGET_DB=%1
set TARGET_PASSWORD=%2
set AUXILIARY_DB=%3
set AUXILIARY_PASSWORD=%4


Rem   ================================================================
Rem  | Set the Window Title. Needed for later if we have to kill it. |
Rem   ================================================================
title=dbClone %AUXILIARY_DB%


Rem   ================================================================
Rem  | Help requested?                                                |
Rem   ================================================================
echo X_%1_X | find /i "X_HELP_X" > nul
if %ERRORLEVEL% EQU 0 (
    call :usage
    goto :eof
)


Rem   ================================================================
Rem  | Parameter Validation.                                          |
Rem   ================================================================
set ERRORS=0


:check_sids

if "%TARGET_DB%" EQU "" (
	call :log Source Database was not passed on commandline.
	set ERRORS=1
) else (
    call :log Refreshing from database %TARGET_DB%.
)

if "%AUXILIARY_DB%" EQU "" (
	call :log Destination Database was not passed on commandline.
	set ERRORS=1
) else (
    call :log Refreshing to database %AUXILIARY_DB%.
)

if "%TARGET_DB%" EQU "%AUXILIARY_DB%" (
	call :log Destination Database %AUXILIARY_DB% is the same as the source database %TARGET_DB%.
	set ERRORS=1
)


:check_passwords

if "%TARGET_PASSWORD%" EQU "" (
	call :log Source Database SYS password was not passed on commandline.
	set ERRORS=1
) else (
    call :log SYS password for %TARGET_DB% has been supplied.
)

if "%AUXILIARY_PASSWORD%" EQU "" (
	call :log Destination Database SYS password was not passed on commandline.
	set ERRORS=1
) else (
    call :log SYS password for %AUXILIARY_DB% has been supplied.
)


:check_scripts

if not exist %SCRIPTS_LOCATION% (
	call :log SCRIPTS_LOCATION - %SCRIPTS_LOCATION% - does not exist.
	set ERRORS=1
    goto :check_home
)

if not exist %TEMPFILES_SCRIPT% (
	call :log Tempfiles script - %TEMPFILES_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %RMAN_UNREGISTER_SCRIPT% (
	call :log RMAN_UNREGISTER_SCRIPT script - %RMAN_UNREGISTER_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %DRIVE_LETTER_SCRIPT% (
	call :log DRIVE_LETTER_SCRIPT script - %DRIVE_LETTER_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %SERVER_NAME_SCRIPT% (
	call :log SERVER_NAME_SCRIPT script - %SERVER_NAME_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %SPFILE_NAME_SCRIPT% (
	call :log SPFILE_NAME_SCRIPT script - %SPFILE_NAME_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %CREATE_PFILE_SCRIPT% (
	call :log CREATE_PFILE_SCRIPT script - %CREATE_PFILE_SCRIPT% - does not exist.
	set ERRORS=1
)


if not exist %STARTUP_PFILE_SCRIPT% (
	call :log STARTUP_PFILE_SCRIPT script - %STARTUP_PFILE_SCRIPT% - does not exist.
	set ERRORS=1
)


:check_home

if "%ORACLE_HOME%" EQU "" (
	call :log ORACLE_HOME is not defined.
	set ERRORS=1
    goto :check_errors
)

echo %path% | find /i "%oracle_home%\bin" > nul
if %ERRORLEVEL% EQU 1 (
    call :log ORACLE_HOME - %oracle_home%\bin - is not on PATH.
    set ERRORS=1
)

Rem Does rman.exe exist in %oracle_home%\bin?
if not exist %oracle_home%\bin\rman.exe (
    call :log %oracle_home%\bin\rman.exe - not found.
    set ERRORS=1
)


:check_errors

if %ERRORS% EQU 1 (
	call :log Cannot continue with RMAN clone - too many errors.
    call :usage
	goto :eof
)


:JFDI

Rem Do we need to create or overwrite the clone script?
if not exist %RMAN_SCRIPT% (
	call :log RMAN_SCRIPT - %RMAN_SCRIPT% - does not exist.
    call :log RMAN_SCRIPT - %RMAN_SCRIPT% - will be created.
) else (
	call :log RMAN_SCRIPT - %RMAN_SCRIPT% - already exists.
    call :log RMAN_SCRIPT - %RMAN_SCRIPT% - will be overwritten.
)


Rem   ================================================================
Rem  | Save the old stuff. In case the user has set these differently.|
Rem   ================================================================
Rem 
set old_oracle_sid=%oracle_sid%
set oracle_sid=%TARGET_DB%
set old_nls_date_format=%nls_date_format%
set nls_date_format=yyyy/mm/dd hh24:mi:ss

Rem  *****************************************************************
Rem  *****************************************************************
Rem  **         Let's do it. The hard work starts here....          **
Rem  *****************************************************************
Rem  *****************************************************************
Rem 

set ERRORS=0

Rem   ================================================================
Rem  | Fetch the drive letter for the source database datafiles.      |
Rem   ================================================================
call :log Retrieving drive letter for database: %TARGET_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/%TARGET_PASSWORD%@%TARGET_DB% as sysdba @%DRIVE_LETTER_SCRIPT%') do @set TARGET_DRIVE=%%a
call :check_rman_sqlplus
call :log Drive letter for database: %TARGET_DB% is: %TARGET_DRIVE%\.
if "%TARGET_DRIVE%" EQU "?" (
    call :log Database: %TARGET_DB%. Cannot read data drive letter.
    set ERRORS=1
)

Rem   ================================================================
Rem  | Fetch the drive letter for the destination database datafiles. |
Rem   ================================================================
call :log Retrieving drive letter for database: %AUXILIARY_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba @%DRIVE_LETTER_SCRIPT%') do @set AUXILIARY_DRIVE=%%a
call :check_rman_sqlplus
call :log Drive letter for database: %AUXILIARY_DB% is: %AUXILIARY_DRIVE%\.
if "%AUXILIARY_DRIVE%" EQU "?" (
    call :log Database: %AUXILIARY_DB%. Cannot read data drive letter.
    set ERRORS=1
)

Rem   ================================================================
Rem  | Fetch the host server for the source database.                 |
Rem   ================================================================
call :log Retrieving host server for database: %TARGET_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/%TARGET_PASSWORD%@%TARGET_DB% as sysdba @%SERVER_NAME_SCRIPT%') do @set TARGET_SERVER=%%a
call :check_rman_sqlplus
call :log Host server for database: %TARGET_DB% is: %TARGET_SERVER%.

Rem   ================================================================
Rem  | Fetch the host server for the destination database.            |
Rem   ================================================================
call :log Retrieving host server for database: %AUXILIARY_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba @%SERVER_NAME_SCRIPT%') do @set AUXILIARY_SERVER=%%a
call :check_rman_sqlplus
call :log Host server for database: %AUXILIARY_DB% is: %AUXILIARY_SERVER%.

Rem   ================================================================
Rem  | Set NOFILENAMECHECK correctly.                                 |
Rem  | If same servers, we must set it to blank. Otherwise it should  |
Rem  | be "NOFILENAMECHECK".                                          |
Rem   ================================================================
if "%TARGET_SERVER%" NEQ "%AUXILIARY_SERVER%" (
    set NOFILENAMECHECK=NOFILENAMECHECK
    call :log ********************************************************
    call :log File name checking is not required on different servers.
    call :log ********************************************************
) else (
    set NOFILENAMECHECK=
    call :log *****************************************************************************
    call :log File name checking is required and will be used as the same server is in use.
    call :log *****************************************************************************
)


Rem   ================================================================
Rem  | Target database must have been started with an spfile.         |
Rem   ================================================================
call :log Checking spfile_name for database: %TARGET_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/ForConfig2lock as sysdba @%SPFILE_NAME_SCRIPT%') do @set SPFILE_NAME=%%a
call :check_rman_sqlplus
call :log Spfile name for database: %TARGET_DB% is: %SPFILE_NAME%.

if "%SPFILE_NAME%" EQU "" (
    call :log Database %TARGET_DB% must be started with an SPFILE.
    call :log It does not appear to have been started in this manner.
    call :log RMAN clone ^(refresh^) cannot continue.
    set ERRORS=1
)


Rem   ================================================================
Rem  | Another error check. If we have any, we really can't go on.    |
Rem   ================================================================
:check_more_errors

if %ERRORS% EQU 1 (
	call :log Cannot continue with RMAN clone - too many errors.
    call :usage
	goto :eof
)


Rem   ================================================================
Rem  | Auxiliary database must have be using a PFILE, so create one.  |
Rem   ================================================================
set PFILE_NAME=%oracle_home%\init.%AUXILIARY_DB%.ora
set SPFILE_NAME=

call :log Retrieving spfile_name for database: %AUXILIARY_DB%.
for /f "delims=" %%a in ('sqlplus -s sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba @%SPFILE_NAME_SCRIPT%') do @set SPFILE_NAME=%%a
call :log Spfile name for database: %AUXILIARY_DB% is: %SPFILE_NAME%.
if "%SPFILE_NAME%" EQU "" (
    call :log %AUXILIARY_DB% already running with a PFILE.
    copy %ORACLE_HOME%\database\init%AUXILIARY_DB%.ora %PFILE_NAME% 
    
    if %ERRORLEVEL% EQU 0 (
        call :log Pfile: %ORACLE_HOME%\database\init%AUXILIARY_DB%.ora copied to %PFILE_NAME%.
        goto :build_scripts
    ) else (
        call :log Pfile: %ORACLE_HOME%\database\init%AUXILIARY_DB%.ora not be copied to %PFILE_NAME%. Error %ERRORLEVEL%.
        set ERRORS=1
        goto :check_more_errors
    )
)


call :log Creating a PFILE: %PFILE_NAME% - for database %AUXILIARY_DB%.
sqlplus -s "sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba" @%CREATE_PFILE_SCRIPT% %PFILE_NAME% %SPFILE_NAME%
call :log Pfile: %PFILE_NAME% - created for database: %AUXILIARY_DB%.


Rem   ================================================================
Rem  | Create a script to clone the database.                         |
Rem  | The first line clears out the entire script, first!            |
Rem   ================================================================
:build_scripts


call :log Building script: %RMAN_SCRIPT%.
echo run {                                                                    >  %RMAN_SCRIPT%

echo allocate auxiliary channel x1 device type DISK;                          >> %RMAN_SCRIPT%
echo allocate auxiliary channel x2 device type DISK;                          >> %RMAN_SCRIPT%
echo allocate auxiliary channel x3 device type DISK;                          >> %RMAN_SCRIPT%

echo allocate channel d1 device type DISK;                                    >> %RMAN_SCRIPT%
echo allocate channel d2 device type DISK;                                    >> %RMAN_SCRIPT%
echo allocate channel d3 device type DISK;                                    >> %RMAN_SCRIPT%
echo allocate channel d4 device type DISK;                                    >> %RMAN_SCRIPT%
echo allocate channel d5 device type DISK;                                    >> %RMAN_SCRIPT%

echo duplicate target database to %AUXILIARY_DB%                              >> %RMAN_SCRIPT%
echo from active database                                                     >> %RMAN_SCRIPT%
echo spfile                                                                   >> %RMAN_SCRIPT%
echo parameter_value_convert                                                  >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\oradata\%TARGET_DB%',                               >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\oradata\%AUXILIARY_DB%',	                      >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\fast_recovery_area\%TARGET_DB%',                    >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\fast_recovery_area\%AUXILIARY_DB%'               >> %RMAN_SCRIPT%
echo set control_files                                                        >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\oradata\%AUXILIARY_DB%\control01.ctl',           >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\fast_recovery_area\%AUXILIARY_DB%\control02.ctl' >> %RMAN_SCRIPT%
echo set db_file_name_convert                                                 >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\oradata\%TARGET_DB%',                               >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\oradata\%AUXILIARY_DB%',	                      >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\fast_recovery_area\%TARGET_DB%',                    >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\fast_recovery_area\%AUXILIARY_DB%'               >> %RMAN_SCRIPT%
echo set log_file_name_convert                                                >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\oradata\%TARGET_DB%',                               >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\oradata\%AUXILIARY_DB%',                         >> %RMAN_SCRIPT%
echo '%TARGET_DRIVE%:\mnt\fast_recovery_area\%TARGET_DB%',                    >> %RMAN_SCRIPT%
echo '%AUXILIARY_DRIVE%:\mnt\fast_recovery_area\%AUXILIARY_DB%'               >> %RMAN_SCRIPT%

if "%NOFILENAMECHECK%" NEQ "" (
    echo %NOFILENAMECHECK%                                                    >> %RMAN_SCRIPT%
)    
echo ;                                                                        >> %RMAN_SCRIPT%

echo release channel x1;                                                      >> %RMAN_SCRIPT%
echo release channel x2;                                                      >> %RMAN_SCRIPT%
echo release channel x3;                                                      >> %RMAN_SCRIPT%

echo release channel d1;                                                      >> %RMAN_SCRIPT%
echo release channel d2;                                                      >> %RMAN_SCRIPT%
echo release channel d3;                                                      >> %RMAN_SCRIPT%
echo release channel d4;                                                      >> %RMAN_SCRIPT%
echo release channel d5;                                                      >> %RMAN_SCRIPT%
echo }                                                                        >> %RMAN_SCRIPT%

echo exit                                                                     >> %RMAN_SCRIPT%


Rem   ================================================================
Rem  | Create a script to fixup init.ora parameters post clone.       |
Rem  | The first line clears out the entire script, first!            |
Rem   ================================================================
call :log Building script: %DB_PARAMS_SCRIPT%.
echo alter system set instance_name='%AUXILIARY_DB%' scope=spfile;            >  %DB_PARAMS_SCRIPT%

echo alter system set service_names='%AUXILIARY_DB%' scope=spfile;            >> %DB_PARAMS_SCRIPT%
echo alter system set audit_file_dest=                                        >> %DB_PARAMS_SCRIPT%
echo 'C:\ORACLEDATABASE\ADMIN\%AUXILIARY_DB%\ADUMP' scope = spfile;           >> %DB_PARAMS_SCRIPT%
echo alter system set dispatchers=                                            >> %DB_PARAMS_SCRIPT%
echo '(PROTOCOL=TCP) (SERVICE=%AUXILIARY_DB%XDB)' scope=spfile;               >> %DB_PARAMS_SCRIPT%
echo alter role NORMAL_USER identified by %AUXILIARY_DB%123;                  >> %DB_PARAMS_SCRIPT%
echo alter role SVC_AURA_SERV_ROLE identified by %AUXILIARY_DB%123;           >> %DB_PARAMS_SCRIPT%

echo -- The following may fail. Please ignore.                                >> %DB_PARAMS_SCRIPT%
echo -- alter database disable block change tracking;                         >> %DB_PARAMS_SCRIPT%

echo -- The following will work.                                              >> %DB_PARAMS_SCRIPT%
echo alter database enable block change tracking                              >> %DB_PARAMS_SCRIPT%
echo using file '%AUXILIARY_DRIVE%:\mnt\fast_recovery_area\bct.dbf' reuse;    >> %DB_PARAMS_SCRIPT%

echo startup force                                                            >> %DB_PARAMS_SCRIPT%
echo @tempfiles.sql                                                           >> %DB_PARAMS_SCRIPT%
echo exit                                                                     >> %DB_PARAMS_SCRIPT%



Rem   ================================================================
Rem  | Use SQL*Plus to create a TEMPFILES script for afterwards.      |
Rem  | The script generated is named tempfiles.sql.                   | 
Rem   ================================================================
Rem 
call :log Building script: .\tempfiles.sql.
sqlplus -s "sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba" @%TEMPFILES_SCRIPT%
call :check_rman_sqlplus


Rem   ================================================================
Rem  | Use RMAN to deregister the current destination database. This  |
Rem  | will also delete all known backups of the destination database.|
Rem  | The database must be MOUNTed or OPEN for this to work.         |
Rem   ================================================================
Rem 
call :log Deleting old backups for %AUXILIARY_DB%.
call :log Unregistering %AUXILIARY_DB% from RMAN catalog (rman11g@azrmna01).
rman target sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% catalog rman11g/%RMAN_PASSWORD%@azrmn01 log="deRegister.%AUXILIARY_DB%.log" @%RMAN_UNREGISTER_SCRIPT%
call :check_rman_sqlplus

Rem   ================================================================
Rem  | Use RMAN to clone the database.                                |
Rem  | We need to restart the database in NOMOUNT mode with a PFILE.  |
Rem   ================================================================
Rem 
call :log NOMOUNTing database %AUXILIARY_DB% using PFILE: %PFILE_NAME%.
sqlplus -s "sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba" @%STARTUP_PFILE_SCRIPT% %PFILE_NAME%
call :check_rman_sqlplus

call :log Cloning %TARGET_DB% to %AUXILIARY_DB% using script %RMAN_SCRIPT%.
rman target sys/%TARGET_PASSWORD%@%TARGET_DB% auxiliary sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% log="dbClone.%AUXILIARY_DB%.log" @%RMAN_SCRIPT%
call :check_rman_sqlplus


Rem   ================================================================
Rem  | Use SQL*Plus to fixup the parameters that retain the value of  |
Rem  | the source database. This will fix the tempfiles and restart   | 
Rem  | the database.                                                  |
Rem   ================================================================
Rem 
call :log Resetting database parameters post clone, using %DB_PARAMS_SCRIPT%.
sqlplus -s "sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% as sysdba" @%DB_PARAMS_SCRIPT%
call :check_rman_sqlplus


Rem   ================================================================
Rem  | Use RMAN to register the (new) destination database. This will |
Rem  | also reconfigure the required RMAN parameters for the database.|
Rem   ================================================================
Rem 
call :log Registering %AUXILIARY_DB% with RMAN catalog (rman11g@azrmna01).
rman target sys/%AUXILIARY_PASSWORD%@%AUXILIARY_DB% catalog rman11g/%RMAN_PASSWORD%@azrmn01 log="reRegister.%AUXILIARY_DB%.log" @%RMAN_REREGISTER_SCRIPT%
call :check_rman_sqlplus


Rem   ================================================================
Rem  | Restore the old stuff - return the user to a known state.      |
Rem   ================================================================
Rem 
set oracle_sid=%old_oracle_sid%
set nls_date_format=%old_nls_date_format%



Rem   ================================================================
Rem  | And finally, turn off the "doing it correctly" setting. Sigh.  |
Rem  | And skip over the sub-routines.                                |
Rem   ================================================================
Rem 
endlocal

call :log %0 - complete.
goto :eof


Rem  *******************************************************************
Rem  *******************************************************************
Rem  ** Here endeth the main code. The following are all CALLable     **
Rem  ** subroutine(s) because we need them a lot.                     **
Rem  *******************************************************************
Rem  *******************************************************************


Rem   ================================================================
Rem  |                                                          LOG() |
Rem   ================================================================
Rem  | Set up a logging procedure to log output to the %MYLOG% file.  |
Rem  | Each line is yyyy/mm/dd hh:mi:ss: <stuff>                      |
Rem   ================================================================
:log

echo %*
echo %date:~6,4%/%date:~3,2%/%date:~0,2% %time:~0,8%: %* >> %MYLOG%
goto :eof


Rem   ================================================================
Rem  |                                           CHECK_RMAN_SQLPLUS() |
Rem   ================================================================
Rem  | Check the exit code from RMAN to see if everything was ok.     |
Rem  | 'echo.' or 'echo[' (no space) prints a linefeed. Errors in     |
Rem  | RMAN do not have a final linefeed.                             |
Rem   ================================================================
:check_rman_sqlplus

echo.
if %ERRORLEVEL% NEQ 0 (
    call :log ************************************************
    call :log RMAN or SQL*Plus exited with result code %ERRORLEVEL%.
    call :log You need to check the RMAN log file for details.
    call :log ************************************************
)
goto :eof

Rem   ================================================================
Rem  | Kill this job now. There's no easy way in a batch file to exit |
Rem  | from the current batch file other than exit or goto :eof but   |
Rem  | those only exit from the current call level, and here we are   |
Rem  | in a sub-routine, possibly nested.                             |
Rem  | This is why we set the window title to "dbClone %AUXILIARY_DB%"|
Rem  | at the start.                                                  |
Rem   ================================================================
:kill_me_now
taskkill /im cmd.exe /fi "windowtitle eq dbClone $AUXILIARY_DB%"
goto :eof


Rem   ================================================================
Rem  |                                                        USAGE() |
Rem   ================================================================
Rem  | Explain to the user what they typed in wrongly when calling    |
Rem  | this utility.                                                  |
Rem   ================================================================
:usage

echo  =================================================================
echo * USAGE:                                                          *
echo *                                                                 *
echo * dbClone  src_db src_pw dst_db dst_pw                            *
echo *                                                                 *
echo * src_db  - Database to be cloned.                                *
echo * src_pw  - SYS password for the source database.                 *
echo * dst_db  - Database to be refreshed from source.                 *
echo * dst_drv - SYS password for the destination database.            *
echo  =================================================================
goto :eof