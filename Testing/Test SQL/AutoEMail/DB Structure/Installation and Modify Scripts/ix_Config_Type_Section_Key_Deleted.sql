-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- ========================================================================
-- Author:		Tony Tasker
-- Create date: 22/03/2017
-- Description:	Add Index ix_Config_Type_Section_Deleted to xCABS_CONFIG_TABLE
--				This file was split out from 01c.xCABS_Config_Table_Index.sql	
-- ========================================================================
-- Version: 3
-- Date: 08/11/2016
-- ========================================================================
-- Changes: 03/08/2016: TT: Original
-- Changes: 11/10/2016: TT: Added UPDATE to trigger to help with testing
-- Changes: 08/11/2016: TT: Tidied Up Script
-- ========================================================================

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[dbo].[xCABS_CONFIG_TABLE]') AND NAME ='ix_Config_Type_Section_Key_Deleted')
BEGIN
    DROP INDEX ix_Config_Type_Section_Key_Deleted ON [dbo].[xCABS_CONFIG_TABLE];
	PRINT 'xCABS_Config_Table_Index: Dropped ix_Config_Type_Section_Key_Deleted ON [dbo].[xCABS_CONFIG_TABLE]'
END
ELSE
BEGIN
	PRINT 'xCABS_Config_Table_Index: INDEX ix_Config_Type_Section_Key_Deleted ON [dbo].[xCABS_CONFIG_TABLE] Does Not Exist !'
END
GO

PRINT 'xCABS_Config_Table_Index: Creating INDEX ix_Config_Type_Section_Key_Deleted ON [dbo].[xCABS_CONFIG_TABLE]'
CREATE NONCLUSTERED INDEX ix_Config_Type_Section_Key_Deleted
ON [dbo].[xCABS_CONFIG_TABLE] ([TYPE],[SECTION],[KEY],[DELETED])
GO

PRINT '*****************************************************************************'								   
PRINT 'xCABS_Config_Table_Index: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [xCABS_CONFIG_TABLE]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_Type_Section_Key_Deleted]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_Type_Section_Key_Deleted' AND ep.name = 'Product')
BEGIN		
	PRINT 'xCABS_Config_Table_Index: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'xCABS_Config_Table_Index: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [xCABS_CONFIG_TABLE]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_Type_Section_Key_Deleted]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_Type_Section_Key_Deleted' AND ep.name = 'Module')
BEGIN		
	PRINT 'xCABS_Config_Table_Index: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'xCABS_Config_Table_Index: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [xCABS_CONFIG_TABLE]
							   ,@level2type = N'INDEX' 
							   ,@level2name = [ix_Config_Type_Section_Key_Deleted]
							   ,@name = N'Version' 
							   ,@value = N'3.0'

IF EXISTS (SELECT NULL FROM sys.extended_properties ep inner join sys.indexes i on ep.major_id = i.object_id where i.name = 'ix_Config_Type_Section_Key_Deleted' AND ep.name = 'Version')								   
BEGIN		
	PRINT 'xCABS_Config_Table_Index: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'xCABS_Config_Table_Index: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO





