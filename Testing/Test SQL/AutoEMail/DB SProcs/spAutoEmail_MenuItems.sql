-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'spAutoEmail_MenuItems'
SET @SPROC_Name = 'spAutoEmail_MenuItems'
if exists (select * from sys.objects where object_id = object_id(N'[spAutoEmail_MenuItems]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [spAutoEmail_MenuItems]
	PRINT @FileName + ': Dropped Procedure ' + @SPROC_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @SPROC_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Procedure ' + @SPROC_Name
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mark Birch
-- Create date: 11-SEP-2015
-- Description:	To Excute SPROC For AutoEmailer based on Menu Items
-- =============================================
-- Version: 2
-- Date: 02/10/2015
-- =============================================
-- Changes: 02/10/2015: MCB: Handled if more than one Menu had ever been amended
-- =============================================
CREATE PROCEDURE [dbo].[spAutoEmail_MenuItems]
	@MenuCode VARCHAR(10), @BookingNumber VARCHAR(10), @SessionNumber VARCHAR(10), @BookingDateTime DATETIME, @CanSend INT, @Source VARCHAR(50), @Action VARCHAR(1), @Department VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- ================================================
-- DECLARATIONS
-- ================================================
	--DECLARE @Action VARCHAR(1)
-- ================================================
-- GET SETTINGS
-- ================================================
--Debug
DECLARE
@MCode VARCHAR(100),
@DelCount INT,
@MenItemCount INT  

SET @MCode = (SELECT MEN_MENU_CODE FROM MenuActivityCount WHERE MEN_MENU_CODE = @MenuCode)
SET @DelCount = (SELECT MEN_DEL_COUNT FROM MenuActivityCount WHERE MEN_MENU_CODE = @MenuCode)
SET @MenItemCount = (SELECT [dbo].[uf_GetMenuItemCount] (@MenuCode))

	SET @Action = 
	(SELECT CASE
		WHEN (SELECT [dbo].[uf_GetMenuItemCount] (@MenuCode)) > MEN_DEL_COUNT THEN 'I'
		WHEN (SELECT [dbo].[uf_GetMenuItemCount] (@MenuCode)) < MEN_DEL_COUNT THEN 'D'
		WHEN (SELECT [dbo].[uf_GetMenuItemCount] (@MenuCode)) = MEN_DEL_COUNT THEN 'U'
	END
	FROM MenuActivityCount
	 WHERE MEN_MENU_CODE = @MenuCode)	
-- ================================================
-- The Work
-- ================================================
	EXECUTE ae_INS_EmailTypes_AEF_Link @BookingNumber, @SessionNumber, @BookingDateTime, @CanSend, @Source, @Action, @Department
-- ================================================
END
GO

PRINT '*****************************************************************************'

PRINT 'spAutoEmail_MenuItems: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [spAutoEmail_MenuItems]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('spAutoEmail_MenuItems') AND [name] = 'Product')
BEGIN		
	PRINT 'spAutoEmail_MenuItems: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'spAutoEmail_MenuItems: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [spAutoEmail_MenuItems]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('spAutoEmail_MenuItems') AND [name] = 'Module')
BEGIN		
	PRINT 'spAutoEmail_MenuItems: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'spAutoEmail_MenuItems: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [spAutoEmail_MenuItems]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('spAutoEmail_MenuItems') AND [name] = 'Version')
BEGIN		
	PRINT 'spAutoEmail_MenuItems: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'spAutoEmail_MenuItems: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO