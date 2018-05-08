=========================
PNET01/RTT - Housekeeping
=========================

Introduction
============

The recent exercise in deleting huge amounts of data in order to avoid the *Billion Parcel Rollover* event causing duplicate parcel IDs, showed the need for some housekeeping to be put in place on the PNET01P1/RTT database. 

It is believed that the problem stems from Cassandra, and/or the Cobol Copy Files/Libraries, which are defined with too small a numeric "picture" and cannot handle parcel ID numbers greater than 999,999,999 (one billion minus 1). In addition, and apparently, IBM's DB2 cannot cope with certain types of numeric data with values over 1.2 billion. (Happily, Oracle copes just fine.)

In an ideal situation, we would simply need to truncate and/or drop the oldest partition every month, keeping only 13 months worth of data. This is an impressively quick way to delete millions of rows in a few seconds, but sadly, there are a number of problem areas that prevent us doing this.

A new package to carry out this housekeeping has been written (and partially tested) but further discussion is required to enable a full working version to be built. At present, it only considers the larger, partitioned tables in the database.


Problems to be Discussed
========================

The following are areas of uncertainty in the proposed, and partially developed, new housekeeping system.

Which Tables are Involved?
--------------------------

In an ideal housekeeping scenario, we would be deleting all the relevant data. In the past, it appears that only the larger tables were house-kept, thus leaving orphaned data about parcels which had been deleted from the system. This may have caused confusion in the application whenever the parcel ID grew big enough to match one present in the table(s) that were not house-kept. This could be construed as "incorrect data" and may fall foul of data protection laws.

I would think that we should be housekeeping all relevant tables. Definitely all tables where a parcel ID is present, but equally, in any other table where there is some form of trail back to a parcel - order items, customer orders etc.

**What is required here is for someone with a good working knowledge of the system to determine which data should be house-kept and how it all relates back to a parcel ID.**


Frequency of Execution
----------------------

Given the data volumes at peak times - see `Data Volumes <#data-volumes>`_ below - I would suggest that we really need to be housekeeping on a daily basis. Anything less frequent could result in extended run times as higher volumes of data needs to be deleted.

The consideration here is that while we have reasonably large volumes of data to delete, we also have a fair number of large tables that all require similar deletions. **Should they run in parallel with the possibility to tying up too many resources, or, should they run sequentially, with the potential for overruns?**


Run Times
---------

Consideration needs to be given to the running times of the housekeeping. **How much actual maintenance time do we have available on a daily basis for this to execute? Are there times (or dates and times) we should avoid during the day?**


Referential Integrity Constraints
---------------------------------

There are no proper referential integrity constraints whereby the PCL (parcel) table, for example, is the parent table in various relations with the other tables containing a parcel ID column. This table *should* be the parent of all the other tables where a parcel ID exists, all the IDs refer to a specific parcel after all.

There are many of these potential child tables, but no referential links (foreign keys) between them. This could be a valid design decision, of course, but it currently means that a parcel ID in one table may hold information for a completely different parcel to the one currently holding that parcel ID in the PCL table, simply because the latter is a wrapped around ID from after a previous *Billion Parcel Rollover* event, and the one in the other table is from before that event.

**In the most recent exercise to remove old data, this problem was addressed - but was it addressed correctly and completely?**

The following table shows the current list of tables which contain a parcel ID. The ones marked as 'partitioned' are the larger ones and were the only ones initially subject to housekeeping considerations. The others were eventually house-kept, but it was not originally planned for this to happen.

+----------------------------------+-------------+----------------------------------+-------------+
| TABLE NAME                       | PARTITIONED | TABLE NAME                       | PARTITIONED |
+==================================+=============+==================================+=============+
| AMAZON                           | NO          | AMAZON2                          | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| CLT_PUSH_TRIG                    | NO          | DLY_POT_MFST                     | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| EML_TRIG                         | NO          | EML_TRIG_PCLSHP_RMDR             | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| *MFST_PCL_DET*                   | YES         | *MNL_MFST_PCL_DET*               | YES         |
+----------------------------------+-------------+----------------------------------+-------------+
| *PCL*                            | YES         | PCL_ADDL_ATRBS                   | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| PCL_ADDL_SO                      | NO          | PCL_BCDE                         | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| *PCL_DIVN_DET*                   | YES         | PCL_HIST                         | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| *PCL_IMG*                        | YES         | *PCL_ITM_PROG*                   | YES         |
+----------------------------------+-------------+----------------------------------+-------------+
| *PCL_PROG*                       | YES         | S_CLT_PUSH_TRIG                  | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| S_CLT_TRKG                       | NO          | S_EML_TRIG                       | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| S_HHT_TRKG                       | NO          | S_PCL                            | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| S_PCL_PROG                       | NO          | S_PCL_PROG_RCYCL                 | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| UDLD_PCL                         | NO          | UDLD_PCL_ACTN                    | NO          |
+----------------------------------+-------------+----------------------------------+-------------+
| UDLD_PCL_CUST_UPD                | NO          |                                  |             |
+----------------------------------+-------------+----------------------------------+-------------+

I suspect the two *AMAZON* tables are to do with the migration to AWS, but they do have a PCL_ID column, so remain listed for now.

Any one of the unpartitioned tables *could* be holding data for parcels from before the previous roll over event, if they were not house-kept at the time.

It should be noted that referential integrity is a two edged sword. It can make things easy for housekeeping, but can also have the opposite effect. A proper set up would have considered what should happen when a parcel is deleted - should all the rows in other tables, related to that parcel, also be deleted? Common sense says yes, and a foreign key with the *on delete cascade* clause added, would cover that. However, such constraints would need to be carefully applied to *all* possible child tables to ensure that the deletion properly cascades down all the tables required. And, also, having this tree of referential integrity would also mean that deleting parcels would have to be done on a row by row basis, and the quick truncation or dropping of the oldest partitions would then, not normally be possible.

It could be done, with downtime, as the constraints could be disabled, the partitions dropped, and then the constraints re-enabled. Downtime would be needed to prevent the saving of invalid data from the application while the housekeeping took place.

    It has been noted in myhermes, that there are referential integrity loops where a table is a child of a parent, and also the parent of its own parent, or, even in some cases, a parent of its own grand parent. This makes deleting almost impossible as you need to delete the child tables first, but they are parents of themselves, in some cases so they cannot be deleted without dropping and recreating the constraints.

**Should we be considering adding proper referential integrity constraints?** (I suspect not!)


Optimiser Statistics
--------------------

After deleting a number of rows from these tables, the optimiser statistics should be updated. This will take place semi-automatically on the next working day at 06:00 (or thereabouts) in the morning. **Alternatively, we need to consider whether the housekeeping job should also gather statistics, on the partitions deleted from, after the deletions.**



Billion Parcel Problem Areas
============================

The following problem areas were encountered in the recent *Billion Parcel Rollover* event, during the housekeeping of large volumes of data.


Data Volumes
------------

Looking at 2017 figures, it can be seen that the most active table in the PCL_PROG table, which has between 8 and 14 million rows added *per day*, depending on whether it is peak period or otherwise. Because of these large numbers, housekeeping would appear to be needed on a daily basis, and those are the sort of figures that we would expect to be being deleted on a daily basis. 

The other tables have smaller volumes, but for 2017, these are the average daily rate of new rows being added (to partitioned tables only):

+-------------------+-------------+------------+
| TABLE NAME        |   OFF PEAK  |   PEAK     |
+===================+=============+============+
| MFST_PCL_DET      |   679,342   |    ?       |
+-------------------+-------------+------------+
| MNL_MFST_PCL_DET  |    10,234   |    ?       |
+-------------------+-------------+------------+
| PCL               |   701,414   |    ?       |
+-------------------+-------------+------------+
| PCL_DIVN_DET      |      ?      |        24  |
+-------------------+-------------+------------+
| PCL_IMG           |   445,467   |   728,460  |
+-------------------+-------------+------------+
| PCL_ITM_PROG      |         0   |    ?       |
+-------------------+-------------+------------+
| PCL_PROG          | 8,043,324   | 14,127,731 |
+-------------------+-------------+------------+

Peak being November 2017 and off-peak being April 2017. Some tables appear to be missing a chunk of partitions and cannot have their actual row count analysed. It appears that some form of partition pruning is going on, but appears to be somewhat random. (My assumption!)


Database Design
---------------

There are a number of problem areas within the domain of database design that have caused problems for the manual housekeeping recently carried out.

Global Indexes
~~~~~~~~~~~~~~

Because the larger tables are partitioned, some have been partitioned in such a way as to cause there to be a need to have global indexes attached to the table - ie, unpartitioned indexes. The PCL table, for example, has an index on PCL_ID (parcel ID) but the table is partitioned on PCL_ID and CRE_TMESTMP (creation time stamp?). This means that the "high speed" manner of deleting all the data from an older partition cannot be used as it will render the global indexes unusable and may cause severe performance problems in the application. Hence, we had to run specific deletions that took many hours to complete, in order to prevent "damage" to these global indexes.

Because of these global indexes, attempting to delete from the PCL table in one huge chunk - a partition at a time - did eventually cause problems for the online system with data not being processed properly as it had missed its time slot due to the length of time it took to run a process that should run every 90 seconds, but took over 30 minutes on occasions. (I think the application ignored data that it *thought* had already been processed - which is what led to the problem. I may be wrong, Karl knows.)

Investigation showed that the application was hung waiting on the deleting process to finish with the global index on the PCL table.


Application Interference
------------------------

As mentioned above, deleting huge chunks of data from certain tables, PCL in the main, has had undesired consequences for the application. This is *possibly* caused by the application design, but even though, this has to be avoided when housekeeping data. On average, deleting 250,000 rows from PCL at a time, took between 5 and 15 minutes during the recent housekeeping exercise. This would require around three separate deletions given off peak volumes listed above.


Optimiser Statistics
--------------------

Deleting rows in this manner causes the statistics for the table (and/or partition) to "go off" and require regathering. This will take place at around 06:00 on the next working day, but certain tables can cause this process to overrun the start time for ETL3. The daily Statistics Gathering processes executed early morning do attempt to take this into consideration, and process the larger, long running, tables differently - but they still need to be monitored and abandoned if they are about to overrun the ETL.

Abandoning a statistics gathering on a table (or index) could leave that object with no statistics as Oracle appears to delete existing statistics before gathering current values.



