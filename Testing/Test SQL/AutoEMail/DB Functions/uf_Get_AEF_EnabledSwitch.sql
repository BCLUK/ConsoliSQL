-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_Get_AEF_EnabledSwitch'
SET @Func_Name = 'uf_Get_AEF_EnabledSwitch'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_Get_AEF_EnabledSwitch')
BEGIN
	DROP FUNCTION [dbo].[uf_Get_AEF_EnabledSwitch]
	PRINT @FileName + ': Dropped Function ' + @Func_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @Func_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Function ' + @Func_Name
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================
-- Author:		Tony Tasker
-- Create date: 24/11/2016
-- Description:	Returns whether or not an Email Template is 
--				enabled
-- ==========================================================
-- Version: 1 
-- Date: 24/11/2016
-- =============================================
-- Changes: 24/11/2016: TT: Original Version
-- =============================================
CREATE FUNCTION [dbo].[uf_Get_AEF_EnabledSwitch]
(		
	@emailtype varchar(6),
	@Action varchar(1)
)
RETURNS VARCHAR(1)
AS
BEGIN	
	
	DECLARE @Enabled INT
	DECLARE @EnabledB INT
	DECLARE @EnabledE INT
	DECLARE @EnabledC INT
	DECLARE @ReturnValue VARCHAR(1)

	--SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @SYS_EmailType, 'Enabled')), '0')
	SET @Enabled = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'Enabled')), '0'), @Action))

	-- Added to enable email templates to be enabled specifically for changes to Func_Fil
	SET @EnabledB = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'EnabledB')), '0'), @Action))

	-- Added to enable email templates to be enabled specifically for changes to AI_File
	SET @EnabledE = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'EnabledE')), '0'), @Action))

	-- Added to enable email templates to be enabled specifically for changes to the Classification Tables
	SET @EnabledC = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'EnabledC')), '0'), @Action))
	
	IF @Enabled > 0 OR @EnabledB > 0 OR @EnabledB > 0  OR @EnabledC > 0
			SET @Enabled = 1
		ELSE
			SET @Enabled = 0
	
	SET @ReturnValue = @Enabled

	RETURN @ReturnValue

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_Get_AEF_EnabledSwitch: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_AEF_EnabledSwitch]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_AEF_EnabledSwitch') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_Get_AEF_EnabledSwitch: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_AEF_EnabledSwitch: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_AEF_EnabledSwitch]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_AEF_EnabledSwitch') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_Get_AEF_EnabledSwitch: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_AEF_EnabledSwitch: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_AEF_EnabledSwitch]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_AEF_EnabledSwitch') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_Get_AEF_EnabledSwitch: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_AEF_EnabledSwitch: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO