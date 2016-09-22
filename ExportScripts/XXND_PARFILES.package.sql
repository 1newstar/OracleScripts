create or replace package xxnd_parfiles as 
    
    -- Common Parameters
    yesCompress    constant varchar2(30) := 'compress=y';
    yesConstraints constant varchar2(30) := 'constraints=y';
    noConstraints  constant varchar2(30) := 'constraints=n';
    yesDirect      constant varchar2(30) := 'direct=y';
    yesGrants      constant varchar2(30) := 'grants=y';
    noGrants       constant varchar2(30) := 'grants=n';
    yesIndexes     constant varchar2(30) := 'indexes=y';
    noIndexes      constant varchar2(30) := 'indexes=n';
    yesRows        constant varchar2(30) := 'rows=y';
    noRows         constant varchar2(30) := 'rows=n';
    noStatistics   constant varchar2(30) := 'statistics=none';
    yesConsistent  constant varchar2(30) := 'consistent=y';

    -- Various buffer sizes
    buffer_1e6     constant varchar2(30) := 'buffer=1000000';
    buffer_1e9     constant varchar2(30) := 'buffer=1000000000';
    
    -- Table list stuff
    openTables     constant varchar2(30) := 'tables=(';
    closeTables    constant varchar2(1)  := ')';
    
    -- Default list of owners. These are always exported.
    alwaysOwners   constant varchar2(200) := 'CMTEMP,FCS,ITOPS,LEEDS_CONFIG,OEIC_RECALC,ONLOAD,UVSCHEDULER';
    
    -- Full list - we need to include the ONLOAD_% owners, as well as the above.
    allOwners      varchar2(2000);
    
    -- Tables lists for the various exports. This should be anchored as:
    -- type tTableList is table of dba_tables.table_name%type
    -- buit we have one table in fcs8Tables that has a Mixed Case name
    -- so requires three sets of double quotes at each end, which makes
    -- it longer than a table_name column. Sigh.
    -- 
    
    type tTableList is table of varchar2(40)    
        index by dba_tables.table_name%type;
        
    fcs1Tables     tTableList;
    fcs2Tables     tTableList;
    fcs3Tables     tTableList;
    fcs4Tables     tTableList;
    fcs5Tables     tTableList;
    fcs6Tables     tTableList;
    fcs7Tables     tTableList;
    fcs8Tables     tTableList;
    fcs9Tables     tTableList;
    unLovedTables  tTableList;
    
    -- And a couple of working indexers for same.
    tableIndexer dba_tables.table_name%type;
    currentTable dba_tables.table_name%type;

    -- Various publically visible procedures, functions etc.
    procedure buildNOROWS(iFolder in varchar2);
    procedure buildNOFCS(iFolder in varchar2);
    procedure buildFCS1(iFolder in varchar2);
    procedure buildFCS2D(iFolder in varchar2);
    procedure buildFCS3(iFolder in varchar2);
    procedure buildFCS4(iFolder in varchar2);
    procedure buildFCS5(iFolder in varchar2);
    procedure buildFCS6(iFolder in varchar2);
    procedure buildFCS7(iFolder in varchar2);
    procedure buildFCS8(iFolder in varchar2);
    procedure buildFCS9(iFolder in varchar2);

end;
/    
 

