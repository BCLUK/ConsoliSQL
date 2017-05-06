-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_GetMenuItemCount'
SET @Func_Name = 'uf_GetMenuItemCount'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_GetMenuItemCount]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[uf_GetMenuItemCount]
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
-- Create date: 11-SEP-2015
-- Description:	To Return a current count of Menu Items for a Menu
-- =============================================
CREATE FUNCTION uf_GetMenuItemCount
(
	-- Add the parameters for the function here
	@MenuCode VARCHAR(10)
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar INT

	-- Add the T-SQL statements to compute the return value here
	SET @ResultVar = (SELECT COUNT(*) FROM MADEMENU WHERE MEN_MENU_CODE = @MenuCode)

	-- Return the result of the function
	RETURN @ResultVar

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_GetMenuItemCount: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetMenuItemCount]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetMenuItemCount') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_GetMenuItemCount: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetMenuItemCount: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetMenuItemCount]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetMenuItemCount') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_GetMenuItemCount: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetMenuItemCount: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetMenuItemCount]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetMenuItemCount') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_GetMenuItemCount: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetMenuItemCount: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO