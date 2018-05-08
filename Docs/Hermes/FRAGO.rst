==========================
MISA Daily Defragmentation
==========================

Summary
=======

The daily reorganisation, which takes place after the BO Reporting has completed, and before 14:00 (normally) when the RMAN backups kick in, is run to:

*   Determine which, of a select group of tables or partitions (for the current and previous month only) have less than 50% of the blocks in the object full to 100% capacity. Only those with a weighting factor of 50 or more and which are bigger than 3 MB are considered.
*   Reorganise the blocks so that only 100% full blocks are now part of the object. There are (normally) no free blocks after reorganisation.
*   Rebuild any affected indexes.
*   Gather statistics on the reorganised objects as existing statistics are now invalid.

This is designed to make the ETL runs quicker and the BO Reporting  more efficient.

**NOTE:** It has been observed that the reorganisation takes place *after* the BO Reports, so the efficiency there is not coming from the reorganisation. In addition, almost as soon as any ETL work is carried out on the objects (or at least, those observed) it completely unorganises the objects again.

**NOTE:** In theory, reorganising an Oracle object is *almost never* required. However, it *can* be helpful in reclaiming unused space if and only if, the object in question is only ever ``DELETE``d from and ``INSERT /*+ APPEND */``ed into. For the sake of argument, ``INSERT`` covers ``MERGE`` also.


Frag Analysis
=============

The analysis begins by archiving "yesterday's" frag_report data into the frag_report_archive table, the archive table is then trimmed by deleting anything older than 31 days. 

The analysis continues by obtaining a list of:

*   All table partition names, for the current and previous month, owned by ``HERMES_MI_MART``, ``ECHO_EDW`` and ``C2C``, which are not in the ARCHIVE tablespaces, which do not have MAX in their name, and which do not have $ in their name;
*   All table partition names, for the current and previous month, for the tables ``PCL``, ``PCL_PROG`` and ``PCL_HIST``, owned by ``HERMES_MI_STAGE``, which are not in the ARCHIVE tablespaces, which do not have MAX in their name, and which do not have $ in their name;
*   All table names, owned by ``HERMES_MI_MART``, which are not in the ARCHIVE tablespaces, which do not have $ in their name and which are not named TEMP something;
*   All table names, owned by ``HERMES_MI_STAGE`` or ``C2C``, which are not in the ARCHIVE tablespaces, which do not have $ in their name and which are not named TEMP something and which are named as follows:
    *   ``ALL_PARCELSHOP_RATES_DIM_T``
    *   ``ALL_PARCELSHOP_RATES_PREV``
    *   ``CR_OVRD``
    *   ``DLY_ZNE``
    *   ``HMI_RECONCILE_BATCH``
    *   ``LOCN_WORKING_CALENDAR``
    *   ``MGR_DIM_TAB``
    *   ``RETS_CUST_ORD``
    *   ``S_CLN_RQST_PROG_NO_CLN``
    *   ``S_CR_CAT_VOL_MISSING``
    *   ``S_CR_RND_ALCN_MISSING``
    *   ``S_DELIVERY_INVOICE_C2B``
    *   ``S_PCL_PROG_NO_PCL``
    *   ``CALENDAR``
    *   ``ECHO_CUST_PRICEBAND_TAB``
    *   ``PRICEBAND``
    *   ``CSV_OUTLYING_FINANCE_AREA``
    *   ``CSV_OUTLYING_PCODE_AREA``

All of the selected table and partition names are then examined to determine space usage and unused space by making two separate calls to ``DBMS_SPACE`` utility routines. The following data are collected:

*   Full blocks - the total number of 100% full blocks in the object;
*   FS1 Blocks - counts of blocks, on the freelists, with less than 25% free space;
*   FS2 Blocks - counts of blocks, on the freelists,  with 25% - 50% free space;
*   FS3 Blocks - counts of blocks, on the freelists,  with 50 - 75% free space;
*   FS4 Blocks - counts of blocks, on the freelists,  with 75% - 100% free space;
*   Total blocks - the total number of blocks in the object in question;
*   Unused blocks - the number of blocks which are unused - in other words, are above the object's High Water Mark.

**WARNING:** It should be noted that the total number of blocks is not *simply* the sum of the other counts - there are blocks allocated for use by the system, for example.

