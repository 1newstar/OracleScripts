========================================
Things I Wish Vendors & Developers Knew!
========================================

Introduction
============

Years of being a developer and a DBA has given me a few things that just about every vendor and/or developer *should* know about, but apparently do not. Hopefully this document will be taken in the spirit it was intended, and will provide a decent overview of things that vendors and developers *should* be aware of - before they get turned loose on *my* databases!

==================================
Database & Development Environment
==================================

How Does Your Database Work?
============================

A strange question perhaps? You'd be surprised at how many vendors and developers don't actually know. The Oracle ``Concepts`` manual is a good place to start. Once you've read through and *understood* this book, then you will hopefully be able to write code that works better.

Even if nothing else, you won't be expecting your indexes to be rebuilt on a regular basis! [1]_

Want to write a system that runs *on any database backend* as many vendors would have you believe? It's not going to happen, unless you use the lowest common denominator of features that *all* the prospective backend databases have. Or, if you develop using a language called `Uniface <https://www.uniface.com/>`_ which does allow numerous backends to be used, as it has *properly* written specific drivers for each supported database.

Why should your customers not be able to make full use of all the database features that they have paid for, just so that you can sell your application to someone with a lesser featured database?

How Does Your Development Language Work?
========================================

You should already know this, but again, many don't. 

For example, (function) local objects are created on the stack and deleted on function exit. So if you are using a prepared statement and bind variables, don't make them local parameters in a function or procedure, make them member variables of the parent object.

Provide Proper Error Messages
=============================

What's more helpful?

..  code-block:: none

    Cannot login to database.
    
Or:

..  code-block:: none

    Cannot login to database.
    Database: PROD.
    Username: XYZABC_ADMIN.
    Error Code: ORA-01017.
    Error Message: invalid username/password; logon denied
    
I would suggest the latter, and all the additional information is available, quite simply, from the database exception that was raised. Use the full information provided in the exception, to give the users and the support teams, who have to fix the problem, a fighting chance of fixing it efficiently.

Autonomous Transactions
=======================

You have to carry out some processing. However, you find a problem that you must record in a logging table, but if the main transaction rolls back, the logging table entry also vanishes - and nobody will be able to find out exactly why the transaction failed. What to do?

If you write a logging procedure (or packaged procedure) to do the actual logging, you can make it *autonomous* and it can happily ``COMMIT`` its ``INSERT`` into the logging table, without, affecting the transaction that is having problems!

This is *exactly* what Oracle does when you select the ``NEXTVAL`` from a sequence.

..  code-block:: sql

    create or replace procedure logging(

        pMessage in varchar2
    )

    as
        pragma autonomous_transaction;

    begin
        insert into logging_table(what, when, who)
        values (pMessage, sysdate, USER);
        commit;

    exception
        when others then raise;
            
    end;
    /   

Now in your code this sort of things works:

..  code-block:: sql

    declare
        action varchar2(100);
        
    begin
        ...
        action := 'Insert into some_table';
        
        insert into some_table
        values (lots, of, stuff...);
        ...
        
        action := 'Delete from other_table';
        
        delete from other_table
        where id in (select id from some_table);
        ...
        
        commit;

    exception
        when others then
            logging(action);
            
            -- Re-raise the exception and thus, rollback.
            raise;
            
    end;
    
Package Your Procedures
=======================

Always, or at least, where ever possible, use packages. Do not write stand alone functions or procedures.

With a procedure or function, recompiling will be necessary whenever you make changes to the code. In this case, *everything* that calls your procedure or function will also become invalid. Invalid objects need to be recompiled before their next usage.

Luckily, Oracle will notice an invalid object, and attempt to recompile it when it is accessed. If this works, all well and good, but this has an effect on performance, especially if there's a tree of dependencies on the code you changed.

When you package up a procedure or function, you have two objects:

-   The package *specification*:

    ..  code-block:: sql
    
        create or replace package myPackage as ...
        
-   The package *body*:
    ..  code-block:: sql
    
        create or replace package body myPackage as ...
        
Now, whenever you need to change the code, simply recompile the package body and *not* the package itself. By doing this, none of the other objects that depend on your package need to be invalidated and recompiled.

You only ever need to recompile the package when you change the calling parameters of an existing procedure or function, or add (or remove) a new one.

Also, when saving code developed in Toad or SQLDeveloper, always save the package and body as two separate files. Only ever offer the package for deployment:

-   On first ever deployment, you need to compile the specification at lease once;
-   When you have had to add new procedures or functions, remove existing ones, change the calling conventions etc.


The Application is *not* the Only Way!
======================================

Business rules, check constraints, etc, are required to be as close to the data as possible. What this means is simple. If you have to check that a column in a table is either 'Y' or 'N' or NULL, then you add a check constraint *to the database* - you *do not* put some checking code in the application as the *only* constraint check.

The database can be accessed from the application, this is true, but the DBA can also access it directly, using scripts, Toad, SQL*Plus etc etc. So can the developers. What would the application do if it read some data from a sex column, expecting 'M' or 'F' or NULL, and found it had read a 'U' instead? Would it cope if the developers wrote it *knowing* that it - the application - only allowed NULL, 'M' or 'F' through when the data are entered?

You *can* put the checks in the application *as well*, but these application checks should only be used to prevent a round trip to the database with incorrect data, and to enable a better and more informative error message to be presented to the users.

Data are the most valuable thing to a business, not the application - those live and die, but the data lives on. Keep it safe, keep it clean.


SQL*Plus is Not Toad!
=====================

SQL*Plus is the supplied utility for accessing Oracle databases *on the server* and is the *only* utility guaranteed to be present. For this reason, all scripts, deployments, patches etc will be run using SQL*Plus, and not Toad, SQLDeveloper or whatever.

Blank Lines
-----------

Unlike Toad etc, SQL*Plus does not accept blank lines in the middle of a statement:

    ..  code-block:: sql
    
        select
            column_a,
            column_b
            column_c
            ...

        from
            table_a
            
        where
            some_column = some_value;
            
    If you *need* blank lines, use a blank comment instead:

    ..  code-block:: sql
    
        select
            column_a,
            column_b
            column_c
            ...
        --
        from
            table_a
        --    
        where
            some_column = some_value;
            
Slashes 
-------

In SQL*Plus a slash character '/' is required to either:

-   Execute the preceding statement if it did not end with a semi-colon;

    ..  code-block:: sql
    
        select * from dual
        /
        
-   Execute the preceding statement again, if it did end with one;

    ..  code-block:: sql
    
        create table_a(a number);        
        table created
        
        insert into table_a(a) values (666);        
        1 row inserted
        
        -- Here begins the demo!
        
        insert into table_a
        select * from table_a;
        
        1 row inserted
        
        /        
        2 rows inserted
               
        /        
        4 rows inserted
        
        /        
        8 rows inserted
        
        
-   Terminate the entry of PL/SQL code and execute it. Whenever you type in a ``DECLARE``, ``BEGIN`` etc, you switch from the SQL buffer in SQL*Plus, to the PL/SQL buffer. Because the latter knows that statements terminate with a semi-colon, it does not attempt to execute them when you type in a semi-colon. It waits until you terminate the PL/SQL entry with a trailing slash character.

    ..  code-block:: sql
    
        begin
            do_come_plsql_stuff();
            and_someMore();
        exception
            when others then raise;
        end;
        /
        

Beware of NULLs
===============

Empty Strings *are* NULL
------------------------

Oracle considers an empty string and NULL to be the same. They are *definitely not* the same. A NULL is an absence of any value, a nothing, an unknown. An empty string *is* a value. It is a string, containing exactly zero characters - but it is still a string value. 

