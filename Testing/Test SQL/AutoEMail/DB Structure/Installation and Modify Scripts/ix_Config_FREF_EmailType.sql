-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 22/03/2017
-- Description:	Script to Add Indexe ix_Config_FREF_EmailType to table AEF_LINK
--				Split out from file 01d.AEFLINK_Table_Index.sql so have kept old notes
-- =====================================================================================================
-- Version:		2
-- Date:		07/11/2016
-- =====================================================================================================
-- Changes:		TT: xx/xx/2016: Original Version
--	 (1)
-- Changes:		TT: 07/11/2016: Tidied Up Script
--	 (2)
-- =====================================================================================================		   

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[dbo].[AEF_Link]') AND NAME ='ix_Config_FREF_EmailType')
BEGIN
    DROP INDEX ix_Config_FREF_EmailType ON [dbo].[AEF_Link];
	PRINT 'AEFLINK_Table_Index: Dropped INDEX ix_Config_FREF_EmailType ON [dbo].[AEF_Link]'
END
ELSE
BEGIN
	PRINT 'AEFLINK_Table_Index: INDEX ix_Config_FREF_EmailType ON [dbo].[AEF_Link] Does Not Exist - Cannot DROP !'
END
GO

CREATE NONCLUSTERED INDEX ix_Config_FREF_EmailType
ON [dbo].[AEF_Link] ([AEFL_FREF],[AEFL_EMailType])
PRINT 'AEFLINK_Table_Index: Created INDEX ix_Config_FREF_EmailType ON [dbo].[AEF_Link]'
GO

PRINT '*****************************************************************************'
PRINT 'AEFLINK_Table_Index: Creating Extended Properties'								   
GO

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_FREF_EmailType]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_FREF_EmailType' AND ep.name = 'Product')
BEGIN		
	PRINT 'AEFLINK_Table_Index: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEFLINK_Table_Index: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_FREF_EmailType]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_FREF_EmailType' AND ep.name = 'Module')
BEGIN		
	PRINT 'AEFLINK_Table_Index: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEFLINK_Table_Index: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AEF_Link]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_FREF_EmailType]
							   ,@name = N'Version' 
							   ,@value = N'1.0'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_FREF_EmailType' AND ep.name = 'Version')								   
BEGIN		
	PRINT 'AEFLINK_Table_Index: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AEFLINK_Table_Index: Version Extended Propety Not Created Successfully !'
END

PRINT '*****************************************************************************'								   
GO