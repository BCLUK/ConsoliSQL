-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_DELETE_RECORDS'
SET @SPROC_Name = 'CABS_AEF_DELETE_RECORDS'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_DELETE_RECORDS]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].CABS_AEF_DELETE_RECORDS
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

-- ==========================================================================
-- Author:		Tony Tasker
-- Create date: 01/11/2016
-- Description:	Deletes records from table AEF_LINK that are aged. 
--				This code will be executed by a scheduled job 
--				[CABS] Auto-Email AEF_LINK Delete. The job will run daily at 
--				02:00. 
--				
--				AEF_LINK will contain a record for each configured email 
--				template for each function. This table is the basis for 
--				vw_AEFLink which contains a number of functions used to 
--				calculate field values. It will therefore be more efficient
--				if the size of this table is managed.
-- =========================================================================
-- Version: 2
-- Date: 28/11/2016
-- =========================================================================
-- Changes: 01/11/2016: TT:  Original Version
-- (1)
-- Changes: 28/11/2016: TT:  Added new function reference (FFFFFFD) for 
-- (2)						 Summary Weekly Reminder Email
--
-- ==========================================================================

CREATE PROCEDURE [dbo].[CABS_AEF_DELETE_RECORDS] 
AS
BEGIN	
	SET NOCOUNT ON;

-- =============================================
-- LOCAL DECLARATIONS 
-- =============================================
	DECLARE	@Enabled INT
	DECLARE	@SettingsType VARCHAR(1000)
	DECLARE @Section VARCHAR(1000)
	DECLARE @AgedDays VARCHAR(10)
	DECLARE @DebugFlag VARCHAR(10)

-- =============================================
-- LOCAL DEFAULT SETTINGS
-- =============================================
	SET @Enabled = 0
	SET @SettingsType = 'S' 
	SET @Section = 'CABS_AUTO_EMAIL_FUNCS_Trigger'

-- =============================================
-- GET SETTINGS 
-- =============================================

	SET @DebugFlag = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @Section, 'DebugFlag')), '0')
	
	IF @DebugFlag = 1
	BEGIN
		PRINT '********************************************************************'
		PRINT 'CABS_AEF_DELETE_RECORDS: Entered Procedure CABS_AEF_DELETE_RECORDS'
		PRINT '********************************************************************'
	END	

	SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @Section, 'Enabled')), '0')	

-- =============================================
-- THE WORK
-- =============================================
	IF @Enabled = 0 
	BEGIN
		
		IF @DebugFlag = 1
		BEGIN
			PRINT 'CABS_AEF_DELETE_RECORDS: CABS_AUTO_EMAIL_FUNCS_Trigger Not Enabled'
		END
		RETURN

	END
    
	-- Get the Aged Days confog setting
	SET @AgedDays = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @Section, 'AgedFunctionInDays')), '0')
	IF @DebugFlag = 1
	BEGIN
		PRINT 'CABS_AEF_DELETE_RECORDS: @AgedDays = ' +  @AgedDays
	END

	-- Only if the setting is > 0 - the default is 0 - no deletion of records
	IF @AgedDays > 0
	BEGIN
		IF @DebugFlag = 1
		BEGIN
			PRINT 'CABS_AEF_DELETE_RECORDS: Deleting Records in AEF_LINK'
		END
		
		-- Used for testing and debugging
		--SELECT * FROM AEF_LINK WHERE DATEADD(dd, CONVERT(Int, @AgedDays), AEFL_FDay) < GETDATE() AND AEFL_FREF <> 'FFFFFFF' AND AEFL_FREF <> 'FFFFFFE'
		-- Added new function reference (FFFFFFD) for Summary Weekly Reminder Email - TT - 28/11/2016
		--DELETE AEF_LINK WHERE DATEADD(dd, CONVERT(Int, @AgedDays), AEFL_FDay) < GETDATE() AND AEFL_FREF <> 'FFFFFFF' AND AEFL_FREF <> 'FFFFFFE' 
		DELETE AEF_LINK WHERE DATEADD(dd, CONVERT(Int, @AgedDays), AEFL_FDay) < GETDATE() 
							AND AEFL_FREF <> 'FFFFFFF' 
							AND AEFL_FREF <> 'FFFFFFE' 
							AND AEFL_FREF <> 'FFFFFFD'
	END
	ELSE
	BEGIN
		IF @DebugFlag = 1
		BEGIN
			PRINT 'CABS_AEF_DELETE_RECORDS: Not Deleting Records in AEF_LINK as AgedDays is set to 0 or less'
		END
	END

	IF @DebugFlag = 1
	BEGIN
		PRINT '********************************************************************'
		PRINT 'CABS_AEF_DELETE_RECORDS: Leaving Procedure CABS_AEF_DELETE_RECORDS'
		PRINT '********************************************************************'
	END	
END
GO

PRINT '*****************************************************************************'

PRINT 'CABS_AEF_DELETE_RECORDS: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_DELETE_RECORDS]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_DELETE_RECORDS') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_DELETE_RECORDS: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_DELETE_RECORDS: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_DELETE_RECORDS]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_DELETE_RECORDS') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_DELETE_RECORDS: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_DELETE_RECORDS: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_DELETE_RECORDS]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_DELETE_RECORDS') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_DELETE_RECORDS: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_DELETE_RECORDS: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO