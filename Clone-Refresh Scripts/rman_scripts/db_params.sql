alter system set instance_name='azdba02' scope=spfile;            
alter system set service_names='azdba02' scope=spfile;            
alter system set audit_file_dest=                                        
'C:\ORACLEDATABASE\ADMIN\azdba02\ADUMP' scope = spfile;           
alter system set dispatchers=                                            
'(PROTOCOL=TCP) (SERVICE=azdba02XDB)' scope=spfile;               
alter role NORMAL_USER identified by azdba02123;                  
alter role SVC_AURA_SERV_ROLE identified by azdba02123;           
-- The following may fail. Please ignore.                                
alter database disable block change tracking;                            
-- The following will work.                                              
alter database enable block change tracking                              
using file 'F:\mnt\fast_recovery_area\bct.dbf';          
startup force                                                            
@tempfiles.sql                                                           
exit                                                                     
