@echo off
Rem   ================================================================
Rem  |Refresh an existing Oracle Database from Production dumps.      |
Rem  |                                                                |
Rem  | Norman Dunbar.                                                 |
Rem  | May/June 2016.                                                 |
Rem   ================================================================
Rem 
Rem 
Rem   ================================================================
Rem  | USAGE:                                                         |
Rem  |                                                                | 
Rem  | dbRefresh  oracle_sid  [no]restart                             | 
Rem  | dbRefresh  help                                                | 
Rem  |                                                                |
Rem  | Oracle_sid  - database to be refreshed. Will be trashed.       |
Rem  | [no]restart - database will be shutdown and mounted, archivelog|
Rem  |               and flashback database will be disabled prior to |
Rem  |               the refresh and enabled afterwards.              |
Rem   ================================================================
Rem 
Rem 
Rem The following dumps are required and should be named as such:
Rem   ================================================================
Rem  | exp_NOROWS.dmp - All schemas, but no row data.                 |
Rem  |                                                                |
Rem  | exp_ROWS_NOFCS.dmp - Every schema, all objects, except FCS.    |
Rem  | exp_ROWS_FCS1.dmp  - FCS.AUDIT_LOG_DETAIL only.                |
Rem  | exp_ROWS_FCS2D.dmp - Everything not in FCS1, 3, 4, 5, 6 & 7.   |
Rem  | exp_ROWS_FCS3.dmp  - FCS.ORDTRAN table only.                   |
Rem  | exp_ROWS_FCS4.dmp  - FCS.STP_MESSAGES table only.              |
Rem  | exp_ROWS_FCS5.dmp  - FCS.AUDIT_LOG table only.                 |
Rem  | exp_ROWS_FCS6.dmp  - 5 Large FCS tables.                       |
Rem  | exp_ROWS_FCS7.dmp  - Everything not in FCS1, 2D, 3, 4, 5 & 6.  |
Rem   ================================================================
Rem 

Rem   ================================================================
Rem  | The directory structure assumes the following. ROOT is where   |
Rem  | we expect to find this and other batch files, SQL logs are also|
Rem  | written here.                                                  |
Rem  |                                                                |
Rem  | ROOT                                                           |
Rem  |   |--- RefreshScripts    - Where the SQL scripts live.         |
Rem  |   |--- ParFiles          - Import & export parameter files.    |
Rem  |   |--- DumpFiles         - Where we expect to find the dumps.  |
Rem  |   |--- LogFiles          - Where the imp/exp logfiles go.      |
Rem  |                                                                |
Rem   ================================================================
Rem 

Rem   ================================================================
Rem  | This is hard to believe. We need the next line because Windows |
Rem  | evaluates variable values, and substitutes them into the code  |
Rem  | when it reads the statement in, not at execution time. WTF?    |
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
set BATCH_LOCATION=.\
set DUMPS_LOCATION=.\DumpFiles
set LOGS_LOCATION=.\LogFiles
set PARFILES_LOCATION=.\ParFiles
set SCRIPTS_LOCATION=.\RefreshScripts
set BATCH_IMPORT_SCRIPT=%BATCH_LOCATION%Batch_Import_Rows.bat
set MYLOG=%BATCH_LOCATION%%0.log

Rem   ================================================================
Rem  | The next two define the first and last entry in the following  |
Rem  | "arrays" which are not really arrays, honest!                  |
Rem   ================================================================
set FirstDump=0
set LastDump=8

Rem   ================================================================
Rem  | The following "arrays" are not arrays. They look like they are | 
Rem  | but are actually just a pile of scalar variables with '[n]' in |
Rem  | their name. Oh, and we have to use '!variable_name! later on   |
Rem  | too for some unfathomable reason.                              |
Rem   ================================================================

Rem   ================================================================
Rem  | List of dump files that we will be importing. They must exist. |
Rem   ================================================================
set DumpFiles[0]=exp_NOROWS.dmp
set DumpFiles[1]=exp_ROWS_FCS1.dmp 
set DumpFiles[2]=exp_ROWS_FCS2D.dmp
set DumpFiles[3]=exp_ROWS_FCS3.dmp 
set DumpFiles[4]=exp_ROWS_FCS4.dmp 
set DumpFiles[5]=exp_ROWS_FCS5.dmp 
set DumpFiles[6]=exp_ROWS_FCS6.dmp 
set DumpFiles[7]=exp_ROWS_FCS7.dmp 
set DumpFiles[8]=exp_ROWS_NOFCS.dmp

Rem   ================================================================
Rem  | List of parameter files to run the imports for us.             |
Rem   ================================================================
set ParFiles[0]=imp_NOROWS.par
set ParFiles[1]=imp_ROWS_FCS1.par 
set ParFiles[2]=imp_ROWS_FCS2D.par
set ParFiles[3]=imp_ROWS_FCS3.par 
set ParFiles[4]=imp_ROWS_FCS4.par 
set ParFiles[5]=imp_ROWS_FCS5.par 
set ParFiles[6]=imp_ROWS_FCS6.par 
set ParFiles[7]=imp_ROWS_FCS7.par 
set ParFiles[8]=imp_ROWS_NOFCS.par

Rem   ================================================================
Rem  | List of log files that we will be scanning.                    |
Rem   ================================================================
set LogFiles[0]=imp_NOROWS.log
set LogFiles[1]=imp_ROWS_FCS1.log 
set LogFiles[2]=imp_ROWS_FCS2D.log
set LogFiles[3]=imp_ROWS_FCS3.log 
set LogFiles[4]=imp_ROWS_FCS4.log 
set LogFiles[5]=imp_ROWS_FCS5.log 
set LogFiles[6]=imp_ROWS_FCS6.log 
set LogFiles[7]=imp_ROWS_FCS7.log 
set LogFiles[8]=imp_ROWS_NOFCS.log


Rem   ================================================================
Rem  | Clear any existing logfile.                                    |
Rem   ================================================================
Rem 
del %MYLOG% > nul 2>&1

call :log %0 - v%VERSION% : Logging to %MYLOG%
call :log Executing: %0 %*


Rem   ================================================================
Rem  | Help requested?                                                |
Rem   ================================================================
echo X_%1_X | find /i "X_HELP_X" > nul
if %ERRORLEVEL% EQU 0 (
    call :usage
    goto :eof
)


Rem   ================================================================
Rem  | Commandline Parameters.                                        |
Rem   ================================================================
set SID=%1
set RESTART_REQUIRED=%2


Rem   ================================================================
Rem  | Parameter Validation.                                          |
Rem   ================================================================
set ERRORS=0
set RESTART_OK=0


:check_sid

if "%SID%" EQU "" (
	call :log ORACLE_SID was not passed on commandline.
	set ERRORS=1
) else (
    call :log Refreshing database %SID%.
)


:check_restart

if "%RESTART_REQUIRED%" EQU "" (
	call :log RESTART_REQUIRED was not passed on commandline.
	set ERRORS=1
    goto :check_home
)

Rem It might be NORESTART, but it could be NORESTARTING etc
Rem Make sure we only catch NORESTART.
echo X_%RESTART_REQUIRED%_X | find /i "X_NORESTART_X" > nul
if %ERRORLEVEL% EQU 0 (
    set RESTART_REQUIRED=NORESTART
    set RESTART_OK=1
    call :log Database will not be closed prior to the refresh.
    goto :check_home
)

Rem It might be RESTART, but it could be DON'T RESTART!
Rem Make sure we only catch RESTART.
echo X_%RESTART_REQUIRED%_X | find /i "X_RESTART_X" > nul
if %ERRORLEVEL% EQU 0 (
    set RESTART_REQUIRED=RESTART
    set RESTART_OK=1
    call :log Database will be closed prior to the refresh.
    call :log ARCHIVELOG and FLASHBACK modes will be disabled
    call :log  prior to,and re-enabled, after the refresh.
)

Rem We should now have either RESTART or NORESTART
if %RESTART_OK% NEQ 1 (
    set ERRORS=1
    call :log Invalid RESTART parameter supplied - %RESTART_REQUIRED%
)


:check_home

if "%ORACLE_HOME%" EQU "" (
	call :log ORACLE_HOME is not defined.
	set ERRORS=1
    goto :check_dumps
)

echo %path% | find /i "%oracle_home%\bin" > nul
if %ERRORLEVEL% EQU 1 (
    call :log ORACLE_HOME - %oracle_home%\bin - is not on PATH.
    set ERRORS=1
)

Rem Does imp.exe exist in %oracle_home%\bin?
if not exist %oracle_home%\bin\imp.exe (
    call :log %oracle_home%\bin\imp.exe - not found.
    set ERRORS=1
)

