set lines 2000 pages 2000 trimspool on echo on


spool DropExternalTables.lst

drop table fcs.EXT_THR_TBLCLIENT cascade constraints purge;
drop table fcs.EXT_THR_TBLCLIENTAGREEMENT cascade constraints purge;
drop table fcs.EXT_THR_TBLCLIENTHOLDING cascade constraints purge;
drop table fcs.EXT_THR_TBLCONTACTS cascade constraints purge;
drop table fcs.EXT_THR_TBLDETAILTRAN cascade constraints purge;
drop table fcs.EXT_THR_TBLFUND cascade constraints purge;
drop table fcs.EXT_THR_TBLFUNDAMC cascade constraints purge;
drop table fcs.EXT_THR_TBLFUNDTYPE cascade constraints purge;
drop table fcs.EXT_THR_TBLPRICE cascade constraints purge;
drop table fcs.EXT_THR_TBLTRANSACTION cascade constraints purge;
drop table fcs.EXT_THR_TBLTRANSTYPE cascade constraints purge;
drop table fcs.EXT_THR_TBLVALDATE cascade constraints purge;
drop table fcs.EXT_THR_TBLWITHDRAWALALLOWANCE cascade constraints purge;

-- And the temporary directory too.
drop directory thread_ext_tables;

spool off
