-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 07/11/2016
-- Description:	Script to create AutoEMail table AEF_LNK.
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
IF (SELECT COUNT(*) FROM sys.objects WHERE object_id = object_id(N'[AEF_Link]')) = 0
BEGIN
	CREATE TABLE [AEF_Link]
	(
		[AEFL_ID] [int] IDENTITY(1,1) NOT NULL,
		[AEFL_FREF] [varchar](7) NULL,
		[AEFL_SessNo] [varchar](7) NULL,
		[AEFL_EMailType] [varchar](6) NULL,
		[AEFL_CanSend] [int] NULL,
		[AEFL_FDay] [datetime] NULL,
		[AEFL_Sent] [int] NULL,
		[AEFL_SendTime] [datetime] NULL,
		[AEFL_Source] [varchar](50) NULL,
		[AEFL_Department] [varchar](MAX) NULL,
		--Added column [AEFL_EmailSPROC] to be used for storing template specific stored proc - MB/TT - 01/06/2016
		[AEFL_EmailSPROC] [varchar](200) NULL, 
		-- Added Column to store MBR_No - TT - 02/08/2016
		[AEFL_MBRNo] [varchar](7) NULL,
		-- Added colummn to store date and time of last record change - TT - 01/11/2016
		[AEFL_LastUpdate] [DateTime] NULL
	) ON [PRIMARY]
	PRINT 'tab_AEF_LINK_CREATE: Table AEF_LINK Created'
END
ELSE
BEGIN
	PRINT 'tab_AEF_LINK_CREATE: Table AEF_LINK Not Created - Already Exists !'
END

PRINT '*****************************************************************************'								   
PRINT 'AEF_Link: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Product')
BEGIN		
	PRINT 'AEF_Link: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Link: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Module')
BEGIN		
	PRINT 'AEF_Link: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Link: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Version')
BEGIN		
	PRINT 'AEF_Link: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEF_Link: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

