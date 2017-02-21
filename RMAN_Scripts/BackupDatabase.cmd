@echo off
REM =====================================================================================
REM Backup any database using RMAN.
REM =====================================================================================
REM PARAMETERS:
REM 
REM 	BackupDatabase database_name SYS_Password [RMAN_level] [backup_location]
REM
REM 	The first two are mandatory. 
REM 	RMAN_Level defaults to 0.
REM 	Backup_Location defaults to \\Backman01\RMANBackup\backups\<database_name>
REM 
REM 	Backup logs are written to <backup_location><logs><database_name>
REM
REM =====================================================================================

:set_defaults
	set DATABASE_NAME=%1
	set SYS_PASSWORD=%2
	set RMAN_LEVEL=%3
	set BACKUP_LOCATION=%4
	set ERRORS=0

:check_database_name	
	if "%DATABASE_NAME%" equ "" (
		echo DATABASE_NAME must be supplied.
		set ERRORS=1
	)

:check_sys_password	
	if "%SYS_PASSWORD%" equ "" (
		echo SYS_PASSWORD must be supplied.
		set ERRORS=1
		goto :check_errors
	)

:check_rman_level	
	if "%RMAN_LEVEL%" equ "" (
		echo RMAN_LEVEL not supplied ^- defaulting to level 0.
        set RMAN_LEVEL=0
		goto :check_backups
	)

	if "%RMAN_LEVEL%" equ "0" (
		goto :check_backups
	)
		
	if "%RMAN_LEVEL%" neq "1" (
		echo RMAN_LEVEL, if supplied, must be 0 or 1 only. ^(%RMAN_LEVEL%^)
		set ERRORS=1
	)

	
:check_backups
	if "%BACKUP_LOCATION%" equ "" (
		echo BACKUP_LOCATION not supplied - defaulting to \\Backman01\RMANBackup\backups.
		set BACKUP_LOCATION=\\Backman01\RMANBackup\backups
	)

:check_errors
	if "%ERRORS%" neq "0" (
		echo Too many errors. Cannot continue.
		exit/b 1
	)

:do_backup	
	call oraenv %DATABASE_NAME%
	call rman_backup %RMAN_LEVEL% %SYS_PASSWORD%

