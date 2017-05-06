-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AUTO_EMAIL_FUNCS'
SET @SPROC_Name = 'CABS_AUTO_EMAIL_FUNCS'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AUTO_EMAIL_FUNCS]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS]
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

CREATE PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS] @FromTrigger INT = 0, @FunctionRef VARCHAR(7) = '', 
											  @DetailHeading_Alt VARCHAR(1000) = '', @DetailSubHeading_Alt VARCHAR(1000) = '', 
											  @EmailHeaderText_Alt VARCHAR(1000) = '', @EmailSubTitle_Alt VARCHAR(1000) = '', 
											  @IncOtherSession INT = 0, @Department VARCHAR(1000) = '', @EmailSPROC VARCHAR(200) = '', 
											  @EmailTemplate VARCHAR(100) = '', @SubjectLine_Alt VARCHAR(1000) = '', 
											  @SendToHost_Alt VARCHAR(1000) = '', @SendToDepartment_Alt VARCHAR(1000) = '',
											  @SendToBooker_Alt VARCHAR(1000) = '', @EmailBodyText_Alt VARCHAR(1000) = '',
											  @EmailSalut_Alt VARCHAR(1000) = '', @EmailSignature_Alt VARCHAR(1000) = ''
AS
BEGIN
	-- ====================================================================================================
	-- Author:		Mark Birch
	-- Create date: 27-OCT-2010
	-- Description:	Gathers all Function Details to
	-- ====================================================================================================
	-- Version: 5
	-- Date: 23/03/2017
	-- ====================================================================================================
	-- Changes: MCB: 06-JUL-2011: Added IncludeWeekends Handling
	-- Changes: MCB: 20-DEC-2012: Changed Select Statement
	-- Changes: MCB: 21-MAR-2013: Added @CreateDayCutOff Handling
	-- Changes: MCB: 08-APR-2013: Created/Added SPROC to Create AutoEmailFunction Table
	-- Changes: MCB: 15-APR-2013: Added Weekend Booking and Send Handling
	-- Changes: MCB: 22-MAY-2013: Change Extra Email SQL
	-- Changes: MCB: 24-JUN-2013: Passed through @SP_TRG	
	-- Changes: MCB: 24-JUN-2013: Added @LayoutNumber
	-- Changes: MCB: 28-AUG-2013: Handled apostrophe in Company Name
	-- Changes: MCB: 04-SEP-2013: Handled apostrophe in Company Name
	-- Changes: MCB: 04-SEP-2013: Handled apostrophe in Room Name	
	-- Changes: MCB: 15-JAN-2014: Set Default For @EmailFooterText
	-- Changes: MCB: 17-JAN-2014: Added From Trigger Handling
	-- Changes: MCB: 31-MAR-2014: Added HideRoom Handling
	-- Changes: MCB: 29-JUL-2014: Added Additional HideRoom Handling based on RoomGiven
	-- Changes: MCB: 15-AUG-2014: Added Alt Details
	-- Changes: MCB: 15-AUG-2014: Added Session Number
	-- Changes: MCB: 20-AUG-2014: Added IncludeSubjectInBody
	-- Changes: MCB: 20-AUG-2014: Added IncludeHostMBRNo	
	-- Changes: MCB: 20-AUG-2014: Added IncludeHostMBRTel
	-- Changes: MCB: 20-AUG-2014: Added IncludeSessNo	
	-- Changes: MCB: 20-AUG-2014: Added IncludeBookingStatus	
	-- Changes: MCB: 20-AUG-2014: Added HiddenRoomText	
	-- Changes: MCB: 20-AUG-2014: Added IncludeBookerMBRNo		
	-- Changes: MCB: 20-AUG-2014: Added IncludeBookerName			
	-- Changes: MCB: 20-AUG-2014: Added IncludeBookerMBRTel
    -- Changes: MCB: 22-AUG-2014: Added @IncOtherSession
    -- Changes: MCB: 22-SEP-2014: Set @Now to get date from new Function
	-- Changes: MCB: 23-SEP-2014: Use a Function Now to get local time as @Now    
	-- Changes: MCB: 23-SEP-2014: Added @UseMBRInternForNames   
	-- Changes: MCB: 25-SEP-2014: Added @UseJobTitleForMBRIntern
	-- Changes: MCB: 07-OCT-2014: Removed Duplicate 'AND' from Select statement
	-- Changes: MCB: 18-NOV-2014: Handled Apostrophe in Purpose field
	-- Changes: MCB: 20-NOV-2014: Handled Apostrophe in MBR fields	
	-- Changes: MCB: 24-NOV-2014: Handled Apostrophe in MBR fields Update	
	-- Changes: MCB: 01-DEC-2014: Changed the following to VARCHAR(MAX) to alleviate incorrect syntax issue:
								--@EmailTitle
								--@EmailSubTitlef
								--@DetailHeading
								--@DetailSubHeading
	-- Changes: MCB: 15-DEC-2014: Handled NULL Values for Booker Text								
	-- Changes: MCB: 16-DEC-2014: Changed FromTrigger SQL to allow for re-sends of Emails already been sent. 
	-- Changes: MCB: 19-DEC-2014: Added @IncludeMeetingType handling	
	-- Changes: MCB: 11-MAR-2015: Added Drink Trolley Value into AutoEmailFunction Table
	-- Changes: TT:  01/06/2016:  Added new parameters @EmailSPROC which contains name of email template 
	--							  specific stored procedure and 
	--							  @EmailTemplate which contains the name of the Email Template
	--							  @SubjectLine_Alt which contains the email template specific subject line
	--							  @SendToHost_Alt which contains the email template specific send to host
	--							  setting
	--							  @SendToDepartment_Alt which contains the email template specific send to 
	--							  department setting
	--							  @SendToBooker_Alt which contains the email template specific send to
	--							   booker setting
	--							  @EmailBodyText_Alt which contains the email template specific body text
	-- Changes: TT: 08/06/2016:   Converted call to CABS_AUTO_EMAIL_FUNCS_SEND to Dynamic SQL to enable 
	--							  calls to different Email Templates
	--  						  Added code to deal with new recurring emails (EmailTemplates AEFUPE, 
	--							  AEFUIE)
	-- Changes: TT: 20/06/2016:   Added Debug Flag in X CABS Config to aid testing	
	-- Changes: TT: 29/06/2016:   Added/amended debugging information to aid testing
	-- Changes: TT: 05/07/2016:   Added new parameters in code @EmailSalut_Alt, @EmailSignature_Alt
	--  (1)
	-- Changes: TT: 22/11/2016:   Increased the size of @SQL0 from 1000 to 2000
	--  (2)	
	-- Changes: TT: 28/11/2016:   Added code to handle new recurring email (AEFSWR) with table 
	--  (3)						  autoemailfunction	
	--
	-- Changes: TT: 06/03/2017:   Added additional diagnostic information around the code tthat inserts
	--	(4)						  a record into table AutoEmailFunction
	--
	--							  At the end of the stored procedure added code to ensure that if table 
	--							  AutoEmailFunction contained a record for the current Function Ref then 
	--							  it is deleted	
	--
	-- Changes: TT: 23/03/2017:   Removed call to stored procedure CABS_CREATE_AUTOEMAILER_TABLES as it 
	--	(5)						  should not be needed if the build processs is robust
	--							  
	-- ====================================================================================================

	SET NOCOUNT ON;
