-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to create AutoEMail table MenuActivityCount.
--
-- =====================================================================================================
-- Version:		1
-- Date:		07/11/2016
-- =====================================================================================================
-- Changes:		TT: 07/11/2016: Original Version
--	 (1)
-- =====================================================================================================

SET NOCOUNT ON;

-- *****************************************
-- If table does not already exist create it
-- *****************************************

IF (SELECT COUNT(*) FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[MenuActivityCount]')) = 0
BEGIN
	CREATE TABLE MenuActivityCount
	(
		MEN_MENU_CODE VARCHAR(10) NULL,
		MEN_DEL_COUNT INT NULL,
		MEN_REC_TYPE VARCHAR(1),
		MEN_DATE DATETIME 		
	)
	PRINT 'tab_MenuActivityCount_CREATE: Table MenuActivityCount Created'	
END
ELSE
BEGIN
	PRINT 'tab_MenuActivityCount_CREATE: Table MenuActivityCount Not Created - Already Exists !'
END
GO

PRINT '*****************************************************************************'								   
PRINT 'MenuActivityCount: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MenuActivityCount]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Product')
BEGIN		
	PRINT 'MenuActivityCount: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'MenuActivityCount: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MenuActivityCount]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Module')
BEGIN		
	PRINT 'MenuActivityCount: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'MenuActivityCount: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MenuActivityCount]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Version')
BEGIN		
	PRINT 'MenuActivityCount: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'MenuActivityCount: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

