=======================
GDPR Meeting - Thoughts
=======================

The following are my own thoughts and observations on the matters for discussion, based on previous contracts and processes.


Access Control
==============

Access Management
-----------------

Accounts
~~~~~~~~

Only people with a documented right to access the system were permitted an account. DBAs had individual accounts, with SYSDBA privileges, and were able to connect, stop and start the database, listener etc as required.

DBAs logged in as "themselves" on the server, and executed the ``su - oracle`` command so that audit logging of work carried out on the server could be collected. There was some sort of system in place whereby the session details were written down to a log file - not visible to the DBA logging in - which was based on the username and the session number. 

Unfortunately, from time to time this failed as another DBA could log in and get the same session number, so would attempt to overwrite the logging file and fail due to permissions. Thus losing  the required audit data.

Auditing
~~~~~~~~

Auditing was enabled for all databases. I note some databases here do not have auditing enabled. In addition, audit trail data was written to the server audit logging system to prevent the odd occasional rogue DBA (or other user) from accessing their own audit records and wiping them.

SYS actions were always audited.

Access Requests
~~~~~~~~~~~~~~~

Access to a system was form based, and had to be approved - and signed off - by various teams, including but not limited to:

*   The Team Leader responsible for the application;
*   The DBA Team Leader;
*   The Security Team Leader;
*   The applicant's own Team Leader.

The form listed any desired privileges or roles and options such as "the same privileged as Fred or Barney" were not allowed.

Database Profiles
~~~~~~~~~~~~~~~~~

Profiles were set up on the database for two main types of user:

*   Service Users - the owners of the data;
*   Application users - the people using the service users' data via the application.

The profiles determined the following restrictions:

*   FAILED_LOGIN_ATTEMPTS - how many times a person could attempt to login, and get it wrong, before the account was locked for a time;
*   PASSWORD_LOCK_TIME - How long a password would remain in a locked state after too many failed login attempts;
*   PASSWORD_LIFE_TIME - How long a password could be used for, before it had to be changed;
*   PASSWORD_GRACE_TIME - How long a password could be used to login, after its normal expiry date. If the password is not changed during the grace period, the account will be locked by the database.
*   PASSWORD_REUSE_MAX - How many different passwords have been in use since the one attempted to be set, was last used. Works alongside PASSWORD_REUSE_TIME.
*   PASSWORD_REUSE_TIME - How many days have passed since the last time the proposed password was last in use. Works with PASSWORD_REUSE_MAX.
*   PASSWORD_VERIFY_FUNCTION - A function that would assist in verifying how complicated the password being set for a user was. Things like minimum size, how many letters, digits, special characters, if it contained the username or the word password, how different it was from the previous password etc.
*   IDLE TIME - to log the user out after a "long" period of inactivity. This could sometimes be a problem if the user submitted a long running query or report as the session could be dropped in mid report, leading to the expense of a database rollback etc when the problem was detected by PMON/SMON.

Oracle Client Installs
~~~~~~~~~~~~~~~~~~~~~~

Application users had the minimal installation of Oracle Client, if necessary, on their desktop for application that required a dedicated connection to the database. This was not necessary when the connection was via an application server, for example. SQL*Plus and other utilities  was not considered essential for application users, only for DBAs and support teams.

Managers, who may have necessity to "correct things" for users of an application had a minimal install of the client software and some of the tools.

DBAs had full installs of the entire Oracle Client software.

Named Users
-----------

All users wishing to access a system had to have a named user account with the minimum level of permissions (via roles where appropriate). Passwords  had to be changed regularly - every 30 days for normal users and DBAs, and this was based on profiles.

Access had to be approved by a number of separate teams.

Service Accounts
----------------

Service accounts, did not have an expiry date on the profile, but, were only used for system installation and/or maintenance. Users of the system had to connect via the application, using their own individual account.

Obviously this is dependent on how the various third parties author their applications. There were three main methods:

*   Everyone logs in as the service account user when using the application - the account name and password were usually hard coded, or, configured in a separate text file using some form of encryption to obfuscate the password details. There is no way to tell who is the actual user using the application and/or doing the work/damaging the system. These applications were very much frowned upon from a security point of view.

*   Everyone using the application logs in to the service user, however, the application maintains its own table(s) of accounts whereby the actual user doing the work can be identified as the user sees a login form on first connection to the application. Audit trails were kept by the application, permissions could be set etc. These applications did not need a separate Oracle (or database) account for each user, only the service account was needed.

*   Everyone using the application had to have an individual Oracle (or other database) account to be able to use the system. The application did not connect as the service user. User accounts for these applications had been granted specific roles that enabled various privileges within the database and it was the database privilege system that controlled what each user could and could not do or see.

Account Expiry and Locking
--------------------------

With limited exceptions:

*   Any account that was not logged into for 30 days would be automatically locked;
*   Any account that remained locked for 30 days would be locked and expired;
*   Any account that remained locked and expired for 6 months or longer, would be dropped.

However, this did occasionally catch out people on maternity leave who came back and found that they had no access.

A "Leavers" process existed whereby HR would be informed by each individual department as to who had left and which services that they had access to. On a daily basis, a process was executed that would disable those users' accounts for:

*   The network;
*   Email;
*   Applications access;
*   Database access.

The period of time that a user who had left but who's account(s) remained open was limited to a short period of around 24 hours.

After a leaving, some companies demanded that the users PC be backed up and then wiped back to a standard install. The backup was deemed necessary as some developers had been known to develop systems on their desktop and not put the code into version control.

You Said:
---------

*   *All new AWS d/b’s will be on 12c which now has LAST_LOGIN on dba_users. Therefore, we need to ensure a standard policy for expiring Accounts. Typically this would be a) locked after n days of inactivity and b) automatically removed after n days in a LOCKED state. Standard Policy must be implemented.*

    See above, and beware of maternity leave.

*   *Password Exposure/Risk. Any applications using core schema account credentials will be eradicated and should not be permitted.*

    This might be impinged upon by various third party applications.   

*   *Removal of ALL inappropriate privileges (least privilege approach).*

    Very wise. Normally, the DBA, CONNECT  and RESOURCE roles and any '\_ANY\_' privileges were not permitted on any Oracle database.

*   *What data should appropriately be made available for Support Users.*

    This can be facilitated using roles so that only specific tables can be accessed, or, using advanced security options (extra cost option) to prevent access to certain columns in certain tables, etc.

*   *Position and monitoring of inappropriate use of Production accounts.*

    This has been facilitated by the use of OEM to determine when numerous failed attempts to login has occurred on an account, etc.

Data Retention Policy
=====================

*   *EACH database must have one in place ( even if it’s empty to start with! ). We then need to fill it out.*

*   *Housekeeping. How Retention Policy is enforced must be documented/implemented.*

Data/Business Owners
====================

*   We need to agree Business Owners for data.

Database Links
==============

*   *Pitfalls/Current 'blindspots' need removing.*

    In the past, PUBLIC database links have been expressly forbidden as any user account can use them to access data on the remote database.
    
    Other restrictions on database links involved always naming them after the remote database but that was seen to be a problem when more than one link, connecting to the same database but different account, were required.
    
    Oracle has the GLOBAL_NAMES parameter that enforces the use of a link which then has to be named after the remote database. This defaults to FALSE but if set to TRUE then a database link can only be created if the name of it matches the database it connects to.
    
In addition:
  
    * There could be no database links from any database not deemed to be production, to any production database. If a database had to have a link to a production database, that was permitted only provided both databases were at production level.
    
    

Response to SAR’s
=================

SAR = Subject Access Requests.

*   *Do we understand the Data Models?*

    Actually, do we *have* the Data Models? Are they properly documented and kept up to date with changes?
    
*   *Where are we duplicating data structures and client data? ( i.e addresses, etc. )*

    This is a perennial problem I'm afraid and comes down to basic database design.

AOB
===

Test and development databases were regularly restored from backups of production and as such users could have had access to personal data, credit card numbers etc. These databases were depersonalised before handover to ensure that all columns identified as identifying or personal were obfuscated.

This was done using an in-house written script which did not take referential integrity into account (or didn't need to on the columns involved) but in the event of needing to consider referential integrity, Oracle has their Data Masking option (extra cost?) which - apparently - copes with this.