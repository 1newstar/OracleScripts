============================
Oracle Trace Files Explained
============================

Introduction
============

Oracle trace files are not greatly documented. This document is an attempt to do so. It is not official in any way and is based on a good few years of reading these files to help diagnose various database problems.

A trace file is really the best way to delve into what Oracle is doing, or to discover why something is taking so long - it shows you exactly what happened during the period that the session was being traced.

Even better, when you extract an Explain Plan from a trace file, it is showing you exactly how Oracle retrieved the data from the tables, and exactly where the time was spend in doing so. Running an ``Explain Plan for ...`` statement in SQL*Plus, Toad etc tells you what Oracle *might* do. The two are not always the same.

TraceAdjust
-----------

**Unashamed plug** 

*TraceAdjust* is a utility that I wrote to help me process the myriads of trace files that I come across in my DBA work. You can get the source code from github at
``https://github.com/NormanDunbar/TraceAdjust`` and compile it on Windows or Linux/Unix with any decent C++ compiler.

It reads a normal trace file and writes out an adjusted one, as follows:

-   The ``tim`` values are converted to seconds, by inserting a decimal point in the appropriate position;
-   It adds a ``delta`` to each ``tim`` line. The delta is the number of microseconds between the ``tim`` on this line, and the ``tim`` on the previous (appropriate) trace line. This al;lows me to see how long passed between the previous ``tim`` and this one. Occasionally useful!
-   It adds a ``dslt`` to each ``tim`` line. This is the "delta since last timestamp" and simply counts up the number of microseconds that have passed since the trace file last produced a timestamp line similar to the one in the header. Again, occasionally useful.
-   It adds a ``local`` to each ``tim`` line. This is a conversion of the ``tim`` value on the line, to an actual date, in the current local timezone. The time part is resolved down to microsecond level. This is usually very useful!

Running a trace file through TraceAdjust will create a new trace file, which some trace  analysing utilities cannot cope with due to the additional fields that I have introduced. The Trace File Browser, in Toad, on the other hand, copes with my trace files quite happily and simply ignores the additional data as appropriate.

Trace File Sections
===================

The trace file is made up of two main sections, the header and the trace details. 

The Header
----------

The header is the top of the file and consists of a few lines of text giving details of where the trace file came from, which server (operating System) it was created on, various details about the server and the database and so on.

The following is an example of a trace file created on a Windows server, running Oracle 11.2.0.4. Server, database and other potentially sensitive information has been obfuscated to protect the guilty, me!

..  code-block:: none

    Trace file C:\ORACLEDATABASE\diag\rdbms\cfg\cfg\trace\cfg_ora_27680_FREESPACE.trc
    Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
    Windows NT Version V6.2  
    CPU                 : 8 - type 8664, 8 Physical Cores
    Process Affinity    : 0x0x0000000000000000
    Memory (Avail/Total): Ph:29917M/57343M, Ph+PgF:24634M/65535M 
    Instance name: orcl
    Redo thread mounted by this instance: 1
    Oracle process number: 373
    Windows thread id: 27680, image: ORACLE.EXE (SHAD)


    *** 2017-06-27 13:56:36.872
    *** SESSION ID:(1017.1085) 2017-06-27 13:56:36.872
    *** CLIENT ID:() 2017-06-27 13:56:36.872
    *** SERVICE NAME:(ORCLSRV) 2017-06-27 13:56:36.872
    *** MODULE NAME:(TOAD background query session) 2017-06-27 13:56:36.872
    *** ACTION NAME:() 2017-06-27 13:56:36.872
 
    =====================
    
The last line, consisting of equals signs, is the separator between the header and the following trace details.

Timestamp Lines
---------------

One line that you should be interested in is this one from the above:

..  code-block:: none

    *** 2017-06-27 13:56:36.872

This is the first timestamp line in the trace file and sets the baseline for all the ``tim`` fields (these will be explained below) that follow, however, briefly, the ``tim`` values are in microseconds (millionths of a second) from a specific "epoch" - which depends on the operating system - and there isn't a consistent, operating system independent, method of converting ``tim`` values from a huge number of microseconds to an actual date and time that humans will understand.

