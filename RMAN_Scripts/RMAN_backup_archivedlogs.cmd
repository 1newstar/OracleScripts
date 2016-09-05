@echo off
rem ==========================================================================
rem Backup a database's archivedlogs using an RMAN incremental level 0 backup.
rem The script relies on helper routines in the SCRIPTS sub-directory.
rem
rem USAGE:
rem
rem   set ORACLE_SID=<desired database>
rem   set ORACLE_HOME=<appropriate home>
rem   set backup_location=<appropriate top level path>
rem
rem ==========================================================================
rem EXAMPLE USAGE:
rem
rem     set oracle_sid=azdba01
rem     set oracle_home=C:\OracleDatabase\product\11.2.0\dbhome_1
rem     set backup_location=h:/backups
rem     RMAN_backup_archivedlogs
rem
rem ==========================================================================



rem ==========================================================================
rem NOTE: the catalog user's password is hard coded into this script. Change
rem       it in one place, as required, on the following line(s).
rem ==========================================================================

set CATPASS=rman11gcatalog
set CATUSER=rman11g
set CATALOG=azrmn01

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
	echo Using H:\backups as the default.
	set backup_location=h:\backups
)


:check_exists

if not exist %BACKUP_LOCATION% (
	echo BACKUP_LOCATION - %BACKUP_LOCATION% - does not exist.
	set ERRORS=1
)


set LEVEL=0


rem --------------------------------------------------------------------------
rem Does RMAN script exist?
rem --------------------------------------------------------------------------
set SCRIPT_FILE=scripts\RMAN_archlogs.rman
set LOG_FILE=logs\%ORACLE_SID%\RMAN_archlogs.log

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
echo Running RMAN script - %SCRIPT_FILE%.
echo Backup files will be written to - %BACKUP_LOCATION%\%ORACLE_SID%



rem --------------------------------------------------------------------------
rem Just in case, create ouput folders.
rem --------------------------------------------------------------------------
mkdir logs\%ORACLE_SID%\ 2> nul
mkdir %BACKUP_LOCATION%\%ORACLE_SID% 2> nul



rem --------------------------------------------------------------------------
rem If we are backing up the catalog database, don't use a catalog, otherwise
rem we must use a catalog.
rem --------------------------------------------------------------------------
set USE_CATALOG=1
if /i "%CATALOG%" equ "%ORACLE_SID%" (
	echo Backing up RMAN Catalog database in NOCATALOG mode.
	set USE_CATALOG=0
)



rem --------------------------------------------------------------------------
rem Script found. Execute it using RMAN.
rem
rem NOTE: %BACKUP_LOCATION% will not be expanded within the called script as
rem %ORACLE_SID% will be. Strange. To get around this, pass %BACKUP_LOCATION%
rem on the command line as a parameter, IN QUOTES, and expand it that way  
rem within the called script. Consistent? Never!
rem --------------------------------------------------------------------------
set NLS_DATE_FORMAT=yyyy/mm/dd hh24:mi:ss

if "%USE_CATALOG%" equ "1" (
	echo rman target / catalog %CATUSER%/*******@%CATALOG% log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
	rman target / catalog %CATUSER%/%CATPASS%@%CATALOG% log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
) else (
	echo rman target / nocatalog log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
	rman target / nocatalog log %LOG_FILE% cmdfile %SCRIPT_FILE% '%BACKUP_LOCATION%'
)