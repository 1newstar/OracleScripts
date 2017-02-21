set lines 2000
set trimspool on
set pages 2000
set head off
set echo off
set feed off

select 'create public database link ' || name || ' connect to ' || userid ||
       ' identified by "' || password || '" using ''' || host || ''';'
from   sys.link$
where  owner# = (select user# from sys.user$ where name = 'PUBLIC')


spool t095_recreatePublic_DB_links.sql
/