There are usually a few timestamp lines written to the trace file, depending on how long it has been processing for, and these mean that we can, with a bit of fiddling, relate a ``tim`` value to an actual time on the clock.

    
Trace Details
-------------

The majority of the trace file consists of the full trace details for the session that was traced. There are numerous lines of text here, each different, each with their own fields of one kind or another.

These are explained in the following sections.

There are a few common details that you need to be aware of in trace files. 

Recursive SQL
~~~~~~~~~~~~~

Your SQL statements are normally executed as top-level statements, but Oracle might need to execute some (a lot!) of recursive SQL statements, in order that your statement can be processed.

If, for example, you drop a user in a database with the ``drop user xxx cascade`` statement, Oracle goes off and executes hundreds of separate SQL statement to find out what objects the user owns, or has privileges to, and undoes all of those before finally dropping the contents of the user and finally the user itself.

Top-level SQL statements are identified by having a depth of zero. This can be seen in many of the trace file lines as ``dep=0`` in the various lines of the trace file.

Recursive statements, executed in the background, have a depth greater than zero, and some of these require recursive statements of their own, and so on.

This recursion leads to a foible in the trace file, your statement appears last and all the possibly nested, recursive statements will normally appear first. This is simply because in order for your statement to be executed, the recursive statements have to run to completion *first*.

For example, in a trace file I have open in front of me, the first statement with a ``dep=0`` occurs at line 709 in the file. Everything prior to that runs at ``dep=3``, ``dep=2`` or ``dep=1`` and complete before I can see my own SQl statement.

Under normal circumstances, a statement that is parsed (executed etc) at ``dep=n`` has been called recursively, to facilitate a statement, that will follow in the trace file, that is itself parsed (executed etc) at ``dep=n-1``.

Waits
~~~~~

``WAIT`` lines in a trace file are similar, in that the ``WAIT`` must complete, and so is written to the trace file *before* the statement that incurred the wait. For example, a ``FETCH`` that had to wait for ``db file scattered read`` events, will appear later in the trace file that the individual ``WAIT`` lines that the ``FETCH`` suffered from.

Cursor Ids
~~~~~~~~~~

Every time you see a '#' followed by a number, you are looking at a cursor ID. In previous versions of Oracle, these were simply an ever increasing number, starting from 1 and increasing by 1 for each new cursor.

In Oracle 11g, the cursor *appears* to be an address in memory[1]_, and *will be reused* as cursors are closed and new ones opened. You cannot assume, therefore, that a cursor with a specific ID at the end of the trace file, relates to any other lines with that same ID previously written to the trace file, without checking for any intervening ``CLOSE`` lines with the same ID - that's just how it is now!

Trace File Details
==================

PARSING IN CURSOR
-----------------

This is usually the first line you will see for a cursor. It shows the full SQL statement between the ``PARSING IN CURSOR`` line and the ``END OF STMT`` line. The SQL is displayed exactly as the user (or application) entered it.

This is not the ``PARSE`` for the cursor though, that normally follows on later, usually!

As an example, here is the ``PARSING IN CURSOR`` line for the SQL query that Toad runs in the background to extract the free space used in the database by various tablespaces, including temporary ones:

..  code-block:: none

    PARSING IN CURSOR #3220341128 len=3081 dep=0 uid=0 oct=3 lid=0 tim=3520788574727 hv=3219027813 ad='7ffcb6778350' sqlid='7bwtj5azxwxv5'

The various fields defined, and their descriptions can be seen in the table below.
    
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| len      | The size, in characters, of the SQL statement.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| uid      | The user id of the user parsing the statement.  |
+----------+-------------------------------------------------+
| oct      | Oracle Command Code of the SQL Statement. (See  |
|          | Appendices.)                                    |
+----------+-------------------------------------------------+
| lid      |  Unknown.                                       |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+
| hv       | Hash Value for the statement.                   |
+----------+-------------------------------------------------+
| ad       | Cursor address in memory?                       |
+----------+-------------------------------------------------+
| sqlid    | The SQL ID for the statement.                   |
+----------+-------------------------------------------------+