-- =============================================
-- CABS CONFIGURATION - GENERIC
-- =============================================
-- =============================================
-- OBJECT HEADER
-- =============================================
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'CABS_AUTO_EMAIL_FUNCS' --The Object Name

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) = 0 -- Object Doesn't Exist; Run As Normal
	BEGIN -- No Settings Begin
		PRINT 'CABS_AUTO_EMAIL_FUNCS: No CABS_AUTO_EMAIL_FUNCS sectionin X CABS CONFIG' -- Added - TT - 29/09/2016
		RETURN
	END -- No Settings End
	ELSE
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) > 0 -- Object Exists; Settings to Consider
	BEGIN --Settings Begin
-- =============================================
-- Dev Overide - Manually run through SQL:
-- See The Settings but DO NOT Send Email
-- =============================================
		DECLARE @DevOverride VARCHAR(1000)
		SET @DevOverride = 0
-- =============================================
-- Set Type of Settings
-- =============================================		
		DECLARE @SettingsType VARCHAR(10)
		SET @SettingsType = 'S' 
-- =============================================
-- DECLARATIONS
-- =============================================
		DECLARE
		  @StatusCode VARCHAR(1000), @EmailProfile VARCHAR(1000), @Company VARCHAR(1000)  
		, @AdminSubjectLine VARCHAR(1000), @Enabled VARCHAR(1000), @AdminEmailAddr VARCHAR(1000), @EmailFormat VARCHAR(1000)
		, @SubjectLine VARCHAR(1000), @SubjectLineText VARCHAR(1000), @EmailTitle VARCHAR(MAX), @EmailSubTitle VARCHAR(MAX), @EmailSalut VARCHAR(MAX)
		, @EmailSignature VARCHAR(1000), @DetailHeading VARCHAR(MAX), @DetailSubHeading VARCHAR(MAX), @SendToBooker VARCHAR(1000), @SendToHost VARCHAR(1000)
		, @Bullet01 VARCHAR(1000), @Bullet02 VARCHAR(1000), @EmailLink01_Address VARCHAR(1000), @EmailLink02_Address VARCHAR(1000), @CurrencySymbol VARCHAR(1000)
		, @IncludeWeekends VARCHAR(1000), @Importance VARCHAR(1000), @Sensitivity VARCHAR(1000), @IncludeAttachments VARCHAR(1000) , @FileAttachments VARCHAR(1000)
		, @AddHostToSubject VARCHAR(1000), @AddFuncRefToSubject VARCHAR(1000), @Frequency VARCHAR(1000), @OnlyIncludeAssignedExtras VARCHAR(1000)
		, @ExtraCCToInclude VARCHAR(1000), @FirstRunDate VARCHAR(1000), @EmailType VARCHAR(1000), @EmailHeaderText VARCHAR(1000), @EmailFooterText VARCHAR(1000)
		, @LocEmailAddress VARCHAR(1000), @EmailTitleFontColor VARCHAR(1000), @EmailTitleFontSize VARCHAR(1000), @EmailTitleFontType VARCHAR(1000), @EmailTitleFontWeight VARCHAR(1000)
		, @EmailSubTitleFontColor VARCHAR(1000), @EmailSubTitleFontSize VARCHAR(1000), @EmailSubTitleFontType VARCHAR(1000), @EmailSubTitleFontWeight VARCHAR(1000), @EmailSalutFontColor VARCHAR(1000)
		, @EmailSalutFontSize VARCHAR(1000), @EmailSalutFontType VARCHAR(1000), @EmailSalutFontWeight VARCHAR(1000), @EmailSignatureFontColor VARCHAR(1000), @EmailSignatureFontSize VARCHAR(1000)
		, @EmailSignatureFontType VARCHAR(1000), @EmailSignatureFontWeight VARCHAR(1000), @DetailHeadingFontColor VARCHAR(1000), @DetailHeadingFontSize VARCHAR(1000), @DetailHeadingFontType VARCHAR(1000)
		, @DetailHeadingFontWeight VARCHAR(1000), @DetailSubHeadingFontColor VARCHAR(1000), @DetailSubHeadingFontSize VARCHAR(1000), @DetailSubHeadingFontType VARCHAR(1000), @DetailSubHeadingFontWeight VARCHAR(1000)
		, @EmailHeaderTextFontColor VARCHAR(1000), @EmailHeaderTextFontSize VARCHAR(1000), @EmailHeaderTextFontType VARCHAR(1000), @EmailHeaderTextFontWeight VARCHAR(1000), @EmailFooterTextFontColor VARCHAR(1000)
		, @EmailFooterTextFontSize VARCHAR(1000), @EmailFooterTextFontType VARCHAR(1000), @EmailFooterTextFontWeight VARCHAR(1000), @EmailBodyFontColor VARCHAR(1000), @EmailBodyFontSize VARCHAR(1000)
		, @EmailBodyFontType VARCHAR(1000), @EmailBodyFontWeight VARCHAR(1000), @AttachCalendarFile VARCHAR(1000), @IncludeOtherSessionDetails VARCHAR(1000), @SendOnWeekends VARCHAR(1000)
		, @EmailLink01_DisplayText VARCHAR(1000), @EmailLink02_DisplayText VARCHAR(1000), @LayoutNumber VARCHAR(1000), @HideRoom VARCHAR(1000), @HideRoomGivenOverride VARCHAR(1000)
		, @IncludeSubjectInBody VARCHAR(1000), @IncludeHostMBRNo VARCHAR(1000), @IncludeHostMBRTel VARCHAR(1000), @IncludeSessNo VARCHAR(1000), @IncludeBookingStatus VARCHAR(1000), @HiddenRoomText VARCHAR(1000)
		, @IncludeBookerMBRNo VARCHAR(1000), @IncludeBookerName VARCHAR(1000), @IncludeBookerMBRTel VARCHAR(1000)
		, @UseMBRInternForNames VARCHAR(1000)
		, @UseJobTitleForMBRIntern VARCHAR(1000)
		, @IncludeMeetingType VARCHAR(1000) 
		, @SendToDepartment VARCHAR(1000)
		, @DeptIncludeMailList VARCHAR(1000)
		, @DeptExcludeMailList VARCHAR(1000)
		, @EmailBodyFontColorDel VARCHAR(1000)
		, @EmailBodyFontSizeDel VARCHAR(1000)
		, @EmailBodyFontTypeDel VARCHAR(1000)
		, @EmailBodyFontWeightDel VARCHAR(1000)
		, @EmailBodyText VARCHAR(1000) -- TT - 08/06/2016 - Added for EMail template specific settings
		, @DebugFlag INT -- TT - 20/06/2016 - Added to enable debugging code to be activated from X CABS Config
-- =============================================
-- GET SETTINGS
-- =============================================

		SET @DebugFlag = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DebugFlag')), '0')  -- Added by TT - 20/06/2016
		-- If X CABS Config setting Debug Flag is set (in section CABS_AUTO_EMAIL_FUNCS section) then activate debugging info - TT - 28/06/2016
		IF @DebugFlag = 1
			SET @DevOverride = 1
			
		IF @DevOverride = 1
		BEGIN
			PRINT '**************************************************************'
			PRINT 'CABS_AUTO_EMAIL_FUNCS: Entered Procedure CABS_AUTO_EMAIL_FUNCS' -- Amended TT - 29/06/2016					
			PRINT '**************************************************************'
		END			

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = @SettingsType AND SECTION = @SP_TRG AND [KEY] = 'FirstRunDate') = 0
		BEGIN
			SET @FirstRunDate = (CONVERT(VARCHAR(11), (GETUTCDATE()), 103))
			
			INSERT INTO xCABS_CONFIG_TABLE
			([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
			VALUES
			(@SettingsType, '', @SP_TRG, 'FirstRunDate', @FirstRunDate, 0, 'INS', GETUTCDATE()) 
		END
		ELSE
			SET @FirstRunDate = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'FirstRunDate')), '')

		/* 
			Added to code to read and test if functionality is enabled
			If not then no need to process other settings - TT - 20/06/2016
		*/
		SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Enabled')), '1')
		IF @Enabled = '0'
		BEGIN
			IF @DebugFlag = 1 PRINT 'CABS_AUTO_EMAIL_FUNCS: Functionality not Enabled in X CABS Config' -- Added by TT - 28/06/2016
			RETURN 
		END
		
		/*
			End of Enabled check changes - TT - 20/06/2016 
		*/

		SET @StatusCode = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'StatusCode')), 'CONFRM')
		SET @EmailProfile = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailProfile')), '')
		SET @Company = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Company')), '')
		SET @Frequency = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Frequency')), 'D:1;H:0;M:0')
		-- SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Enabled')), '1') Moved to start of procedure - TT - 20/06/2016
		SET @AdminEmailAddr = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'AdminEmailAddr')), '')
		SET @EmailFormat = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFormat')), 'HTML')
		SET @SubjectLine = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SubjectLine')), 'Function Request :')
		SET @EmailTitle = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailTitle')), 'Reminder Alert')
		SET @EmailSubTitle = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitle')), 'You have requested a booking')
		SET @EmailSalut = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSalut')), 'Kind regards')
		SET @EmailSignature = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSignature')), 'Corporate Hospitality')
		SET @DetailHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeading')), 'Please make sure all details of the booking below are correct')
		SET @DetailSubHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeading')), '')
		SET @SendToBooker = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SendToBooker')), '1')
		SET @SendToHost = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SendToHost')), '1')
		SET @Bullet01 = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Bullet01')), '')
		SET @Bullet02 = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Bullet02')), '')
		SET @EmailLink01_Address = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailLink01_Address')), '')
		SET @EmailLink02_Address = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailLink02_Address')), '')
		SET @CurrencySymbol = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'CurrencySymbol')), '£')
		SET @IncludeWeekends = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeWeekends')), '0')
		SET @Importance = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Importance')), 'Normal')
		SET @Sensitivity = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Sensitivity')), 'Normal')
		SET @IncludeAttachments = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeAttachments')), '0')
		SET @FileAttachments = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'FileAttachments')), '')
		SET @AddHostToSubject = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'AddHostToSubject')), '1')
		SET @OnlyIncludeAssignedExtras = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'OnlyIncludeAssignedExtras')), '0')
		SET @ExtraCCToInclude = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'ExtraCCToInclude ')), '')
		SET @EmailType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailType')), 'S')
		SET @EmailHeaderText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderText')), '')
		SET @EmailFooterText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFooterText')), '')
		SET @EmailTitleFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailTitleFontColor')), 'Black')
		SET @EmailTitleFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailTitleFontSize')), '10')
		SET @EmailTitleFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailTitleFontType')), 'Arial')
		SET @EmailTitleFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailTitleFontWeight')), 'Normal')
		SET @EmailSubTitleFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitleFontColor')), 'Black')
		SET @EmailSubTitleFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitleFontSize')), '10')
		SET @EmailSubTitleFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitleFontType')), 'Arial')
		SET @EmailSubTitleFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitleFontWeight')), 'Normal')
		SET @EmailSalutFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSalutFontColor')), 'Black')
		SET @EmailSalutFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSalutFontSize')), '10')
		SET @EmailSalutFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSalutFontType')), 'Arial')
		SET @EmailSalutFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSalutFontWeight')), 'Normal')
		SET @EmailSignatureFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSignatureFontColor')), 'Black')
		SET @EmailSignatureFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSignatureFontSize')), '10')
		SET @EmailSignatureFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSignatureFontType')), 'Arial')
		SET @EmailSignatureFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSignatureFontWeight')), 'Normal')
		SET @DetailHeadingFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeadingFontColor')), 'Black')
		SET @DetailHeadingFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeadingFontSize')), '10')
		SET @DetailHeadingFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeadingFontType')), 'Arial')
		SET @DetailHeadingFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeadingFontWeight')), 'Normal')
		SET @DetailSubHeadingFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeadingFontColor')), 'Black')
		SET @DetailSubHeadingFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeadingFontSize')), '10')
		SET @DetailSubHeadingFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeadingFontType')), 'Arial')
		SET @DetailSubHeadingFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeadingFontWeight')), 'Normal')
		SET @EmailHeaderTextFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderTextFontColor')), 'Black')
		SET @EmailHeaderTextFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderTextFontSize')), '10')
		SET @EmailHeaderTextFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderTextFontType')), 'Arial')
		SET @EmailHeaderTextFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderTextFontWeight')), 'Normal')
		SET @EmailFooterTextFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFooterTextFontColor')), 'Black')
		SET @EmailFooterTextFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFooterTextFontSize')), '10')
		SET @EmailFooterTextFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFooterTextFontType')), 'Arial')
		SET @EmailFooterTextFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailFooterTextFontWeight')), 'Normal')
		SET @EmailBodyFontColor = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontColor')), 'Black')
		SET @EmailBodyFontSize = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontSize')), '10')
		SET @EmailBodyFontType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontType')), 'Arial')
		SET @EmailBodyFontWeight = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontWeight')), 'Normal')
		SET @AddFuncRefToSubject = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'AddFuncRefToSubject')), '1')
		SET @AttachCalendarFile = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'AttachCalendarFile')), '0')
		SET @IncludeOtherSessionDetails = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeOtherSessionDetails')), '0')
		SET @SendOnWeekends = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SendOnWeekends')), '1')
		SET @EmailLink01_DisplayText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailLink01_DisplayText')), '')
		SET @EmailLink02_DisplayText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailLink02_DisplayText')), '')
		SET @LayoutNumber = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'LayoutNumber')), '1')
		SET @HideRoom = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'HideRoom')), '0')
		SET @HideRoomGivenOverride = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'HideRoomGivenOverride')), '0')
		SET @IncludeSubjectInBody = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeSubjectInBody')), '1')
		SET @IncludeHostMBRNo = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeHostMBRNo')), '1')
		SET @IncludeHostMBRTel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeHostMBRTel')), '1')
		SET @IncludeSessNo = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeSessNo')), '1')
		SET @IncludeBookingStatus = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeBookingStatus')), '1')
		SET @HiddenRoomText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'HiddenRoomText')), 'To Be Advised')
		SET @IncludeBookerMBRNo = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeBookerMBRNo')), '0')
		SET @IncludeBookerName = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeBookerName')), '0')
		SET @IncludeBookerMBRTel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeBookerMBRTel')), '0')
		SET @UseMBRInternForNames = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'UseMBRInternForNames')), '0')
		SET @UseJobTitleForMBRIntern = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'UseJobTitleForMBRIntern')), '0')
		SET @IncludeMeetingType = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'IncludeMeetingType')), '1')			
		SET @SendToDepartment = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SendToDepartment')), '0')		
		SET @DeptIncludeMailList = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DeptIncludeMailList')), '')				
		SET @DeptExcludeMailList = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DeptExcludeMailList')), '')
		SET @EmailBodyFontColorDel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontColorDel')), 'Black')
		SET @EmailBodyFontSizeDel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontSizeDel')), '10')
		SET @EmailBodyFontTypeDel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontTypeDel')), 'Arial')
		SET @EmailBodyFontWeightDel = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailBodyFontWeightDel')), 'Normal')					

-- ===================================================
-- Can I run
-- =================================================== 
		IF @Enabled = '0'
		BEGIN
			RETURN 
		END
		ELSE
		IF @Enabled = '1'
		BEGIN --Can I run 
-- =============================================
-- Create AutoEmailer Table
-- =============================================
			-- Removed call to CABS_CREATE_AUTOEMAILER_TABLES - TT - 23/03/2017
			-- EXEC CABS_CREATE_AUTOEMAILER_TABLES
			
			DECLARE @SQL varchar (MAX), -- TT - 07/06/2016 - Changed varchar(4000) to varchar(MAX)
					@ESQL varchar (4000),
				@StatusInClause varchar(50)
			SET @StatusInClause = @StatusCode
			
			DECLARE @WeekendSQL VARCHAR(4000)
			SET @WeekendSQL = ''
			
			IF @IncludeWeekends = 0
			BEGIN
				SET @WeekendSQL = ' AND NOT DATEPART(dw, F_DAY) IN(1, 7) '
			END
			
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: @IncludeWeekends = ' + @IncludeWeekends -- Amended by TT - 28/06/2016
			END
			
			IF @FromTrigger = 1
			BEGIN
				IF COALESCE(@DetailHeading_Alt, '') <> '' 				
					SET @DetailHeading = @DetailHeading_Alt				

				IF COALESCE(@DetailSubHeading_Alt, '') <> '' 				
					SET @DetailSubHeading = @DetailSubHeading_Alt				

				IF COALESCE(@EmailHeaderText_Alt, '') <> '' 				
					SET @EmailHeaderText = @EmailHeaderText_Alt

				IF COALESCE(@EmailSubTitle_Alt, '') <> '' 				
					SET @EmailSubTitle = @EmailSubTitle_Alt
					
				IF COALESCE(@SubjectLine_Alt, '') <> ''
					SET @SubjectLine = @SubjectLine_Alt

				IF COALESCE(@SendToHost_Alt, '') <> ''
					SET @SendToHost = @SendToHost_Alt

				IF COALESCE(@SendToDepartment_Alt, '') <> ''
					SET @SendToDepartment = @SendToDepartment_Alt
				
				IF COALESCE(@SendToBooker_Alt, '') <> ''
					SET @SendToBooker = @SendToBooker_Alt

				IF COALESCE(@EmailBodyText_Alt, '') <> ''
					SET @EmailBodyText = @EmailBodyText_Alt

				-- Added - TT - 05/07/2016
				IF COALESCE(@EmailSalut_Alt, '') <> ''
					SET @EmailSalut = @EmailSalut_Alt

				IF COALESCE(@EmailSignature_Alt, '') <> ''
					SET @EmailSignature = @EmailSignature_Alt
				-- End of changes - TT - 05/07/2016
											  										  			
  			END

			IF @FromTrigger = 1
			BEGIN
				-- Added code new recurring email to if clause - AEFSWR - TT - 28/11/2016
				-- Added code to update a different record to AutoEmailFunction for Recurring Emails - TT - 17/06/2016
				-- These emails are used for regular sent "report" type emails - sent weekly
				IF @EmailTemplate = 'AEFUIE' OR @EmailTemplate = 'AEFUPE' OR @EmailTemplate = 'AEFSWR'
				BEGIN
					SET @SQL = 'IF(SELECT COUNT(*) FROM AutoEmailFunction WHERE AEF_FUNC_REF = ' + CHAR(39) + @FunctionRef + CHAR(39) + ') = 0
								BEGIN
									INSERT INTO AutoEmailFunction
										(AEF_FUNC_REF, AEF_DATE, AEF_SESSNO, AEF_CANSEND, AEF_SENT, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER)							
										SELECT AEFL_FREF, AEFL_FDAY, AEFL_SESSNO, 
											CASE AEFL_CanSend 
												WHEN 1 THEN ' + CHAR(39) + 'Yes' + CHAR(39) + 
												' ELSE ' + CHAR(39) + 'No' + CHAR(39) + ' END, 
												AEFL_SENT, GETUTCDATE(), NULL, 1 
										FROM vw_AEFLink
										WHERE AEFL_FREF = ' + CHAR(39) + @FunctionRef + CHAR(39)  +					
								'END '					
				END
				ELSE
					SET @SQL = '
						IF(SELECT COUNT(*) FROM AutoEmailFunction WHERE AEF_FUNC_REF = ' + '''' + @FunctionRef + '''' + ') = 0
						BEGIN
							INSERT INTO AutoEmailFunction 
							SELECT F_REF, F_STATUS, '''', F_ROOM, '''', F_USE, '''', REPLACE(F_COMMENT, CHAR(39), CHAR(146)), F_BOOKER, '''', '''', F_DAY, F_START, F_END, F_SETUP, F_BDOWN, F_PAX_ACT, F_MBR_NO, REPLACE(F_MBR_NAME, CHAR(39), CHAR(146)), MBR_CONTCT, MBR_EMAIL, MBR_CEMAIL, F_INTERN, 0, 0, 0, F_RMGIVEN, F_SESSNO, F_STARTDATETIME, ''Yes'', 0, '''', GETUTCDATE(), NULL, 1, 0 
							FROM FUNC_FIL, ROOMS, MBRFILE
							WHERE MBR_SYSNO = F_MBR_NO ' + 
							'AND NOT F_REF in(SELECT AEF_FUNC_REF FROM AutoEmailFunction)' +
							'AND ( F_OWNER IS NULL OR F_OWNER = '''' OR F_OWNER = F_REF )' +
							'AND F_ROOM = RM_ABBR ' +
							'AND F_REF = ' + '''' + @FunctionRef + '''' +
						'END '

				--Removed 20/08/14 For Testing
				--AND NOT F_SESSNO in(SELECT AEF_SESSNO FROM AutoEmailFunction) AND NOT F_SESSNO in(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger)
			END								

			IF @FromTrigger = 0						
			BEGIN
				IF @EmailType = 'E'
				BEGIN
					SET @ESQL = ' AND F_REF in(SELECT AI_FREF FROM AI_FILE)'	
					SET @SQL = (@SQL + @ESQL)
				END
			END	
		
			-- Added Additional Diagnostic Information - TT - 06/03/2017
			DECLARE @NORECS INT	
			SET @NORECS = (SELECT COUNT(*) FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FunctionRef)
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: @FromTrigger = ' + CAST(@FromTrigger AS VARCHAR(10))
				PRINT 'CABS_AUTO_EMAIL_FUNCS: AutoEMailFunction SQL:  @SQL = ' + @SQL 
						
				IF @NORECS = 0
					PRINT 'CABS_AUTO_EMAIL_FUNCS: @NORECS = ' + CAST(@NORECS AS VARCHAR(10)) + ' - New Record WILL be Inserted into Table AutoEMailFunction'
				ELSE
					PRINT 'CABS_AUTO_EMAIL_FUNCS: @NORECS = ' + CAST(@NORECS AS VARCHAR(10)) + ' - Record Already Exists - New Record WILL NOT be Inserted into Table AutoEMailFunction !' 
				
			END
			-- End of changes - 06/03/2017

			EXEC ( @SQL )
-- =========================================
-- Set Hidden Room Text
-- =========================================
			SET @HiddenRoomText = (SELECT [dbo].[fn_GetHiddenRoomText](@HiddenRoomText, @Frequency))
			
			-- Added DynamicSQL to reduce size of code
			-- @EmailSPROC and @EmailTemplate are passed in parameters from calling procedure
			-- 08/06/2016 - TT

			SET CONCAT_NULL_YIELDS_NULL OFF -- TT - 08/06/2016 - Added to convert NULLS to empty string in following concatenation

			-- Used to split the dynamic sql string into several smaller strings for easier debugging - TT - 28/06/2016
			-- Incresed the size of @SQL0 from 1000 to 2000 - TT - 22/11/2016
			DECLARE @SQL0 VARCHAR(2000), 
					@SQL1 VARCHAR(1000),
					@SQL2 VARCHAR(1000),
					@SQL3 VARCHAR(1000), 
					@SQL4 VARCHAR(1000), 
					@SQL5 VARCHAR(1000), 
					@SQL6 VARCHAR(1000), 
					@SQL7 VARCHAR(1000), 
					@SQL8 VARCHAR(1000), 
					@SQL9 VARCHAR(1000)

			SET @SQL0 =	'EXEC ' + @EmailSPROC + ' '  + CHAR(39) + @StatusCode  + CHAR(39) + ',' + CHAR(39) + @EmailProfile + CHAR(39) + ',' + 
						CHAR(39) + @Company  + CHAR(39) + ','  + CHAR(39) + @Enabled  + CHAR(39) + ',' + 
						CHAR(39) + @AdminEmailAddr + CHAR(39) + ',' + CHAR(39) + @EmailFormat + CHAR(39) + ',' + 
						CHAR(39) + @SubjectLine + CHAR(39) + ',' + CHAR(39) + @SubjectLineText + CHAR(39) + ',' + 
						CHAR(39) + @EmailTitle + CHAR(39) + ',' + CHAR(39) + @EmailSubTitle  + CHAR(39) + ',' + 
						CHAR(39) + @EmailSalut  + CHAR(39) + ',' + CHAR(39) + @EmailSignature + CHAR(39) + ',' + 
						CHAR(39) + @DetailHeading + CHAR(39) + ',' + CHAR(39) + @DetailSubHeading + CHAR(39) + ','

			SET @SQL1 = CHAR(39) + @SendToBooker  + CHAR(39) + ',' + CHAR(39) + @SendToHost + CHAR(39) + ',' + 
						CHAR(39) + @Bullet01 + CHAR(39) + ',' + CHAR(39) + @Bullet02 + CHAR(39) + ',' + 
						CHAR(39) + @EmailLink01_Address + CHAR(39) + ',' + CHAR(39) + @EmailLink02_Address + CHAR(39) + ',' + 
						CHAR(39) + @CurrencySymbol + CHAR(39) + ',' + CHAR(39) + @IncludeWeekends + CHAR(39) + ',' + 
						CHAR(39) + @Importance + CHAR(39) + ',' + CHAR(39) + @Sensitivity + CHAR(39) + ',' + 
						CHAR(39) + @IncludeAttachments + CHAR(39) + ',' + CHAR(39) + @FileAttachments + CHAR(39) + ',' + 
						CHAR(39) + @AddHostToSubject + CHAR(39) + ',' + CHAR(39) + @DevOverride + CHAR(39) + ','

			SET @SQL2 = CHAR(39) + @OnlyIncludeAssignedExtras + CHAR(39) + ',' + CHAR(39) + @ExtraCCToInclude + CHAR(39) + ',' + 
						CHAR(39) + @FirstRunDate + CHAR(39) + ',' + CHAR(39) + @EmailType + CHAR(39) + ',' + 
						CHAR(39) + @EmailHeaderText + CHAR(39) + ',' + CHAR(39) + @EmailFooterText + CHAR(39) + ',' +
						CHAR(39) + @LocEmailAddress + CHAR(39) + ',' + CHAR(39) + @EmailTitleFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailTitleFontSize + CHAR(39) + ',' + CHAR(39) + @EmailTitleFontType + CHAR(39) + ',' + 
						CHAR(39) + @EmailTitleFontWeight + CHAR(39) + ',' + CHAR(39) + @EmailSubTitleFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailSubTitleFontSize + CHAR(39) + ',' + CHAR(39) + @EmailSubTitleFontType + CHAR(39) + ','

			SET @SQL3 =	CHAR(39) + @EmailSubTitleFontWeight + CHAR(39) + ',' + CHAR(39) + @EmailSalutFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailSalutFontSize + CHAR(39) + ',' + CHAR(39) + @EmailSalutFontType + CHAR(39) + ',' + 
						CHAR(39) + @EmailSalutFontWeight + CHAR(39) + ',' + CHAR(39) + @EmailSignatureFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailSignatureFontSize + CHAR(39) + ',' + CHAR(39) + @EmailSignatureFontType + CHAR(39) + ',' + 
						CHAR(39) + @EmailSignatureFontWeight + CHAR(39) + ',' + CHAR(39) + @DetailHeadingFontColor + CHAR(39) + ',' + 
						CHAR(39) + @DetailHeadingFontSize + CHAR(39) + ',' + CHAR(39) + @DetailHeadingFontType + CHAR(39) + ',' + 
						CHAR(39) + @DetailHeadingFontWeight + CHAR(39) + ',' + CHAR(39) + @DetailSubHeadingFontColor + CHAR(39) + ','

			SET @SQL4 = CHAR(39) + @DetailSubHeadingFontSize + CHAR(39) + ',' + CHAR(39) + @DetailSubHeadingFontType + CHAR(39) + ',' + 
						CHAR(39) + @DetailSubHeadingFontWeight + CHAR(39) + ',' + CHAR(39) + @EmailHeaderTextFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailHeaderTextFontSize + CHAR(39) + ',' + CHAR(39) + @EmailHeaderTextFontType + CHAR(39) + ',' + 
						CHAR(39) + @EmailHeaderTextFontWeight + CHAR(39) + ',' + CHAR(39) +@EmailFooterTextFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailFooterTextFontSize + CHAR(39) + ',' + CHAR(39) + @EmailFooterTextFontType + CHAR(39) + ',' + 
						CHAR(39) + @EmailFooterTextFontWeight + CHAR(39) + ',' + CHAR(39) + @EmailBodyFontColor + CHAR(39) + ',' + 
						CHAR(39) + @EmailBodyFontSize + CHAR(39) + ',' + CHAR(39) + @EmailBodyFontType + CHAR(39) + ',' 

			SET @SQL5 =	CHAR(39) + @EmailBodyFontWeight + CHAR(39) + ',' + CHAR(39) + @AddFuncRefToSubject + CHAR(39) + ',' + 
						CHAR(39) + @AttachCalendarFile + CHAR(39) + ',' + CHAR(39) + @IncludeOtherSessionDetails + CHAR(39) + ',' + 
						CHAR(39) + @EmailLink01_DisplayText + CHAR(39) + ',' + CHAR(39) + @EmailLink02_DisplayText + CHAR(39) + ',' + 
						CHAR(39) + @EmailTemplate + CHAR(39) + ',' + CHAR(39) + @LayoutNumber + CHAR(39) + ',' + 
									CAST(@FromTrigger AS VARCHAR(10)) + ',' + CHAR(39) + @FunctionRef + CHAR(39) + ',' +
						CHAR(39) + @HideRoom + CHAR(39) + ',' + CHAR(39) + @HideRoomGivenOverride + CHAR(39) + ',' + 
						CHAR(39) + @DetailHeading_Alt + CHAR(39) + ',' + CHAR(39) + @DetailSubHeading_Alt + CHAR(39) + ','

			SET @SQL6 = CHAR(39) + @EmailHeaderText_Alt + CHAR(39) + ',' + CHAR(39) + @EmailSubTitle_Alt + CHAR(39) + ',' + 
						CHAR(39) + @IncludeSubjectInBody + CHAR(39) + ',' + CHAR(39) + @IncludeHostMBRNo + CHAR(39) + ',' + 
						CHAR(39) + @IncludeHostMBRTel + CHAR(39) + ',' + CHAR(39) + @IncludeSessNo + CHAR(39) + ',' + 
						CHAR(39) + @IncludeBookingStatus + CHAR(39) + ',' + CHAR(39) + @HiddenRoomText + CHAR(39) + ',' + 
						CHAR(39) + @IncludeBookerMBRNo + CHAR(39) + ',' + CHAR(39) + @IncludeBookerName + CHAR(39) + ',' + 
						CHAR(39) + @IncludeBookerMBRTel + CHAR(39) + ',' + CAST(@IncOtherSession AS VARCHAR(10)) + ',' + 
						CHAR(39) + @UseMBRInternForNames + CHAR(39) + ',' + CHAR(39) + @UseJobTitleForMBRIntern + CHAR(39) + ','

			SET @SQL7 =	CHAR(39) + @IncludeMeetingType + CHAR(39) + ',' + CHAR(39) + @SendToDepartment + CHAR(39) + ',' + 
						CHAR(39) + @Department + CHAR(39) + ',' + CHAR(39) + @DeptIncludeMailList + CHAR(39) + ',' + 
						CHAR(39) + @DeptExcludeMailList + CHAR(39) + ',' + CHAR(39) + @EmailBodyFontColorDel + CHAR(39) + ',' + 
						CHAR(39) + @EmailBodyFontSizeDel + CHAR(39) + ',' + CHAR(39) + @EmailBodyFontTypeDel + CHAR(39) + ',' + 
						CHAR(39) + @EmailBodyFontWeightDel + CHAR(39) + ',' + CHAR(39) + @EmailBodyText + CHAR(39) + ',' +						
						CAST(@DebugFlag AS VARCHAR(1))

			SET @SQL = @SQL0 + @SQL1 + @SQL2 + @SQL3 + @SQL4 + @SQL5 + @SQL6 + @SQL7

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: CABS SQL String built up by combining the following:'
				PRINT '    @SQL0 = ' + @SQL0
				PRINT '    @SQL1 = ' + @SQL1
				PRINT '    @SQL2 = ' + @SQL2
				PRINT '    @SQL3 = ' + @SQL3
				PRINT '    @SQL4 = ' + @SQL4
				PRINT '    @SQL5 = ' + @SQL5
				PRINT '    @SQL6 = ' + @SQL6
				PRINT '    @SQL7 = ' + @SQL7
			END

			SET CONCAT_NULL_YIELDS_NULL OFF -- TT - 08/06/2016 - Turn setting off again

			EXEC (@SQL) 

/*
				-- Have left this code in as it may be useful for debugging - much easier to debug code than dynamic SQL
				-- IF @EmailSPROC = **** Replace with Template Specific Stored Procedure - e.g. 'CABS_AEF_SEND_CXL'
				IF @EmailSPROC = 'CABS_AEF_SEND_SWR'				
				EXEC CABS_AEF_SEND_SWR
					@StatusCode, @EmailProfile, @Company,    
					@Enabled, @AdminEmailAddr, @EmailFormat, @SubjectLine, @SubjectLineText, @EmailTitle, @EmailSubTitle, @EmailSalut, 
					@EmailSignature, @DetailHeading, @DetailSubHeading, @SendToBooker, @SendToHost, @Bullet01, @Bullet02, 
					@EmailLink01_Address, @EmailLink02_Address, @CurrencySymbol, @IncludeWeekends, @Importance, @Sensitivity, @IncludeAttachments, @FileAttachments, 
					@AddHostToSubject, @DevOverride, @OnlyIncludeAssignedExtras, @ExtraCCToInclude, @FirstRunDate, @EmailType, @EmailHeaderText, @EmailFooterText, 
					@LocEmailAddress, @EmailTitleFontColor, @EmailTitleFontSize, @EmailTitleFontType, @EmailTitleFontWeight, @EmailSubTitleFontColor, 
					@EmailSubTitleFontSize, @EmailSubTitleFontType,@EmailSubTitleFontWeight, @EmailSalutFontColor, @EmailSalutFontSize, @EmailSalutFontType, 
					@EmailSalutFontWeight, @EmailSignatureFontColor, @EmailSignatureFontSize, @EmailSignatureFontType, @EmailSignatureFontWeight, 
					@DetailHeadingFontColor, @DetailHeadingFontSize, @DetailHeadingFontType, @DetailHeadingFontWeight, @DetailSubHeadingFontColor,
					@DetailSubHeadingFontSize, @DetailSubHeadingFontType, @DetailSubHeadingFontWeight, @EmailHeaderTextFontColor, @EmailHeaderTextFontSize, 
					@EmailHeaderTextFontType, @EmailHeaderTextFontWeight,@EmailFooterTextFontColor, @EmailFooterTextFontSize, @EmailFooterTextFontType, 
					@EmailFooterTextFontWeight,@EmailBodyFontColor, @EmailBodyFontSize, @EmailBodyFontType, @EmailBodyFontWeight, @AddFuncRefToSubject, 
					@AttachCalendarFile, @IncludeOtherSessionDetails, @EmailLink01_DisplayText, @EmailLink02_DisplayText, 
					'AEFSWR', @LayoutNumber, @FromTrigger, @FunctionRef, @HideRoom, @HideRoomGivenOverride, @DetailHeading_Alt, @DetailSubHeading_Alt, 
					@EmailHeaderText_Alt, @EmailSubTitle_Alt, @IncludeSubjectInBody, @IncludeHostMBRNo, @IncludeHostMBRTel, @IncludeSessNo, 
					@IncludeBookingStatus, @HiddenRoomText, @IncludeBookerMBRNo, @IncludeBookerName, @IncludeBookerMBRTel, @IncOtherSession, 
					@UseMBRInternForNames, @UseJobTitleForMBRIntern, @IncludeMeetingType, @SendToDepartment, @Department, @DeptIncludeMailList, 
					@DeptExcludeMailList, @EmailBodyFontColorDel, @EmailBodyFontSizeDel, @EmailBodyFontTypeDel, @EmailBodyFontWeightDel, @EmailBodyText, @DebugFlag								
*/			
			-- Added code to ensure that if table AutoEmailFunction contained a record for the current Function Ref then it is deleted - TT - 06/03/2016
			SET @NORECS = (SELECT COUNT(*) FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FunctionRef)
			If @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: No of Records Remaining in Table AutoEmailFunction (@NORECS) = ' + CAST(@NORECS AS VARCHAR(10)) + ' NOTE: This Should be 0'
			END
			IF @NORECS > 0 
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: DELETING Records in AutoEmailFunction - This could be an indication of an issue !'
				DELETE AutoEmailFunction WHERE AEF_FUNC_REF = @FunctionRef
			END
			ELSE
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS: No Records in AutoEmailFunction Require Deletion'
			END
			--End of Changes - 06/03/2017
			
		END --Can I run
	END --Settings Begin

	IF @DevOverride = 1
	BEGIN
		PRINT '**************************************************************'
		PRINT 'CABS_AUTO_EMAIL_FUNCS: Leaving Procedure CABS_AUTO_EMAIL_FUNCS' -- Amended TT - 29/06/2016					
		PRINT '**************************************************************'
	END
END
GO

PRINT '*****************************************************************************'

PRINT 'CABS_AUTO_EMAIL_FUNCS: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS]
							   ,@name = N'Version' 
							   ,@value = N'5.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO