-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_getMenuItemDescription'
SET @Func_Name = 'uf_getMenuItemDescription'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_getMenuItemDescription]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[uf_getMenuItemDescription]
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
-- Author:		Mark Birch
-- Create date: 13th MAR 2015
-- Description:	gets the description for an Menu Item
-- =============================================
CREATE FUNCTION [dbo].[uf_getMenuItemDescription] 
(
	-- Add the parameters for the function here
	@PCode varchar(100)
)
RETURNS varchar(200)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(200)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = isnull((Select REPLACE(MNI_DESCRIPTION, CHAR(39), CHAR(146)) from MENUITEM where MNI_Code = @PCode), 'No Description Found' + ' (' + @PCode + ')' )

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_getMenuItemDescription: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getMenuItemDescription]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getMenuItemDescription') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_getMenuItemDescription: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getMenuItemDescription: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getMenuItemDescription]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getMenuItemDescription') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_getMenuItemDescription: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getMenuItemDescription: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getMenuItemDescription]
							   ,@name = N'Version' 
							   ,@value = N'12.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getMenuItemDescription') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_getMenuItemDescription: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getMenuItemDescription: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO