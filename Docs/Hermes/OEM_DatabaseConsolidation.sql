SELECT  A.DATABASE_NAME,
        TO_CHAR(A.STARTUP_TIME,'DD-MON-YYYY') "STARTUP_DATE" ,
        TO_CHAR(A.creation_date,'DD-MON-YYYY') "CREATION_DATE",
        A.LOG_MODE,A.CHARACTERSET,A.DBVERSION,
        AVAILABILITY_STATUS,E.SGASIZE,
        G.HOME_LOCATION "ORACLE_HOME",
        F.property_value "PORT",
        A.HOST_NAME,
        C.cpu_count,
        C.CPU_CORE_COUNT,
        SUBSTR(D.OS_SUMMARY,1,40) "OS PLATFORM" 
 FROM   SYSMAN.MGMT$DB_DBNINSTANCEINFO A, 
        SYSMAN.MGMT$AVAILABILITY_CURRENT B,
        SYSMAN.MGMT$DB_CPU_USAGE C ,  
        sysman.mgmt$os_hw_summary D,
        sysman.mgmt$db_sga_all E ,
        SYSMAN.MGMT$TARGET_PROPERTIES F  , 
        SYSMAN.MGMT$ORACLE_SW_ENT_TARGETS G 
 WHERE  B.TARGET_TYPE='oracle_database' and
        A.TARGET_NAME=B.TARGET_NAME AND
        A.TARGET_NAME=C.TARGET_NAME AND 
        A.HOST_NAME=D.HOST_NAME and 
        a.target_name=E.target_name  AND 
        E.SGANAME='Total SGA (MB)'  AND
        A.TARGET_NAME=F.TARGET_NAME AND
        a.target_name=G.TARGET_NAME and  
        F.PROPERTY_NAME='Port' 
ORDER BY database_name