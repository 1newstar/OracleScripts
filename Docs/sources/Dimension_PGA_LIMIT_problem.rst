==================
Dimension problems
==================

Problem Description
-------------------

..  code-block:: none

    ORA-04036: PGA memory used by the instance exceeds PGA_AGGREGATE_LIMIT.

From time to time the database kills off sessions at random, as these sessions have allocated enough memory, from the PGA pool, so as to exceed the setting for the ``PGA_AGGREGATE_LIMIT``, which defines the maximum amount of memory that can be used, for the sum of the various PGA memory areas used by all sessions. This is a hard limit and can not be exceeded - except it appears that when a session is killed, Oracle may already have exceeded the limit more than once.

The support team for this application had indicated that the problem is with database configuration, and advised adding an additional 5 Gb of memory to the ``PGA_AGGREGATE_LIMIT`` parameter (currently defaulted) however, this would exceed the available RAM on the server.

This report will investigate the feasibility of adding additional RAM and increasing the appropriate parameter.


Database Settings
-----------------

The following database settings are in use, either defined explicitly or defaulted:


+----------------------+----------------+-----------+
| Parameter Name       | Value          | Default?  |
+======================+================+===========+
| pga_aggregate_limit  | 0              | Yes       |
+----------------------+----------------+-----------+
| pga_aggregate_target | 0              | Yes       |
+----------------------+----------------+-----------+
| workarea_size_policy | auto           | No        |
+----------------------+----------------+-----------+
| memory_max_target    | 8,589,934,592  | No        |
+----------------------+----------------+-----------+
| memory_target        | 5,368,709,120  | No        |
+----------------------+----------------+-----------+
| processes            | 1150           | No        |
+----------------------+----------------+-----------+

As ``PGA_AGGREGATE_LIMIT`` is defaulted, it takes its value from ``MEMORY_MAX_TARGET``, so equates to a maximum of 8,589,934,592 bytes (8 Gb.) The minimum value that it will take is the greater of 2 Gb and (3 Mb * ``PROCESES``) which equates to 3.37 Gb in this case.


Observations
============

The database was monitored for a period ranging from 12:00 noon until 15:00 on 21st June 2017. At no time during this period were there any problems of the PGA Limits being exceeded and sessions killed.

Between 12:00 and 13:01 the number of sessions, mainly those with module names ``Report Execution`` or ``dya141mr.exe`` crept up and did not reduce. After 13:01, these sessions remained in the database and no further sessions of these modules were noted in the following 2 hours, until 15:00 when monitoring stopped. 

    **Note**: Further sessions *were* observed at 10:30 on the following day where the totals rose to 312 and 32 respectively. Again, they did not reduce on becoming idle.

At the start of the monitored period, there were 250 sessions connected to the SERVER account, using program ``dya141mr.exe``, at the end of the period there were 297. Only the two modules mentioned above had increased in number, the remainder remained constant.

Alert.log
---------

Nothing relevant to the problem in hand was found in the alert log for the monitored period.

Live Sessions
-------------

The following query was used to determine the following:

-   How many ``dya141mr.exe`` sessions are connected to username SERVER;
-   How many are currently in use/active or were recently active;
-   How much PGA memory is used by each session;
-   What event the sessions might be waiting on;
-   How long they have been waiting if so;
-   When the sessions logged in originally;

The output of this query has been saved in a spreadsheet - to reduce the amount of information in this document. The spreadsheet is named *Dimension_PGA_Problems.xls*.

..  code-block:: sql

    -- Script to extract the "rogue" Dimension logins.
    -- These seem to be a problem area when:
    --
    --  * The USERNAME is SERVER;
    --  * The program is 'DYA141MR.EXE';
    --  * The module is 'Report Execution'.
    --
    -- The latter seems to be the problem. The other modules 
    -- appear to login and "do stuff" pretty much constantly,
    -- apart from the one "Authentication Service", but the 
    -- report execution modules login, do stuff, then go 
    -- idle and stay there for days.
    --
    -- It looks like a problem in either:
    --
    --  * Getting the users to log out after running a report; or
    --  * The application is not disconnecting after running one.
    --
    -- Having said that, the module 'dya141mr.exe' might not be
    -- helping as a few of those have been idle for some time too.
    --
    select  s.sid, s.serial#, p.spid, 
            round(p.pga_used_mem/1024/1024, 3) PGA_USED_MB, 
            s.status, s.event, s.module, s.logon_time, 
            s.state, s.seconds_in_wait, 
            sysdate - (s.seconds_in_wait/(24*60*60)) as waiting_since 
    from    v$session s ,v$process p 
    where   s.paddr=p.addr 
    and     s.username = 'SERVER' 
    and     upper(s.program) = 'DYA141MR.EXE' 
    order   by s.module, seconds_in_wait asc;

