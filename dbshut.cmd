@echo off

REM ===============================================================================
REM Shut down any running Oracle Database services for the current server. This
REM script's name & path must be listed in the Group Policy shutdown script list.
REM
REM -------------------------------------------------------------------------------
REM start->Run->cmd
REM type in "gpedit.msc" and press ENTER
REM Navigate to:
REM Settings->Computer Configuration->Windows Settings->Scripts startup/shutdown
REM Double-click on Shutdown
REM Browse to, and select this script to add it to the shutdown scripts.
REM
REM This will cause the script to be called when the server is about to be closed.
REM It will not be called if the server simply has the plug pulled.
REM -------------------------------------------------------------------------------
REM 
REM Norman Dunbar
REM 14th April 2016.
REM ===============================================================================

REM -------------------------------------------------------------------------------
REM INFORMATION:
REM -------------------------------------------------------------------------------
REM Net Start displays all running services.
REM Find /i "OracleService" extracts only those with "OracleService" in their name.
REM Net Stop XXX stops service xxx.
REM
REM FOR /F %%S IN ('command') DO (something) - calls "something" for each value in 
REM        'command'. But you are not allowed to have piped commands.
REM -------------------------------------------------------------------------------


REM -------------------------------------------------------------------------------
REM The Code Start Here ....
REM -------------------------------------------------------------------------------
REM Extract a list of all the running services. It would be nice to filter out only
REM running Oracle Services here, but we can't used piped commands in a FOR. :-(
REM And, because we have to call a subroutine for everything, we don't get more 
REM than THE FIRST WORD of the service details passed over.
REM -------------------------------------------------------------------------------
FOR /F %%s IN ('net start') DO (call :CheckAndStop %%s)
goto :eof


REM -------------------------------------------------------------------------------
REM Passed the service name. Checks for an Oracle service. If found, stops it.
REM -------------------------------------------------------------------------------
:CheckAndStop
	echo "%1" | find /i "OracleService" > nul
	if %ERRORLEVEL% == 0 (
		echo Stopping Oracle Service: %1
		echo net stop %1
		
		if %ERRORLEVEL% NEQ 0 (
			echo Service %1 failed to stop. Error %ERRORLEVEL%
		)
	) 

	REM I need this to return from a call. Sigh.
	REM But, I don't need an EOF label. Double sigh.
	goto :eof
