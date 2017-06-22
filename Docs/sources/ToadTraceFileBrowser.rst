=========================
Toad's Trace File Browser
=========================

************
Introduction
************

Overview
========

The Trace File Browser, in Toad, is accessed from the ``Database -> Diagnose -> Trace File Browser`` menu option. It allows the DBA/Developer the ability to open a trace file either locally, on the database server or via FTP from a remote server, and analyse the contents.

The raw trace file can be opened in the default external editor if the DBA wishes to consult the raw data in its entirety. The default external editor is set up in toad using ``View -> Toad Options``, click ``Executables`` on the left side and on the right side, you will find a button to assist you to define whichever external editor you wish to use. Or, there's always ``notepad`` I suppose!

The display in Toad has two sections, both with a set of tabbed screens, showing various important parts of the trace file analysis. These are described below. Just about every tab, top or bottom, has a set of options that affect the data displayed on that particular screen.

The following discussion assumes that a trace file has been opened for analysis.

Warning
=======

You might, if you are a seasoned trace file viewer, notice some additional fields in the various trace file ``PARSE #``, ``EXEC #``, ``FETCH #`` and ``WAIT #`` records in the examples elsewhere in this document. For example:

..  code-block:: none

    CLOSE #1016887568:c=0,e=2,dep=2,type=0,tim=1268756.332276,delta=0,dslt=700999,local='2017 Jun 22 08:49:45.700999'
    
These additional fields are added by my own utility `TraceAdjust <https://github.com/NormanDunbar/TraceAdjust>`_ which adjusts a trace file as follows:

-   Adds a decimal point into the ``tim`` field to show full and fractional seconds. ``Tim`` values are in microseconds - at least from Oracle 10g onwards - since some epoch, according to the operating system:

    ..  code-block:: none
    
        tim=1268756.332276
        
-   Adds a ``delta=`` field which shows the number of microseconds difference between this ``tim`` value and the previous ``tim`` value.

    ..  code-block:: none
    
        delta=0
        
-   Adds a ``dslt`` field to show the running ``tim`` deltas since the last timestamp record in the trace file. These timestamp records are the lines that Oracle writes where the actual date and time, plus fractions of a second, are listed, prefixed by '***'. 


    ..  code-block:: none
    
        dslt=700999

    These timestamp records are used by ``TraceAdjust`` to synchronise the ``tim`` values with a real wall clock time, and resemble the following:
    
    ..  code-block:: none
    
        *** 2017-06-22 08:49:45.732
        
-   Adds a ``local`` field to show what the ``tim`` value in this record means when converted to a local timestamp which is adjusted for daylight savings etc.

    ..  code-block:: none
    
        local='2017 Jun 22 08:49:45.700999'
        
The fact that the Toad Trace File Browser copes easily with my added fields shows how well written it has been! Other trace file utilities are, sadly, not so forgiving.

******************************
Trace File Analysis - Top Tabs
******************************

The tabs at the top of the screen show details about the overall content of the trace file.

Statement Details
=================
When you open a trace file, all SQL statements are summarised here. 

Filtering
---------

In addition to listing the entire SQL contents of the trace file, certain filters become available when a trace file is open, allowing you to:

-   Show every statement in the trace file. The default.
-   Show only those statements which suffered from ``log file sync`` waits. In other words, where a ``COMMIT`` was held up.
-   Show only those statement which suffered from ``SQL*Net message from client`` waits.
-   Show only those statement which suffered from ``SQL*Net message to client`` waits. 
-   Show only those statement which suffered from ``SQL*Net more data to client`` waits.

By *suffered from* I do of course, mean *encountered* these waits during their execution.

You may also filter by SQL text, which has a separate text entry area to enter the actual text that you will be searching for. The default here is '*' and indicates that everything will be displayed.

In this case, you might notice that a SQL statement does not appear to contain the requested text. Check the recursive statements for the affected SQL as there will be one or more of those which *do* contain the requested text.

If you simply search for ``DUAL`` then nothing will be found. You should search for:

-   '*DUAL' - any statement, or recursive statement which *ends* with the text 'DUAL'.
-   'SELECT*' - any statement, or recursive statement which *begins* with the text 'SELECT'.
-   '*MANAGER*' - any statement, or recursive statement which *contains* the text 'MANAGER'.

Searches are case insensitive, 'DUAL' is the same as 'dual' or 'DuaL' etc.

Wildcards that can be used are:

-   '*' to represent any number of characters;
-   '?' to represent a single character.


These filters will only show the rows affected by the filter properties, however, be aware that when a top level SQL statement has recursive statements attached - you will see a '+' at the start of the parent statement, then if the recursive statements don't have the waits being filtered, then they will not be seen, even if a '+' exists to indicate recursive statements exist.

A further option exists to allow you to *query the database to decode object IDs*. If you tick this option, various ``WAIT`` event which have their P1, P2, P3 or P4 holding a object_id will have that object_id converted to details of the object_type, object_name and owner. These are displayed on the statement's 'Waits' tab on the lower part of the screen.

When you tick the option, you are required to select from all existing database connections, or start a new one, so that the correct objects can be decoded.

Options
-------

The right-click context menu in this tab offers the following options:

-   Print - Prints the list of SQL statements to a printer, which you may choose on the dialogue(s) that follow. There doesn't appear to be a print preview option - at least, not in Toad version 12.1.0.22.
-   Save - saves the SQL statement list to a text file. To be brutally honest, the lines are so long and wide, it's not so easy to read - the contents of the current tab in the Trace File Browser is much better laid out. (Other opinions are available!)
-   Send to Excel - does *exactly* as it says. The contents of the tab are exported directly to Excel.
-   Expand All - expands all SQL statements with recursive SQL to display all the recursive statements.
-   Collapse All - collapses and hides all the recursive statements. Only a '+' is shown to indicate which top level statements have recursive SQL statements.
-   Include Percentages - displays, or otherwise, the percentage of the total of some counter, that the current statement consumed. For example, a statement may have taken 0.001865 seconds to process (parse, exec, fetch, wait etc) - the percentage shown is the percentage of the whole trace file that this small period of time made up. 
-   Fix Statement Column - 
-   Display Full recursion

Wait Summary
============

Options
-------

The right-click context menu in this tab offers the following options:


Waits by Object
===============

Options
-------

The right-click context menu in this tab offers the following options:


Query Summary
=============

Options
-------

The right-click context menu in this tab offers the following options:


File Header
===========

The file header is simply the contents of the first few lines of the trace file being analysed. Everything from the file, down to the first "separator line" is listed. Don't be surprised if you find a rogue ``CLOSE #`` statement, for example, listed here. If it is above the first line with a number of consecutive '=' signs, it's considered part of the trace file header.

For example:

..  code-block:: none

    Trace file C:\ORACLEDATABASE\diag\rdbms\prduat\prduat\trace\prduat_ora_5864_JOE.trc
    Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
    Windows NT Version V6.2  
    CPU                 : 4 - type 8664, 4 Physical Cores
    Process Affinity    : 0x0x0000000000000000
    Memory (Avail/Total): Ph:6369M/28671M, Ph+PgF:16521M/55295M 
    Instance name: prduat
    Redo thread mounted by this instance: 1
    Oracle process number: 89
    Windows thread id: 5864, image: ORACLE.EXE (SHAD)


    *** 2017-06-22 08:49:45.701
    *** TraceAdjust v0.10: Base Timestamp Adjusted to 'Thu Jun 22 08:49:45 2017'
    *** SESSION ID:(403.1891) 2017-06-22 08:49:45.701
    *** CLIENT ID:() 2017-06-22 08:49:45.701
    *** SERVICE NAME:(PRDUAT) 2017-06-22 08:49:45.701
    *** MODULE NAME:(w3wp.exe) 2017-06-22 08:49:45.701
    *** ACTION NAME:() 2017-06-22 08:49:45.701
     
    CLOSE #1016887568:c=0,e=2,dep=2,type=0,tim=1268756.332276,delta=0,dslt=700999,local='2017 Jun 22 08:49:45.700999'


Options
-------

The right-click context menu in this section has the usual text editor options which allow you to ``select``, ``cut``, ``copy`` etc, from the text displayed in the file header tab. There's nothing much here that will not be familiar already.


*********************************
Trace File Analysis - Bottom Tabs
*********************************

The tabs at the bottom of the screen, generally, show details about something that is selected or highlighted in the top set of tabs. Indeed, the lower section of the display is labelled *Details of Selected Statement*.

SQL Statement
=============

Options
-------

The right-click context menu in this tab offers the following options:


Explain Plan
============
This tab displays the explain plan for the highlighted SQL statement. The difference between what is displayed here, and what might have been displayed for an ``explain plan for...`` for the highlighted statement is simple. This is what *actually* took place. Cardinalities are exact, for example, and not estimated form the optimiser statistics, histograms etc.

Options
-------

The right-click context menu in this tab offers the following options:

-   Print - Prints the explain plan.
-   Save - saves the explain plan.
-   Send to Excel - does *exactly* as it says. The explain plan is exported directly to Excel.
-   Expand All - expands all plan steps to display all the recursive steps.
-   Collapse All - collapses and hides all the recursive steps. Only a '+' is shown to indicate which top level steps have recursive steps.

Parses
======

This tab shows you the parse details for the highlighted statement. You are able to see whether this was a hard or soft parse, for example, and the times taken in terms of CPU and elapsed time to parse the SQL. You should be trying to avoid parsing as much as possible - statements should ideally be parsed once, but executed many times.

Parses are like `Highlanders <https://en.wikipedia.org/wiki/Highlander_(film)>`_, *there can be only one* - at any one time.

Options
-------

The right-click context menu in this tab offers the following options:

-   Print - Prints the parse details.
-   Save - saves the parse details.
-   Send to Excel - does *exactly* as it says. The parse details are exported directly to Excel.

Executions
==========

This tab shows you the execution details for the highlighted statement. You can see exactly how long the statement took to execute and how many blocks it read to process the displayed number of rows.

Where a statement has recursive SQL, then those totals are included in the totals for the parent SQL statement.

Parses are like `Highlanders <https://en.wikipedia.org/wiki/Highlander_(film)>`_, *there can be only one* - at any one time.

Options
-------

The right-click context menu in this tab offers the following options:

-   Print - Prints the execution details.
-   Save - saves the execution details.
-   Send to Excel - The execution details are exported directly to Excel.



Fetches
=======

Options
-------

The right-click context menu in this tab offers the following options:


Waits
=====

Options
-------

The right-click context menu in this tab offers the following options:


Wait Summary
============

Options
-------

The right-click context menu in this tab offers the following options:


Transaction Waits
=================

Options
-------

The right-click context menu in this tab offers the following options:


Deadlock
========

Options
-------

The right-click context menu in this tab offers the following options:


Raw Data
========

Options
-------

The right-click context menu in this tab offers the following options:


