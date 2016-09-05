@echo off
Rem   ================================================================
Rem  |Check an existing Oracle Home for expensive EE Options          |
Rem  |                                                                |
Rem  | Norman Dunbar.                                                 |
Rem  | August 2016.                                                   |
Rem   ================================================================
Rem 
Rem 
Rem   ================================================================
Rem  | USAGE:                                                         |
Rem  |                                                                | 
Rem  | checkChoptOptions [oracle_home]                                | 
Rem  |                                                                |
Rem   ================================================================
Rem 

setlocal EnableDelayedExpansion


Rem   ================================================================
Rem  | Internal Variables.                                            |
Rem   ================================================================
set VERSION=1.00
set ERRORS=0
set MYLOG=.\%0.log
set ORA_HOME=%1

Rem   ================================================================
Rem  | The next two define the first and last entry in the following  |
Rem  | "arrays" which are not really arrays, honest!                  |
Rem   ================================================================
set FirstEntry=0
set LastEntry=6


Rem   ================================================================
Rem  | The following "arrays" are not arrays. They look like they are | 
Rem  | but are actually just a pile of scalar variables with '[n]' in |
Rem  | their name. Oh, and we have to use '!variable_name! later on   |
Rem  | too for some unfathomable reason.                              |
Rem   ================================================================

Rem   ================================================================
Rem  | List of Oracle chopt'able options.                             |
Rem   ================================================================
set Option[0]=Partitioning
set Option[1]=OLAP
set Option[2]=Label Security
set Option[3]=Data Mining
set Option[4]=Database Vault option
set Option[5]=Real Application Testing
set Option[6]=Database Extensions for .NET

Rem   ================================================================
Rem  | List of DLLs that exist for enabled options.                   |
Rem   ================================================================
set Enabled[0]=oraprtop11.dll
set Enabled[1]=oraolapop11.dll
set Enabled[2]=oralbac11.dll
set Enabled[3]=oradmop11.dll
set Enabled[4]=oradv11.dll
set Enabled[5]=orarat11.dll
set Enabled[6]=clr

Rem   ================================================================
Rem  | List of DLLs that exist for disabled options.                   |
Rem   ================================================================
set Disabled[0]=oraprtop11.dll.dbl
set Disabled[1]=oraolapop11.dll.dbl
set Disabled[2]=oralbac11.dll.dbl
set Disabled[3]=oradmop11.dll.dbl
set Disabled[4]=oradv11.dll.dbl
set Disabled[5]=orarat11.dll.dbl
set Disabled[6]=clr.dbl

Rem   ================================================================
Rem  | Clear any existing logfile.                                    |
Rem   ================================================================
Rem 
del %MYLOG% > nul 2>&1

call :log %0 - v%VERSION% : Logging to %MYLOG%
call :log Executing: %0 %*



:check_oracle_home
if "%ORA_HOME%" EQU "" (
    set ORA_HOME=%ORACLE_HOME%
)

if "%ORACLE_HOME%" EQU "" (
	call :log ORACLE_HOME is not defined.
	set ERRORS=1
)

if not exist %ORA_HOME% (
    call :log ORACLE_HOME "%ORA_HOME%" - not found.
    set ERRORS=1
)

:check_errors

if %ERRORS% EQU 1 (
	call :log Cannot continue - too many errors.
	goto :eof
)


Rem *******************************************************************
Rem *******************************************************************
:JDI

call :log Checking ORACLE_HOME = "%ORA_HOME%".

for /L %%f in (%FirstEntry%, 1, %LastEntry%) do (

    Rem Is this option enabled?
    if exist %ORA_HOME%\bin\!Enabled[%%f]! (
        call :log !Option[%%f]! - is currently enabled.
    )
    
    Rem Also check if it is disabled too. This needs investigating.
    if exist %ORA_HOME%\bin\!Disabled[%%f]! (
        call :log !Option[%%f]! - is currently disabled.
    )
)
Rem *******************************************************************
Rem *******************************************************************

Rem   ================================================================
Rem  | And finally, turn off the "doing it correctly" setting.        |
Rem  | And skip over the sub-routines.                                |
Rem   ================================================================
Rem 
call :log %0 - complete.
endlocal
exit /b



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
