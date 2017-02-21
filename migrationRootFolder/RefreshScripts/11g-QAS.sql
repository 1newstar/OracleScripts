set lines 2000 pages 2000 trimspool on

spool 11g_QAS.lst

-- Script to point UV to the QAS webservice

-- Before update
select globalparamid, paramkey, defaultvalue from FCS.GP_GLOBALPARAM where paramkey IN ('QAS_URL', 'ADDRESS_WEB_SERVICE');
select gpvalueid, globalparamid, parametervalue  from FCS.GP_VALUES where globalparamid in (select globalparamid from FCS.GP_GLOBALPARAM where paramkey IN ('QAS_URL', 'ADDRESS_WEB_SERVICE'));

update FCS.GP_GLOBALPARAM set defaultValue = 'TRUE' where paramkey = 'ADDRESS_WEB_SERVICE';
update FCS.GP_GLOBALPARAM set defaultValue = 'http://ppdquickaddap01.casfs.co.uk:49317' where paramkey = 'QAS_URL';
delete from FCS.GP_VALUES where globalparamid in (select globalparamid from FCS.GP_GLOBALPARAM where paramkey IN ('QAS_URL', 'ADDRESS_WEB_SERVICE'));


-- After update
select globalparamid, paramkey, defaultvalue from FCS.GP_GLOBALPARAM where paramkey IN ('QAS_URL', 'ADDRESS_WEB_SERVICE');
select gpvalueid, globalparamid, parametervalue  from FCS.GP_VALUES where globalparamid in (select globalparamid from FCS.GP_GLOBALPARAM where paramkey IN ('QAS_URL', 'ADDRESS_WEB_SERVICE'));

commit;

spool off

