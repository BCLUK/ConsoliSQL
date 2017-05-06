-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_getDepteMail'
SET @Func_Name = 'uf_getDepteMail'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_getDepteMail]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    DROP FUNCTION [dbo].[uf_getDepteMail]
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

-- =============================================
-- Author:		Peter Green
-- Create date: 6th Feb 2015
-- Description:	Gets the email address for a costcentre
-- =============================================
CREATE FUNCTION [dbo].[uf_getDepteMail] 
(
	-- Add the parameters for the function here
	@Dept varchar(10)
)
RETURNS varchar(4000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(4000)

	-- Add the T-SQL statements to compute the return value here
	SET @Result = (Select isnull([VALUE],'') FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'DeptEmailAddresses' AND [KEY] = @Dept)

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_getDepteMail: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDepteMail]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDepteMail') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_getDepteMail: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDepteMail: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDepteMail]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDepteMail') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_getDepteMail: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDepteMail: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDepteMail]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDepteMail') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_getDepteMail: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDepteMail: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO