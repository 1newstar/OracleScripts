select 'create public database link ' || name || ' connect to ' || userid ||
    ' identified by values ''' || password || ''' using ''' || host || ''';'
from  sys.link$
where owner# = (select user# from sys.user$ where name = 'PUBLIC');