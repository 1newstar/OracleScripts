=================================
Daily ASM "Days Remaining" Report
=================================

Introduction
============

Alain used to send out a report on a daily basis that showed the amount of free space remaining in the DATA and FRA disk groups in various ASM instances providing space to MISA, MISD, MOD, MH, RTT production databases. Primary only as far as I can see.

This report was created manually by him running a script, ``/home/oracle/alain/asmchk``, on the 5 production servers, manually, then copying the DATA and FRA free_MB figures into a spreadsheet - one for each database - then adjusting some parameters for his chart, and then copying and pasting the chart into an email to send out.

Problems
~~~~~~~~

*   The system is manual.
*   Alain is no longer here.
*   The report is no longer issued due to Alain's absence.

I think there has to be a better way!

New Daily Reports
=================

Oracle Enterprise Manager keeps statistics on the amount of space within the various ASM Instances. This data are collected regularly and rolled up into hourly and daily totals, amongst others.

I have written two reports in OEM, one to be run daily at 08:00 and emailed to huk.dba, and the other to be run 'on demand' as necessary.

ND - ASM DATA Disk Group - Full up within 60 days
-------------------------------------------------

This report is scheduled to be run daily at 08:00 and lists only those ASM instances for production databases, primary or standby, which have a DATA disk group that will fill up within 60 days, if it continues to use free space at the same rate as it did over the last 14 days. If the consumption of free space means that the DATA group will be full at any time within the next 60 days, then it will be reported upon, otherwise, it will not be listed.

It is expected that most of the time, this report will be blank. 

Points to Note
~~~~~~~~~~~~~~

*   The report must be scheduled for 8:00 AM or later. The figures used for the report, both reports actually, are rolled up into the appropriate metrics table between 07:30 and 07:40 UK time, daily.
*   This report only considers disk groups named DATA;
*   Average consumption rates change. You may see a peak one day which causes the report to list the specific disk group, and then for it to vanish again next day when less space is consumed.
*   Blank reports *can* be ignored. See below for an Outlook rule to delete any blank reports to avoid cluttering up your inbox.


ND - ASM DATA Disk Groups - Free Space Days Remaining
-----------------------------------------------------

This report is identical to the scheduled one above, but the limit on days remaining being 60 or less is removed. The report therefore shows the days remaining for all DATA disk groups.

This report is not scheduled. If you need to run it, then:

*   Login to OEM as normal.
*   Click 'Enterprise' top left.
*   Click 'Reports', then 'Information Publisher Reports'.
*   In the search box, type 'ASM DATA', without quotes, press ENTER or click the 'Go' button.
*   Click 'ND - ASM DATA Disk Groups - Free Space Days Remaining'.
*   Wait...
*   The report will be displayed on screen.

Should you wish to email yourself a copy, then proceed as follows:

*   Login to OEM as normal.
*   Click 'Enterprise' top left.
*   Click 'Reports', then 'Information Publisher Reports'.
*   In the search box, type 'ASM DATA', without quotes, press ENTER or click the 'Go' button.
*   Enable the radio button in the 'Select' column.
*   Click the 'edit' button.
*   On the 'Schedule' tab:
    *   Click the check box to 'Schedule Report', top left.
    *   Click the radio button 'One Time (immediately)'.
    *   Make sure that 'Email report each time ...' is ticked.
    *   Change the contents of the 'To' box to your own email.
    *   Click 'OK' button, far right.
*   Wait for the email...   

Other Reports
=============

I have created a few other reports which operate manually, similar to the description above. None of these are scheduled. All my reports are named 'ND - something' so that they are easily searched for, prior to usage or removal from OEM!

ND - Host & Database Consolidation Report
-----------------------------------------
Displays details of the databases on various hosts, and their versions, archive log mode, etc etc. Handy if you are setting up a ``tnsnames.ora`` entry and you need to quickly find out the server (host) and port to be used. I set it up when trying desperately to get access to the OEM repository database, but it seems we are 'fire walled' out. *C'est la vie*, as they say in Cardiff!

ND - ASM Space Utilisation over Previous 6 Months
-------------------------------------------------
Lists space utilisation in *every* ASM instance, for the previous 6 months.	The report includes every ASM instance configured within OEM, and lists the last 6 months worth of data, where it exists, for each disk group.
	
ND - Production ASM Space Utilisation over Previous 6 Months
------------------------------------------------------------
Lists space utilisation in all the Production ASM instances for the previous 6 months. MISA, MISD, RTT, MOD, MH_C2C ONLY. Includes both primary and standby ASM instances and databases.

ND - MISA ASM Space Utilisation over Previous 6 Months
------------------------------------------------------
Lists space utilisation in the MISA Production ASM instance for the previous 6 months. Includes both primary and standby ASM instances and databases.
	
ND - MISD ASM Space Utilisation over Previous 6 Months
------------------------------------------------------
Lists space utilisation in the MISD Production ASM instance for the previous 6 months. Includes both primary and standby ASM instances and databases.
	
ND - MOD ASM Space Utilisation over Previous 6 Months
-----------------------------------------------------
Lists space utilisation in the MOD Production ASM instance for the previous 6 months. Includes both primary and standby ASM instances and databases.
	
ND - MyHermes ASM Space Utilisation over Previous 6 Months
----------------------------------------------------------
Lists space utilisation in the MyHermes Production ASM instance for the previous 6 months. Includes both primary and standby ASM instances and databases.
	
ND - RTT ASM Space Utilisation over Previous 6 Months
------------------------------------------------------
Lists space utilisation in the RTT Production ASM instance for the previous 6 months. Includes both primary and standby ASM instances and databases.


All reports have a small floppy disc icon on the top right of the report's results table on the screen. If you click this the *entire* report will be downloaded, even if only showing a single page of larger reports, to a CSV file on your computer. It can then be opened in Excel for further processing.
	

Setting Up an Outlook Rule
==========================

It will be obvious, that on days when there are no DATA disk groups that will fill up in the next 60 days, the report will not be of any use whatsoever. The report has no way of not sending when no rows are returned, it goes out "blank" regardless.

If you do not wish to be bothered with these "blank" reports in your inbox, then you will need to set up a rule, in Outlook, as follows:

*   Open Outlook and on the left side, click on your account name.
*   On the 'Home' tab, click on 'Rules'.
*   Click 'Manage Rules & Alerts'.
*   On the 'Email Rules' tab, click 'New Rule'.
*   Click on 'Apply rule on messages I receive' which is under the heading 'Start from a blank rule'. Click 'Next' button.
*   Step 1: Select conditions:
    *   Tick 'with specific words in the subject'
    *   Tick 'sent to people or public group'
    *   Tick 'with specific words in the body'
*   Step 2: Edit the rule description (bottom of dialogue):
    *   Click Sent to 'people or public group' and double-click HUK.DBA from the list. Click 'OK' button.
    *   Click and with 'specific words in the subject' and specify 'Disc Groups - Full up within'. Click 'Add' button. Click 'OK' button.
    *   Click and with 'specific words in the body' and specify 'No rows returned' . Click 'Add' button. Click 'OK' button.
    *   The lower section of the dialogue should now read as follows:
        ..  code-block:: none
        
            Apply this rule after the message arrives
            sent to *HUK.DBA*
             and with *Disc Groups - Full up within* in the subject
             and with *No rows returned* in the body
    *   Click 'Next' button.
*   Step 1: Select Action:        
    *   Tick 'delete it', or, 'permanently delete it'.
    *   Click 'Finish' button.
*   Click 'OK' button.    

When a "blank" report is now received, it will be moved to your deleted items folder, if you chose 'delete it', or will simply vanish forever, if you chose 'permanently delete it'. I prefer the former as then you have the chance to see what it did contain in case of errors from Outlook.