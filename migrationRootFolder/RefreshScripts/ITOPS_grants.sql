  -- 2 Roles for ITOPS 
  GRANT COMMS_ROLE TO ITOPS;
  GRANT NORMAL_USER TO ITOPS;
  ALTER USER ITOPS DEFAULT ROLE ALL;
  -- 1 System Privilege for ITOPS 
  GRANT CREATE SESSION TO ITOPS;
  -- 12 Object Privileges for ITOPS 
    GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON ONLOAD.LARGE_OBJECTS TO ITOPS;
    GRANT SELECT ON ONLOAD.ODEY_MAPPING TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_IFA TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_INVESTOR TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_INVESTORBANK TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_NOMINEE TO ITOPS;
    GRANT DELETE, INSERT, SELECT ON ONLOAD.ODEY_STG_NOMINEE_MAPPING TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_ORDTRAN TO ITOPS;
    GRANT SELECT, UPDATE ON ONLOAD.ODEY_STG_REGISTER TO ITOPS;
    GRANT DELETE, INSERT, SELECT ON ONLOAD.PSO_BACKUP TO ITOPS;
    GRANT SELECT ON ONLOAD.VALHEAD_IOE TO ITOPS;
    GRANT SELECT ON ONLOAD.VALHOLD_IOE TO ITOPS;