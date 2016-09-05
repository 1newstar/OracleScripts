@echo off
:: Lists all the service that are for an Oracle database
:: and which are currently running. 
::
:: NOTE: This doesn't mean that the databases are up
:: only that the services are. It is possible for a
:: service to be running and the database not yet started.
::
:: Norman Dunbar 1 September 2016.
::
echo The following database services are running:
echo.
net start | find /i "OracleService" | sort
echo.
echo NOTE: The databases themselves might need to be started.
echo.

:: There's a pause in case someone double-clicks in Explorer.
pause
