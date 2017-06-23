=========================
Toad's Trace File Browser
=========================

************
Introduction
************

The following details are applicable to Toad version 12.1.0.22 as this is the current version that I have. There may be changes in any later versions. Please bear this in mind.

Overview
========

The Trace File Browser, in Toad, is accessed from the ``Database -> Diagnose -> Trace File Browser`` menu option. It allows the DBA/Developer the ability to open a trace file either locally, on the database server or via FTP from a remote server, and analyse the contents.

The raw trace file can be opened in the default external editor if the DBA wishes to consult the raw data in its entirety. The default external editor is set up in toad using ``View -> Toad Options``, click ``Executables`` on the left side and on the right side, you will find a button to assist you to define whichever external editor you wish to use. Or, there's always ``notepad`` I suppose!

The display in Toad has two sections, both with a set of tabbed screens, showing various important parts of the trace file analysis. These are described below. Just about every tab, top or bottom, has a set of options that affect the data displayed on that particular screen.

The following discussion assumes that a trace file has been opened for analysis.

TraceAdjust Utility
===================

You might, if you are a seasoned trace file viewer, notice some additional fields in the various trace file ``PARSE``, ``EXEC``, ``FETCH`` and ``WAIT`` records in the examples elsewhere in this document. For example:

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

Sorting Results
===============

In all of the table, whether top or bottom of the display, clicking on a column header will allow you to sort on that column. Click once to sort one way (ascending perhaps) and again to reverse the sort order.

The sorted column will display an arrow pointing in the general direction of up or down to indicate the sort order on this column.

Only one column can be sorted.

Wait Details
============

Some of the more common wait events are displayed in the various 'Wait \*' tabs in blue text with underlines. If you double click on these event names, a pop-up window will appear giving some helpful information about the wait in question and how to avoid it.

For example, the following details appear if you double-click a 'log file sync' wait event:

..  code-block:: none

    Wait Event: log file sync
    Wait Class: Commit

    Redo log writer process has to flush the log buffer for a session commit, which the log file sync has to wait for to complete

    Possible solutions are: 
    
        * Commit less frequently 
        * Increase the size and/or number of redo log files 
        * Use faster disks 
        * Do not place log files on RAID 5 devices, which are generally too slow for numerous writes. 
        * Improve CPU priority/resources for redo log processing 


******************************
Trace File Analysis - Top Tabs
******************************

The tabs at the top of the screen show details about the overall content of the trace file. The tabs visible here are:

-   Statement Details
-   Wait Summary
-   Waits by Object
-   Query Summary
-   File Header

Statement Details
=================
When you open a trace file, all SQL statements found in the trace file are listed here. 

Filtering
---------

By Wait Event
~~~~~~~~~~~~~

In addition to listing the entire SQL contents of the trace file, certain filters become available when a trace file is open, allowing you to select a wait event to use to filter statements. The drop down will be populated with all the wait events detected within the trace file.

By SQL Text
~~~~~~~~~~~

You may also filter by SQL text, which has a separate text entry area to enter the actual text that you will be searching for. The default here is '\*' and indicates that everything will be displayed.

In this case, you might notice that a SQL statement does not appear to contain the requested text. Check the recursive statements for the affected SQL as there will be one or more of those which *do* contain the requested text.

If you simply search for ``DUAL`` then nothing will be found. You should search for:

-   '\*DUAL' - any statement, or recursive statement which *ends* with the text 'DUAL'.
-   'SELECT\*' - any statement, or recursive statement which *begins* with the text 'SELECT'.
-   '\*MANAGER\*' - any statement, or recursive statement which *contains* the text 'MANAGER'.

Searches are case insensitive, 'DUAL' is the same as 'dual' or 'DuaL' etc.

Wildcards that can be used are:

-   '\*' to represent any number of characters;
-   '?' to represent a single character.


These filters will only show the rows affected by the filter properties, however, be aware that when a top level SQL statement has recursive statements attached - you will see a '+' at the start of the parent statement, then if the recursive statements don't have the waits being filtered, then they will not be seen, even if a '+' exists to indicate recursive statements exist.

Object Id Decoding
------------------

A further option exists to allow you to *query the database to decode object IDs*. If you tick this option, various ``WAIT`` event which have their P1, P2, P3 or P4 holding a object_id will have that object_id converted to details of the object_type, object_name and owner. These are displayed on the statement's 'Waits' tab on the lower part of the screen.

When you tick the option, you are required to select from all existing database connections, or start a new one, so that the correct objects can be decoded.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the list of SQL statements to a printer, which you may choose on the dialogue(s) that follow. There doesn't appear to be a print preview option - at least, not in Toad version 12.1.0.22.
-   **Save** - saves the SQL statement list to a text file. To be brutally honest, the lines are so long and wide, it's not so easy to read - the contents of the current tab in the Trace File Browser is much better laid out. (Other opinions are available!)
-   **Send to Excel** - does *exactly* as it says. The contents of the tab are exported directly to Excel.
-   **Expand All** - expands all SQL statements with recursive SQL to display all the recursive statements.
-   **Collapse All** - collapses and hides all the recursive statements. Only a '+' is shown to indicate which top level statements have recursive SQL statements.
-   **Include Percentages** - displays, or otherwise, the percentage of the total of some counter, that the current statement consumed. For example, a statement may have taken 0.001865 seconds to process (parse, exec, fetch, wait etc) - the percentage shown is the percentage of the whole trace file that this small period of time made up. 
-   **Fix Statement Column** - **??????????????????**
-   **Display Full Recursion** - **??????????????????**

Wait Summary
============

This tab simply lists all the unique wait events that were encountered while processing the trace file. *All* waits encountered will be summarised on this tab. The view will list the total number of each event that occurred and the number of statements in the trace file, that encountered this particular wait event.

Also displayed are the minimum wait, maximum wait and the average wait (the `arithmetic mean <https://en.wikipedia.org/wiki/Mean>`_ average) - but beware of putting too much emphasis on the latter as any number of events with wildly varying wait times can lead to a much lower than normal average as the various values are spread out. You should concentrate on the maximum wait times - those are the problem area, usually.

This tab is a reasonably good place to begin your trace file analysis as it displays in full details, exactly where the process traced spent most of its time waiting.

Options
-------

The right-click context menu in the *top half* of the display offers the following options:

-   **Print** - prints the wait summary details.
-   **Save** - saves the wait summary details.
-   **Send to Excel** - the wait summary details are exported directly to Excel.
-   **Hide Idle Events** - does what it says! It hides all events which have a value of 'Yes' in the 'Idle' column. See the warning above for a good reason *not* to select this option!


When you click on a wait event in the list, the bottom half of the display will list all those statements which encountered the selected wait event. Various details of how badly affected each statement was by the wait, are also seen here.

Options
-------

The right-click context menu in the *lower part* of the display offers the following options:

-   **Print** - prints the statement list.
-   **Save** - saves the statement list.
-   **Send to Excel** - the statement list is exported directly to Excel.
-   **Find Statement on Details Tab** - switches the display to the 'Statement Details' tab, and selects the chosen SQL statement thereon. You can also double-click a wait event to carry out the same process.

Waits by Object
===============

This tab lists waits by object_id. For some trace files, this will only show a single object_id of -1. This is the case when the trace file contains only -1 in each of the P4 wait event parameters. This usually indicates that the waits in the trace file were not related to a particular object - you had no ``DB File sequential read`` wait events, for example, as that wait event *would* have object_ids associated.

Clicking on the object_id in the top half of the display opens up a list of all statements that had the selected object_id in the P4 parameter, in the lower part of the display.

In the lower part, double-click a statement to open in in the 'Statement Details' tab. I suspect this is a missing menu option, as we can see an option to do exactly this in the 'Wait Summary' tab's context menu.

If you have selected a session to 'Query database to decode object IDs' on the 'Statement Details' tab, then the first column here will show the object details as opposed to an object_id.

    **Bug?**: Sorting by object_id, when decoding is not in effect, sorts by the *textual* representation of the object_ids, as opposed to by their *numeric* values. So, 4, 40, 400 etc would appear together.

Options
-------

The right-click context menu in this tab, upper and lower halves, offers the following options:

-   **Print** - prints the contents.
-   **Save** - saves the contents.
-   **Send to Excel** - the contents are exported directly to Excel.

Query Summary
=============

The 'Query Summary' tab is possibly incorrectly named. Perhaps it should be 'Trace File Summary' as that is actually what it shows!

There are three main parts to this tab.

-   Trace File Summary
-   Summary Graph
-   Statements List

Trace File Summary
------------------

There is a wealth of detail in this part of the tab. It displays such items as:

-   Total number of statements in the trace file;
-   How many were user level (non-recursive) statements;
-   Hard parse count (try to keep this as low as possible!)
-   ``COMMIT`` and ``ROLLBACK`` counts;
-   First and last timestamps in the file. See below though.
-   Etc.

    **Bug?** I have noticed a few trace files do not get their last timestamp listed, even though it does exist in the file. Toad simply states *<no timestamps in file>* for these traces. Hmm.

This section of the display has a lot of helpful and useful information. 

Options
~~~~~~~

This section of the display does not have a right-click context menu.

Summary Graph
-------------

Pretty pictures! 

Beneath the graph, there is a drop down list of options that control which of the pretty pictures you will see. The left axis shows the number of queries while the bottom axis shows the time/count ranges for each of the options available.

Above each bar of the graph is a small box showing the total number of statements included in this bar's value. This is hugely useful as the 3D effect of the bars and `axes <http://mathworld.wolfram.com/Axis.html>`_ (plural of axis!) can be difficult to work out the exact value.

The graph options, in the drop down, are:

-   **Exec Time** - each bar of the graph shows the number of statements which took certain times to carry out the ``EXEC`` phase of processing the entire statement. You can easily find the most affected statements on this graph and investigate further, if necessary.
-   **Fetch Time** - each bar of the graph shows the number of statements which took certain times to carry out the ``FETCH`` phase of processing the entire statement. You can easily find the most affected statements on this graph and investigate further, if necessary.
-   **Parse Time** - each bar of the graph shows the number of statements which took certain times to carry out the ``PARSE`` phase of processing the entire statement. You can easily find the most affected statements on this graph and investigate further, if necessary.
-   **Wait Time** - each bar of the graph shows the number of statements which took certain times to carry out the ``WAIT`` phase of processing the entire statement. You can easily find the most affected statements on this graph and investigate further, if necessary.
-   **Exec Time + Parse Time + Fetch Time + Wait Time** - The sum of all three above. This graph gives you the total *response time* for the various statements, and response times are really what we as DBAs should be concentrating on, as it is the response time that the users see and suffer from!
-   **Consistent Reads** - each bar of the graph displays the total number of statements which carried out a range of consistent reads in order to process the statement. (See below!)
-   **Current Reads** - each bar of the graph displays the total number of statements which carried out a range of current reads in order to process the statement. (See below!)
-   **Physical Reads** - each bar of the graph displays the total number of statements which carried out a range of physical reads in order to process the statement. (See below!)
-   **Execution Count** - each bar of the graph shows the number of statements which were executed a number of time according to the counts specified on the lower axis of the graph.

    Sadly, I suspect *most* trace files in many companies, will shows that everything was executed once only. Sigh!

In case you are wondering about the three 'Reads' options above, here you are:

Consistent Reads
    A normal reading of a block from the buffer cache. A check will be made if the data needs reconstructing from rollback information to give you a consistent view as of the time that the query started. If so, as many rollback blocks as necessary will be applied - to a clone of the actual data block - to revert the data to the desired point in time.
Current Reads
    Oracle internally (Mostly? Always?) getting data blocks where it does not have to check for the need to reconstruct the data from rollback information. Reading segment header blocks, for example, would be a current read.
Physical Reads
    Where Oracle has to get a block from the I/O subsystem and put it in the cache. This could also be considered a current read I suppose, when it's passed unchanged to the application?

    **Credits**: The above is an amalgamation of various official and unofficial sources on the Web, in Oracle Docs, Ask Tom etc. I have the same problems it appears, trying to remember what these things are! See `Martin Widlake's Blog <https://mwidlake.wordpress.com/2009/06/02/what-are-consistent-gets/>`_ for more info. He did *all* the hard work.

Options
~~~~~~~

You may right-click on the graph and choose to:

-   **Copy to Clipboard** - copies the image of the graph being displayed to the clipboard.
-   **Save** - allows you to save the graph as an image file. Only the Windows 'bmp' format is supported.
-   **Print** - prints the image.
-   **Display User and Recursive Statements Separately** - splits the graph to show separately, the user and recursive statements for each time/count range. 

    **Bug?** This latter option shows a possible bug. When the separate images are being graphed, some of the bars in the graph do not display a (full) list of statements until the images are combined again. I've seen 4 statements show as a completely empty list, and 7 statements show as a single statement in the list. When combined, all statements display correctly.

Statements List
---------------

This section of the display shows details of all the statements which correspond to the clicked bar of the 'Summary Graph' above.

Options
~~~~~~~

The right-click context menu in this section offers the following options:

-   **Print** - prints the statement list.
-   **Save** - saves the statement list.
-   **Send to Excel** - the statement list are exported directly to Excel.
-   **Include Percentages** - shows or hides the percentage of the total trace file for certain of the values displayed here. It's a toggle and remains on or off until changed. 

    It does clear the entire lower section and you have to click on the correct bar again to get the change to display!
    
    It also displays percentages in the lower axis titles for the 'Summary Graphs' section of the display.

Double-click a statement in the list to open it in the 'Statement Details' tab. Another missing menu entry? Perhaps!

File Header
===========

The file header is simply the contents of the first few lines of the trace file being analysed. Everything from the file, down to the first "separator line" is listed. Don't be surprised if you find a rogue ``CLOSE`` statement, for example, listed here. If it is above the first line with a number of consecutive '=' signs, it's considered part of the trace file header.

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

The tabs at the bottom of the display will only be visible when the 'Statement Details' tab is the active tab in the upper part of the display.

The tabs at the bottom of the screen, generally, show details about something that is selected or highlighted in the top set of tabs. Indeed, the lower section of the display is labelled *Details of Selected Statement*.

The tabs displayed in the lower part of the screen are:

-   SQL Statement
-   Explain Plan
-   Parses
-   Executions
-   Fetches
-   Waits
-   Wait Summary
-   Transaction Waits
-   Deadlock
-   Raw data

SQL Statement
=============

When a statement is selected in the upper part of the display, it will have it's details show here, in the lower part.

On the 'SQL Statement' tab, the display is split in two:

-   the Bind Details section is on the left;
-   The Statement Text is on the right.

Bind Details
------------

If the highlighted statement has any bind variables, they are displayed here, with the values used by this execution of the statement. This are will be blank if the statement has no binds.

    **Bug?**: Sometimes the display shows 'NULL' for some (NUMBER?) bind variables and at other times, correctly shows the values. This is a problem in 12.1.0.22 and may be fixed in later versions.

Statement Text
--------------

The full text of the statement is displayed in this section. 

Options
-------

The right-click context menu in the binds section tab offers the following options:

-   **Print** - prints the bind details.
-   **Save** - saves the bind details.
-   **Send to Excel** - the bind details are exported directly to Excel.

The right-click context menu in the binds section tab offers the following options:

