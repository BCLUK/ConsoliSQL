/*	
	Script to configure database for the FSI
	This turns several switches on which are required 
	to export the data to a text file
*/

sp_configure 'show advanced options', 1;    
GO    
RECONFIGURE;    
GO    
sp_configure 'xp_cmdshell', 1;    
GO    
RECONFIGURE;    
GO
sp_configure 'Ole Automation Procedures', 1 
GO 
RECONFIGURE; 
GO 

use master

grant exec on sp_OAMethod to guest 
grant exec on sp_OACreate to guest 
grant exec on sp_OADestroy to guest 
grant exec on sp_OAGetErrorInfo to guest 
grant exec on sp_OAGetProperty to guest 
grant exec on sp_OASetProperty to guest 

GO
