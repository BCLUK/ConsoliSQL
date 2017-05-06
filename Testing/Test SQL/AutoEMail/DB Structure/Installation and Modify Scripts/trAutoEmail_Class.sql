-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

if exists (select * from sys.objects where object_id = object_id(N'[trAutoEmail_Class]') and OBJECTPROPERTY(object_id, N'IsTrigger') = 1)
BEGIN
	DROP TRIGGER [trAutoEmail_Class]
	PRINT 'trAutoEmail_Class: Dropped Trigger [dbo].[trAutoEmail_Class] ON [dbo].[AC07]'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Class: Trigger [dbo].[trAutoEmail_Class] ON [dbo].[AC07] Does Not Exist'
END
PRINT 'trAutoEmail_Class: Creating Trigger [dbo].[trAutoEmail_Class] ON [dbo].[AC07]'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================
-- Author:		Tony Tasker
-- Create date: 03/08/2016
-- Description:	Used to instigate an autoemail 
--				when the AC_CODE is changed
--				Due to the fact that CABS Console
--				deletes and then inserts a record
--				rather than updates it this trigger
--				has to be on an INSERT and not an 
--				UPDATE				
-- ========================================================================
-- Version: 2
-- Date: 11/10/2016
-- ========================================================================
-- Changes: 03/08/2016: TT: Original
-- Changes: 11/10/2016: TT: Added UPDATE to trigger to help with testing
-- ========================================================================
CREATE TRIGGER [dbo].[trAutoEmail_Class] 
   ON  [dbo].[AC07] 
   -- Added UPDATE - TT - 11/10/2016
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- =============================================
-- LOCAL DECLARATIONS 
-- =============================================
	DECLARE
		@Enabled INT,
		@SettingsType VARCHAR(1000),
		@Section VARCHAR(1000),
		@InsertCount INT, 
		@DeleteCount INT

-- =============================================
-- LOCAL DEFAULT SETTINGS
-- =============================================
	SET @Enabled = 0
	SET @SettingsType = 'S' 
	SET @Section = 'CABS_AUTO_EMAIL_MBR_Trigger'
	
-- =============================================
-- DECLARATIONS 
-- =============================================

	DECLARE @Action VARCHAR(1)
	DECLARE @Source VARCHAR(20)
	DECLARE @CanSend INT	
	DECLARE @AC_CODE VARCHAR(7)	
	DECLARE @AC_OWNER VARCHAR(7)
	DECLARE @BookingDateTime DATETIME

-- =============================================
-- GET SETTINGS 
-- =============================================
	SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @Section, 'Enabled')), '0')
-- =============================================
-- THE WORK
-- =============================================
	IF @Enabled = 0 BEGIN
		RETURN
	END
	
	-- Check record change counts 
	SET @InsertCount = (SELECT COUNT(*) FROM INSERTED)
	
	-- Check if a record update - if not return		
	IF (@InsertCount > 0) 
	BEGIN --Update Check		
		SET @Action = 'I'		
		SET @Source = 'Insert'
		SET @CanSend = 1
	END
	ELSE
		RETURN

	-- Create a cursor to run through all inserted records 
	-- (although there should only be one)
	DECLARE
		UpdatedRec
	CURSOR FAST_FORWARD FOR
		-- Get the MBR No (AC_OWNER) and the code for the new 
		-- Event co-ordinator
		SELECT AC_OWNER, AC_CODE 
			FROM INSERTED	
		
	OPEN UpdatedRec

	FETCH NEXT FROM
		UpdatedRec
	INTO
		@AC_OWNER,
		@AC_CODE		

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Get what maybe an MBR_NO (Could also be a client/contact no)	
		-- If MBR_NO does not start with an M then check next record
		IF SUBSTRING(@AC_OWNER, 1, 1) <> 'M'
		BEGIN
			FETCH NEXT FROM 
				UpdatedRec
			INTO
				@AC_OWNER,
				@AC_CODE	
			CONTINUE
		END
		
		-- Build source string include th eold and new EC code
		SET @Source = 'INSERT:EC-' + @AC_CODE
		-- Set booking date to MBR start date time
		SET @BookingDateTime = (SELECT MBR_FROM FROM MBRFILE WHERE MBR_SYSNO = @AC_OWNER )
		-- Call sproc to insert data into table aef_link
		EXECUTE ae_INS_EmailTypes_AEF_Link_MBR @BookingDateTime, @CanSend, @Source, @Action, @AC_OWNER

		FETCH NEXT FROM 
			UpdatedRec
		INTO
			@AC_OWNER,
			@AC_CODE	
	END

	CLOSE UpdatedRec
	DEALLOCATE UpdatedRec

-- =============================================
-- THE END
-- =============================================

END
GO

PRINT '*****************************************************************************'								   
PRINT 'trAutoEmail_Class: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AC07]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Class]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Class') AND [name] = 'Product')
BEGIN		
	PRINT 'trAutoEmail_Class: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Class: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AC07]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Class]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Class') AND [name] = 'Module')
BEGIN		
	PRINT 'trAutoEmail_Class: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Class: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [AC07]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Class]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Class') AND [name] = 'Version')
BEGIN		
	PRINT 'trAutoEmail_Class: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Class: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