The number of monitored sessions crept up constantly, and did not reduce. The number of sessions connected to the username SERVER using the application named ``dya141mr.exe`` - rose from 250 to 297 over the monitored period.

The following was observed:

-   The ``Authentication Service`` module has a single session, and appears to have been idle for as long as it has been connected - over a month.
-   The ``Batch Service`` modules, of which there are 1 or 2 sessions, appear to be constantly active. 
-   The ``Calculation Service`` modules, of which there are 4, also appear to be constantly active.
-   The ``Unified Logging`` modules, of which there are 6, again appear to be constantly active.

The problematic sessions appear to be the following:

-   The ``Report Execution`` modules, of which there are a constantly increasing number appear to login, do some work for a brief period of a couple of minutes maximum, then "go idle" and remain connected, with a few MB of PGA memory allocated to each. The PGA usage ranges from 1 to 6.8 Mb per session.

These modules remain connected, but idle, to the database until the database has to be restarted.

-   The ``dya141mr.exe`` modules, of which there are is a slowly increasing number also appear to login, do some work for a brief period, then "go idle" and remain connected, with a few MB of PGA memory allocated to each. 

These modules also remain connected, idle and consuming PGA memory from the pool, until the database starts killing sessions and has to be restarted.

PGA Usage
---------

Given the above problem areas, and the fact that there are sessions aborted whenever the allocated PGA totals exceed a defined limit, the following query was used to determine the following:

-   How many ``dya141mr.exe`` sessions are connected to username SERVER aggregated by the module name in use;
-   How much PGA memory is used for each module "type";

..  code-block:: sql

    -- Script to determine the total number, and PGA Usage
    -- of all the sessions logged into SERVER using program DYA141MR.EXE.
    --
    select  s.module, count(*), 
            round(sum(p.pga_used_mem)/1024/1024, 3) PGA_MB_USED
    from    v$session s ,v$process p 
    where   s.paddr=p.addr 
    and     s.username = 'SERVER' 
    and     upper(s.program) = 'DYA141MR.EXE'
    group   by rollup(s.module) 
    order   by s.module;

The results of the above query are:

+------------------------+-------+---------+
| Module                 | Count | PGA MB  |
+========================+=======+=========+
| Authentication service | 1     | 1.473   |
+------------------------+-------+---------+
| Batch service          | 2     | 6.042   |
+------------------------+-------+---------+
| Calculation service    | 4     | 13.016  |
+------------------------+-------+---------+
| Report Execution       | 260   | 625.28  |
+------------------------+-------+---------+
| Unified Logging        | 6     | 9.26    |
+------------------------+-------+---------+
| dya141mr.exe           | 24    | 62.262  |
+------------------------+-------+---------+
| TOTAL                  | 297   | 717.333 |
+------------------------+-------+---------+

It can be seen from the above, that the two problem modules, ``Report Execution`` and ``dya141mr.exe`` are responsible for the vast majority of the total PGA usage across the database. 

    **Note**: These problematic modules are also logged in as other users, not just SERVER. They also suffer from the same problem of appearing not to terminate. There are, however, only 4 of those at the time monitored, and this figure did not appear to be changing.

Conclusion
----------

There is a problem whereby the application starts sessions to execute reports, for example, and then does not terminate those sessions. As the number of sessions increases, PGA memory allocated to the sessions increases and eventually, the 8 Gb limit is exceeded and the database starts killing sessions.

Adding additional Ram, at some expense, to the server and increasing the ``PGA_AGGREGATE_LIMIT`` parameter from the default (which equates to 8gb) by an additional 5 Gb would simply delay the next occurrence of the database killing off sessions that cause the limit to be exceeded.

The evidence here should be supplied to SimCorp for further investigation. It is possible that we are running without certain advisory patches on the server and/or the database software - perhaps SimCorp have documentation to the effect of the required settings and/or patches?


| Norman Dunbar.
| Contract Oracle DBA.
| 22 June 2017.