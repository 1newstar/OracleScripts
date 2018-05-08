==========================
GDPR - Password Processing
==========================

Introduction
============

Following on from our meeting on 8th February, to discuss the GDPR "stuff", I have adapted some code that I used in a past life for the purpose of setting and validating passwords.

However, we should consider the various settings for account profiles before we put such things into test/practice.

Obviously, comments, objections, better ideas etc are gratefully received. Thanks.

The security team were queried about current standards for Windows Logins and replied thus:

..  code-block:: none

    From: Callum Wright 
    Sent: 12 February 2018 13:31
    To: Phil Hubbard; Robert Tomkins
    Cc: HUK.DBA
    Subject: RE: GDPR - Password proposals

    I do indeed. The current guidance I give is:

    The minimum standard for passwords is as follows:

    *   Minimum length of 8 characters.
    *	The password must be different from the user ID.
    *	The password must contain characters from 3 of the following 4 categories:
        *	Upper Case
        *	Lower Case
        *	Numerals
        *	Special Characters (e.g. !”£$%^&*)
    *	Complexity enforcement must be automated.
    *	The previous 8 passwords must be prevented from re-use.
    *	Rotate every 90 days

    For privileged accounts the following enhanced requirements must be in place:

    *	The password length must be at least 14 characters
    *	The password must be different from the previous 10 passwords used for that account.
    *	Will need to discuss the password rotation – ideally we could implement multifactor auth and not have to worry too much about changing passwords.

Observations on the Above
-------------------------
    
The default settings for the password verification function, and the password generating script, are far stricter than these options in many areas. I propose, for database use at least, that we stick with the stricter options for added security.

The password generating script uses 15 character passwords for all users, privileged or not. This exceeds the Security Team's requirements.

The verification function, described below, enforces numerous restrictions, including ensuring  that the password and username do not match.

The password generation script will generate passwords with characters from *all 4* specified categories. However, the special characters are limited to $_# in an Oracle Database.

Complexity enforcement is automated by the verification function attached to the profile, attached to the user accounts. It acts as soon as a password is being changed.

The previous 8 passwords must be prevented from re-use. Oracle has to also have a number of days in which the password cannot be changed - to prevent people simply changing the password 8 times, and then using the original one again. Our profile will set a limit of 10 changes before a password can be used within 30 days. This will cover the Security Team's requirements for privileged account passwords as well as non-privileged ones.

Rotate every 90 days. This can be attached to the profile for the accounts.


Profiles
========

In a previous life, three profiles were in use:

*   DBA_PROFILE - for DBA users;
*   APP_PROFILE - A profile for the application owners;
*   USER_PROFILE - a profile for application users and non-dba user accounts.

The profiles had the reasonable password resource limits. Based on the Security Team's requirements above, the following is proposed. Please note that some limits are more 

+--------------------------+------------------+------------------+------------------+
| Resource                 | Limit DBA        | Limit APP        | Limit USER       |
+==========================+==================+==================+==================+
| FAILED_LOGIN_ATTEMPTS    | 5                | 5                | 5                |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_LIFE_TIME       | 90               | UNLIMITED        | 90               |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_GRACE_TIME      | 7                | 7                | 7                |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_REUSE_TIME      | 30               | UNLIMITED        | 30               |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_REUSE_MAX       | 10               | UNLIMITED        | 10               |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_LOCK_TIME       | 1/24 (one hour)  | 1/24 (one hour)  | 1/24 (one hour)  |
+--------------------------+------------------+------------------+------------------+
| PASSWORD_VERIFY_FUNCTION | PASSWORD_VERIFY  | PASSWORD_VERIFY  | PASSWORD_VERIFY  |
+--------------------------+------------------+------------------+------------------+

This meant that after 5 failed attempts to login, the account was locked for one hour (1/24 day) - but invariably, the DBAs were asked to unlock them ahead of time! 

Passwords would expire after 90 days - except for the application owners' passwords which never expired. There were some applications where the application logged in to the account with a hard coded password. 

Any user not logging in for over 30 days would find that they had an additional 7 days to change their password. ~Failure to do so would expire the password and the account would be unusable. This was used as a fall back in the event of the DBA team not being notified of a leaver, the account would eventually expire.~ It appears that this only happens when the user first attempts to login after the expiry date and grace period.

The reuse of passwords is restricted to ensure that the users do not use a previous password unless it has been changed at least 10 times in the previous 30 days.

The DEFAULT profile's settings were used for anything not explicitly mentioned above.

Profiles did not get set up to abort sessions after a certain time limit, or run time, blocks read etc - that was considered too restrictive and caused excessive work on the database as killed sessions had to be rolled back etc.

Profiles set up on 12c databases will need to consider the CONTAINER = CURRENT or ALL options where pluggable databases are used.

Password Generation
===================

A script, ``password_generator.sql`` has been written to generate random passwords of 15 characters in length. This is made up of, currently, 10 letters, 4 digits and one special character - although this is configurable. The letters will be in upper or lower case.

Some letters and digits are never used in generated passwords, this is due to some fonts making them too similar and thus, difficult to determine from other characters. The missing characters are:

*   Lower case L - too similar to the digit one;
*   Lower case Q - reasons unknown!
*   Upper case O - too similar to digit zero;
*   Digit zero - too similar to upper case O;
*   Digit one - too similar to lower case L.

An Oracle password allows one or more of the special characters '\#', '\_' or '\$' with no problems. Some other characters can be used, but the password must be wrapped in double quotes. In some cases, certain characters in a password will prevent the user from logging in - the '@' for example confuses SQL*Plus into thinking that everything after the '@' makes up a TNS Alias for the database when it is actually part of the password.

The rules built in to the script are:

*   10 letters of mixed case, plus
*   4 digits, plus
*   1 special character from the three above.
*   The first character will always be a letter.

This ensures that the password is 15 characters long - but as mentioned, the settings can be changed with up to 20 in each category. (A tad overkill at 60 characters, and will Oracle accept such a thing?)

Execution
---------

The script could be built in to a package and compiled on every database, however, at the moment, it is best simply executed as a plain SQL script from within SQLDeveloper, Toad or SQL\*Plus.

The script generates a command as follows, which can be used to change a password:

..  code-block:: sql

    alter user 
    identified by "TGDj$Uepx375cL8" account unlock;

You *should* paste in the appropriate username at the end of the first line, before executing it!
    
Password Verification
=====================

The password verification function should be owned by SYS and attached to a profile, existing or new, in the normal manner. It can be attached to the DEFAULT profile and will take effect immediately on all attempts to change a password.

**NOTE:**   On some very rare occasions, a password generated by the script above, will fail to create enough of one kind of character (upper, lower, digits etc) so that the verification function rejects it. This is rare, and when or if it does occur, simply generate a new password. This is a failing in the *synchronisation* between the password generator and the password verifier.


Verification Rules
------------------

The following rules are built in to the password verification code:

*   The database is expected to have the initialisation parameter ``SEC_CASE_SENSITIVE_LOGON`` set to true.

*   The username will not be part of the new password;
*   The reversed username will not be part of the new password;
*   The new password will not be "similar" to the username;
*   It will not be similar to the old password - but see below for problems;
*   The password will be longer than 7 characters;
*   It will not contain forbidden words;
*   It will not be similar to a forbidden word;
*   The database name is considered a forbidden word;
*   The server name is considered a forbidden word;
*   The current month name is considered a forbidden word;
*   There must be at least one:
    *   Lower case letter;
    *   Upper case letter;
    *   Digit;
    *   Special character;
*   A letter cannot be repeated more than 6 times, case insensitively;
*   There must be at least 4 different characters in the password;
*   If an old password is supplied, it must "differ" from the new one by at least 4. (See below.)

Most of the above is able to be changed.

Differences
~~~~~~~~~~~

The difference between two words is worked out using the UTL_MATCH package - available from 11g onwards - which has a number of ways of reflecting how different two words are.

