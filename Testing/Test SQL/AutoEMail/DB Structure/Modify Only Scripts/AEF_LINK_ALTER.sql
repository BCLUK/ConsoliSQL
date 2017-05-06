-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to ALter table AEF_Link
--
-- =====================================================================================================
-- Version:		2
-- Date:		07/11/2016
-- =====================================================================================================
-- Changes:		TT: xx/xx/2016: Original Version
--	 (1)
-- Changes:		TT: 07/11/2016: Tidied Up Script
--	 (2	)
-- =====================================================================================================

SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[AEF_Link]')) = 0
BEGIN
	PRINT 'AEF_LINK_ALTER: Table AEF_Link Does Not Exist - Cannot Add New Columns !'
	RETURN
END
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF COL_LENGTH('AEF_Link','AEFL_MBRNo') IS NULL
BEGIN	
	ALTER TABLE [dbo].[AEF_Link]
	ADD [AEFL_MBRNo] [varchar](7) NULL
	PRINT 'AEF_LINK_ALTER: Added Column AEFL_MBRNo'
END
ELSE
BEGIN
	PRINT 'AEF_LINK_ALTER: Cannot Added Column AEFL_MBRNo - It Already Exists !'
END	
GO

-- Added column to determine working window - TT - 01/11/2016
IF COL_LENGTH('AEF_Link','AEFL_LastUpdate') IS NULL
BEGIN	
	ALTER TABLE [dbo].[AEF_Link]
	ADD AEFL_LastUpdate [DateTime] NULL
	PRINT 'AEF_LINK_ALTER: Added Column AEFL_LastUpdate'
END	
ELSE
BEGIN
	PRINT 'AEF_LINK_ALTER: Cannot Added Column AEFL_LastUpdate - It Already Exists !'
END	
GO

SET ANSI_PADDING OFF
GO

PRINT '*****************************************************************************'								   
PRINT 'AEF_LINK_ALTER: Updaing Extended Properties'

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
								  ,@level0name = [dbo] 
								  ,@level1type = N'TABLE' 
								  ,@level1name = [AEF_Link]
								  ,@name = N'Product' 
								  ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Product')
BEGIN		
	PRINT 'AEF_LINK_ALTER: Product Extended Property Updated Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_LINK_ALTER: Product Extended Property Not Updated Successfully !'
END	

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Module')
BEGIN		
	PRINT 'AEF_LINK_ALTER: Module Extended Property Updated Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_LINK_ALTER: Module Extended Property Not Updated Successfully !'
END			

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
								  ,@level0name = [dbo] 
								  ,@level1type = N'TABLE' 
								  ,@level1name = [AEF_Link]
								  ,@name = N'Version' 
								  ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Version')
BEGIN		
	PRINT 'AEF_LINK_ALTER: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_LINK_ALTER: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