Rem Is the %oracle_home%\network\admin\sqlnet.ora file set up correctly?
Rem Assuming it exists of course.
if not exist %oracle_home%\network\admin\sqlnet.ora (
    call :log %oracle_home%\network\admin\sqlnet.ora not found.
    goto :check_dumps
)    

    call :log %oracle_home%\network\admin\sqlnet.ora found.
    find /i "SQLNET.AUTHENTICATION_SERVICES" %oracle_home%\network\admin\sqlnet.ora | find /i "NTS" | find "#" > nul
    if %ERRORLEVEL% EQU 0 (
        Rem We have the commented version, or, there's no entry in sqlnet.ora.
       	call :log ****************************************************************
        call :log Please set "SQLNET.AUTHENTICATION_SERVICES = (NTS)" in file
        call :log %oracle_home%\network\admin\sqlnet.ora
        call :log and comment out any other setting in the file. We cannot
        call :log connect to the database with the current setting.
	    call :log ****************************************************************
        set ERRORS=1
    )


:check_dumps

if not exist %DUMPS_LOCATION% (
	call :log DUMPS_LOCATION - %DUMPS_LOCATION% - does not exist.
	set ERRORS=1
    goto :check_logs
)

for /L %%f in (%FirstDump%, 1, %LastDump%) do (
    if not exist %DUMPS_LOCATION%\!DumpFiles[%%f]! (
        call :log Dump File - !DumpFiles[%%f]! - does not exist.
        set ERRORS=1
    )
)


:check_logs

if not exist %LOGS_LOCATION% (
	call :log LOGS_LOCATION - %LOGS_LOCATION% - does not exist.
	set ERRORS=1
)


:check_parfiles

if not exist %PARFILES_LOCATION% (
	call :log PARFILES_LOCATION - %PARFILES_LOCATION% - does not exist.
	set ERRORS=1
    goto :check_scripts
)

for /L %%f in (%FirstDump%, 1, %LastDump%) do (
    if not exist %PARFILES_LOCATION%\!ParFiles[%%f]! (
        call :log Parameter File - !ParFiles[%%f]! - does not exist.
        set ERRORS=1
    )
)


:check_scripts

if not exist %SCRIPTS_LOCATION% (
	call :log SCRIPTS_LOCATION - %SCRIPTS_LOCATION% - does not exist.
	set ERRORS=1
    goto :check_errors
)

if not exist %BATCH_IMPORT_SCRIPT% (
	call :log BATCH_IMPORT_SCRIPT - %BATCH_IMPORT_SCRIPT% - does not exist.
	set ERRORS=1
)


:check_errors

if %ERRORS% EQU 1 (
	call :log Cannot continue with refresh - too many errors.
    call :usage
	goto :eof
)


Rem   ================================================================
Rem  | Save the old stuff. In case the user has set these differently.|
Rem  | We set NLS_DATE_FORMAT to null as there's a bug in the database|
Rem  | design which forgot to use TO_DATE() on a VARCHAR2 default for |
Rem  | a DATE column. Go figure!                                      |
Rem   ================================================================
Rem 
set old_oracle_sid=%oracle_sid%
set nls_old_format=%nls_date_format%

set oracle_sid=%SID%
set nls_date_format=


Rem  *****************************************************************
Rem  *****************************************************************
Rem  **         Let's do it. The hard work starts here....          **
Rem  *****************************************************************
Rem  *****************************************************************
Rem 

Rem Do we need to disable ARCHIVELOG and FLASHBACK DATABASE modes?
if %RESTART_REQUIRED% EQU "RESTART" (
    call :log Shutting down the %oracle_sid% database to disable
    call :log ARCHIVELOG and FLASHBACK DATABASE modes.
    sqlplus "/ as sysdba" @%SCRIPTS_LOCATION%\ShutDownRestart.sql
)

Rem Delete existing data.
call :log About to delete existing data.
sqlplus "/ as sysdba" @%SCRIPTS_LOCATION%\PreRefresh.sql

Rem Import the new tables etc. No indexes or constraints though.
call :log Running NOROWS import.
imp parfile=%PARFILES_LOCATION%\imp_NOROWS.par

Rem Post NOROWS tidyup etc.
call :log Running post_import_norows script.
sqlplus "/ as sysdba" @%SCRIPTS_LOCATION%\post_import_norows.sql

Rem Submit multiple imports, wait for completion.
Rem This will submit each of the required (8) separate imports.
call :log Submitting ROWS imports, and waiting for completion.
call :log ***********************************************************
call :log ***********************************************************
call :log ** DO NOT kill this session, it waits for over 24 hours. **
call :log **   Please find something else to do for a day or so.   **
call :log ***********************************************************
call :log ***********************************************************
call %BATCH_IMPORT_SCRIPT% 


Rem Windows doesn't have the ability to wait for a multiple set 
Rem Of spawned processes. Sigh. We have to look for all the imp
Rem processes that are running, and if any are found, delay for
Rem a while, then check again. 