For any object which has at least one block with any free space in it, a weighting factor is calculated as a percentage of the total number of blocks with any free space. Blocks are weighted according to the amount of free space in each, giving a higher weighting to the more emptier blocks:

*   For FS1 blocks, the weighting factor is 0.25;
*   For FS2 blocks, the weighting factor is 0.50;
*   For FS3 blocks, the weighting factor is 0.75;
*   For FS4 blocks, the weighting factor is 1.00.

The calculated weighting factor for the object, is the total number of blocks with free space, as a percentage of the sum of all 4 weightings. Weighted sum / total free * 100.

The collected data are then written to the frag_report table. Columns include (but are not limited to) the following:

*   The object's details - name, type, size (Mb) etc;
*   The various FSn block counts;
*   The weighting factor;
*   The total number of blocks;
*   The "other" blocks - any block that is not unused, not free and not full - system usage in other words for the segment bitmaps and such like.


Frag View
=========

The view ``FRAG_VIEW`` is based on the ``FRAG_REPORT`` table which is updated by the ``FRAG ANALYSIS`` procedure detailed above.

The view selects data from the table which has all of the following attributes:

*   Size greater than 3 Mb;
*   Weighting factor greater than 50;
*   Less than 50% of blocks are full to capacity;

In other words, objects which are of a reasonable size, with a decent weighting factor and which have "not enough" completely full blocks.


Frag Report
===========

The report, is produced by the package ``PKG_FRAG``'s procedure ``FRAG_REPORT`` - owned by ``HERMES_MI_ADMIN`` and is based on all the rows in the ``FRAG_VIEW`` view.

For each TABLE which doesn't have *enough* full blocks, a report entry as follows is output:

..  code-block:: none

    -- TABLE:      D_PCLSHP_DPOT_SERVICE             % Full Blocks:   20.03

For each TABLE PARTITION, the report entry is as follows:

..  code-block:: none

    -- TABLE:      F_PCLSHP_OVERALL_SOS
    -- PARTITION:  F_PCLSHP_OVERALL_SOS_201801       % Full Blocks:   49.77
    
The report simply shows the object name and the percentage of completely full blocks within the object.


Frag Control
============

This is the other packaged procedure in ``PKG_FRAG``. It executes the report above, and then either:

*   Displays the SQL commands that are required to reorganise a table or partition, plus all affected indexes and to regenerate statistics for the affected object; or
*   Executes the SQL commands to carry out the actual reorganisation and to regenerate statistics for the affected objects after all reorganisations have taken place.

In the former case, progress can be seen on-screen as the code outputs regular updates of where it has got to in the list - "Done n out of nn" messages will be displayed.

In the case of the latter, ``V$SESSION`` will display the table, or partition, being processes in the ``ACTION`` column where the ``MODULE`` column is set to FRAGO. Progress can be checked there:

..  code-block:: sql

    select sid, module, action
    from   v$session
    where  module = 'FRAGO';


Is This a Worthwhile Effort?
============================

An observation on *one* particular object was carried out over a couple of days. The object was the table ``HERMES_MI_MART.F_PCLSHP_OVRALL_SOS_B2C``, partition ``F_PCLSHP_OVRALL_SOS_B2C_201802``. The current partition for this table.


Tuesday 6th February 2018
-------------------------

11:15 - Before Reorganisation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+
| FS1 Blocks     | 0      |
+----------------+--------+
| FS2 Blocks     | 1911   |
+----------------+--------+
| FS3 Blocks     | 821    |
+----------------+--------+
| FS4 Blocks     | 1636   |
+----------------+--------+
| FULL_BLOCKS    | 2872   |
+----------------+--------+
| UNUSED BLOCKS  | 834    |
+----------------+--------+
| TOTAL BLOCKS   | 8192   |
+----------------+--------+
| WEIGHTING      | 73.43% |
+----------------+--------+

Prior to the reorganisation, this partition had a total of 8192 blocks of which 834 were above the High Water Mark. The various FSn blocks are available for use by ``INSERT`` which do not use direct path loading. ``UPDATE`` statements may use these if necessary, to increase the size of a column's data, or for LOBs.

Direct path loads will use only the blocks above the HWM and on completion, the HWM will be moved up. 

DELETE statements will reduce the amount of space in various blocks, and these will be added to the free lists (viz, the FSn blocks) and will become available for use again - just not by direct path loads.



12:20 - After Reorganisation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+
| FS1 Blocks     | 0      |
+----------------+--------+
| FS2 Blocks     | 0      |
+----------------+--------+
| FS3 Blocks     | 0      |
+----------------+--------+
| FS4 Blocks     | 0      |
+----------------+--------+
| FULL_BLOCKS    | 4532   |
+----------------+--------+
| UNUSED BLOCKS  | 758    |
+----------------+--------+
| TOTAL BLOCKS   | 5376   |
+----------------+--------+
| WEIGHTING      | n/a    |
+----------------+--------+

After the reorganisation, the numerous blocks with any free space have all been reduced to zero - all the data are now "compressed" into full blocks, as it turned out on this occasion. The HWM has been adjusted and the total number of blocks in the table has reduced to 5376 with 758 of those above the HWM.

This will, briefly, improve performance of full table scans as only those blocks beneath the HWM will be scanned - we have reduced this from 7358 (8192 - 834) to 4618 (5376 - 758) which is a reduction of 37%.Now when the reports run, they should be quicker. But they don't run after the reorganisation, they run *before* it.

The ETL processing is assumed to only ever use direct path loads, so there will be usage of the 758 blocks above the HWM for this purpose, and any deletions will move those nicely full blocks back onto the free lists.

Wednesday 7th February 2018
---------------------------

11:14 - Before Reorganisation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+
| FS1 Blocks     | 0      |
+----------------+--------+
| FS2 Blocks     | 2282   |
+----------------+--------+
| FS3 Blocks     | 1079   |
+----------------+--------+
| FS4 Blocks     | 1481   |
+----------------+--------+
| FULL_BLOCKS    | 3724   |
+----------------+--------+
| UNUSED BLOCKS  | 780    |
+----------------+--------+
| TOTAL BLOCKS   | 9472   |
+----------------+--------+
| WEIGHTING      | 70.86% |
+----------------+--------+

The stats above reflect the partition *after* the overnight ETL processing and BO Reports. The table is a lot more fragmented than it was yesterday before the reorganisation! So the performance of the BO Reporting *should* have been *seriously affected* by this *total disorganisation* - but was it? It has an extra 583 blocks to scan for reporting data - so performance *must* have suffered. And yet, nobody complained or raised any service desk calls. (Of course, we are assuming that this partition is reported on by the BO Reports. It may be that it isn't, but that itself raises the question of why are we reorganising it?)

We can see that yesterday's reorganisation has been undone. ``DELETE`` statements against the table have freed up large quantities of space in the 100% full blocks, and they have now been added back to the free lists for subsequent use by ``INSERT`` or ``UPDATE`` statements. There are now 4842 blocks with some usable free space.

The HWM on the table has been increased from 4618 to 8692, nearly 47% more blocks since the reorganisation went to the trouble of reducing the number of blocks.


11:42 After Reorganisation
~~~~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+
| FS1 Blocks     | 0      |
+----------------+--------+
| FS2 Blocks     | 0      |
+----------------+--------+
| FS3 Blocks     | 0      |
+----------------+--------+
| FS4 Blocks     | 0      |
+----------------+--------+
| FULL_BLOCKS    | 5717   |
+----------------+--------+
| UNUSED BLOCKS  | 329    |
+----------------+--------+
| TOTAL BLOCKS   | 6144   |
+----------------+--------+
| WEIGHTING      | n/a    |
+----------------+--------+

The reorganisation on Wednesday 7th reduced the total blocks from 9472 to 6144 and again, coalesced all the blocks with free space into full blocks. 

+----------------+--------+
| FS1 Blocks     | 0      |
+----------------+--------+
| FS2 Blocks     | 2372   |
+----------------+--------+
| FS3 Blocks     | 535    |
+----------------+--------+
| FS4 Blocks     | 1085   |
+----------------+--------+
| FULL_BLOCKS    | 5020   |
+----------------+--------+
| UNUSED BLOCKS  | 82     |
+----------------+--------+
| TOTAL BLOCKS   | 9216   |
+----------------+--------+
| WEIGHTING      | 66.94  |
+----------------+--------+

And the overnight processing on the 7th undid all the good work. Again.