The ``lid`` field is unknown at present. It's probably an ID of some kind, but for what?

As mentioned, the cursor ID field has a value that may (or may not) be an address in memory. However, that's not the same as the ``ad`` field, which is (I think) an address in memory for the cursor. 


PARSE
-----

+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

PARSE ERROR
-----------
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+

EXEC
----
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

FETCH
-----
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

WAIT
----
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

ERROR
-----
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+

STAT
----
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

CLOSE
-----

An example of a ``CLOSE`` line from a trace file is as follows:

..  code-block:: none

    CLOSE #3220452784:c=0,e=13,dep=0,type=0,tim=3520822918452

+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| #nnnn    | The cursor ID. This may be reused if for future |
|          | cursors if this one is closed, and another      |
|          | opened.                                         |
+----------+-------------------------------------------------+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| type     | Unknown.                                        |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

This line is written when a cursor used for an SQL statement, is no longer required and has been closed. The elapsed times relate to the time it took to close the cursor.

The ``type`` field is currently unknown, but I have seen two values here zero and 3. So far I have not been able to determine what this means as the values relate to PL/SQL and SQL cursors, those opened with the rule based optimiser and those with the cost based one. Nothing seems to match up.

A cursor ID that has been closed may be re-used by a subsequent opening of a new cursor, which can be for a different statement, or for this one again.

XCTEND
------
+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| c        | Elapsed CPU time. Microseconds.                 |
+----------+-------------------------------------------------+
| e        | Elapsed wall clock time, also in microseconds.  |
+----------+-------------------------------------------------+
| dep      | Recursion level. 0 = Top-level, user, SQL.      |
+----------+-------------------------------------------------+
| tim      | Time, in microseconds, for this statement to be |
|          | parsed. This is not the time it took!           |
+----------+-------------------------------------------------+

BINDS
-----

The following are some of the fields used in the descriptions of each individual Bind variable in a trace file. Anything not listed below is of an unknown nature.

+----------+-------------------------------------------------+
| Code     | Description                                     |
+==========+=================================================+
| oacdty   | Data type code. (See Appendices)                |
+----------+-------------------------------------------------+
| mxl      | Maximum length of the bind variable value.      |
+----------+-------------------------------------------------+
| mal      | Array length.                                   |
+----------+-------------------------------------------------+
| scl      | Scale - NUMBER data types only (oacdty = 2).    | 
+----------+-------------------------------------------------+
| pre      | Precision - NUMBER data types only (oacdty = 2).|
+----------+-------------------------------------------------+
| oacflg   | Special flag indicating bind options.           |
+----------+-------------------------------------------------+
| fl2      | Second part of oacflg.                          |
+----------+-------------------------------------------------+
| csi      | Character set identifier. (See Appendices)      |
+----------+-------------------------------------------------+
| siz      | Amount of memory to be allocated for this chunk.|
+----------+-------------------------------------------------+
| off      | Offset into the chunk of the bind buffer.       |
+----------+-------------------------------------------------+
| kxsbbbfp | Bind address.                                   |
+----------+-------------------------------------------------+
| bln      | Bind buffer length.                             |
+----------+-------------------------------------------------+
| avl      | Actual value length.                            |
+----------+-------------------------------------------------+
| flg      | Bind status flag.                               |
+----------+-------------------------------------------------+
| value    | Value of the bind variable (See Appendices).    |
+----------+-------------------------------------------------+


==========
Appendices
==========

Oracle Data Types
=================

The ``oacdty`` parameter in a bind variables details determines the data type of that bind variable. This is not necessarily the data type of the column in a table that it may be being ``INSERT``ed or ``UPDATE``d into, or compared against.

The following data are taken from the *Internal Data Types* section of the *Data Types* chapter in the 12cR2 *Oracle Call Interface* manual, which you can find at `<http://docs.oracle.com/database/122/LNOCI/data-types.htm#LNOCI16266>`_.

Listed data types are:

