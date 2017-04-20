===========
DBA Code QA
===========

Why?
====

To try an prevent problems in production from occurring due to incorrectly written, or tested, code.


Rules
=====

The following is a non-exclusive list of requirements that we expect to see in any code release being applied to production.

- All changes should be accompanied by valid Release Notes.

- All code will be QA'd by the production DBAs before being considered for execution. Any code that has not been QA'd by the production DBAs will not be considered for execution.

- The DBA *will not* be permitted to make changes to any code supplied to him/her in order to make it run or to fix 'obvious' problems, etc. The code is assumed to have been fully tested and therefore, should run without change. If the DBA considers that changes are required, then the code must be rejected as it is potentially untested code. The exception to this rule is where code runs in Toad, for example, without a trailing semi-colon, or slash, but in SQL*Plus it does not. See the following rule, however.

- The code *must* be able to run in ``SQL*Plus``. This is the only SQL access to any databases in a production environment, which can be guaranteed. ``Toad``, ``SQLSDeveloper`` etc are not installed by default, or are not guaranteed to be available on all database servers. 

- Code will *not* ``COMMMIT`` or ``ROLLBACK``. Code will instead, ``PROMPT`` the DBA to do so depending on whether or not the code ran successfully.

- Code that mixes DML with DDL will not be accepted. DDL commands - ``CREATE``, ``ALTER``, ``DROP`` and others, including ``GATHER_STATS`` for example, ``COMMIT`` before starting, and after finishing successfully. This renders all DML up to that point as also being committed and unable to be rolled back. Scripts that do require a mix of DDL and DML must be separated into constituent parts. 

- Where code has DDL and DML scripts, the DDL scripts must all be executed *before* any DML can be run. The only exceptions to this are where the DML scripts prompt the DBA to ``COMMIT`` or ``ROLLBACK`` - these *can* be followed by DDL scripts as the data are already known to be in a valid state.

- Code that is run on production will be *identical* to the code that runs on production. *No changes* are permitted between the test runs, and the live runs. If code needs to be changed to run on either system, it should be parameterised so that the correct values can be used at run time - and the release notes must fully document the desired parameters for each run.

- All code will spool to a log file. This prevents errors from simply vanishing up the screen as the code is executed.

- All SQL commands will be run with ``SET ECHO ON``. PL/SQL commands creating packages etc, need not if the listings are large.

- If a script is ``SELECT``\ ing lots of data, it should make sure to ``SET LINES 2000 TRIMSPOOL ON PAGES 2000`` to ensure that the amount of output is reduced to manageable levels.

- All compilations or ``CREATE OR REPLACE`` of ``PACKAGE``s, ``PROCEDURE``s, ``FUNCTION``s, or other stored PL/SQL objects, must be followed by a ``SHOW ERRORS`` command suitable for the object being created or replaced. ``SHOW ERRORS PACKAGE BODY flintstone`` for example. These must be logged to the spool file.

- Any 'urgent' changes will be fully supported by the appropriate developer, on site at the time the code is to be deployed in case of errors/problems. The DBA shall not be left to deal with code problems.

- Dates must be stored in DATE or TIMESTAMP columns. Passing dates (and times) to a script, or procedure for use in tables etc, must be done correctly. Strings are not acceptable, unless wrapped in a TO_DATE() or TO_TIMESTAMP() accordingly.