:delay_loop

Rem The following works, but burns CPU as it prints a message
Rem counting down from whatever the /t value is given as. We are
Rem going to be needing every last CPU we can use, so avoid this
Rem timeout command in this instance. (Standard on Windows 7 & 8.)
Rem timeout /t 600 /nobreak

Rem The following passes the processing off to the network. And
Rem doesn't appear to burn any host CPU cycles. It delays for 
Rem the specified number of -w milli-seconds. We wait 15 minutes.
Rem 15 minutes * 60 seconds * 1,000 = 900,000 milli-seconds.
call :log Waiting for imp.exe processes to complete.
ping -n 1 -w 900000 1.1.1.1 > nul

Rem Every 15 minutes, check if any imp.exe processes are still
Rem running. If so, delay for another 15 minutes.
tasklist /FI "imagename eq imp.exe" | find /i "imp.exe" > nul
if %ERRORLEVEL% EQU 0 (
    goto :delay_loop
)

Rem All import's have completed. Is there a way to determine
Rem if they were successful or not? Other than scanning the 
Rem logfiles?
Rem 
Rem The NOROWS import always has warnings, these can be ignored.

Rem It seems that we cannot use goto within a FOR loop. Sigh.

call :log Checking import logfiles ....
call :log ***********************************************************
setlocal EnableDelayedExpansion
for /L %%f in (%FirstDump%, 1, %LastDump%) do (
    call :check_log %LOGS_LOCATION%\!LogFiles[%%f]!
)
call :log ***********************************************************


Rem Post ROWS tidyup etc.
call :log Running post_import_rows script.
sqlplus "/ as sysdba" @%SCRIPTS_LOCATION%\post_import_rows.sql



Rem Do we need to enable ARCHIVELOG and FLASHBACK DATABASE modes?
if %RESTART_REQUIRED% EQU "RESTART" (
    call :log Shutting down the %oracle_sid% database to enable
    call :log ARCHIVELOG and FLASHBACK DATABASE modes.
    sqlplus "/ as sysdba" @%SCRIPTS_LOCATION%\PostRefresh.sql
)


Rem   ================================================================
Rem  | Restore the old stuff - return the user to a known state.      |
Rem   ================================================================
Rem 
set oracle_sid=%old_oracle_sid%
set nls_date_format=%nls_old_format%


Rem   ================================================================
Rem  | And finally, turn off the "doing it correctly" setting. Sigh.  |
Rem  | And skip over the sub-routines.                                |
Rem   ================================================================
Rem 
call :log %0 - complete.
endlocal
exit /b


Rem  *******************************************************************
Rem  *******************************************************************
Rem  ** Here endeth the main code. The following are all CALLable     **
Rem  ** subroutines either because we need them a lot, or, because    **
Rem  ** Windows can't cope with some things we need to do. (I'm       **
Rem  ** looking at you "FIND" in a loop!)                             **
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
Rem  |                                                    CHECK_LOG() |
Rem   ================================================================
Rem  | This code is called to check each of the import log files to   |
Rem  | determine if the import completed and if there were warnings or|
Rem  | errors etc. This should be able to be inserted above in the    |
Rem  | main code, but it seems that Windoze can't manage to do this in|
Rem  | a loop as it always returns "successful" regardless of the log |
Rem  | contents. And yes, I did try in many different ways before I   |
Rem  | had to extract it to here. Sigh.                               |
Rem   ================================================================
:check_log

    Rem Assume no errors or warnings.
    find /i "without warnings" %1
    if %ERRORLEVEL% EQU 0 (
        call :log %1 - completed successfully.
	goto :eof
    )

    Rem Assume warnings, if the above failed.
    find /i "with warnings" %1
    if %ERRORLEVEL% EQU 0 (
        call :log %1 - completed with warnings. Please check.
	goto :eof
    )

    Rem Assume errors, if the above failed.
    find /i "with errors" %1
    if %ERRORLEVEL% EQU 0 (
        call :log %1 - completed with errors. Please check.
	goto :eof
    )

    Rem It seems all the above failed.
    call :log %1 - completed with unknown status. Check the logfile.
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
echo * dbRefresh  oracle_sid  [no]restart                              *
echo *                                                                 *
echo * Oracle_sid  - database to be refreshed. Will be trashed.        *
echo * [no]restart - database will be shutdown and mounted, archivelog *
echo *               and flashback database will be disabled prior to  *
echo *               the refresh and enabled afterwards.               *
echo  =================================================================
goto :eof
    