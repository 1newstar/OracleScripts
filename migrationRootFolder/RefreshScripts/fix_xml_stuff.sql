set lines 2000 trimspool on pages 2000

spool fix_xml_stuff.lst

alter table fatca_file_submission 
add constraint fatca_file_submission_fk01 
foreign key (submission_parent_messageref) 
references xml_fatca_reports (messageref) 
enable novalidate;


CREATE TABLE "UKFATCASubmissionFIRe98_TAB" OF "XMLTYPE" 
 XMLSCHEMA "http://hmrc.gov.uk/UKFATCASubmissionFIReport" ELEMENT "UKFATCASubmissionFIReport" 
  PCTFREE 10 
  PCTUSED 40 
  INITRANS 1 
  MAXTRANS 255 NOCOMPRESS LOGGING STORAGE
(
  INITIAL 65536 
  NEXT 1048576 
  MINEXTENTS 1 
  MAXEXTENTS 2147483645 
  PCTINCREASE 0 
  FREELISTS 1 
  FREELIST GROUPS 1 
  BUFFER_POOL DEFAULT
) 
TABLESPACE "UVDATA01" ;

spool off

