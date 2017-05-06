-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to create AutoEMail table AutoEmail_Function_FromTrigger.
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

IF (SELECT COUNT(*) FROM sys.objects WHERE object_id = object_id(N'[AutoEmailFunction_FromTrigger]')) = 0
BEGIN
	CREATE TABLE AutoEmailFunction_FromTrigger
	(
		AEF_T_KEY int IDENTITY(1,1) NOT NULL,
			AEF_KEY int NULL,
			AEF_FUNC_REF varchar(7) NULL,
			AEF_STATUS varchar(6) NULL,
			AEF_STATUS_TEXT VARCHAR(100) NULL,
			AEF_ROOM varchar(6) NULL,
			AEF_ROOM_TEXT varchar(100) NULL,
			AEF_USE varchar(6) NULL,
			AEF_USE_TEXT varchar(100) NULL,
			AEF_PURPOSE varchar(100) NULL,
			AEF_BOOKER varchar(50) NULL,
			AEF_BOOKER_TEXT varchar(200) NULL,
			AEF_BOOKER_EMAIL varchar(100) NULL,
			AEF_DATE datetime NULL,
			AEF_START varchar(5) NULL,
			AEF_END varchar(5) NULL,
			AEF_SETUP varchar(5) NULL, 
			AEF_BDOWN varchar(5) NULL,
			AEF_COVERS int NULL,
			AEF_MBR_NO varchar(7) NULL,
			AEF_MBR_NAME varchar(100) NULL,
			AEF_CONTCT varchar(40) NULL,
			AEF_EMAIL varchar(100) NULL,
			AEF_CEMAIL varchar(100) NULL,
			AEF_INTERN int NULL,
			AEF_EXTRAYN int NULL,
			AEF_PACKYN int NULL,
			AEF_MENUYN int NULL,
			AEF_RMGIVEN VARCHAR(3) NULL,
			AEF_SESSNO VARCHAR(7) NULL,
			AEF_STARTDATETIME datetime NULL,
			AEF_CANSEND varchar(3) NULL,
			AEF_SENT int NULL,
			AEF_SENT_DATE datetime NULL,
			AEF_SENT_SESSION int NULL,
			AEF_INSERTED_DATE datetime NULL,
			AEF_UPDATED_DATE datetime NULL,
			AEF_FROM_TRIGGER INT NULL,
			-- Increased column width from 10 to 100 to store email stored proc name and template - TT - 02/08/2016
			AEF_ROUTE VARCHAR(100) NULL,			
			AEF_DTYN int NULL,
			-- Added column to store mail item id from system email tables - TT - 18/10/2016
			AEF_MAILITEM_ID int NULL
	)
	PRINT 'tab_AutoEmailFunction_FromTrigger_CREATE: Table AutoEmailFunction_FromTrigger Created'
END
ELSE
BEGIN
	PRINT 'tab_AutoEmailFunction_FromTrigger_CREATE: Table AutoEmailFunction_FromTrigger Not Created - Already Exists !'
END
GO

PRINT '*****************************************************************************'								   
PRINT 'AutoEmailFunction_FromTrigger: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_FromTrigger]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Product')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_FromTrigger]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Module')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AutoEmailFunction_FromTrigger]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Version')
BEGIN		
	PRINT 'AutoEmailFunction_FromTrigger: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AutoEmailFunction_FromTrigger: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

