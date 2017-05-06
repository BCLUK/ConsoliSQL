
DECLARE @RC int
DECLARE @SOURCE varchar(1000) 
DECLARE @SECTION varchar(1000) 
DECLARE @KEY varchar(1000) 
DECLARE @VALUE varchar(1000) 
DECLARE @TYPE varchar(1000) 

-- TODO: Set parameter values here.
set @SOURCE = ''
set @SECTION = 'usp_CreateExportFile_HALSUM'
set @KEY = 'MaxNameLength'
set @VALUE = '25'
set @TYPE = 'S'

EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE

  Set @KEY = 'FileExt'
  Set @VALUE = 'csv'

EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE


GO


