-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_GetEmailSendType'
SET @Func_Name = 'uf_GetEmailSendType'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_GetEmailSendType')
BEGIN
	DROP FUNCTION [dbo].[uf_GetEmailSendType]
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

-- ===================================================
-- Author:		Tony Tasker
-- Create date: 16/06/2016
-- Description:	For a particular EmailType this 
--				function returns the Send Type
--
--				Possible options are: CR, B4, NW, RE
-- ===================================================
-- Version: 1 
-- Date: 16/06/2016
-- =============================================
-- Changes: 16/06/2016: TT: Original Version
-- =============================================
CREATE FUNCTION [dbo].[uf_GetEmailSendType] 
(
	-- Calling function/procedure supplies the EmailType
	@EmailType Varchar(7)
)
RETURNS VARCHAR(10)
AS
BEGIN
	-- The return value defaults to an empty string
	DECLARE @GetEmailSendType VARCHAR(10) = ''

	-- Declare Required Variables
	DECLARE @Frequency VARCHAR(1000)
	DECLARE @POS INT
	
	-- Check the X CABS CONFIG settings for the Email Type and Check that a Frequecny Key exists
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailType AND [KEY] = 'Frequency') > 0
	BEGIN

		-- Get the Value of the Key "Frequency" from X CABS CONFIG
		SET @Frequency = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailType AND [KEY] = 'Frequency')

		-- Look for the Character "L" in the Frequency string - format will be L:XX
		-- where XX is B4 or CR or NW or RE
		SET @POS = PATINDEX( '%L%', @Frequency )

		-- If it exists then get the emailtype
		IF @POS > 0
			SET @GetEmailSendType = SUBSTRING( @Frequency, @POS + 2, 2)		
	END

	-- Return the email type
	RETURN @GetEmailSendType

END

GO

PRINT '*****************************************************************************'								   
PRINT 'uf_GetEmailSendType: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailSendType]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailSendType') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_GetEmailSendType: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailSendType: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailSendType]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailSendType') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_GetEmailSendType: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailSendType: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailSendType]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailSendType') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_GetEmailSendType: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailSendType: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO