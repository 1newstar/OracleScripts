  -- 2 Roles for LEEDS_CONFIG 
  GRANT LEEDS_CONFIG_ROLE TO LEEDS_CONFIG;
  GRANT SELECT_CATALOG_ROLE TO LEEDS_CONFIG;
  ALTER USER LEEDS_CONFIG DEFAULT ROLE ALL;
  -- 1 System Privilege for LEEDS_CONFIG 
  GRANT CREATE SESSION TO LEEDS_CONFIG;
  -- 1 Tablespace Quota for LEEDS_CONFIG 
  ALTER USER LEEDS_CONFIG QUOTA 25M ON CFA;
  -- 4 Object Privileges for LEEDS_CONFIG 
    GRANT SELECT ON FCS.EVENTLOG TO LEEDS_CONFIG;
    GRANT SELECT ON FCS.GP_GLOBALPARAM TO LEEDS_CONFIG;
    GRANT SELECT ON FCS.GP_VALUES TO LEEDS_CONFIG;
    GRANT SELECT ON FCS.MESSAGE_LOG TO LEEDS_CONFIG;