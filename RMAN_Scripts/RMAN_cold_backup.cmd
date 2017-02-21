@echo off
rem ==========================================================================
rem Cold backup any database using an RMAN full cold backup.
rem The script relies on helper routines in the SCRIPTS sub-directory.
rem
rem USAGE:
rem
rem   set ORACLE_SID=<desired database>
rem   set ORACLE_HOME=<appropriate home>
rem   set backup_location=<appropriate top level path>
rem
rem   RMAN_cold_backup sys_password
rem
rem ==========================================================================
rem EXAMPLE USAGE:
rem
rem     set oracle_sid=azdba01
rem     set oracle_home=C:\OracleDatabase\product\11.2.0\dbhome_1
rem     set backup_location=\\backman01\RMANBackup\backups
rem     RMAN_Cold_backup sys_password
rem
rem ==========================================================================

Rem   ================================================================
Rem  | This is hard to believe. We need the next line because Windows |
Rem  | evaluates variable values, and substitutes them into the code  |
Rem  | when it reads the statement in, not at execution time. WTH?    |
Rem   ================================================================
setlocal EnableDelayedExpansion

rem ==========================================================================
rem NOTE: the catalog user's password is hard coded into this script. Change
rem       it in one place, as required, on the following line(s).
rem ==========================================================================

set CATPASS=rman11gcatalog
set CATUSER=rman11g
set CATALOG=rmancatsrv

set DEFAULT_LOCATION=\\Backman01\RMANBackup\backups

rem Default logfile timestamp - yyyymmdd-hhmm
set TIMESTAMP=%date:~6,4%%date:~3,2%%date:~0,2%-

rem Times before 10 AM have a leading space. Not nice!
if "%time:~0,1%" EQU " " (
	set TIMESTAMP=%TIMESTAMP%0%time:~1,1%%time:~3,2%
) else (
	set TIMESTAMP=%TIMESTAMP%%time:~0,2%%time:~3,2%
)

echo %TIMESTAMP%

rem ==========================================================================
rem The following environment variables must be defined external to this
rem script:
rem
rem     ORACLE_SID - Database to be backed up. Used for output files too.
rem     ORACLE_HOME - Oracle Home for the database. Used to find RMAN.
rem     BACKUP_LOCATION - Top level folder where backups are created.
rem ==========================================================================


rem --------------------------------------------------------------------------
rem Do the external variables exist and are they valid?
rem --------------------------------------------------------------------------

set ERRORS=0
set SYS_PASSWORD=%1


:check_sid

if "%ORACLE_SID%" EQU "" (
	echo ORACLE_SID is not defined.
	set ERRORS=1
)


:check_home

if "%ORACLE_HOME%" EQU "" (
	echo ORACLE_HOME is not defined.
	set ERRORS=1
	goto :check_location
)


:check_rman

if not exist %ORACLE_HOME%\bin\rman.exe (
	echo Cannot locate RMAN.exe binary in %ORACLE_HOME%\bin.
	set ERRORS=1
)


:check_location

if "%BACKUP_LOCATION%" EQU "" (
	echo BACKUP_LOCATION is not defined.
	echo Using "%DEFAULT_LOCATION%" as the default.
	set backup_location=%DEFAULT_LOCATION%)


:check_exists

if not exist %BACKUP_LOCATION% (
	echo BACKUP_LOCATION - %BACKUP_LOCATION% - does not exist.
	set ERRORS=1
)


rem --------------------------------------------------------------------------
rem Do we have a password for SYS?
rem --------------------------------------------------------------------------

:check_password

if "%SYS_PASSWORD%" EQU "" (
	echo No SYS_PASSWORD parameter supplied.
	set ERRORS=1
)


rem --------------------------------------------------------------------------
rem Does RMAN script exist?
rem --------------------------------------------------------------------------

:check_script

set SCRIPT_FILE=scripts\RMAN_cold_backup.rman
set LOG_FILE=%BACKUP_LOCATION%\logs\%ORACLE_SID%\RMAN_cold_backup.%TIMESTAMP%.log

if not exist %SCRIPT_FILE% (
	echo %SCRIPT_FILE% cannot be found in the scripts directory.
	set ERRORS=1
)


rem --------------------------------------------------------------------------
rem Check for validation errors. Bale out if any were found.
rem --------------------------------------------------------------------------

:check_errors

if %ERRORS% EQU 1 (
	echo Cannot continue with backup.
	goto :eof
)

echo Logging RMAN output to logfile - %LOG_FILE%.
echo Running cold backup script - %SCRIPT_FILE%.
echo Backup files will be written to - %BACKUP_LOCATION%\%ORACLE_SID%


rem --------------------------------------------------------------------------
rem Just in case, create output folders.
rem --------------------------------------------------------------------------
mkdir %BACKUP_LOCATION%\logs\%ORACLE_SID%\ 2> nul
mkdir %BACKUP_LOCATION%\%ORACLE_SID% 2> nul


rem --------------------------------------------------------------------------
rem If we are backing up the catalog database, don't use a catalog, otherwise
rem we must use a catalog.
rem --------------------------------------------------------------------------
set USE_CATALOG=1
echo "%ORACLE_SID%" | find /i "RMN" > nul
if "%ERRORLEVEL%" equ "0" (
	echo Backing up RMAN Catalog database in NOCATALOG mode.
	set USE_CATALOG=0
) else (
	echo Backing up %ORACLE_SID% database in CATALOG mode.
)


rem --------------------------------------------------------------------------
rem NOTE: %BACKUP_LOCATION% will not be expanded within the called script as
rem %ORACLE_SID% will be. Strange. To get around this, pass %BACKUP_LOCATION%
rem on the command line as a parameter, IN QUOTES, and expand it that way  
rem within the called script. Consistent? Never!
rem --------------------------------------------------------------------------
rem We cannot use a service_name here for the connection to the target, as we
rem lose it on the shutdown and the database will not restart. We must go in
rem via ORACLE_SID instead.
rem --------------------------------------------------------------------------
:do_backup

set NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss

echo Backing up "%ORACLE_SID%".
if "%USE_CATALOG%" equ "1" (
	echo rman target sys/******* catalog %CATUSER%/*******@%CATALOG% log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
	rman target sys/%SYS_PASSWORD% catalog %CATUSER%/%CATPASS%@%CATALOG% log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
) else (
	echo rman target sys/******* nocatalog log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
	rman target sys/%SYS_PASSWORD% nocatalog log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
)