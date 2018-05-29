=====================
Create_Release Script
=====================

Rob has created a nice setup on the AWS Database Management Server to enable us to apply releases/developer scripts/etc to development, test and/or production (with CAB approval!) and to keep a record of what was applied and where. This should help in the migration process as we have a documented audit trail of what was changed, by whom, and when.

Current Process
===============

According to Rob's document, whenever we have a change request to apply, we must obtain the change number and the appropriate scripts from the requester. Then we:

*   Login to the server (ip = 10.128.3.242) as the oracle user;
*   Change to the ``Releases`` directory;
*   Change to the appropriate module directory;
*   Scan the existing directories for the 'next' version of our change;
*   Create a directory named ``CHG<number>_v<version>`` (Upper case 'CHG' and lower case 'v' and seven digits with leading zeros for the numeric part of the change number.);
*   Copy ``~/Releases/deploy_all.template`` and ``~/Releases/rollback.template`` to the new directory;
*   Change into the new directory;
*   Edit ``deploy_all.template`` into a new file ``deploy_all.sql`` and set the change number, version number and the (meaningful) description;
*   Edit ``rollback.template`` into a new file ``rollback.sql`` and set the change number and version number;
*   Copy or create the actual script files required, and add them to ``deploy_all.sql``.

And *that's* all there is to it!


New Improved and Better Process
===============================

I'm basically too lazy to do all that, each and every time I have a change. I'm also *fat fingered* when typing as I don't look at the screen (I can't touch type even after 35+ years in IT!) so, here is the new process that I have put in place:

*   Login to the server (ip = 10.128.3.242) as the oracle user;
*   Change to the ``Releases`` directory;
*   Execute the following command:

    ..  code-block:: bash
    
        ./create_release.sh [MODULE] [CHANGE] ["Description in quotes"]

*   Change into the new directory;
*   Copy or create the actual script files required, and add them to ``deploy_all.sql``.


Parameter Details
=================

The script expects three separate parameters. These are:

*   `Module Name <#module>`_.
*   `Change Number <#change-number>`_.
*   `Description <#description>`_.

These are described below.


Module
------
This is, currently, one of the following:

+--------+--------------------------+
| Module | Description              |
+========+==========================+
| RTT    | Real Time Tracking.      |
+--------+--------------------------+
| MOD    | Method of Delivery.      |
+--------+--------------------------+
| MYH    | My Hermes.               |
+--------+--------------------------+
| PSH    | Parcel Shop.             |
+--------+--------------------------+
| SHP    | Shipping.                |
+--------+--------------------------+
| SVOC   | Single View of Customer. |
+--------+--------------------------+
| TRK    | Tracking.                |
+--------+--------------------------+
| COL    | Couriers Online.         |
+--------+--------------------------+

Module names can be entered in any letter case - they will be converted to upper case as required.

While ``DB2`` is currently a valid module, it is not *yet* implemented by this system because DBA changes don't appear to follow the same procedures as, for example, ``RTT``.


Change Number
-------------

Change numbers are assumed to be of the format 'CHGnnnnnnn', ie with a 7 digit actual change number, and the script assumes this too. We *could* be in a spot of bother when we move from 9,999,999 to 10,000,000 though, but see below! 

To ease up on the strain of typing, the script allows you to enter any of the following formats for a hypothetical change number CHG0012345:

*   12345
*   0012345
*   CHG12345
*   CHG0012345
*   chg12345
*   chg0012345

In addition to the above, any numeric parts of the change number will accept any number of *leading* zeros.

In all cases, the correctly named directory will be created. This will be ``CHG0012345_v<version>`` where <version> will be the next available version number, starting at 1 and incrementing by 1. The user need not and should not specify a version number.

If there are non-digit characters in the change number, *after* the 'chg' text at the start, if present, then the script will exit with an error.

The script copes with change numbers in the standard format of up to 7 digits, so all changes, between 'CHG0000000' and 'CHG9999999' will be coped with. Anything higher than 9,999,999 will *not* be truncated to 7 digits but will continue with the full compliment of digits passed. This implies that the directory names will get longer as change requests come through in the years to come!


Description
-----------

The description is free format text. It *must* be wrapped in double quotes if there are any special characters, or spaces. If the description is, for example, a single word, then the quotes are not required, but is a one word description *really* a (meaningful) description! 

The description is converted to upper case and no other validation is performed on this parameter.


Exit Codes
==========

The script is quite well error trapped, and the following exit codes will be used:

+------+-----------------------------------------------+
| Code | Description of error                          |
+======+===============================================+
| 0    | No errors. Everything worked fine.            |
+------+-----------------------------------------------+
| 1    | DB2 module requested. Not (yet) implemented.  |
+------+-----------------------------------------------+
| 2    | Invalid module passed.                        |
+------+-----------------------------------------------+
| 3    | Invalid change number passed.                 |
+------+-----------------------------------------------+