-   **Format** - this is a 'sticky' option. You toggle it on or off as desired, and it remains set accordingly, for all subsequent statement views. The SQL text displayed is formatted according to the formatting rules that you have set up (or left as default) in the main Toad editor. (Right-click and select ``Formatting Tools -> Formatter Options``.)

Explain Plan
============
This tab displays the explain plan for the highlighted SQL statement. The difference between what is displayed here, and what might have been displayed for an ``EXPLAIN PLAN FOR...`` for the highlighted statement is simple. This is what *actually* took place. Cardinalities are exact, for example, and not estimated from the optimiser statistics, histograms etc.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the explain plan.
-   **Save** - paves the explain plan.
-   **Send to Excel** - the explain plan is exported directly to Excel.
-   **Expand All** - expands all plan steps to display all the recursive steps.
-   **Collapse All** - collapses and hides all the recursive steps. Only a '+' is shown to indicate which top level steps have recursive steps.

Parses
======

This tab shows you the parse details for the highlighted statement. You are able to see whether this was a hard or soft parse, for example, and the times taken in terms of CPU and elapsed time to parse the SQL. You should be trying to avoid parsing as much as possible - statements should ideally be parsed once, but executed many times.

Parses are like `Highlanders <https://en.wikipedia.org/wiki/Highlander_(film)>`_, *there can be only one* - at any one time.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the parse details.
-   **Save** - saves the parse details.
-   **Send to Excel** - does *exactly* as it says. The parse details are exported directly to Excel.

Executions
==========

This tab shows you the execution details for the highlighted statement. You can see exactly how long the statement took to execute and how many blocks it read to process the displayed number of rows.

Where a statement has recursive SQL, then those totals are included in the totals for the parent SQL statement.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the execution details.
-   **Save** - saves the execution details.
-   **Send to Excel** - the execution details are exported directly to Excel.

Fetches
=======

This tab allows you to view all the individual ``FETCH`` calls for the highlighted SQL statement. You can see how long, in terms of Wall Clock time, each fetch took and how many blocks and rows were processed in each fetch.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the fetch details.
-   **Save** - saves the fetch details.
-   **Send to Excel** - the fetch details are exported directly to Excel.

Waits
=====

This tab allows you to view all the individual ``WAIT`` calls for the highlighted SQL statement. Each wait listed may be from the ``PARSE``, ``EXEC`` or ``FETCH`` phases of executing the statement.

Each listed wait will display whether or not Oracle considers the wait to be an 'idle' one or not. Beware, do not be misled, ``SQL*Net message from client`` is listed as idle, but need not be - this can be the application 'thinking' time when the database sends back some data, which is a performance problem if it takes too long, and *is not* an idle wait.

You will also see the P1, P2, P3 and P4 parameters which you can look up in the *Oracle Reference* manual to see what each one represents for the different wait events. The P4 parameter will sometimes display an object_id, and in those cases checking the option to ``Query database to decode object IDs`` will convert the number displayed into an object type, owner and object_name - once you select or start an appropriate connection to the desired database.


Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the wait details.
-   **Save** - saves the wait details.
-   **Send to Excel** - the wait details are exported directly to Excel.
-   **Hide Idle Events** - hides all events which have a value of 'Yes' in the 'Idle' column. See the warning above for a good reason *not* to select this option!


Wait Summary
============

This tab simply lists all the unique wait events that were encountered while processing the SQL statement highlighted in the upper part of the display. *All* waits encountered by the statement will be summarised on this tab. The view will list the total number of each event that occurred for this particular statement.

Also displayed are the minimum wait, maximum wait and the average wait (the `arithmetic mean <https://en.wikipedia.org/wiki/Mean>`_ average) - but beware of putting too much emphasis on the latter as any number of events with wildly varying wait times can lead to a much lower than normal average as the various values are spread out. You should concentrate on the maximum wait times - those are the problem area, usually.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the wait summary details.
-   **Save** - saves the wait summary details.
-   **Send to Excel** - the wait summary details are exported directly to Excel.
-   **Hide Idle Events** - hides all events which have a value of 'Yes' in the 'Idle' column. See the warning above for a good reason *not* to select this option!


