================
Hermes Databases
================

Database Details
================

Server Logins
-------------

Logins have been set up on the servers below. The login name is *hisg494* and they must use the ssh key that was created in the local MobaXterm session. Passwords are not used.


Database Logins
---------------

Logins have been setup on the following databases. These are all *dunbarnor* and you have already tested these and changed your password. 


MISA
----

+----------+-----------------------------+-------------+
| Database | Server                      | Description |
+==========+=============================+=============+
| MISA01P1 | axukprdmisadb01.int.hlg.de  | Primary     |
+----------+-----------------------------+-------------+
| MISA01P2 | axukprdmisadb02.int.hlg.de  | Standby     |
+----------+-----------------------------+-------------+

This is our main *production* data warehouse, that has daily rebuilds done to it in the afternoon. There is a "frago" script Rhyd and Alain run every day when ETL is not running. There are 4 ETL runs per day with this environment, followed by 4 Business Objects report runs (done on the Active Standby Database). Everything goes into this database from other databases. Partitioning is mainly Range.


MISD
----

+----------+-----------------------------+-------------+
| Database | Server                      | Description |
+==========+=============================+=============+
| MISD01P1 | axukprdmisddb01.int.hlg.de  | Primary     |
+----------+-----------------------------+-------------+
| MISD01P2 | axukprdmisddb02.int.hlg.de  | Standby     |
+----------+-----------------------------+-------------+

A newer *production* data warehouse (12c) that uses Interval partitioning, and we use ODI as the tool to manage jobs. This database rarely needs daily maintenance, and its smaller to the MISA data warehouse.


RTT (or PNET)
-------------

+----------+-----------------------------+-------------+
| Database | Server                      | Description |
+==========+=============================+=============+
| PNET01P1 | axukprdmisddb01.int.hlg.de  | Primary     |
+----------+-----------------------------+-------------+
| PNET01P2 | axukprdmisddb02.int.hlg.de  | Standby     |
+----------+-----------------------------+-------------+
| PNET01D1 | devora08.int.hlg.de         | ???         |
+----------+-----------------------------+-------------+
| PNET01T1 | devora08.int.hlg.de         | Development | 
+----------+-----------------------------+-------------+
| PNET01T2 | devora08.int.hlg.de         | Development |
+----------+-----------------------------+-------------+

This is our main OLTP database that contains data about our parcels and couriers. It has had performance issues in the past, and currently is showing a lot of deadlocks from poor application code delivered by a 3rd party supplier


MOD - Method of Delivery
------------------------

+----------+-----------------------------+-------------+
| Database | Server                      | Description |
+==========+=============================+=============+
| MODD01P1 | axukprdmoddb.int.hlg.de     | Standby     |
+----------+-----------------------------+-------------+
| MODD01P2 | axukprdmoddb02.int.hlg.de   | Primary     |
+----------+-----------------------------+-------------+

Method of Delivery. One of our smallest databases that basically requires hardly any maintenance and support. To be frank, we really don’t know what actually goes on with this on as it just ticks away in the background. Due to its size we are looking at potentially migrating this to the AWS cloud as one of the front runners.


MyHermes
--------

+----------+-----------------------------+-------------+
| Database | Server                      | Description |
+==========+=============================+=============+
| ukmhprddb| axukprdmhdb01.int.hlg.de    | Primary     |
+----------+-----------------------------+-------------+
| ukmhprddb| axukprdmhdb02.int.hlg.de    | Standby     |
+----------+-----------------------------+-------------+

This is a OLTP database that tracks parcels from shipping to delivery. It’s basically the app we would use to locate a parcel in flight, and I believe it’s just started using media to show the customer where the parcel has been delivered to.


Database Sizings
----------------

RTT - contains mostly redundant data. Most of it is historical and of little or no use.

MOD - 8 GB split into 4 GB for MOD tables plus another 4 for "delivery" which is effectively, eBay. All tables live in the same schema but will be split for the migration. Delivery/eBay is intended to eventually end up being dropped.

C2B - 4 Gb data, but is not being migrated to Amazon.

MyHermes - the customers' website. Apparently, not a good design of a database.


Overview of Systems & Migration Plans
=====================================

Plans
-----

There are, effectively, 6 Oracle databases and one DB2 database. The latter is being phased out and will, eventually, *die in situ*.

Attempts are being made to reduce data retention and volumes prior to the Amazon migration.

Housekeeping is currently pretty much the deletion of partitions containing old data, however, some tables are not housekept frequently, if at all. Ideally, 4 months of data (aka 4 partitions) is all that is required to be kept, but the *Pulse* application has requested (and received) 12 months worth.

Partitions are not used for performance - as they should be - but for housekeeping!

The migration to Amazon intends to drop the use of Enterprise Edition and use Standard Edition 2 instead. This will result in the loss of all EE features and options - partitioning being one. This requires some investigation and Rhyd is involved in this at the moment.



Issues
------

*	External Tables (*.csv) are in use. As part of the migration, these will not be used. Currently, these live on a single NFS server which is mounted on many database servers. External tables will be converted to normal heap tables within the appropriate databases as part of/prior to the Amazon migration.

*	Daily housekeeping& monitoring - currently carried out by the German Team. Is it working? Is it proactive? What problems are there? Needs to be resolved as it *appears* that it is not proactive.

*	Service Requests have been a little ad-hoc. Now, in the main, they will be directed to Rhyd and/or Rob T who will discuss with the DBAs for action, as required.

* Tuning issues - some developer SQL is not as efficient as it could be. DBAs will be called upon to assist. (Usually *after* there are problems!)

Priorities
----------

1. 	Pretty much anything MI related - MISA and MISD.
2. 	Everything else!

Monitoring
----------

APP Dynamics is being used to monitor the applications and while database licences have been purchased, it is only currently used for minor monitoring of specific issues. The plans are to increase the use of APP Dynamics to monitor the databases.

Oracle Enterprise Manager is in use too. (Need more information - see Rhyd.)

