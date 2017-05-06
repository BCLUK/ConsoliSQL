-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to create AutoEMail table AutoEmail_Function_SEND_PARAMS.
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

if (SELECT COUNT(*) FROM sysobjects WHERE id = object_id(N'[AutoEmailFunction_SEND_PARAMS]')) = 0
BEGIN
	CREATE TABLE AutoEmailFunction_SEND_PARAMS
	(
		AEF_SP_KEY int IDENTITY(1,1) NOT NULL,
		AEF_KEY int NULL,
		AEF_EmailProfile VARCHAR(200) NULL,
		AEF_EMailAddr VARCHAR(200) NULL,
		AEF_EmailFormat VARCHAR(200) NULL,
		AEF_Importance VARCHAR(200) NULL,
		AEF_Sensitivity VARCHAR(200) NULL,
		AEF_FROM_TRIGGER INT NULL,
		AEF_BookingRef VARCHAR(7) NULL,
		AEF_DateStamp DATETIME NULL
	)
	PRINT 'tab_AutoEmailFunction_SEND_PARAMS_CREATE: Table AutoEmailFunction_SEND_PARAMS Created'
END
ELSE
BEGIN
	PRINT 'tab_AutoEmailFunction_SEND_PARAMS_CREATE: Table AutoEmailFunction_SEND_PARAMS Not Created - Already Exists !'
END
GO

PRINT '*****************************************************************************'								   
PRINT 'AutoEmailFunction_SEND_PARAMS: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Product')
BEGIN		
	PRINT 'AutoEmailFunction_SEND_PARAMS: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_SEND_PARAMS: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Module')
BEGIN		
	PRINT 'AutoEmailFunction_SEND_PARAMS: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_SEND_PARAMS: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Version')
BEGIN		
	PRINT 'AutoEmailFunction_SEND_PARAMS: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_SEND_PARAMS: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

