-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'ae_INS_EmailTypes_AEF_Link'
SET @SPROC_Name = 'ae_INS_EmailTypes_AEF_Link'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[ae_INS_EmailTypes_AEF_Link]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].ae_INS_EmailTypes_AEF_Link
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
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================================
-- Author:		Mark Birch
-- Create date: 11-FEB-2015
-- Description:	To Insert Email Types into AEF_Link per booking
-- ===========================================================================================
-- Version: 11
-- Date: 23/03/2017
-- ===========================================================================================
-- Changes: 13/02/2015: MCB: Added Department handling 
-- Changes: 23/02/2015: MCB: Changed the SendTime to use 
--						"dbo.uf_GetEmailSendTime"
-- Changes: 06/03/2015: PLG: Added @EarliestSendDate handling
-- Changes: 13/03/2015: MCB: Changed @Department VARCHAR(MAX)
-- Changes: 27/03/2015: MCB: Check to see if Department already 
--							 exists first
-- Changes: 01/06/2016: TT:  Added ability to use new email 
--							 template specific stored procedure
-- Changes: 01/08/2016: TT:  Added '' to INSERT INTO AEF_LINK ..
--							  to account for new column AEFL_MBRNo
-- Changes: 01/11/2016: TT:  Added GETDATE() to INSERT INTO 
--	(8)						 AEF_LINK .... to account for new column AEFL_LastUpdate 
-- Changes: 16/11/2016: TT:  Do not need to deal with Email Template 
--	(9)						 AEFECC in this procedure
--							 Added field AEFL_FDay = @BookingDateTime to AEF_LINK
--							 update
-- Changes: 24/11/2016: TT:  Do not need to deal with Email Template 
--	(10)					 AEFECC in this procedure
--							 Added code to allow email templates to be enabled
--							 specifically for changes to tables Func_Fil or 
--							 AI_FILE or ACxx update
--							 Added code to ensure that AEFSTC is only processed on 
--							 a status change						
-- Changes: 23/03/2017: TT:  Removed call to stored procedure CABS_CREATE_AUTOEMAILER_TABLES
--	(11)					 as it should not be needed if the build processs is robust
--							 Removed check for table AEF_LINK 	
-- ===========================================================================================
CREATE PROCEDURE [dbo].[ae_INS_EmailTypes_AEF_Link] 
	@BookingNumber VARCHAR(10), @SessionNumber VARCHAR(10), @BookingDateTime DATETIME, @CanSend INT, @Source VARCHAR(50), @Action VARCHAR(1), @Department VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Removed check for table existing - it does - TT - 23/03/2017
	--DECLARE @TableExists INT
	--SET @TableExists = 0

	-- Removed call to CABS_CREATE_AUTOEMAILER_TABLES - TT - 23/03/2017
	--EXEC CABS_CREATE_AUTOEMAILER_TABLES

	-- Removed check for table exisiting - it does - TT - 23/03/2017
	--if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Link]')) = 1
	--BEGIN
	--	SET @TableExists = 1
	--END			

	-- Removed check for table existing - it does - TT - 23/03/2017
	--IF @TableExists = 1
	--BEGIN			
	DECLARE
		@EmailType VARCHAR(6),
		@Enabled INT,			
		@Frequency VARCHAR(1000),
		@SendFrequency VARCHAR(1000),
		@SendMinutes INT,
		@SendDateTime DATETIME,
		@EarliestSendTest Varchar(100),   -- added plg 6-3-15
		@EarliestSendDate DAteTime,   -- added plg 6-3-15
		@EmailSPROC VARCHAR(200) -- 01/06/2016 - TT - Added for New Auto Email Templates
	
	DECLARE
		myCURSOR1
	CURSOR FAST_FORWARD for
		
		SELECT ST_CODE  
		FROM SYS_ABBR		
		-- Do not need to deal with Email Template AEFECC here - TT - 16/11/2016
		WHERE ST_TYPE = 'AET' AND ST_CODE <> 'AEFECC'
		
	OPEN myCURSOR1

	FETCH NEXT FROM
		myCURSOR1
	INTO
		@EmailType

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		--Get SPROC Template Value
		-- 01/06/2016 - TT - Added for New Auto Email Templates
		-- @EmailSPROC will get a template specific stored procedure from X Cabs Config if one exists - the default value will be CABS_AUTO_EMAIL_FUNCS_SEND
		SET @EmailSPROC = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'EmailSPROC')), 'CABS_AUTO_EMAIL_FUNCS_SEND')
		-- Added code to allow email templates to be enabled specifically for changes to tables Func_Fil or AI_FILE or ACxx - TT - 24/11/2016		
		--SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @SYS_EmailType, 'Enabled')), '0')
		--SET @Enabled = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'Enabled')), '0'), @Action))
		SET @Enabled = (SELECT [dbo].[uf_Get_AEF_EnabledSwitch](@EmailType, @Action))
		-- End of changes - TT - 24/11/2016		

		SET @Frequency = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'Frequency')), 'D:1;H:0;M:0')
		SET @SendFrequency = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'SendFrequency')), 'N')
		-- next section    added plg 6-3-15  to test for cutoff dates
		Set @EarliestSendDate = dbo.uf_GetEmailEarlyCutOff(@EmailType, @BookingNumber)
		-- this shoul be OK because the function should return a date even if a setting does not exist
		-- =============================================
		-- GET SEND DATE/TIME
		-- =============================================	
		SET @SendMinutes = (SELECT [dbo].[fn_GetMinsValue]( @Frequency) )
		
		--IF @SendFrequency = 'N' BEGIN
		--	SET @SendDateTime = DATEADD(minute, @SendMinutes, GETDATE())
		--END

		--IF @SendFrequency = 'B' BEGIN
		--	SET @SendDateTime = DATEADD(minute, -@SendMinutes, @BookingDateTime)
		--END	

		SET @SendDateTime = (SELECT dbo.uf_GetEmailSendTime( @EmailType, @BookingNumber))
			
		-- Added code to ensure that AEFSTC is only processed on a status change - TT - 24/11/2016
		-- If Email Template is AEFSTC only want to send this email if the Function Status has changed
		DECLARE @CriteriaOK INT
		-- Initialise variable to do not proceed
		SET @CriteriaOK = 0
		-- If not email template AEFSTC then set flag to proceed
		IF @EmailType <> 'AEFSTC'
		BEGIN 
			SET @CriteriaOK = 1
		END
		-- If email template AEFSTC then only set flag to proceed if the Source from the trigger is'UPDATE:STATUS'
		-- i.e. the status on the booking has changed
		ELSE
		IF @EmailType = 'AEFSTC' AND @Source = 'UPDATE:STATUS'
		BEGIN
			SET @CriteriaOK = 1
		END

		-- Added additional condition to email for AEFSTC	
		--IF (@Enabled > 0) and (DATEDIFF(minute,@earliestSendDate,@Senddatetime) > 0) BEGIN
		IF (@Enabled > 0) and (DATEDIFF(minute,@earliestSendDate,@Senddatetime) > 0 AND @CriteriaOK = 1) BEGIN
		-- End of Changes - TT - 24/11/2016

			IF (SELECT COUNT(*) FROM AEF_Link WHERE AEFL_EMailType = @EmailType AND AEFL_FREF = @BookingNumber) = 0 BEGIN
				INSERT INTO AEF_Link
				-- 01/06/2016 - TT - Email template related stored procedure name (@EmailSPROC)
				-- 01/08/2016 - TT - Added '' to INSERT INTO AEF_LINK .... to account for new column AEFL_MBRNo
				-- 01/11/2016 - TT - Added GETDATE() to INSERT INTO AEF_LINK .... to account for new column AEFL_LastUpdate
				SELECT @BookingNumber, @SessionNumber, @EmailType, @CanSend, @BookingDateTime, 0, @SendDateTime, @Source, @Department, @EmailSPROC, '', GETDATE()
			END	
			ELSE
			IF (SELECT COUNT(*) FROM AEF_Link WHERE AEFL_EMailType = @EmailType AND AEFL_FREF = @BookingNumber) > 0 BEGIN
				UPDATE AEF_Link
				SET AEFL_CanSend = @CanSend,
				AEFL_FDay = @BookingDateTime, -- Added field to Update - TT - 16/11/2016 
				AEFL_SendTime = @SendDateTime,
				AEFL_Sent = 0,
				AEFL_SessNo = @SessionNumber,
				AEFL_SOURCE = COALESCE(@Source, 'UPDATE:MISC'),
				--AEFL_Department = CASE AEFL_Sent WHEN 0 THEN AEFL_Department + @Department WHEN 1 THEN @Department END
				AEFL_Department = CASE AEFL_Sent WHEN 0 THEN 
									CASE (patindex('%'+ @Department +'%', AEFL_Department)) WHEN 0 THEN
										AEFL_Department + @Department
									ELSE
										AEFL_Department
									END
								WHEN 1 THEN @Department END	,
				-- 01/06/2016 - TT - Email template related stored procedure name (@EmailSPROC)
				AEFL_EmailSPROC = @EmailSPROC,
				-- 01/11/2016 - TT - Added GETDATE() to INSERT INTO AEF_LINK .... to account for new column AEFL_LastUpdate
				AEFL_LastUpdate = GETDATE()				
				WHERE AEFL_FREF = @BookingNumber
				AND AEFL_EMailType = @EmailType
			END					
		END
		
		FETCH NEXT FROM 
			myCURSOR1
		INTO
			@EmailType
	END

	CLOSE myCURSOR1
	DEALLOCATE myCURSOR1
	-- Removed check for table existing - it does - TT - 23/03/2017				
	--END --Table Exists
END

GO

PRINT '*****************************************************************************'

PRINT 'ae_INS_EmailTypes_AEF_Link: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link') AND [name] = 'Product')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link') AND [name] = 'Module')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link]
							   ,@name = N'Version' 
							   ,@value = N'11.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link') AND [name] = 'Version')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO