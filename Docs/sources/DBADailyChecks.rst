================
DBA Daily Checks
================

Introduction
------------

The following is a *non-exclusive* list of the daily checks that must be carried out in Azure environments. This is required until such time as we get full access to OEM (Oracle Enterprise Manager) and can set up proper monitoring.

Database Backups
----------------

Using the Log Files
~~~~~~~~~~~~~~~~~~~

These are your top priority. The database backups logs must be checked on the servers as soon as possible each day, especially Mondays as there is a weekend's worth of backups to check.

The primary CFG database is backed up at 03:00 daily, with a level 0 (aka full) backup on Sundays. Other days perform a level 1 incremental backup.

Logs are found at ``\\Backman01\Rmanbackup\backups\lohs\<database_name>`` and should be checked to ensure that:

- The database backup completed successfully;
- The archived logs backup completed successfully;
- The controlfile auto-backup completed successfully.


Using SQL*Plus
~~~~~~~~~~~~~~

On the database being backed up, which is normally the primary, but need not be - RMAN can backup the standby if necessary - run the following query to determine the state of the backups over the last few days - this covers the weekends:

..  code-block:: sql

    set lines 3000 trimspool on pages 2000
    
    select parent_recid, start_time, end_time, object_type, status, operation 
    from v$rman_status
    where row_type in ('COMMAND', 'RECURSIVE OPERATION')
    and (
            -- BACKUP of archived log and database...
            (object_type is not null and operation = 'BACKUP') 
            or 
            -- AUTOBACKUP of controlfile and spfile
            ( object_type is null and operation like 'CONTROL FILE%')
        )
    -- Everything from Monday, Sunday, Saturday and Friday, maximum.
    and start_time >= trunc(sysdate) -3
    order by start_time desc;
    
The resulting output can be seen as follows:

..  code-block::

    PARENT_ START_TIME          END_TIME            OBJECT_TYPE STATUS      OPERATION
    ------- ------------------- ------------------- ----------- ---------   ----------------
        104	2017/03/13 08:55:11		                DB INCR	    FAILED	    BACKUP
        102	2017/03/13 03:03:39	2017/03/13 03:03:46		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        99	2017/03/13 03:02:08	2017/03/13 03:03:48	ARCHIVELOG	COMPLETED	BACKUP
        100	2017/03/13 03:01:10	2017/03/13 03:01:16		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        99	2017/03/13 03:00:19	2017/03/13 03:01:19	DB INCR	    COMPLETED	BACKUP
        97	2017/03/11 03:03:30	2017/03/11 03:03:36		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        94	2017/03/11 03:01:32	2017/03/11 03:03:39	ARCHIVELOG	COMPLETED	BACKUP
        95	2017/03/11 03:00:41	2017/03/11 03:00:48		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        94	2017/03/11 03:00:07	2017/03/11 03:00:51	DB INCR	    COMPLETED	BACKUP
        92	2017/03/10 17:05:42	2017/03/10 17:05:49		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        89	2017/03/10 17:03:11	2017/03/10 17:05:51	ARCHIVELOG	COMPLETED	BACKUP
        90	2017/03/10 17:02:22	2017/03/10 17:02:28		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        89	2017/03/10 17:01:09	2017/03/10 17:02:31	DB INCR	    COMPLETED	BACKUP
        87	2017/03/10 03:04:15	2017/03/10 03:04:21		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        84	2017/03/10 03:01:50	2017/03/10 03:04:24	ARCHIVELOG	COMPLETED	BACKUP
        85	2017/03/10 03:01:07	2017/03/10 03:01:13		        COMPLETED	CONTROL FILE AND SPFILE AUTOBACK
        84	2017/03/10 03:00:11	2017/03/10 03:01:16	DB INCR	    COMPLETED	BACKUP

In the event of a problem, for example, the first line of output above, use the ``PARENT_RECID`` to query ``VRMAN_OUTPUT``, as follows:

..  code-block:: sql
    
    select output
    from v$rman_output
    -- Use the parent_id for the failed session...
    where session_recid=104
    and output <> ' '
    order by recid asc;

The output will show what would have been found in the RMAN log for that particular backup. If no errors are listed, then you can be certain that a DBA abandoned the backup - as any other errors from RMAN will be shown.
    
Data Guard Time Lag
-------------------

Using SQL*Plus
~~~~~~~~~~~~~~

Run the following on the *primary database*\ :

..  code-block:: sql

    select dest_id, Dest_name, destination, archived_seq#, applied_seq#,
    error, db_unique_name, gap_status
    from   v$archive_dest_status
    where  status <> 'INACTIVE'
    and    dest_id in (2,3);

The results will resemble the following:

..  code-block::

    DEST_ID DEST_NAME          DESTINATION ARCHIVED_SEQ# APPLIED_SEQ# ERROR DB_UNIQUE_NAME GAP_STATUS
    ------- ------------------ ----------- ------------- ------------ ----- -------------- ----------
          2 LOG_ARCHIVE_DEST_2 cfgsb               15975         15974      cfgsb          NO GAP
          3 LOG_ARCHIVE_DEST_2 CFGDR               15975         15974      CFGDR          NO GAP

"NO GAP" is what you are hoping to see in the ``GAP_STATUS`` column. Other values that may appears here are:

+---------------------------+-------------------------------------------------------------------------------------------------------------+
| Status                    | Description                                                                                                 |
+===========================+=============================================================================================================+
| NO GAP                    | The desired result. There is not an apply gap.                                                              |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| LOG SWITCH GAP            | The destination has not yet received all of the redo information from the most recently archived log file.  |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| RESOLVAVBLE GAP           | The destination has a redo gap but it can be resolved by fetching, automatically, the missing archived log  |
|                           | files from  *this* database. No action is required, unless ``FAL_SERVER`` for this database does not point  |
|                           | at the *this* database.                                                                                     |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| UNRESOLVAVBLE GAP         | The destination has a redo gap which can not be resolved by fetching, automatically, the missing archived   |
|                           | log files from *this* database, and there are no other destinations (standbys) where the missing            |
|                           | information can be obtained. Action is required in this case as the standby database is not up to date, and |
|                           | cannot be brought up to date. (Someone deleted an archive log or two perhaps?)                              |
+---------------------------+-------------------------------------------------------------------------------------------------------------+
| LOCALLY UNRESOLVAVBLE GAP | The destination has a redo gap which can not be resolved by fetching, automatically, the missing archived   |
|                           | log files from *this* database, however, other destinations (standbys) *may* be able to assist in resolving |
|                           | the missing data. Action is required in this case, but only to monitor that the standby doesn't get further |
|                           | and further out of date.                                                                                    |
+---------------------------+-------------------------------------------------------------------------------------------------------------+

In the above, where you see "*this* database", *this* refers to the database that the query was executed on - in our case, the *primary* database.



Using DGMGRL
~~~~~~~~~~~~

Run the following in ``dgmgrl`` on any of the servers, primary, standby or DR. You need to be logged in as the SYS user. The first command, ``show configuration``\ , simply displays the names of the various databases configured:

..  code-block::

    show configuration

    Configuration - dgmgrl_configuration

      Protection Mode: MaxPerformance
      Databases:
        cfg   - Primary database
        cfgsb - Physical standby database
        cfgdr - Physical standby database

    Fast-Start Failover: DISABLED

    Configuration Status:
    SUCCESS
    
The database names shown above are in lower case. This means that we can use them as-is. If they were in upper case, we would need to wrap them in double quotes, and in upper case too. ``Show database "CFGSB"`` for example.

The next commands display the two, in this case, standby databases:

..  code-block::

    DGMGRL> show database cfgsb

    Database - cfgsb

      Role:            PHYSICAL STANDBY
      Intended State:  APPLY-ON
      Transport Lag:   0 seconds (computed 0 seconds ago)
      Apply Lag:       0 seconds (computed 0 seconds ago)
      Apply Rate:      230.00 KByte/s
      Real Time Query: OFF
      Instance(s):
        cfgsb

    Database Status:
    SUCCESS

and:

..  code-block::

    DGMGRL> show database cfgdr

    Database - cfgdr

      Role:            PHYSICAL STANDBY
      Intended State:  APPLY-ON
      Transport Lag:   0 seconds (computed 0 seconds ago)
      Apply Lag:       1 second (computed 0 seconds ago)
      Apply Rate:      211.00 KByte/s
      Real Time Query: OFF
      Instance(s):
        cfgdr

    Database Status:
    SUCCESS

In either case we are looking to see that there isn't a (large) transport or apply lag and that the "computed" time is not excessive.

Various checks that can be applied when the status is not as desired are:

- Has the standby database just been started up after a while? If so, there will be potentially a large amount of un-applied redo to be obtained from the primary. Monitor the status and ensure that the lags do not simply keep increasing.
- Has the standby lost its managed apply? Check the alert log for details, stop and restart managed apply as per the document on building standby databases using RMAN.
- Has the network failed between the primary and standby? Try using ``tnsping standby`` to determine if this is the case. Once the network problems are alleviated, the standby should automatically start catching up.
- Has the primary database been run in NOACHIVELOG for a while? If so, the standby databases must be recreated.


Tablespace Usage
----------------

Any tablespace which has used 80% or more of its allocated *maximum size* - for ``AUTOEXTEND`` tablespaces and data files - should be considered for investigation and extension. This will need to be done under a service or change request when it involves CFG production (and pre-production?).

Using Toad
~~~~~~~~~~

- Connect to database as your DBA_XXX username; (As SYSDBA).
- Database -> Administer -> Tablespaces.
- Click the refresh button, if the screen has been viewed previously in this session.
- Click the header for ``USED PCT OF MAX`` *twice* to sort by descending usage.

Now, investigate and resolve any tablespaces that show 80% or more in the ``USED PCT OF MAX`` column. 


Using SQL*Plus
~~~~~~~~~~~~~~

The following query, massive as it is, will determine the correct usage figures for all tablespaces, including temporary ones.

..  code-block:: sql

    -- Work out tablespace sizes, usages and free space.
    -- Works on 9i and above.
    -- 
    -- Tablespaces at the top of the list need attention most.
    -- Anything over 80% is a warning, 90% is getting critical.
    --
    -- Norman Dunbar.
    with
    space_size as (
        select  tablespace_name,
                count(*) as files, 
                sum(bytes) as bytes,
                sum(
                    case autoextensible
                    when 'YES' then maxbytes
                    else bytes 
                    end
                ) as maxbytes
        from    dba_data_files
        group   by tablespace_name
    ),
    --
    free_space as (
        select  tablespace_name, sum(bytes) as bytes
        from    dba_free_space
        group   by tablespace_name
    )
    --
    select  s.tablespace_name, 
            s.files as data_files,
            round(s.bytes/1024/1024, 2) as size_mb,
            round(nvl(f.bytes, 0) /1024/1024, 2) as free_mb,
            round((nvl(f.bytes, 0) * 100 / s.bytes), 2) as free_pct,
            round((s.bytes - nvl(f.bytes, 0))/1024/1024, 2) as used_mb,
            round((100 - (nvl(f.bytes, 0) * 100 / s.bytes)), 2) as used_pct,        
            round(s.maxbytes/1024/1024, 2) as max_mb,
            round((nvl(s.bytes, 0) * 100 / s.maxbytes), 2) as size_pct_max,
            round((nvl(f.bytes, 0) * 100 / s.maxbytes), 2) as free_pct_max,
            round((s.bytes - nvl(f.bytes, 0)) * 100 / s.maxbytes, 2) as used_pct_max        
    from    space_size s
    left join free_space f
    on      (f.tablespace_name = s.tablespace_name)
    --
    union all
    --
    -- Get actual TEMP usage as opposed to DBA_FREE_SPACE figures.
    select  h.tablespace_name,
            count(*) data_files,
            --
            round(sum(h.bytes_free + h.bytes_used) / 1048576, 2) as size_mb,
            --
            round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 
            1048576, 2) as free_mb,
            --
            round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) / 
            sum(h.bytes_used + h.bytes_free)) * 100, 2) as  Free_pct,
            --
            round(sum(nvl(p.bytes_used, 0))/ 1048576, 2) as used_mb,
            100 - round((sum((h.bytes_free + h.bytes_used) - 
            nvl(p.bytes_used, 0)) / 
            sum(h.bytes_used + h.bytes_free)) * 100, 2) as  used_pct,
            --
            round(sum(decode(f.autoextensible, 
                             'YES', f.maxbytes, 
                             'NO', f.bytes) / 
            1048576), 2) as max_mb,
            --
            round(sum(h.bytes_free + h.bytes_used) * 100 / 
            sum(decode(f.autoextensible, 
                       'YES', f.maxbytes, 
                       'NO', f.bytes)), 2) as  size_pct_max,
            --
            round(sum((h.bytes_free + h.bytes_used) - 
            nvl(p.bytes_used, 0)) * 100 / 
            sum(decode(f.autoextensible, 
                       'YES', f.maxbytes, 
                       'NO', f.bytes)), 2) as  free_pct_max,
            --
            round(sum(nvl(p.bytes_used, 0)) * 100 / 
            sum(decode(f.autoextensible, 
                       'YES', f.maxbytes, 
                       'NO', f.bytes)), 2) as  used_pct_max
            --
    from    sys.v_$TEMP_SPACE_HEADER h,
            sys.v_$Temp_extent_pool p,
            dba_temp_files f 
    where   p.file_id(+) = h.file_id
    and     p.tablespace_name(+) = h.tablespace_name
    and     f.file_id = h.file_id
    and     f.tablespace_name = h.tablespace_name
    group   by h.tablespace_name
    --
    order   by used_pct_max desc;
               
The output is sorted in descending order of the tablespaces with the most used space, as a percentage of their maximum. (The final column in the listing.) The topmost tablespaces should be investigated if the figures are 80% or higher.

You should note, that where there is a data file in in ``AUTOEXEND`` mode, that the maximum size of *unlimited* actually correlates to 30Gb.

Password Expiry
---------------

Where password changes are forced, using profiles for example, it is advisable to know which users accounts will expire within the next fortnight. The following query will list those affected users. 

Note, only users who have a profile that limits password life times will be selected.

..  code-block:: sql

    -- List all users with a profile which limits password life times
    -- and who are going to have to change their password in the next 
    -- fortnight.
    --
    -- Norman Dunbar.
    --
    with password_life_time as (
        select profile, limit
        from dba_profiles
        where resource_name = 'PASSWORD_LIFE_TIME'
        and limit <> 'UNLIMITED' 
        and limit <> 'DEFAULT'   
    ),
    --
    user_stuff as (
        select username, expiry_date, profile as profile_name, trunc(expiry_date) - trunc(sysdate) as days_remaining
        from dba_users
        where account_status = 'OPEN'
    )
    --
    select username, expiry_date, days_remaining, profile, limit
    from password_life_time, user_stuff
    where profile = profile_name
    and days_remaining <= 14
    order by days_remaining, username;

Restore Points
--------------

Restore points are useful when performing upgrades and releases etc, but leaving them lying around causes the FRA to fill up as flashback logs and archived redo logs remain, online, ready to be used to flashback the database. The following script will identify any restore points that have been in place for 7 or more days.

..  code-block::

    select  name, storage_size/1024/1024/1024 as size_gb,
            time as creation_timestamp, 
            restore_point_time as restore_to_time
    from    v$restore_point
    where   trunc(systimestamp) - trunc(time) >= 7
    order   by time;
 
When a restore point is identified, it should be deleted *after* checking with the team/person/manager/business user who requested it be created. 