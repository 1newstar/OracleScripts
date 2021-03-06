SET HEADING OFF
SET FEEDBACK OFF
SET LINES 2000
SET PAGES 2000

SELECT 'SET TIMING ON' FROM DUAL;
SELECT 'SET ECHO ON' FROM DUAL;
SELECT    'exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>'''
       || OWNER
       || ''',TABNAME=>'''
       || TABLE_NAME
       || ''',Method_Opt=>''FOR ALL INDEXED COLUMNS SIZE AUTO'',Degree=>4,Cascade=>TRUE,No_Invalidate=>FALSE);'
  FROM DBA_TABLES
 WHERE OWNER IN ('FCS', 'OEIC_RECALC', 'LEEDS_CONFIG');