Transaction Waits
=================

This tab allows you to see if any transaction endings (``COMMIT`` or ``ROLLBACK``) had any waits events following that particular transaction but before the following one. Your trace file may show something similar to the following:

..  code-block:: none

    XCTEND rlbk=1, rd_only=1, tim=32135479409461
    WAIT #0: nam='SQL*Net message to client' ela= 2 driver id=1413697536 #bytes=1 p3=0 obj#=-40016363 tim=32135479409533
    WAIT #0: nam='SQL*Net message from client' ela= 575 driver id=1413697536 #bytes=1 p3=0 obj#=-40016363 tim=32135479410150

Technically, these waits occur *after* the ``COMMIT`` or ``ROLLBACK`` has completed - that's why the ``XCTEND`` line appears *before* the waits, but the way that the Trace File Browser has been written tags them onto the end of the previous statement. They are, technically, waits *between* the just finished statements and the next one, so they could have gone either way.

The cursor id of zero in the waits above indicates something out of the ordinary, as cursor IDs in a trace file are now, from 10g (I think) onward, the actual address in memory for the cursor, and not just some monotonically increasing numeric value - as was the case in previous versions.

If the waits are for a cursor id that is not zero, then they will be accumulated into the correct statement's statistics and will not appear in this particular tab.

Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the wait details.
-   **Save** - saves the wait details.
-   **Send to Excel** - the wait details are exported directly to Excel.
-   **Hide Idle Events** - hides all wait events which have a value of 'Yes' in the 'Idle' column. See the warning above for a good reason *not* to select this option!


Deadlock
========

There are some details on `ToadWorld <http://www.toadworld.com/products/toad-for-oracle/b/weblog/archive/2013/08/14/toad-12-1-offers-automatic-trace-file-deadlock-detection>`_ on this tab, including a test trace file that you can download and analyse.

When a deadlock (ORA-00060) is detected by Oracle, it dumps a trace of the details to a separate deadlock trace file, or if the session is being traced, to the trace file, then kills off one of the deadlocked transactions.

This tab allows you to see the *entire* deadlock trace from the main trace file. There's a lot of information here. In addition, you will notice that the 'Statement details' tab shows the affected SQL statement highlighted in red, very very red! That's the statement that got binned by Oracle and rolled back.