+------+--------------------------------+
| Code | Data Type                      |
+======+================================+
| 1    | VARCHAR2 or NVARCHAR2          |
+------+--------------------------------+
| 2    | NUMBER                         |
+------+--------------------------------+
| 8    | LONG                           |
+------+--------------------------------+
| 11   | ROWID[22]_                     |
+------+--------------------------------+
| 12   | DATE                           |
+------+--------------------------------+
| 23   | RAW                            |
+------+--------------------------------+
| 24   | LONG RAW                       |
+------+--------------------------------+
| 25   | Unhandled data type            |
+------+--------------------------------+
| 29   | Unhandled data type            |
+------+--------------------------------+
| 69   | ROWID                          |
+------+--------------------------------+
| 96   | CHAR or NCHAR                  |
+------+--------------------------------+
| 100  | BINARY_FLOAT                   |
+------+--------------------------------+
| 101  | BINARY_DOUBLE                  |
+------+--------------------------------+
| 102  | REF_CURSOR[23]_                |
+------+--------------------------------+
| 108  | User-defined type -            |
|      | object type, VARRAY,           |
|      | nested table)                  |
+------+--------------------------------+
| 111  | REF                            |
+------+--------------------------------+
| 112  | CLOB or NCLOB                  |
+------+--------------------------------+
| 113  | BLOB                           |
+------+--------------------------------+
| 114  | BFILE                          |
+------+--------------------------------+
| 123  | VARRAY[24]_                    |
+------+--------------------------------+
| 180  | TIMESTAMP                      |
+------+--------------------------------+
| 181  | TIMESTAMP WITH TIME ZONE       |
+------+--------------------------------+
| 182  | INTERVAL YEAR TO MONTH         |
+------+--------------------------------+
| 183  | INTERVAL DAY TO SECOND         |
+------+--------------------------------+
| 208  | UROWID                         |
+------+--------------------------------+
| 231  | TIMESTAMP WITH LOCAL TIME ZONE |
+------+--------------------------------+

However, various other sources on the internet, and in books, seem to disagree with some of what the above table shows. In addition, I have come across at least one Oracle Trace where a ROWID was code 11 and not code 69, also, I have seen VARRAY as code 123 and not as code 108. Consistency? Who mentioned consistency?


Oracle Command Codes
====================

The ``oct`` parameter in a PARSING IN CURSOR line in an Oracle trace file, determines the command that is being parsed in the SQL statement.

Known command types are:

+------+-----------------+
| Code | Data Type       |
+======+=================+
| 2    | INSERT          |
+------+-----------------+
| 3    | SELECT          |
+------+-----------------+
| 6    | UPDATE          |
+------+-----------------+
| 7    | DELETE          |
+------+-----------------+
| 26   | LOCK TABLE      |
+------+-----------------+
| 44   | COMMIT          |
+------+-----------------+
| 45   | ROLLBACK        |
+------+-----------------+
| 46   | SAVEPOINT       |
+------+-----------------+
| 47   | PL/SQL Block    |
+------+-----------------+
| 48   | SET TRANSACTION |
+------+-----------------+
| 55   | SET ROLE        |
+------+-----------------+
| 90   | SET CONSTRAINTS |
+------+-----------------+
| 170  | CALL            |
+------+-----------------+
| 189  | MERGE           |
+------+-----------------+

The following two tables outline the various command codes and are taken from an Oracle 12.1.0.2 database.

The first table shows codes 0 through 169, ``Unknown`` to ``Disassociate Statistics``:

+------+-----------------------+------+------------------------------+------+-----------------------------+
| Code | Command               | Code | Command                      | Code | Command                     |
+======+=======================+======+==============================+======+=============================+
| 0    | UNKNOWN               | 53   | DROP USER                    | 111  | DROP PUBLIC SYNONYM         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 1    | CREATE TABLE          | 54   | DROP ROLE                    | 112  | CREATE PUBLIC DATABASE LINK |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 2    | INSERT                | 55   | SET ROLE                     | 113  | DROP PUBLIC DATABASE LINK   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 3    | SELECT                | 56   | CREATE SCHEMA                | 114  | GRANT ROLE                  |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 4    | CREATE CLUSTER        | 57   | CREATE CONTROL FILE          | 115  | REVOKE ROLE                 |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 5    | ALTER CLUSTER         | 59   | CREATE TRIGGER               | 116  | EXECUTE PROCEDURE           |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 6    | UPDATE                | 60   | ALTER TRIGGER                | 117  | USER COMMENT                |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 7    | DELETE                | 61   | DROP TRIGGER                 | 118  | ENABLE TRIGGER              |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 8    | DROP CLUSTER          | 62   | ANALYZE TABLE                | 119  | DISABLE TRIGGER             |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 9    | CREATE INDEX          | 63   | ANALYZE INDEX                | 120  | ENABLE ALL TRIGGERS         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 10   | DROP INDEX            | 64   | ANALYZE CLUSTER              | 121  | DISABLE ALL TRIGGERS        |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 11   | ALTER INDEX           | 65   | CREATE PROFILE               | 122  | NETWORK ERROR               |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 12   | DROP TABLE            | 66   | DROP PROFILE                 | 123  | EXECUTE TYPE                |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 13   | CREATE SEQUENCE       | 67   | ALTER PROFILE                | 128  | FLASHBACK                   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 14   | ALTER SEQUENCE        | 68   | DROP PROCEDURE               | 129  | CREATE SESSION              |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 15   | ALTER TABLE           | 70   | ALTER RESOURCE COST          | 130  | ALTER MINING MODEL          |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 16   | DROP SEQUENCE         | 71   | CREATE MATERIALIZED VIEW LOG | 131  | SELECT MINING MODEL         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 17   | GRANT OBJECT          | 72   | ALTER MATERIALIZED VIEW LOG  | 133  | CREATE MINING MODEL         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 18   | REVOKE OBJECT         | 73   | DROP MATERIALIZED VIEW LOG   | 134  | ALTER PUBLIC SYNONYM        |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 19   | CREATE SYNONYM        | 74   | CREATE MATERIALIZED VIEW     | 135  | DIRECTORY EXECUTE           |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 20   | DROP SYNONYM          | 75   | ALTER MATERIALIZED VIEW      | 136  | SQL*LOADER DIRECT PATH LOAD |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 21   | CREATE VIEW           | 76   | DROP MATERIALIZED VIEW       | 137  | DATAPUMP DIRECT PATH UNLOAD |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 22   | DROP VIEW             | 77   | CREATE TYPE                  | 138  | DATABASE STARTUP            |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 23   | VALIDATE INDEX        | 78   | DROP TYPE                    | 139  | DATABASE SHUTDOWN           |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 24   | CREATE PROCEDURE      | 79   | ALTER ROLE                   | 140  | CREATE SQL TXLN PROFILE     |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 25   | ALTER PROCEDURE       | 80   | ALTER TYPE                   | 141  | ALTER SQL TXLN PROFILE      | 
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 26   | LOCK                  | 81   | CREATE TYPE BODY             | 142  | USE SQL TXLN PROFILE        | 
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 27   | NO-OP                 | 82   | ALTER TYPE BODY              | 143  | DROP SQL TXLN PROFILE       |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 28   | RENAME                | 83   | DROP TYPE BODY               | 144  | CREATE MEASURE FOLDER       |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 29   | COMMENT               | 84   | DROP LIBRARY                 | 145  | ALTER MEASURE FOLDER        |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 30   | AUDIT OBJECT          | 85   | TRUNCATE TABLE               | 146  | DROP MEASURE FOLDER         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 31   | NOAUDIT OBJECT        | 86   | TRUNCATE CLUSTER             | 147  | CREATE CUBE BUILD PROCESS   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 32   | CREATE DATABASE LINK  | 88   | ALTER VIEW                   | 148  | ALTER CUBE BUILD PROCESS    |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 33   | DROP DATABASE LINK    | 91   | CREATE FUNCTION              | 149  | DROP CUBE BUILD PROCESS     |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 34   | CREATE DATABASE       | 92   | ALTER FUNCTION               | 150  | CREATE CUBE                 |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 35   | ALTER DATABASE        | 93   | DROP FUNCTION                | 151  | ALTER CUBE                  |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 36   | CREATE ROLLBACK SEG   | 94   | CREATE PACKAGE               | 152  | DROP CUBE                   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 37   | ALTER ROLLBACK SEG    | 95   | ALTER PACKAGE                | 153  | CREATE CUBE DIMENSION       |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 38   | DROP ROLLBACK SEG     | 96   | DROP PACKAGE                 | 154  | ALTER CUBE DIMENSION        |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 39   | CREATE TABLESPACE     | 97   | CREATE PACKAGE BODY          | 155  | DROP CUBE DIMENSION         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 40   | ALTER TABLESPACE      | 98   | ALTER PACKAGE BODY           | 157  | CREATE DIRECTORY            |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 41   | DROP TABLESPACE       | 99   | DROP PACKAGE BODY            | 158  | DROP DIRECTORY              |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 42   | ALTER SESSION         | 100  | LOGON                        | 159  | CREATE LIBRARY              |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 43   | ALTER USER            | 101  | LOGOFF                       | 160  | CREATE JAVA                 |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 44   | COMMIT                | 102  | LOGOFF BY CLEANUP            | 161  | ALTER JAVA                  |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 45   | ROLLBACK              | 103  | SESSION REC                  | 162  | DROP JAVA                   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 46   | SAVEPOINT             | 104  | SYSTEM AUDIT                 | 163  | CREATE OPERATOR             |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 47   | PL/SQL EXECUTE        | 105  | SYSTEM NOAUDIT               | 164  | CREATE INDEXTYPE            |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 48   | SET TRANSACTION       | 106  | AUDIT DEFAULT                | 165  | DROP INDEXTYPE              |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 49   | ALTER SYSTEM          | 107  | NOAUDIT DEFAULT              | 166  | ALTER INDEXTYPE             |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 50   | EXPLAIN               | 108  | SYSTEM GRANT                 | 167  | DROP OPERATOR               |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 51   | CREATE USER           | 109  | SYSTEM REVOKE                | 168  | ASSOCIATE STATISTICS        |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 52   | CREATE ROLE           | 110  | CREATE PUBLIC SYNONYM        | 169  | DISASSOCIATE STATISTICS     |
+------+-----------------------+------+------------------------------+------+-----------------------------+

The second table shows codes 170 through 305, ``Call Method`` to ``Alter Public database Link``. You should notice a gap between 242 and 304 inclusive, I wonder what Oracle have in mind for those values?

+------+-----------------------+------+------------------------------+------+-----------------------------+
| Code | Command               | Code | Command                      | Code | Command                     |
+======+=======================+======+==============================+======+=============================+
| 170  | CALL METHOD           | 199  | PURGE TABLESPACE             | 218  | CREATE FLASHBACK ARCHIVE    |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 171  | CREATE SUMMARY        | 200  | PURGE TABLE                  | 219  | ALTER FLASHBACK ARCHIVE     |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 172  | ALTER SUMMARY         | 201  | PURGE INDEX                  | 220  | DROP FLASHBACK ARCHIVE      |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 173  | DROP SUMMARY          | 202  | UNDROP OBJECT                | 225  | ALTER DATABASE LINK         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 174  | CREATE DIMENSION      | 204  | FLASHBACK DATABASE           | 226  | CREATE PLUGGABLE DATABASE   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 175  | ALTER DIMENSION       | 205  | FLASHBACK TABLE              | 227  | ALTER PLUGGABLE DATABASE    |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 176  | DROP DIMENSION        | 206  | CREATE RESTORE POINT         | 228  | DROP PLUGGABLE DATABASE     |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 177  | CREATE CONTEXT        | 207  | DROP RESTORE POINT           | 229  | CREATE AUDIT POLICY         |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 178  | DROP CONTEXT          | 208  | PROXY AUTHENTICATION ONLY    | 230  | ALTER AUDIT POLICY          |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 179  | ALTER OUTLINE         | 209  | DECLARE REWRITE EQUIVALENCE  | 231  | DROP AUDIT POLICY           |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 180  | CREATE OUTLINE        | 210  | ALTER REWRITE EQUIVALENCE    | 232  | CODE-BASED GRANT            |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 181  | DROP OUTLINE          | 211  | DROP REWRITE EQUIVALENCE     | 233  | CODE-BASED REVOKE           |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 182  | UPDATE INDEXES        | 212  | CREATE EDITION               | 238  | ADMINISTER KEY MANAGEMENT   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 183  | ALTER OPERATOR        | 213  | ALTER EDITION                | 239  | CREATE MATERIALIZED ZONEMAP |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 190  | PASSWORD CHANGE       | 214  | DROP EDITION                 | 240  | ALTER MATERIALIZED ZONEMAP  |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 192  | ALTER SYNONYM         | 215  | DROP ASSEMBLY                | 241  | DROP MATERIALIZED ZONEMAP   |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 197  | PURGE USER_RECYCLEBIN | 216  | CREATE ASSEMBLY              | ---  | Lots Missing Here!          |
+------+-----------------------+------+------------------------------+------+-----------------------------+
| 198  | PURGE DBA_RECYCLEBIN  | 217  | ALTER ASSEMBLY               | 305  | ALTER PUBLIC DATABASE LINK  |
+------+-----------------------+------+------------------------------+------+-----------------------------+

The exact list of commands for your particular database version can be extracted using the following SQL command:

..  code-block:: sql

    select action as code,
           name as command
    from audit_action;

There are 212 different commands in Oracle 12c (12.1.0.2) while Oracle 11g (11.2.0.4) has only (!) 181.

Oracle Characterset Codes
=========================

Some data types use different character sets. These are coded in the ``csi`` field in the bind details lines of the trace file. Typical values that you may see here are as follows:

+------+---------------+
| Code | Character Set |
+======+===============+
| 1    | US7ASCII      |
+------+---------------+
| 31   | WE8ISO8859P1  |
+------+---------------+
| 46   | WE8ISO8859P15 |
+------+---------------+
| 170  | EE8MSWIN1250  |
+------+---------------+
| 178  | WE8MSWIN1252  |
+------+---------------+
| 871  | UTF8          |
+------+---------------+
| 873  | AL32UTF8      |
+------+---------------+
| 2000 | AL16UTF16     |
+------+---------------+

Examples
--------

Example 1 - ALUTF16
~~~~~~~~~~~~~~~~~~~

..  code-block:: none

    Bind#0
      oacdty=96 mxl=128(50) mxlc=00 mal=00 scl=00 pre=00
      oacflg=01 fl2=1000010 frm=02 csi=2000 siz=128 off=0
      kxsbbbfp=1109ffe98  bln=128  avl=22  flg=05
      value=0 34 0 32 0 35 0 33 0 35 0 32 0 2d 0 39 0 30 0 30 0 37 

This bind has ``csi=2000`` so it is using the ALUTF16 character set for its value, which happens to decode as '425352-9007'.

Example 2 - WE8ISO8859P1
~~~~~~~~~~~~~~~~~~~~~~~~

..  code-block:: none

    Bind#1
      oacdty=01 mxl=32(04) mxlc=00 mal=00 scl=00 pre=00
      oacflg=10 fl2=0001 frm=01 csi=31 siz=0 off=24
      kxsbbbfp=610cd550  bln=32  avl=04  flg=01
      value="DUAL"

This bind, on the other hand, has ``csi=31`` so it is using the WE8ISO8859P1 character set. You can see the value in the extract above.


=======

| Author: Norman Dunbar
| Email: norman@dunbar-it.co.uk
| Last Updated: 21st July 2017.


..  [1] But don't quote me on this, I saw it written down somewhere on the Oracle Support web site, but now that I need it, I cannot find it again. Sigh!

..  [22] Code 11 is not officially listed by Oracle, but I have seen it in a trace file of my own for a ROWID data type.

..  [23] Code 102 is not officially listed by Oracle, but I've seen REF CURSORs with this code in my own trace files.

..  [24] Code 123 is not officially listed by Oracle, but I have seen it in a trace file of my own for a VARRAY data type.