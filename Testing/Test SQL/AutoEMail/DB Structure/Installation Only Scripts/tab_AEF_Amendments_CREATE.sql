-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to create AutoEMail table AEF_Amendments.
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

if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Amendments]')) = 0
BEGIN
	CREATE TABLE [AEF_Amendments]
	(
		[AEFA_ID] [int] IDENTITY(1,1) NOT NULL,
		[AEFA_FREF] [varchar](7) NULL,
		[AEFA_PRIKEY] [varchar](100) NULL,
 		[AEFA_CODE] [varchar](100) NULL,
 		[AEFA_START] [varchar](5) NULL,
 		[AEFA_END] [varchar](5) NULL,
 		[AEFA_COVERS] [varchar](5) NULL,
 		[AEFA_CHARGE] DECIMAL (10, 2) NULL,
 		[AEFA_NOTES] [TEXT] NULL,
 		[AEFA_ACTION] [varchar](1) NULL 
	) ON [PRIMARY]
	PRINT 'tab_AEF_Amendments_CREATE: Table AEF_Amendments Created'
END
ELSE
BEGIN
	PRINT 'tab_AEF_Amendments_CREATE: Table AEF_Amendments Not Created - Already Exists !'
END

PRINT '*****************************************************************************'								   
PRINT 'AEF_Amendments: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Amendments]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Product')
BEGIN		
	PRINT 'AEF_Amendments: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Amendments: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Amendments]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Module')
BEGIN		
	PRINT 'AEF_Amendments: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Amendments: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Amendments]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Version')
BEGIN		
	PRINT 'AEF_Amendments: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Amendments: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

