
DELETE  xCABS_CONFIG_TABLE where section = 'EnhancedMBRCopierMapping' and [Key] like'%~%'
GO


DECLARE @RC int
DECLARE @SOURCE varchar(1000) = ''
DECLARE @SECTION varchar(1000) = 'EnhancedMBRCopierMapping'
DECLARE @KEY varchar(1000) = 'CRMR~BMC'
DECLARE @VALUE varchar(1000) = 'ACAC'
DECLARE @TYPE varchar(1000) = 'S'

-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'ACL~AB' 
set @Value = 'ACBRAL'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'CRMR~DAT' 
set @Value = 'ACAFC'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'ACL1~CL' 
set @Value = 'ACAL'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'ACLL2~CL' 
set @Value = 'ACAL'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'DRMB~AB' 
set @Value = 'ACBR'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'ACL3~EDI' 
set @Value = 'ACCD'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'DRML~CL' 
set @Value = 'ACCLU'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'DRMD~EDI' 
set @Value = 'ACDR'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'EWCR~BMC' 
set @Value = 'ACEAC'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'EWCR~DAT' 
set @Value = 'ACEACE'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'EWREST~CL' 
set @Value = 'ACEHL'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'CMRREC~FEV' 
set @Value = 'ACRECD'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE
set @Key = 'OTHER~OTHER' 
set @Value = 'XXXXX'
EXECUTE @RC = [dbo].[xCABS_CONFIG_WriteString]    @SOURCE  ,@SECTION  ,@KEY  ,@VALUE  ,@TYPE








GO


