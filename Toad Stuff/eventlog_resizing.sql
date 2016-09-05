--================================
-- This script must be run as FCS.
--================================

set lines 2000
set trimspool on
set pages 2000
set serveroutput on size 1000000;
set timing on
set time on


spool aura_resize.lst

-- Don't attempt to move stuff already deleted.
-- purge dba_recyclebin;



-- Some code to move everything out of AURA tablespace
-- into either the ARCHIVE1 or the UVDATA01 tablespaces.
--
-- Any tables named QUEST% or TOAD%, as well as indexes
-- will go to ARCHIVE1. Others go to UVDATA01.
--
-- LOBINDEX and LOBSEGMENTs will also move.
--
-- We must change LONG to CLOB and LONG RAW to BLOB
-- before we move the table, or we get the usual error
-- about LONG columns being illegal.
--
--
declare
    type nameList is table of dba_segments.segment_name%type
        index by dba_segments.segment_name%type;
    
    -- Indexes that will line in CFA tablespace.
    cfaIndexes nameList;

    -- Indexes that will line in CFA_INDEX tablespace.
    cfaIndexIndexes nameList;

    -- Indexes that will line in UVDATA01 tablespace.
    uvdata01Indexes nameList;

    -- Indexes that will line in ARCHIVE1_INDEX tablespace.
    archive1IndexIndexes nameList;
    
    -- Indexes that will live in the AURA_INDEX tablespace.
    auraIndexIndexes nameList;
    -- Tablespace name to use for rebuilding indexes into.    
    indexTablespaceName dba_tablespaces.tablespace_name%type;

    -- Tablespace name to use for moving tables into.    
    tableTablespaceName dba_tablespaces.tablespace_name%type;

    -- List of tables and indexes to gather stats on.
    gatherTableStats nameList;
    gatherIndexStats nameList;
        
    -- We occasionally need a table, column or index name. Or a date.
    vTableName dba_tables.table_name%type;
    vColumnName dba_tab_columns.column_name%type;
    vIndexName dba_indexes.index_name%type;
    vDate date;
    
    -- And sometimes, a SQL statement to execuute.
    vSql varchar2(2000);
    
    -- Indicator, does this table have a LONG [RAW] column?
    vTableHasLONG boolean;
    
    
    --=================================================================
    -- Some helper procedures etc to save on typing the same code over
    -- and over ...
    --=================================================================
    
    -- I can't be doing with typing dbms_output.put_line all
    -- the time! ;-)
    procedure pl (iMessage in varchar2) as 
    begin
        dbms_output.put_line(iMessage);
    end;
    
    
    -- I can't be doing with typing execute immediate all
    -- the time either! ;-)
    procedure doit (iSql in varchar2) as 
    begin
        pl(iSql || ';');
        --execute immediate iSql;
    exception
        when others then
            pl('FAILED: ' || iSql);
            raise;        
    end;


    -- Is this table one of the QUEST/TOAD ones?
    function questTable (iTableName in dba_tables.table_name%type)
        return boolean
    as
    begin            
        if (iTableName like 'TOAD%' or
            iTableName like 'QUEST%' ) then
                return true;
        end if;

        return false;
    end;
    

    -- Is this index one of the QUEST/TOAD ones?
    function questIndex (iOwner in dba_indexes.owner%type,
                         iIndexName in dba_indexes.index_name%type)
        return boolean
    as
        vTableName dba_tables.table_name%type;
        
    begin   
        -- Check the actual name first.         
        if (iIndexName like 'TOAD%' or
            iIndexName like 'QUEST%' ) then
                return true;
        end if;
        
        -- It may be an index on a QUEST/TOAD table.
        select table_name
        into vTableName
        from dba_indexes
        where index_name = iIndexName
        and   owner = iOwner;

        return questTable(vTableName);
        
    exception
        when no_data_found then
            -- Warn the user, but carry on anyway.
            pl('Index ' || iOwner || '.' || iIndexName || ' Has no known table!');
            return false; 
    end;
    

    -- Convert LONG to CLOB or LONG RAW to BLOB. 
    function convertToLob(iOwner in dba_tables.owner%type,
                          iTableName in dba_tables.table_name%type,
                          iType in dba_tab_columns.data_type%type)
             return boolean
    as
        vColumnName dba_tab_columns.column_name%type;
        vSql varchar2(2000);
        vType dba_tab_columns.data_type%type;
        
        -- Does this table have a LONG [RAW] column? 
        -- There can be only one!
    begin
        vType := upper(iType);
        
        select column_name
        into   vColumnName
        from   dba_tab_columns
        where  owner = iOwner
        and    table_name = iTableName
        and    data_type = vType;
            
        -- Convert to CLOB/BLOB.
        vSql := 'alter table ' || iOwner || '.' || iTablename ||
                     ' modify (' || vColumnName || ' ' ;
                             
        if (vType = 'LONG') then
            vSql := vSql || 'CLOB)';
        else
            vSql := vSql || 'BLOB)';
        end if;         
                  
        doit(vSql);
        return true;
        
    exception
        when no_data_found then
            return false;
    end;        
    

    -- Move CLOB or BLOB columns. 
    procedure moveLobs(iOwner in dba_tables.owner%type,
                       iTableName in dba_tables.table_name%type,
                       iTablespace dba_tablespaces.tablespace_name%type default 'UVDATA01',
                       iQuestTablespace dba_tablespaces.tablespace_name%type default 'ARCHIVE1')
    as
        vColumnName dba_tab_columns.column_name%type;
        vSql varchar2(2000);
        type tColumnNames is table of dba_tab_columns.column_name%type
            index by binary_integer;
        vColumnNames tColumnNames;
        
    begin
        select column_name
        bulk collect into vColumnNames
        from   dba_tab_columns
        where  owner = iOwner
        and    table_name = iTableName
        and    data_type in ('CLOB','BLOB');

        for x in 1 .. vColumnNames.count loop
            -- Move the LOB columns.
            vSql := 'alter table ' || iOwner || '.' || iTablename ||
                         ' move lob (' || vColumnNames(x) || ') store as ( tablespace ' ;
                         
            if (questTable(iTableName)) then
                vSql := vSql || iQuestTablespace || ')';
            else
                vSql := vSql || iTablespace || ')';
            end if;
                          
            doit(vSql);
        end loop;            
        
    exception
        when no_data_found then
            -- Nothing to do here.
            null;
    end;        
    
    
    -- Do the table move. Copes happily with QUEST or TOAD tables.
    -- Moves any LOB columns as these need to be moved separately.
    procedure moveTable(iOwner dba_tables.owner%type,
                        iTableName dba_tables.table_name%type,
                        iTablespace dba_tablespaces.tablespace_name%type default 'UVDATA01',
                        iQuestTablespace dba_tablespaces.tablespace_name%type default 'ARCHIVE1'
                        )
    as
        vSql varchar2(2000);
        
    begin                        
        -- Set up the move SQL.
        vSql := 'alter table ' || iOwner || '.' || iTableName || ' move tablespace ';

        -- If this is a TOAD or QUEST table, deal with it separately.
        if (questTable(iTableName)) then
            vSql := vSql || iQuestTablespace;
        else
            vSql := vSql || iTablespace;
        end if;

        doit(vSql);
        
        -- And move any LOB columns too.
        moveLobs(iOwner, iTableName, iTablespace, iQuestTablespace);
        
    end;
    
    
