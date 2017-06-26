========================================
Things I Wish Vendors & Developers Knew!
========================================

Introduction
============

Years of being a developer and a DBA has given me a few things that just about every vendor and/or developer *should* know about, but apparently do not. Hopefully this document will be taken in the spirit it was intended, and will provide a decent overview of things that vendors and developers *should* be aware of - before they get turned loose on *my* databases!

How Does Your Database Work?
============================

A strange question perhaps? You'd be surprised at how many vendors and developers don't actually know. The Oracle ``Concepts`` manual is a good place to start. Once you've read through and *understood* this book, then you will hopefully be able to write code that works better.

Even if nothing else, you won't be expecting your indexes to be rebuilt on a regular basis! [1]_

How Does Your Development Language Work?
========================================

You should already know this, but again, many don't. Local objects are created on the stack and deleted on exit. So if you are using a prepared statement and bind variables, don't make them local parameters in a function or procedure, make them member variable of the parent object.

The Application is *not* the Only Way!
======================================

Business rules, check constraints, etc, are required to be as close to the data as possible. What this means is simple. If you have to check that a column in a table is either 'Y' or 'N' or NULL, then you add a check constraint *to the database* - you *do not* put some checking code in the application as the *only* constraint check.

The database can be accessed from the application, this is true, but the DBA can also access it directly, using scripts, Toad, SQL*Plus etc etc. So can the developers. What would the application do if it read some data from a sex column, expecting 'M' or 'F' or NULL, and found it had read a 'U' instead?

You *can* put the checks in the application, but these would be used only to prevent a round trip to the database with incorrect data, and perhaps to enable a better and more informative error message to be presented to the users.

Data are the most valuable thing to a business, not the application - those live and die, but the data lives on. Keep it safe, and clean.


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

Contention
==========

``SELECT For Update``
---------------------
Many applications execute code that resembles the following:

..  code-block:: sql

    select stuff
    from table_a
    where something = some_value
    FOR UPDATE;
    
This allows a user to pull up some data, in an application, then go outside for lunch, a comfort break, a ciggy or whatever, leaving other users stuck in a queue waiting for a ``COMMIT`` or ``ROLLBACK``. 

Why do they developers write this code? It's easy and it's lazy and it's called *pessimistic locking*. 

Pessimistic locking means that if anyone already has a row locked, then the ``SELECT for UPDATE`` code will hang until the lock is removed, and then the data can be updated, written back, and committed without having to deal with locked rows.

There are numerous means of getting around the need to lock early, as pessimistic locking does, because an ideal application will lock late for best performance and one method is described at `this link <https://qdosmsq.dunbar-it.co.uk/blog/2009/01/lazy-developer-syndrome-and-rowids/>`_.

Lock Table
----------

If you ever see code that resembles the following, run away!

..  code-block:: sql

    lock table table_name for ... ;
    
If you have to lock a table, you are doing something seriously wrong in your code. Oracle need only lock the rows that you are ``UPDATE``ing, and does it very well, you don't need to lock the table. Oracle is *not* SQL Server! 

Unindexed Foreign Keys
----------------------

See *Foreign Keys May Need Indexing* elsewhere for details.

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

ROWIDs Are Your Best Friend
===========================

Well, maybe not your *very* best friend, but they are fun. Check `this link <https://qdosmsq.dunbar-it.co.uk/blog/2009/01/rowids-are-fun/>`_ for details.

``SELECT *`` is *not* Your Friend
=================================

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

Bind variable peeking. Works best after 11.2.

PL/SQL stuff with parameters etc, are bind variables.

SQL Injection
=============

Briefly:

-   Don't use hard coded literals taken from fields filled in by users in the application!
-   Always sanitise your user input.
-   Use PL/SQL packages to access data passed in from the users via the application.

The latter will automatically create SQL statement with bind variables. SQL Injection is exceedingly difficult with binds.

`Little Bobby Tables! <https://xkcd.com/327/>`_.

Use Sequences not Tables
========================

Indexes
=======

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

OLTP do not use bitmap indexes. These are a data warehouse feature and should be used there and there only. The reason being that when you update a single row in a table, and the bitmap index has to be maintained, then *every single row* covered by the bitmap segment in question will be locked.

With a normal index, Oracle will only lock the row that was updated - and as you updated it, that row is already locked. One row versus potentially, thousands.

Data Warehouses tend to be loaded overnight with new data, so having bitmaps is not such a major problem there.

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





-------

| Author: Norman Dunbar
| Email: norman@dunbar-it.co.uk
| Last Updated: 26 June 2017.

..  [1] If you have to ask, you have to read the Concepts manual again!