What is a deadlock? Well, if one session has updated a row with sequence 4 and is attempting to update a row with sequence 8 while another session has already updated the row with sequence 8, but not committed, and is also attempting to update the row worth sequence 4, we have a deadlock. The transactions need not be in the same table, but both sessions (or more, if there's a circular deadlock) are holding something that someone else needs, and is waiting on something that someone else has locked.

For example:

-   Session 1: Delete from table_a where id = 4;
-   Session 2: Update table_b set something = 'A value' where id = 6;
-   Session 1: Update table_b set something_else = 666 where id = 6;
-   Session 2: Update table_a set another_column = 616 where id = 4;

At this point Oracle will detect a deadlock, and one unlucky statement (not the entire transaction, just the statement) will get killed. It is up to the application to handle this and rollback before continuing as appropriate.



There are other kinds of deadlocks, for example, ITL Deadlocks where there is no space to create a new entry in the ITL (Interested Transaction List) in the block header, and no free space (big enough) in the free space of the block to create one either.


Options
-------

The right-click context menu in this section has all the usual text editor options allowing you to ``select``, ``cut``, ``copy`` etc, from the text displayed in the tab's content. 

There's nothing much in the options here that will not be familiar already.

Raw Data
========

All data, from the trace file, for the SQL statement highlighted, will be displayed in this tab, in pretty much it's raw state as you would see it when browsing the raw trace file. The following sections will be seen:

Header
------

This is basically the ``PARSING IN CURSOR`` line taken straight from the trace file. As mentioned above, Toad's Trace File Browser is quite happy to display all the details from my own *TraceAdjust* output files. (See above.)

..  code-block:: none

    PARSING IN CURSOR #1016812856 len=65 dep=0 uid=272 oct=3 lid=272 tim=1268756.404777,delta=1037,dslt=786881,local='2017 Jun 22 08:49:45.786881'

SQL Statement
-------------

The unformatted SQL Statement is displayed. It appears here exactly as it appears in the trace file.

Parse Info
----------

This displays the ``PARSE`` line from the trace file.

..  code-block:: none

    PARSE #1016812856:c=15625,e=12086,p=0,cr=188,cu=0,mis=1,r=0,dep=0,og=1,plh=819305395, tim=1268756.404776,delta=-1,dslt=786880,local='2017 Jun 22 08:49:45.786880'

Exec Info
---------

This displays the ``EXEC`` line from the trace file.

..  code-block:: none

    EXEC #1016812856:c=0,e=31,p=0,cr=0,cu=0,mis=0,r=0,dep=0,og=1,plh=819305395, tim=1268756.404888,delta=112,dslt=786992,local='2017 Jun 22 08:49:45.786992'

Fetch and Wait Info
-------------------

This displays *all* the ``WAIT`` and ``FETCH`` lines from the trace file, for this statement.

..  code-block:: none

    ...
    WAIT #1016812856: nam='SQL*Net message from client' ela= 1902 driver id=1413697536 #bytes=1 p3=0 obj#=-1 tim=1268756.516385,delta=1926,dslt=898489,local='2017 Jun 22 08:49:45.898489'
    WAIT #1016812856: nam='SQL*Net message to client' ela= 1 driver id=1413697536 #bytes=1 p3=0 obj#=-1 tim=1268756.516447,delta=62,dslt=898551,local='2017 Jun 22 08:49:45.898551'
    FETCH #1016812856:c=0,e=65,p=0,cr=0,cu=0,mis=0,r=18,dep=0,og=1,plh=819305395, tim=1268756.516503,delta=56,dslt=898607,local='2017 Jun 22 08:49:45.898607'
    WAIT #1016812856: nam='SQL*Net message from client' ela= 1611 driver id=1413697536 #bytes=1 p3=0 obj#=-1 tim=1268756.518200,delta=1697,dslt=900304,local='2017 Jun 22 08:49:45.900304'
    ...

Stats
-----

This displays *all* the ``STAT`` lines from the trace file, for this statement.

..  code-block:: none

    STAT #1016812856 id=1 cnt=3266 pid=0 pos=1 obj=0 op='SORT ORDER BY (cr=52 pr=0 pw=0 time=7999 us cost=14 size=307004 card=3266)'
    STAT #1016812856 id=2 cnt=3266 pid=1 pos=1 obj=88773 op='TABLE ACCESS FULL FUND_USAGE (cr=52 pr=0 pw=0 time=1798 us cost=13 size=307004 card=3266)'

It is from these lines that the 'Explain Plan' tab is able to build the *exact* plan used by Oracle to access the data for the statement.
    
Options
-------

The right-click context menu in this tab offers the following options:

-   **Print** - prints the wait details.
-   **Save** - saves the wait details.
-   **Send to Excel** - the wait details are exported directly to Excel.
-   **Expand All** - expand all the various sections above in the display.
-   **Collapse All** - collapse all the sections in the display.

    **Bug?**: the latter two options do appear, in 12.1.0.22, to be rather slow, even for a small trace file. 
    
    It appears that once you select one of these two options, you have to click somewhere *outside of Toad* to actually get a response from the tab itself! Of course, this *could* simply be a Windows 7 foible!
    
-------
    
| Author: Norman Dunbar
| Email: Norman@dunbar-it.co.uk
| Last Updated: June 23 2017