The verification code uses the ``EDIT_DISTANCE_SIMILARITY`` function to get a range between 0 (completely different) and 100 (completely identical) and anything over 60 is considered "too similar".

Forbidden words
~~~~~~~~~~~~~~~

The list of forbidden words are as follows:

+------------+-------------+-------------------+-------------+-------------+
| WELCOME    | PASSWORD    | PASSW0RD          | P4SSW0RD    | P455W0RD    |
+------------+-------------+-------------------+-------------+-------------+
| ORACLE     | DATABASE    | LETMEIN           | FORGOTTEN   | HERMES      |
+------------+-------------+-------------------+-------------+-------------+
| H3RM3S     | MANAGER     | CHANGE_ON_INSTALL | ABCDEF      | ABC123      |
+------------+-------------+-------------------+-------------+-------------+
| QWERTY     | 123456      | The database name | host name   | Month name  |
+------------+-------------+-------------------+-------------+-------------+

Other related words can, of course, be added.

    
Known Problems
--------------

See http://qdosmsq.dunbar-it.co.uk/blog/2013/11/so-how-do-you-change-a-users-password/ for full details, but:

*   The verification code is never passed an old password unless the user calls the ``PASSWORD`` command, or, executes ``alter user me identified by new_password replace old_password``. This makes it difficult to prevent passwords simply getting extra digits tagged on the end to make them "different".


Exceptions
----------

The verification function will raise an exception - sadly, only one even if there are numerous problems with the new password - for the following reasons:

+-----------+---------------------------------------------------------------------------------------+
| Code      | Exception Message                                                                     |
+===========+=======================================================================================+
| ORA-20000 | Unexpected error.                                                                     |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20001 | Password contains the username.                                                       |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20002 | Password contains the username in reverse.                                            |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20003 | Password too similar to username.                                                     |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20004 | Password length less than n.                                                          |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20005 | Password too similar to old password.                                                 |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20006 | Password contains a forbidden word.                                                   |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20007 | Password is too similar to a forbidden word.                                          |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20008 | Password fails to differ from previous by at least n characters.                      |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20009 | Password contains less than n alphabetic characters.                                  |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20010 | Password contains less than n uppercase characters.                                   |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20011 | Password contains less than n lowercase characters.                                   |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20012 | Password contains less than n numeric characters.                                     |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20013 | Password contains less than n punctuation characters.                                 |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20014 | Password contains less than n of the following characters '_','#','$'.                |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20015 | Password contains less than n special characters. Ie not alphanumeric or '_','#','$'. |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20016 | Password contains less than n distinct characters.                                    |
+-----------+---------------------------------------------------------------------------------------+
| ORA-20017 | Password contains more than n occurrences of the same character.                      |
+-----------+---------------------------------------------------------------------------------------+

**NOTE:**   ORA-20015, is currently disabled. 

Leavers Processing
==================

When a 'colleague' left, all their accounts had to be disabled (almost) immediately. HR would inform the various teams responsible for accounts on:

*   The network;
*   The databases;
*   Email.

Each team has a process in place to disable accounts. For the DBAs this was set up to run a PL/SQL procedure (daily) to read a file containing the names of the leavers (and checking that none of the system or application owner accounts were *accidentally* listed) and disabling  their accounts by expiring and locking the account. After 180 days of being locked, the daily process would list a number of accounts for deletion - those expired and locked for 180 days or longer. OEM executed a report which listed these accounts as part of a daily checks process - so the DBAs could see which accounts were due for pruning.

Any necessary backups of the accounts' data was obviously taken (and checked) before the 180 days were up and the accounts deleted, manually, by the DBAs.

In the event that HR neglected to inform the DBAs of a leaver, the account would lock after PASSWORD_LIFE_TIME + PASSWORD_GRACE_TIME, but would not expire, so would not be considered for deletion after 180 days. To alleviate this problem, OEM also ran a report that would list those accounts that were expired (but not expired and locked) for longer than 31 days.