Other databases do not have this problem, only Oracle (as far as I'm aware).

..  code-block:: sql

    select nvl('', 'Oops - Null') from dual;
    
Gives the result:

..  code-block:: none

    Oops - Null
    
Go figure.

Check Constraints
-----------------

Do not ever do this:

..  code-block:: sql

    alter table table_a
    add constraint check_sex
    check (sex in ('M','F', NULL));
    
Do this instead:

..  code-block:: sql

    alter table table_a
    add constraint check_sex
    check (sex is null or sex in ('M','F'));
    
If you use the former, the *any* value will be able to be stored in the column because checking any value with NULL results in NULL and NULL is allowed, so whatever you inserted gets through. Watch and be amazed:

..  code-block:: sql

    create table test(sex char(1));

    alter table test add constraint
    check_sex check (sex in ('M','F',NULL));

    insert into test(sex) values ('M');
    insert into test(sex) values ('F');
    insert into test(sex) values (NULL);
    insert into test(sex) values ('X');
    insert into test(sex) values ('Y');
    insert into test(sex) values ('Z');

Oops! No errors, what's in the table?

..  code-block:: sql

    select nvl(sex, 'NULL FOUND') from test;
    
..  code-block:: none

    M
    F
    NULL FOUND
    X
    Y
    Z
    
Only a minor disaster! 

Doing it correctly:

..  code-block:: sql

    create table test(sex char(1));

    alter table test add constraint
    check_sex check (sex is null or sex in ('M','F'));

    insert into test(sex) values ('M');
    insert into test(sex) values ('F');
    insert into test(sex) values (NULL);
    insert into test(sex) values ('X');

Oops! An error! That's exactly what we expected:

..  code-block:: none

    ORA-02290: check constraint (SYS.CHECK_SEX) violated

And there's no bad data in the table:

..  code-block:: sql

    select nvl(sex, 'NULL FOUND') from test;
    
..  code-block:: none

    M
    F
    NULL FOUND

=================
Contention Issues
=================

Select For Update
=================
Many applications execute code that resembles the following:

..  code-block:: sql

    select stuff
    from table_a
    where something = some_value
    FOR UPDATE;
    
This allows a user to pull up some data, in an application, then go outside for lunch, a comfort break, an eCiggy or whatever, leaving other users stuck in a queue waiting for a ``COMMIT`` or ``ROLLBACK``. 

Why do they developers write this code? It's easy and it's lazy and it's called *pessimistic locking*. 

Pessimistic locking means that if anyone already has a row locked, then the ``SELECT for UPDATE`` code will hang until the lock is removed, and then the data can be updated, written back, and committed without having to deal with locked rows.

There are numerous means of getting around the need to lock early, as pessimistic locking does, because an ideal application will lock late for best performance and one method is described at `this link <https://qdosmsq.dunbar-it.co.uk/blog/2009/01/lazy-developer-syndrome-and-rowids/>`_.

Lock Table
==========

If you ever see code that resembles the following, run away!

..  code-block:: sql

    lock table table_name for ... ;
    
If you have to lock a table, you are doing something seriously wrong in your code. Oracle need only lock the rows that you are ``UPDATE``ing, and does it very well, you don't need to lock the table. Oracle is *not* SQL Server! 

Unindexed Foreign Keys
======================

See *Foreign Keys May Need Indexing* elsewhere for details.

DeadLocks
=========

Oracle will detect a deadlock situation between two or more sessions, and choose one of the sessions at random, and rollback the *statement* with an ``ORA-00060 while waiting for resource`` error message.

The application must be able to cope with this. Normally, it would trap the exception, carry out a ``ROLLBACK``, then retry the entire transaction - although you may wish to consider ``SAVEPOINT``s in your code - but it should also give up after a few attempts to prevent an endless loop, or drastically long response times.

==========================
General Performance Issues
==========================

Select Count(*) Into
====================

Many times you will see code, similar to the following, in a PL/SQL package:

..  code-block:: sql

    ...
    select count(*)
    into lvHowMany
    from table_a
    where some_condition;
    
    if (lvHowMany = 0) then
        do_something();
    else
        do_something_else();
    end if;
    ...
    
The idea being to determine if a row exists, and if so, ``UPDATE`` it perhaps, while if it doesn't exist, ``INSERT`` it.    

If so, then the `MERGE <http://docs.oracle.com/cd/E11882_01/server.112/e41084/statements_9016.htm#SQLRF01606>`_ statement will do that for you. Use that instead.
    
If you are only interested in there being a row or not, then use the `EXISTS <http://docs.oracle.com/cd/E11882_01/server.112/e41084/conditions012.htm#SQLRF52167>`_ statement.

-   The ``SELECT COUNT`` statement will continue reading to the end of the table\ [3]_ as you are asking for a count of all rows meeting the ``WHERE`` clause conditions. 
-   ``EXISTS`` will stop looking when it finds the first row meeting the ``WHERE`` clause conditions. This can help short circuit the query, but it depends on how far through the table scan it finds a matching row of course.

Use the Correct Data Types
==========================

Use Anchoring
-------------

The following code *might* work for all time, but it has an existing, potentially serious error:

..  code-block:: sql

    create or replace package body .....
    as
        procedure broken ( ... )
        as
            type tTableName is table of varchar2(30);
            vTableNames tTableName;
            ...
        begin
            select table_name
            into vTableName
            from user_tables
            where ... ;
            
            ...
            
        end;
    ...

What happens when Oracle decide to allow table names to be longer than 30 characters? Your code will fail when the first table name with a longer length of name is selected and you will  have to find *every* location in this and other code, where a table_name is selected into a VARCHAR2(30) data type.

If you use anchoring, as follows, your procedure will not fail. When user_tables changes, Oracle may/will notice that your package depends upon it, and recompile quietly on first execution.

..  code-block:: sql

    create or replace package body .....
    as
        procedure broken ( ... )
        as
            type tTableName is table of user_tables.table_name%type;
            vTableNames tTableName;
            ...
        begin
            select table_name
            into vTableName
            from user_tables
            where ... ;
            
            ...
            
        end;
    ...

The same is true of your own code and tables, whenever you are selecting data from a table, into a PL/SQL variable, you must use anchoring to define the PL/SQL variable correctly to match the table's column.

In General
----------

Strings are not numbers. Numbers are not strings, Dates are just that, Dates (and times) etc.

Storing data in the wrong data type is a problem. If, for example, you store numeric values in character data types, try sorting. The same applies to dates, unless you store them in yyyymmdd format.

Also, if the column(s) in question are used to join two tables, then they must be the same data type, precision and scale in both tables, or the optimiser applies implicit functions to convert one data type to another - thus negating the ability to use indexes.

Dates
-----

Always specify the format of a date that you are storing in, or reading back from a table. *Never* rely on the default data format for the database being the same as the default date format in the database you did your testing in. (You *do* test don't you?)

..  code-block:: sql

    insert into some_table(a_date)
    values '01/03/2017';
    
What actual value does the string get converted to? In the UK and most of the rest of the world, *probably* 1st March 2017. The default date format is likely to be 'dd/mm/yyyy'. in America, all bets are off, as they have the weirdest date format by default, being 'mm/dd/yyyy' so the above date becomes 3rd January 2017.

The code above should always be as follows:

..  code-block:: sql

    insert into some_table(a_date)
    values to_date('01/03/2017', 'dd/mm/yyyy');

This *explicitly* defines exactly what the date string represents and Oracle will make the *correct* conversion from string to ``DATE`` when storing the data. Do not leave the database to guess!

Stop Using Column Defaults
--------------------------

If a column has no value, leave it as NULL. Do not use a default value to represent something that isn't there. This can, and does, throw the optimiser off as it has to account for the potential mass of defaults that all have the same value in the table.

This skew may require the use of histograms when gathering statistics for the optimiser to prevent the optimiser from choosing a less than efficient execution plan.


Stop Parsing
============

Parsing is when a SQL statement is checked for syntax and semantic errors, privileges are checked to ensure that the calling user has been granted access to the objects used by  the SQL, and if all that passes, we use the Cost Based Optimiser to figure out the best plan to actually get at the data. It will check up to 20,000 different access paths as a default maximum, you can set it higher though.

You want to avoid parsing. Bind variables can help.

So, you use bind variables in your code, it must be good and efficient then? Not necessarily. In an ideal world, a statement would be parsed once, and remain parsed for the life of that particular connection.

Every execution of the statement would:

-   Bind new values to the variables in the statement;
-   Execute the statement without parsing it;
-   Process the results.

Sadly, what seems to happen is, either:

-   Bind variables are never used, literals are hard coded and parsed every time. This floods the SQL Library Cache with numerous identical statements, and may cause useful code to be flushed out and re-parsed when next required; or
-   Binds *are* used, but the statement is parsed every time it is executed anyway!

`This link <https://qdosmsq.dunbar-it.co.uk/blog/2009/02/it-must-be-efficient-im-using-bind-variables/>`_ has details of how this can be overcome.

Stop Hinting!
=============

Telling Oracle that you know better than the Cost Based Optimiser is a little high handed perhaps? Do you really know that what you ask for is the most efficient way to get the data? Perhaps it is indeed the best way, now, what about is some time when there's more (or less) data in the table? Plans change.

Now, Oracle is actually free to ignore your hints, so no harm done? Well, perhaps, but perhaps not. Your plan is highly unlikely to be the most efficient access method, so you are artificially causing performance problems in the application.

Just. Say. **NO**!

Rowids Are Your Best Friend
===========================

Well, maybe not your *very* best friend, but they are fun. Check `this link <https://qdosmsq.dunbar-it.co.uk/blog/2009/01/rowids-are-fun/>`_ for details.

Basically though, if you ``SELECT`` a row, or rows, and you know that you will be updating them soon, ``SELECT`` the rowid as well as the desired columns for each row. For example, instead of this code:

..  code-block:: sql

    select column_a, column_b, ...
    from table_a
    where some_condition;
    
Run this instead:
    
..  code-block:: sql

    select rowid as ri,
           column_a, column_b, ...
    from table_a
    where pk_column = 123;
    
When the ``UPDATE``s are ready to be done, run this code:

..  code-block:: sql

    update table_a
    set column_a = new_value,
        column_b = new_value    
    where rowid = <previous_ri_value>;

Doing this will mean that you miss out querying the pk_column's index again to be able to write the row back to the table with updated values - why bother looking up the rowid when you already have it?
    
Select * is *not* Your Friend
=============================

many are the application developers who:

..  code-block:: sql

    select * 
    from table
    ...
    ;
    
This is fine, but all those columns of data have to:

-   Be read from the disc;
-   Be packaged up into a TCP packet or three;
-   Be sent over the network;
-   Have to be found a home in a local variable or two when it arrives in the application;
-   Etc.    

If you need 5 columns, ask for 5, some tables have hundreds of columns and there's no need for the other 95 to be pulled over the network when they will be ignored.

It could be that the 5 columns you ask for are part of an index. In this case, Oracle will not read the table because it can get the requested data from the index alone. Scanning an index is far quicker than scanning a table with numerous columns.

What will happen to the application when someone, for another purpose, adds a new column? The application will fail and need to be rebuild, and redeployed. Not good.

If the application asks for only what it needs, then adding columns need not mean a recompile and redeployment, but that depends on the changes made.

Bind Variables *Can* Stuff Things Up!
=====================================

When Oracle parses a query, it builds an execution plan on the first parse. This is a hard parse. If the same query is parsed again, then the existing execution plan will be used, this is a soft parse. So, a statement with bind variables, which is (wrongly) parsed every time it is executed, will see one hard parse and lots of soft parses\ [2]_\ .

Up until Oracle 11g, this could cause problems because the bind values were not known at parse time, so the execution plan may not have been ideal. In addition, depending on the first set of binds used, the plan was then fixed for *all* executions and this can cause serious problems if the data are skewed as the first plan will be used always, regardless of it being the best plan of not.

For example, given a query that hits a row of data in a huge table because the optimiser sees that the first bind used has exactly one row, an index will be used to fetch that one row. However, every subsequent execution returns hundreds of rows, the index will be used and it will not be the most efficient access method.

From 11g, Oracle does *bind variable peeking* and if it thinks the plan should change - based on the bind values, it will generate a new plan, on the fly, to cater for the change required.

Use Sequences not Tables
========================

Sequences run in a separate (autonomous) transaction from the one you are running. This makes them ideal for numeric primary keys, sequence numbers etc.

Some vendors want to make their systems "run on any database backend" so they have a sequences table instead. This, on Oracle, means that their system *cannot* be run with more than one user!

The idea is to:

-   Select the current number from the table for use;
-   Write the current number plus one back to the sequences table;
-   Do all the necessary work with the sequence number thus obtained;
-   Commit everything.

The above works perfectly as long as only one user is running. With multiple users, the problem is, Oracle does read consistency. *Everyone* who queries the sequences table sees *exactly the same sequence value* until such time as the (first) change is ``COMMIT``ted. This gives everyone the same number for the primary key, so we get PK Constraint violation errors at best, and if the application retries on a duplicate key, we have queues of people all waiting to get a unique value from the table.

Another problem, if the first user decides to go for lunch, before ending the transaction, everyone else will hang on a Mode 3 enqueue waiting for the first session to ``COMMIT`` or ``ROLLBACK``.

Indexes
=======

How does an index work?
-----------------------

When you use an index to look up a row in a table, Oracle takes the values supplied in the ``WHERE`` clause and checks the indexed column values, in the index, to find the rowid for the desired row. That tells it exactly where on disc the data are to be found.

A row's rowid *never* changes\ [4]_\ . 

Don't Over Index
----------------

Every index on a table needs to be maintained whenever rows in the table are ``INSERT``ed or ``DELETE``ed, and some may need maintenance on ``UPDATE`` statements. 

Every index with columns ``a``, ``b`` and ``c``, can be used for queries referencing ``a``, or ``a,b`` or ``a,b,c``, and in some cases for ``b``, or ``c`` or ``b,c`` as well! Look up index skip scans.

Foreign Keys May Need Indexing
------------------------------

If a child table is set up without an index on the columns making up the foreign key, then you will see performance problems if one or more of the following conditions can be true:

-   The parent records can be deleted;
-   The parent records referenced columns can be updated or changed or NULLed out.
-   The parent table can be queried with a join to the child table using the foreign key column(s).

If any of these are possible, add an index to the Foreign key columns on the child table. If not, the processing is as follows, for a ``DELETE`` from the parent, for example:

-   Oracle waits for all other sessions to commit or rollback transactions using the child table. Exclusive access is required.
-   Once it has exclusive access, the child table is locked. Nobody else can read or write to it.
-   A full table scan is carried out on the child table. Oracle is looking for any row that references the parent table's "soon to be deleted" row(s).
-   Oracle releases the lock on the child table. Other sessions can use it now.
-   Oracle does the ``DELETE`` - assuming the Foreign Key was set up accordingly, and no child rows were found.

If, on the other hand, an index exists, Oracle uses it without any waiting or locking, and no other sessions are held up.

Don't Rebuild Indexes
---------------------

When you rebuild an index, everything is nice and clean, all available space is taken up, there are no holes where deleted rows used to be, and life is good.

However, an ``INSERT`` comes along. It needs to put a new entry into the index. Oracle has to go off and allocate a new block, split an existing block or similar, and create an entry. all that hard work cleaning stuff up is wasted.

As soon as the application starts working after the rebuild, Oracle stars breaking down the index structure to make it as efficient as possible. A clean index is not necessarily a useful one.

However, `this PDF document <https://richardfoote.files.wordpress.com/2007/12/index-internals-rebuilding-the-truth.pdf>`_ hopefully explains things if far more details than you probably want! 

Bitmap Indexes
--------------

OLTP (Online Transaction Processing) systems *must not* not use bitmap indexes. 

These are a data warehouse feature and should be used there and there only. The reason being that when you update a single row in a table, and the bitmap index has to be maintained, then *every single row* covered by the bitmap segment in question will be locked.

With a normal index, Oracle will only lock the row that was updated - and as you updated it, that row is already locked. One row versus potentially, thousands.

Data Warehouses tend to be loaded overnight with new data, so having bitmaps is not such a major problem there as the data are being loaded as new, so will add extra segments to the index, which is not going to affect existing rows.


=======================
Security Considerations
=======================

Passwords
=========

Make sure that the application copes with the users' passwords expiring. Many databases use profiles to expire users' passwords after a certain time. Your application must cope with this and offer the user the ability to change their own password.

Hopefully, the database profile also has a password verification function to check for, and reject, ridiculous passwords!


SQL Injection
=============

Briefly:

-   Don't use hard coded literals taken from fields filled in by users in the application!
-   Always sanitise your user input.
-   Use PL/SQL packages to access data passed in from the users via the application.
-   `Little Bobby Tables! <https://xkcd.com/327/>`_.

The latter will automatically create SQL statement with bind variables. SQL Injection is exceedingly difficult with binds.

Beware the Lost Update
======================

Security includes data security!

If two sessions carry out updates to the same rows in a table, but at separate times so that the first user's ``UPDATE``s are fully ``COMMIT``ted when the subsequent changes are made, the data for the first user *may* be lost. 

See `Lost Update <https://morpheusdata.com/blog/2015-02-21-lost-update-db>`_\ for full details.



-------

| Author: Norman Dunbar
| Email: norman@dunbar-it.co.uk
| Last Updated: 26 June 2017.

..  Footnotes:

..  [1] If you have to ask, you have to read the Concepts manual again!
..  [2] Sadly that's what we *usually* see. What we *should* see is one hard parse, and many, many executions and no soft parses!
..  [3] Actually, to the table's *high water mark* which may be a lot higher than the last row in the table. Try creating a huge table with multi-millions of rows, run a ``COUNT(*)`` and time it. ``DELETE`` all the rows and do another ``COUNT(*)``. Same time? Oracle reads *all* the blocks in a table, even empty ones in a full table scan. The ``TRUNCATE`` command moves the high water mark down as all the rows are deleted - that will improve table scan performance.
..  [4] *Almost* never changes actually. If a table is exported (using ``exp`` or ``expdp``) then it will change when it is imported again. If an RMAN backup is restored, it will have exactly the same rowid as before. However, in normal conditions, a rowid never changes.