How to Break Latex
==================

..  The 'A' in 'Anything ...' below, MUST line up under the previous line's 'D' and 
..  not under the first backtick or Latex output will:
..      Create a description list, rather than a list item;
..      Fail to note the end of said description list;
..      break the build!

..  You cannot put comments inside a list - that breaks docx and latex builds too.

..  You need to leave a blank line between the start and end of an embedded/nested list
..  or you get weird results for the last entry of the embedded list and/or the first
..  of the nesting list after it.

..  The following is a test extracted from RMANCloning.rst.

..  BEGIN TEST EXTRACT

We can ignore any of the following parameters:

-   ``AUDIT_FILE_DEST``
-   ``CONTROL_FILES``
-   ``DB_RECOVERY_FILE_DEST``
-   Anything that lives in ``%ORACLE_BASE%`` or ``%ORACLE_HOME%``. These usually include:

    *   ``BACKGROUND_DUMP_DEST``
    *   ``CORE_DUMP_DEST``
    *   ``DG_BROKER_CONFIG_FILE%``
    *   ``DIAGNOSTIC_DEST``
    *   ``SPFILE``
    *   ``STANDBY_ARCHIVE_DEST``
    *   ``USER_DUMP_DEST``
    
-   ``NLS_DATE_FORMAT`` :-)  

These are explicitly set by the ``RMAN`` commands to create the clone database 
or default to acceptable values when the database is created and/or opened.

..  END TEST EXTRACT