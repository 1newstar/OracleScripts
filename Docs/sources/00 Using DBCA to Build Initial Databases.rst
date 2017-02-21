===============================
Default Azure Builds Using DBCA
===============================

Abstract
========

The following outlines the steps followed in order to create a new
database on an Azure server.

Make sure that the user you are logged in as is a member of the oracle
group and that your user has administrator rights.

Please note that your eyes are *not* failing, those screen shots really are
out of focus. Don't ask, Windows does that sort of thing sometimes!


Build the Default Database
==========================

The default DBCA database should be created first. This will be a *general purpose
database* from the appropriate template. 

The following steps take you through the use of ``dbca.bat``, to
create the initial database.

-  Locate the file ``%ORACLE_HOME%\bin\dbca.bat``
-  Right click on ``dbca.bat`` and select "run as administrator" this is very important. Confirm your desire to do so when prompted.

There are 12 screens to pass through before you can get a new database.

Welcome
=======

-  On the Welcome screen, click next.

   (*No Image*)


Operations
==========

|image1|

-  Select "Create a Database", click next.


Database Templates
==================

|image2|

-  Select "General Purpose or Transaction Processing" and click next.


Database Identification
=======================

|image3|

-  Enter the Global Database name, and the same for the SID. Click next.


Management Options
==================

|image4|

-  *Deselect* "Configure Enterprise Manager", click next.


Database Credentials
====================

|image5|

-  Select "use same password …" then enter and confirm the desired
   password to be used for SYS and SYSTEM. Click next.


Database File Locations
=======================

|image6|

-  Select "use common location for all database files".

-  Either type the desired drive and path & click next, or,

   -  Click browse.

   -  Select the correct data drive in the drop down at the top.

   -  Select the ``\mnt\oradata`` folder as appropriate.
   
   Regardless of which method you use, *do not* tag the database name onto the end of the path selected/typed. DBCA will do this automatically when it creates the database. 

-  Click OK. Confirm when prompted. Click Next.


Recovery Configuration
======================

|image7|

-  Select "Specify Fast Recovery Area". 

-  Either type desired FRA path, or,

   -  Click browse.

   -  Select the correct data drive in the drop down at the top.

   -  Select the ``\mnt\fast_recovery_area`` folder as appropriate.

   -  *Do not* amend the Directory path at the bottom of the dialog. Click OK.

-  If necessary, *Change* the Fast Area Recovery Size to a suitable size
   and ensure MBytes or GBytes is selected as appropriate.

-  *Deselect* "enable archiving" for now. Click next.

-  If prompted, *Confirm* the fact that the FRA size is too small.

   
Initialization Parameters
=========================

-  *Deselect* "Sample Schemas". Click next. (This will *still* create the
   SCOTT schema, however, and it will need to be dropped later.)
   
   (*No Image*)


Memory Tab
----------

|image8|

   -  Leave size as defaulted.

   -  Select "Use automatic memory management"

Sizing Tab
----------
   
   (*No Image*)

   -  No changes required.

Character Sets Tab
------------------
   
|image9|

   -  Select "choose from the list …"

   -  Deselect "Show recommended …"

   -  Select "WE8ISO8859P1" from the drop down.

   -  NLS Character Set should already be correctly set to AL16UTF16.

   -  Choose "American" as the default language.

   -  Choose "United States" as the default territory.

Connection Mode Tab
-------------------
   
   (*No Image*)

   -  No changes required.

   -  Click next

   
Database Storage
================

Control Files
-------------
   
|image10|

-  Click on controlfile then make sure that there is one file created in
   ``?:\mnt\oradata\{DB_UNIQUE_NAME}\`` and the other in
   ``?:\mnt\fast_recovery_area\{DB_UNIQUE_NAME}\``. A third will
   have a path but no name. This is fine.
   
   
Redo Files
----------
   
|image11|

-  ONLY change the redo logs groups if you are not intending to convert
   this default database to a UV full sized database. If so, there are
   separate instructions in the appropriate document for this.

   -  Click the '+' beside Redo Log Groups.

   -  For each of the 3 options, 1, 2 and 3, click it.

      -  Change the name to ``redo0?a.log`` where '?' is 1, 2 or 3.

      -  For each redo file listed, ensure the path is
         ``?:\mnt\oradata\{DB_UNIQUE_NAME}\`` where '?' is the
         correct drive letter.

   -  For each of the 3 options, 1, 2 and 3, click it.

      -  Add a second logfile where the name is ``redo0?b.log`` where '?' is
         1, 2 or 3, to the second line. Beware, Oracle will try to add
         ".ora" to the end. Delete it.

      -  Make sure that the path is set to
         ``?:\mnt\fast_recovery_area\{DB_UNIQUE_NAME}\``. ('?' is
         the correct drive obviously!)

   -  Click next.


Creation Options
================

|image12|

-  Select Create Database.

-  You may, if you wish, create a template if you need to create another
   database like this one in future. It's not worth it though. Oracle
   changes/defaults far too much of what you entered, so you'll end up
   changing everything again.

-  Select Create database Creation Scripts though. This is useful and
   will save you running through all this again, if required. Leave the
   Destination Directory as per the default.

-  Click finish.

-  Click OK on the confirmation screen.

-  Click OK to confirm that the script creation was ok.

-  The database will start to build. Wait ….

-  Click Exit when give the opportunity to do so.


Post Build Scripts
==================

When the utility has finished, a new database, service and all supporting requirements will have been created and started (in OPEN mode). This database is nothing more than a blank, small, default database that is not in a fit state to be used for UV in any way.

See the document *``01 Building UV Databases``* for the next steps in converting  the default database to a full sized working UV one.

.. |image1| image:: images\image1.png
   :width: 6.01042in
   :height: 4.30208in
.. |image2| image:: images\image2.png
   :width: 5.96875in
   :height: 4.29167in
.. |image3| image:: images\image3.png
   :width: 5.97917in
   :height: 4.29167in
.. |image4| image:: images\image4.png
   :width: 6.00000in
   :height: 4.26042in
.. |image5| image:: images\image5.png
   :width: 6.00000in
   :height: 4.27083in
.. |image6| image:: images\image6.png
   :width: 6.00000in
   :height: 4.29167in
.. |image7| image:: images\image7.png
   :width: 5.97917in
   :height: 4.28125in
.. |image8| image:: images\image8.png
   :width: 5.98958in
   :height: 4.27083in
.. |image9| image:: images\image9.png
   :width: 6.03125in
   :height: 4.30208in
.. |image10| image:: images\image10.png
   :width: 6.03125in
   :height: 4.27083in
.. |image11| image:: images\image11.png
   :width: 6.02083in
   :height: 4.31250in
.. |image12| image:: images\image12.png
   :width: 6.01042in
   :height: 4.30208in