--=====================================================================
begin
    -- Prepare lists of special indexes.
    -- These will go into the CFA_INDEX tablespace.
    cfaIndexIndexes('EMXTRANS_ORDUID')      := 'EMXTRANS_ORDUID';
    cfaIndexIndexes('EMXTRANS_NX01')        := 'EMXTRANS_NX01';
    cfaIndexIndexes('MEMO_IX4')             := 'MEMO_IX4';
    cfaIndexIndexes('PARENTID')             := 'PARENTID';
    cfaIndexIndexes('MEMOTYPE')             := 'MEMOTYPE';
    cfaIndexIndexes('M_CHECK_PK')           := 'M_CHECK_PK';


    -- These will go into the CFA tablespace.
    cfaIndexes('AURAOBJECT_UX01')           := 'AURAOBJECT_UX01';
    cfaIndexes('AURAUSER_UI_MUSER')         := 'AURAUSER_UI_MUSER';
    cfaIndexes('IDX_CONSTATSHOLDINGS')      := 'IDX_CONSTATSHOLDINGS';
    cfaIndexes('IDX_CONSTATSHOLDING_INV')   := 'IDX_CONSTATSHOLDING_INV';
    cfaIndexes('SNAPSHOTID_PK')             := 'SNAPSHOTID_PK';
    cfaIndexes('IDX_CONSTATS_TRANS')        := 'IDX_CONSTATS_TRANS';
    cfaIndexes('CONTRACT_RUN_PK')           := 'CONTRACT_RUN_PK';
    cfaIndexes('DOCUMENT_IMAGE_PK')         := 'DOCUMENT_IMAGE_PK';
    cfaIndexes('DOCUMENT_TYPES_PK')         := 'DOCUMENT_TYPES_PK';
    cfaIndexes('EMAILADDR_IX01')            := 'EMAILADDR_IX01';
    cfaIndexes('EMXORIG_UNIQ')              := 'EMXORIG_UNIQ';
    cfaIndexes('EMXPROVIDER_U')             := 'EMXPROVIDER_U';
    cfaIndexes('EMXTRANS_UK')               := 'EMXTRANS_UK';
    cfaIndexes('IX_EMXTRANS_CREATEDDATE')   := 'IX_EMXTRANS_CREATEDDATE';
    cfaIndexes('EMXTRANS_NX02')             := 'EMXTRANS_NX02';
    cfaIndexes('EMXVALREQ_UK')              := 'EMXVALREQ_UK';
    cfaIndexes('IX_EMXVALREQ_CREATEDDATE')  := 'IX_EMXVALREQ_CREATEDDATE';
    cfaIndexes('FUND_USAGE_UK3')            := 'FUND_USAGE_UK3';
    cfaIndexes('IFA_BANK_IX01')             := 'IFA_BANK_IX01';
    cfaIndexes('IFA_FUNDOWNER_PK')          := 'IFA_FUNDOWNER_PK';
    cfaIndexes('IMA_CODE')                  := 'IMA_CODE';
    cfaIndexes('IMA_TRSTCODE')              := 'IMA_TRSTCODE';
    cfaIndexes('INVESTORBANK_UK1')          := 'INVESTORBANK_UK1';
    cfaIndexes('INVESTORBANK_CNX')          := 'INVESTORBANK_CNX';
    cfaIndexes('INDX_TDATE')                := 'INDX_TDATE';
    cfaIndexes('OBJECTLOCKS_PK01')          := 'OBJECTLOCKS_PK01';
    cfaIndexes('SYS_C004230')               := 'SYS_C004230';
    cfaIndexes('PK_PAGE_LITERALS')          := 'PK_PAGE_LITERALS';
    cfaIndexes('PAGE_LITERALS_GROUP_PK')    := 'PAGE_LITERALS_GROUP_PK';
    cfaIndexes('PK_PAYMENT_SPINST')         := 'PK_PAYMENT_SPINST';
    cfaIndexes('QUEST_SL_TOPSQL_I')         := 'QUEST_SL_TOPSQL_I';
    cfaIndexes('RENEWAL_PARAM_IX01')        := 'RENEWAL_PARAM_IX01';
    cfaIndexes('RENEWAL_UNQ01')             := 'RENEWAL_UNQ01';
    cfaIndexes('PK_IFA_RENEWAL_RATE')       := 'PK_IFA_RENEWAL_RATE';
    cfaIndexes('RENEWAL_RATES_IX01')        := 'RENEWAL_RATES_IX01';
    cfaIndexes('REPORTS_UK21069682621953')  := 'REPORTS_UK21069682621953';
    cfaIndexes('REPORTS_R01')               := 'REPORTS_R01';
    cfaIndexes('REPORT_MENU_IX1')           := 'REPORT_MENU_IX1';
    cfaIndexes('REPORT_MENU_U01')           := 'REPORT_MENU_U01';
    cfaIndexes('SEARCHFIELDS_IX2')          := 'SEARCHFIELDS_IX2';
    cfaIndexes('SEARCHSETS_PK2_1_1')        := 'SEARCHSETS_PK2_1_1';
    cfaIndexes('SUPERVISOR_REQUESTS_PK')    := 'SUPERVISOR_REQUESTS_PK';
    cfaIndexes('SUPERVISOR_REQUESTS_IX1')   := 'SUPERVISOR_REQUESTS_IX1';
    cfaIndexes('TAMPROVIDER_U')             := 'TAMPROVIDER_U';
    cfaIndexes('TAM_FILES_PK')              := 'TAM_FILES_PK';
    cfaIndexes('TAM_FILES_U01')             := 'TAM_FILES_U01';
    cfaIndexes('TAM_TRANS_PK')              := 'TAM_TRANS_PK';
    cfaIndexes('TAM_TRANS_SWITCHID')        := 'TAM_TRANS_SWITCHID';
    cfaIndexes('TAM_TRANS_UK')              := 'TAM_TRANS_UK';
    cfaIndexes('RENEWAL_COMMISSION_NX08')   := 'RENEWAL_COMMISSION_NX08';
    cfaIndexes('RENEWAL_COMMISSION_IX07')   := 'RENEWAL_COMMISSION_IX07';
    cfaIndexes('RENEWAL_COMMISSION_IX06')   := 'RENEWAL_COMMISSION_IX06';
    cfaIndexes('RENEWAL_COMMISSION_IX05')   := 'RENEWAL_COMMISSION_IX05';
    cfaIndexes('RENEWAL_COMMISSION_IX04')   := 'RENEWAL_COMMISSION_IX04';
    cfaIndexes('RENEWAL_COMMISSION_IX03')   := 'RENEWAL_COMMISSION_IX03';
    cfaIndexes('RENEWAL_COMMISSION_IX02')   := 'RENEWAL_COMMISSION_IX02';
    cfaIndexes('RENEWAL_COMMISSION_IX01')   := 'RENEWAL_COMMISSION_IX01';
    cfaIndexes('RENEWAL_COMMISSION_NX01')   := 'RENEWAL_COMMISSION_NX01';
    cfaIndexes('RENEWAL_COMMISSION_NX09')   := 'RENEWAL_COMMISSION_NX09';
    cfaIndexes('REN_ORDUIS')                := 'REN_ORDUIS';

    -- These will go into the UVDATA01_INDEX tablespace.    
    uvdata01Indexes('EMXTRANS_TRSTCODE_IDX') := 'EMXTRANS_TRSTCODE_IDX';
    uvdata01Indexes('NOMINEE_NX02')          := 'NOMINEE_NX02';
    
    -- These will go into the ARCHIVE1_INDEX tablespace.
    archive1IndexIndexes('TPSQL_IDX')       := 'TPSQL_IDX';
    archive1IndexIndexes('TPTBL_IDX')       := 'TPTBL_IDX';
    archive1IndexIndexes('TOAD_RES_PK')     := 'TOAD_RES_PK';
    
    -- These go into the AURA_INDEX tablespace.    
    auraIndexIndexes('ADDCOMM_UNIQ')        := 'ADDCOMM_UNIQ';
    auraIndexIndexes('ADDCOMM_ORDUID')      := 'ADDCOMM_ORDUID';
    auraIndexIndexes('ADDCOMMUNK')          := 'ADDCOMMUNK';
    auraIndexIndexes('ADDCOMM_TRUST_INDX')  := 'ADDCOMM_TRUST_INDX';
    auraIndexIndexes('U_AURAGROUPS_1')      := 'U_AURAGROUPS_1';
    auraIndexIndexes('AURAGROUPOBJECT_IX1') := 'AURAGROUPOBJECT_IX1';
    auraIndexIndexes('AURAOBJECT_IX1')      := 'AURAOBJECT_IX1';
    auraIndexIndexes('AURAUSERGROUP_IX1')   := 'AURAUSERGROUP_IX1';
    auraIndexIndexes('AURAUSEROBJECT_IX1')  := 'AURAUSEROBJECT_IX1';
    auraIndexIndexes('AURA_LOGON_IX1')      := 'AURA_LOGON_IX1';
    auraIndexIndexes('AURA_LOGON_IX2')      := 'AURA_LOGON_IX2';
    auraIndexIndexes('PK_AURA_LOGON')       := 'PK_AURA_LOGON';
    auraIndexIndexes('AURA_LOGON_IX3')      := 'AURA_LOGON_IX3';
    auraIndexIndexes('PK_BANK_ACCOUNT')     := 'PK_BANK_ACCOUNT';
    auraIndexIndexes('BANK_ACCOUNT_IX1')    := 'BANK_ACCOUNT_IX1';
    auraIndexIndexes('PK_BANK_ACCOUNT_TYPE') := 'PK_BANK_ACCOUNT_TYPE';
    auraIndexIndexes('BANK_PARENT_TYPE_PK') := 'BANK_PARENT_TYPE_PK';
    auraIndexIndexes('CONTRACT_RUN_TRUST_PK') := 'CONTRACT_RUN_TRUST_PK';
    auraIndexIndexes('EMXFILES_PRVDSTAT')   := 'EMXFILES_PRVDSTAT';
    auraIndexIndexes('EMXORIG_IFA_INDX')    := 'EMXORIG_IFA_INDX';
    auraIndexIndexes('EMXTRANS_PRVDORDSTAT') := 'EMXTRANS_PRVDORDSTAT';
    auraIndexIndexes('EMXVALREQ_PRVSTAT')   := 'EMXVALREQ_PRVSTAT';
    auraIndexIndexes('EXECUTIVE_IFACODE')   := 'EXECUTIVE_IFACODE';
    auraIndexIndexes('USAGE_TRUST_INDX')    := 'USAGE_TRUST_INDX';
    auraIndexIndexes('IDX_USAGE_SEDOL')     := 'IDX_USAGE_SEDOL';
    auraIndexIndexes('GP_GLOBALPARAM_IX1')  := 'GP_GLOBALPARAM_IX1';
    auraIndexIndexes('GP_GROUP_IX1')        := 'GP_GROUP_IX1';
    auraIndexIndexes('GP_VALUES_IX1')       := 'GP_VALUES_IX1';
    auraIndexIndexes('PK_IFA_BANK')         := 'PK_IFA_BANK';
    auraIndexIndexes('INDEX1_IFA_DISCOUNTS_1') := 'INDEX1_IFA_DISCOUNTS_1';
    auraIndexIndexes('IFADISC_INV_INDX')    := 'IFADISC_INV_INDX';
    auraIndexIndexes('IFDISC_IFA_INDX')     := 'IFDISC_IFA_INDX';
    auraIndexIndexes('IFA_LARGE_SALE')      := 'IFA_LARGE_SALE';
    auraIndexIndexes('LARGE_IFA_INDX')      := 'LARGE_IFA_INDX';
    auraIndexIndexes('FOWNER_INV_INDX')     := 'FOWNER_INV_INDX';
    auraIndexIndexes('INV_ADDRESS_TMP')     := 'INV_ADDRESS_TMP';
    auraIndexIndexes('PK_MEMO')             := 'PK_MEMO';
    auraIndexIndexes('ML_CHECK_IX1')        := 'ML_CHECK_IX1';
    auraIndexIndexes('ML_CHECKDOCS_PK')     := 'ML_CHECKDOCS_PK';
    auraIndexIndexes('PK_ML_DOC_TYPE_PROOF') := 'PK_ML_DOC_TYPE_PROOF';
    auraIndexIndexes('NOMINEE_IX1')         := 'NOMINEE_IX1';
    auraIndexIndexes('PAGE_LITERALS_IX2')   := 'PAGE_LITERALS_IX2';
    auraIndexIndexes('PAGE_LITERALS_IX1')   := 'PAGE_LITERALS_IX1';
    auraIndexIndexes('RENEWAL_AMC_UNQ1')    := 'RENEWAL_AMC_UNQ1';
    auraIndexIndexes('REN_AMC_INV_INDX')    := 'REN_AMC_INV_INDX';
    auraIndexIndexes('RENEWAL_COMMISSION_TEMP') := 'RENEWAL_COMMISSION_TEMP';
    auraIndexIndexes('REN_TEMP_IFA')        := 'REN_TEMP_IFA';
    auraIndexIndexes('RENTEMP_TRSTCOMDATE_INDX') := 'RENTEMP_TRSTCOMDATE_INDX';
    auraIndexIndexes('RENEWAL_NOCOM_UNQ')   := 'RENEWAL_NOCOM_UNQ';
    auraIndexIndexes('NOCOM_TRUST_INDX')    := 'NOCOM_TRUST_INDX';
    auraIndexIndexes('RENRATE_TRUST_INDX')  := 'RENRATE_TRUST_INDX';
    auraIndexIndexes('REPORTARCHIVEMD_IX1') := 'REPORTARCHIVEMD_IX1';
    auraIndexIndexes('REPORTARCHIVEMD_IX2') := 'REPORTARCHIVEMD_IX2';
    auraIndexIndexes('REPORT_ARCHIVE_METADATA_FK2') := 'REPORT_ARCHIVE_METADATA_FK2';
    auraIndexIndexes('REPORTARCHIVEMD_IX3') := 'REPORTARCHIVEMD_IX3';
    auraIndexIndexes('SEQUENCELINK_UNQ')    := 'SEQUENCELINK_UNQ';
    auraIndexIndexes('PK_SUBCAT')           := 'PK_SUBCAT';
    auraIndexIndexes('TAM_TRANS_PRVDORDSTAT') := 'TAM_TRANS_PRVDORDSTAT';
    auraIndexIndexes('REN_PAYMENTDATE_INDX')  := 'REN_PAYMENTDATE_INDX';
    auraIndexIndexes('PK_RENEWAL_COMMISSION') := 'PK_RENEWAL_COMMISSION';
    auraIndexIndexes('RENTRSTUNITCOMDT')      := 'RENTRSTUNITCOMDT';
    auraIndexIndexes('REN_CONFIRMEDDATE_INDX') := 'REN_CONFIRMEDDATE_INDX';
    auraIndexIndexes('REN_FUNDOWNERID')     := 'REN_FUNDOWNERID';
    auraIndexIndexes('REN_IFA_INDX')        := 'REN_IFA_INDX';
    auraIndexIndexes('REN_IFA')             := 'REN_IFA';
    auraIndexIndexes('REN_INV_INDX')        := 'REN_INV_INDX';
    

    --=================================================================    
    -- The real work starts here.
    --=================================================================

    -- Any table that lives in the AURA tablespace will be moved. Some
    -- tables are QUEST/TOAD specific (why are they in production?) so
    -- get treated differently. Others with LONG [RAW] columns need to
    -- convert those to CLOB [BLOB] first or they can't be moved.
    for tableName in (select owner, 
                             segment_name as table_name
                      from   dba_segments
                      where  segment_type = 'TABLE'
                      and    tablespace_name = 'AURA'
                      and    owner in ('TOAD','FCS')
                      order by 1,2)
    loop
        vTableHasLONG := false;
        
        -- Does this table have a LONG column? There can be only one!
        vTableHasLONG :=  convertToLob(IOWNER =>tableName.owner,
                                       ITABLENAME => tableName.table_name, 
                                       ITYPE => 'LONG');
                           
        if (not vTableHasLONG) then
            vTableHasLONG := convertToLob(IOWNER =>tableName.owner,
                                          ITABLENAME => tableName.table_name, 
                                          ITYPE => 'LONG RAW');
        end if;
                     
        -- Add table to gatherTableStats list for later
        -- But only for application tables, we care not a jot
        -- about Toad or Quest tables here!
        if (tableName.owner = 'FCS') then
            gatherTableStats(tablename.table_name) := tablename.table_name;
        end if;
        
        -- Do the move of the table.
        -- Also handles any LOB columns.
        moveTable(IOWNER => tableName.owner,
                  ITABLENAME => tableName.table_name); 
                  
    end loop;
    
    
    -- Now do the indexes - those in the AURA tablespace 
    -- get rebuilt. If the index is on one of our various lists,
    -- it will get rebuilt in another tablespace.        
    for indexName in (select owner, 
                             segment_name as index_name
                      from   dba_segments
                      where  segment_type = 'INDEX'
                      and    tablespace_name = 'AURA'
                      and    owner in ('TOAD','FCS')
                      order  by 1,2)
    loop
        -- Do the AURA indexes rebuild, but consider QUEST/TOAD ones.
        indexTablespaceName := 'UVDATA01_INDEX';
        
        if (questIndex(indexName.owner, indexName.index_name)) then
            indexTablespaceName := 'ARCHIVE1_INDEX';
        end if;
        
        -- However, it might be a special index as well...
        if (cfaIndexes.exists(indexName.index_name)) then
            indexTablespaceName := 'CFA';
        elsif (cfaIndexIndexes.exists(indexName.index_name)) then
            indexTablespaceName := 'CFA_INDEX';
        elsif (uvdata01Indexes.exists(indexName.index_name)) then 
            indexTablespaceName := 'UVDATA01';
        elsif (auraIndexIndexes.exists(indexName.index_name)) then
            indexTablespaceName := 'AURA_INDEX';       
        elsif (archive1IndexIndexes.exists(indexName.index_name)) then
            indexTablespaceName := 'ARCHIVE1_INDEX';
        end if;
        
        -- Add the index to gatherIndexStats list for later
        -- But only for application indexes, we care not a jot
        -- about Toad or Quest tables here!
        if (indexName.owner = 'FCS') then
            gatherIndexStats(indexName.index_name) := indexName.index_name;
        end if;

        -- Do the rebuild.        
        vSql := 'alter index ' || indexName.owner || '.' || 
                indexName.index_name || ' rebuild online tablespace ' ||
                indexTablespaceName;
        doit(vSql);

    end loop;


    -- When we move a table, we render the indexes UNUSABLE. We need
    -- to catch these now in case they are yet to be rebuilt. They can
    -- also be flagged for a rebuild into a new tablespace, so check.
    for unusableIndexes in (select  owner, 
                                    index_name
                            from    dba_indexes
                            where   owner in ('TOAD','FCS')
                            and     status = 'UNUSABLE'
                            order  by 1,2)
    loop
        -- Default tablespace name for the indexes.
        indexTablespaceName := 'UVDATA01_INDEX';
        
        -- Yes, duplicated code, I know, but timescales!
        if (questIndex(unusableIndexes.owner, unusableIndexes.index_name)) then
            indexTablespaceName := 'ARCHIVE1_INDEX';
        end if;
        
        -- However, it might be a special index as well...
        if (cfaIndexes.exists(unusableIndexes.index_name)) then
            indexTablespaceName := 'CFA';
        elsif (cfaIndexIndexes.exists(unusableIndexes.index_name)) then
            indexTablespaceName := 'CFA_INDEX';
        elsif (uvdata01Indexes.exists(unusableIndexes.index_name)) then 
            indexTablespaceName := 'UVDATA01';
        elsif (auraIndexIndexes.exists(unusableIndexes.index_name)) then
            indexTablespaceName := 'AURA_INDEX';       
        elsif (archive1IndexIndexes.exists(unusableIndexes.index_name)) then
            indexTablespaceName := 'ARCHIVE1_INDEX';
        end if;
        
        -- Add the index to gatherIndexStats list for later
        -- But only for application indexes, we care not a jot
        -- about Toad or Quest tables here!
        if (unusableIndexes.owner = 'FCS') then
            gatherIndexStats(unusableIndexes.index_name) := unusableIndexes.index_name;
        end if;


        -- Do the rebuild.        
        vSql := 'alter index ' || unusableIndexes.owner || '.' || 
                unusableIndexes.index_name || ' rebuild online tablespace ' ||
                indexTablespaceName;
        doit(vSql);

    end loop;   


    --=================================================================
    -- LOBSEGMENT? LOBINDEX? Need to consider those too!
    --=================================================================

    pl('--');
    pl('-- The following, if any, might need moving too.');
    pl('--');
    
    for lobs in (select owner, 
                        table_name, 
                        column_name,  
                        index_name as lob_index_name 
                from    dba_lobs
                where   segment_name in ( select  segment_name 
                                          from    dba_segments 
                                          where   tablespace_name = 'AURA' 
                                          and     segment_type LIKE 'LOB%')
                order   by 1,2,3)
    loop
        pl('-- Table: ' || lobs.owner || '.' || lobs.table_name || ' ' ||
            'Column: ' || lobs.column_name || ' (and lobindex: ' || 
            lobs.lob_index_name || ')');
    end loop;    
    

    --=================================================================
    -- And now we gather stats on any table that we moved with the
    -- gathering cascaded down to the indexes. 
    --=================================================================
    vTableName := gatherTableStats.first;
    
    while (vTableName is not null) loop
        vSql := 'begin ' ||
                'dbms_stats.gather_table_stats(ownname=>''FCS'', ' ||
                'tabname=>''' || vTableName || ''', ' ||
                'method_opt=>''for all indexed columns size auto'', ' ||
                'degree=>4, cascade=>true, no_invalidate=>false); ' ||
                'end;';
        doit(vSql);
        
        vTableName := gatherTableStats.next(vTableName); 
    end loop;
    

    --=================================================================
    -- And now we gather stats on any index that we rebuilt but not if 
    -- it was just analyzed with it's table above. 
    --=================================================================
    vIndexName := gatherIndexStats.first;
    
    while (vIndexName is not null) loop
        begin
            -- Has this one just been analyzed with the table?
            select  last_analyzed
            into    vDate
            from    dba_indexes
            where   owner = 'FCS'
            and     index_name = vIndexName;
        
        exception
            when no_data_found then
                vDate := sysdate - 30;
            when others then
                raise;
        end;
        
        -- If we didn't analyze the index with the table, do it now.
        if (trunc(vDate) != trunc(sysdate)) then 
            vSql := 'begin ' ||
                    'dbms_stats.gather_index_stats(ownname=>''FCS'', ' ||
                    'indname=>''' || vIndexName || ''', ' ||
                    'degree=>4, no_invalidate=>false); ' ||
                    'end;';
            doit(vSql);
        end if;
                
        vIndexName := gatherIndexStats.next(vIndexName); 
    end loop;
    

    --=================================================================
    -- Everything else, just in case.
    --=================================================================

    pl('--');
    pl('-- The following objects, if any, will need investigating.');
    pl('--');
    
    for stuff in (select  owner,
                          segment_name,
                          segment_type 
                  from    dba_segments 
                  where   tablespace_name = 'AURA' 
                  and     segment_type not LIKE 'LOB%'
                  and     segment_type not in ('TABLE','INDEX')
                  order   by 1,2,3)
    loop
        pl('-- Object: ' || stuff.segment_type || ', Owner: ' || 
           stuff.owner || '.' || stuff.segment_name);
    end loop;    
    
    

end;
/


spool off
