-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to Alter table AutoEmailFunction_FromTrigger
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

IF (SELECT COUNT(*) FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[AutoEmailFunction_FromTrigger]')) = 0
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Table AutoEmailFunction_FromTrigger Does Not Exist - Cannot Add New Columns !'
	RETURN
END
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

ALTER TABLE [dbo].[AutoEmailFunction_FromTrigger]
ALTER COLUMN [AEF_ROUTE] VARCHAR(100)
PRINT 'AutoEmailFunction_FromTrigger_ALTER: Altered Column AEF_ROUTE'
GO

IF COL_LENGTH('AutoEmailFunction_FromTrigger','AEF_MAILITEM_ID') IS NULL
BEGIN	
	ALTER TABLE [dbo].[AutoEmailFunction_FromTrigger]
	ADD [AEF_MAILITEM_ID] [int] NULL
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Added Column AEF_MAILITEM_ID'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Column AEF_MAILITEM_ID Already Exists !'
END
GO

SET ANSI_PADDING OFF
GO

PRINT '*****************************************************************************'								   
PRINT 'AutoEmailFunction_FromTrigger_ALTER: Updating Extended Properties'

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
								  ,@level0name = [dbo] 
								  ,@level1type = N'TABLE' 
								  ,@level1name = [AutoEmailFunction_FromTrigger]
								  ,@name = N'Product' 
								  ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Product')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Product Extended Property Updated Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Product Extended Property Not Updated Successfully !'
END	

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
								  ,@level0name = [dbo] 
								  ,@level1type = N'TABLE' 
								  ,@level1name = [AutoEmailFunction_FromTrigger]
								  ,@name = N'Module' 
								  ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Module')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_updateextendedproperty @level0type = N'SCHEMA' 
							      ,@level0name = [dbo] 
							      ,@level1type = N'TABLE' 
							      ,@level1name = [AutoEmailFunction_FromTrigger]
							      ,@name = N'Version' 
							      ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Version')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger_ALTER: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

