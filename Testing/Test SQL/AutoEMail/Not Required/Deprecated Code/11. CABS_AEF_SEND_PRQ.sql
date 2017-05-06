DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = '11. CABS_AEF_SEND_PRQ'
SET @SPROC_Name = 'CABS_AEF_SEND_PRQ'
IF EXISTS ( SELECT * FROM   sysobjects 
            WHERE  id = object_id(N'[dbo].[CABS_AEF_SEND_PRQ]') 
                   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_PRQ]
	PRINT @FileName + ': Dropped Procedure ' + @SPROC_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @SPROC_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Procedure ' + @SPROC_Name
GO

/****** Object:  StoredProcedure [dbo].[CABS_AEF_SEND_PRQ]    Script Date: 22/06/2016 12:19:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 30/06/2016
-- Description:	This stored procedure is used within the CABS AutoEMail functionality
--				This specific procedure is used to send an email to request porters
--              All components of this email are configured via X CABS Config settings (section AEFPRQ)
--				Not all arguments passed are required but there are a number of similar stored
--				procedures and the it means the interface can is consistent between all.
--
--				The stored procedure currently only supports HTML email
-- =====================================================================================================
-- Version:		2
-- Date:		10/10/2016
-- =====================================================================================================
-- Changes:		TT: 08/06/2016: Original Version
-- Changes:		TT: 05/07/2016: Added @EmailSalut and @EmailSignature to the code
-- Changes:		TT: 02/08/2016	Changed SPROC to 'CABS_AEF_SEND_PRQ-' + @EmailTemplate 
--	 							in INSERT to AutoEmailFunction_FromTrigger
-- Changes:		TT: 02/08/2016: Added code to cursor query records to limit 
--								returned records to only those that are relevant 
--								to FREF and Email Type
--
-- Changes:		TT: 10/10/2016: Added code to add the mailitem_id from table sysmail_allitems into
--								audit table AutoEmailFunction_FromTrigger. This will occur when a call 
--								to sp_send_dbmail is made. This will enable better audit/diagnostic 
--								reports to be run
--
-- =====================================================================================================

CREATE PROCEDURE [dbo].[CABS_AEF_SEND_PRQ] 
						@StatusCode VARCHAR(1000), @EmailProfile VARCHAR(1000), @Company VARCHAR(1000), @Enabled VARCHAR(1000), @AdminEmailAddr VARCHAR(1000), 
						@EmailFormat VARCHAR(1000), @SubjectLine VARCHAR(1000), @SubjectLineText VARCHAR(1000), @EmailTitle VARCHAR(MAX), @EmailSubTitle VARCHAR(MAX),
						@EmailSalut VARCHAR(MAX), @EmailSignature VARCHAR(1000), @DetailHeading VARCHAR(MAX), @DetailSubHeading VARCHAR(MAX), @SendToBooker VARCHAR(1000), 
						@SendToHost VARCHAR(1000), @Bullet01 VARCHAR(1000), @Bullet02 VARCHAR(1000), @EmailLink01_Address VARCHAR(1000), @EmailLink02_Address VARCHAR(1000), 
						@CurrencySymbol VARCHAR(1000), @IncludeWeekends VARCHAR(1000), @Importance VARCHAR(1000), @Sensitivity VARCHAR(1000), @IncludeAttachments VARCHAR(1000), 
						@FileAttachments VARCHAR(1000), @AddHostToSubject VARCHAR(1000), @DevOverride VARCHAR(1000), @OnlyIncludeAssignedExtras VARCHAR(1000), 
						@ExtraCCToInclude VARCHAR(1000), @FirstRunDate VARCHAR(1000), @EmailType VARCHAR(1000), @EmailHeaderText VARCHAR(1000), @EmailFooterText VARCHAR(1000), 
						@LocEmailAddress VARCHAR(1000), @EmailTitleFontColor VARCHAR(1000), @EmailTitleFontSize VARCHAR(1000), @EmailTitleFontType VARCHAR(1000), 
						@EmailTitleFontWeight VARCHAR(1000), @EmailSubTitleFontColor VARCHAR(1000), @EmailSubTitleFontSize VARCHAR(1000), @EmailSubTitleFontType VARCHAR(1000),
						@EmailSubTitleFontWeight VARCHAR(1000), @EmailSalutFontColor VARCHAR(1000), @EmailSalutFontSize VARCHAR(1000), @EmailSalutFontType VARCHAR(1000), 
						@EmailSalutFontWeight VARCHAR(1000), @EmailSignatureFontColor VARCHAR(1000), @EmailSignatureFontSize VARCHAR(1000), @EmailSignatureFontType VARCHAR(1000), 
						@EmailSignatureFontWeight VARCHAR(1000), @DetailHeadingFontColor VARCHAR(1000), @DetailHeadingFontSize VARCHAR(1000), @DetailHeadingFontType VARCHAR(1000), 
						@DetailHeadingFontWeight VARCHAR(1000), @DetailSubHeadingFontColor VARCHAR(1000), @DetailSubHeadingFontSize VARCHAR(1000), 
						@DetailSubHeadingFontType VARCHAR(1000), @DetailSubHeadingFontWeight VARCHAR(1000), @EmailHeaderTextFontColor VARCHAR(1000), 
						@EmailHeaderTextFontSize VARCHAR(1000), @EmailHeaderTextFontType VARCHAR(1000), @EmailHeaderTextFontWeight VARCHAR(1000),
						@EmailFooterTextFontColor VARCHAR(1000), @EmailFooterTextFontSize VARCHAR(1000), @EmailFooterTextFontType VARCHAR(1000), 
						@EmailFooterTextFontWeight VARCHAR(1000), @EmailBodyFontColor VARCHAR(1000), @EmailBodyFontSize VARCHAR(1000), @EmailBodyFontType VARCHAR(1000), 
						@EmailBodyFontWeight VARCHAR(1000), @AddFuncRefToSubject VARCHAR(1000), @AttachCalendarFile VARCHAR(1000), @IncludeOtherSessionDetails VARCHAR(1000),
						@EmailLink01_DisplayText VARCHAR(1000), @EmailLink02_DisplayText VARCHAR(1000), @EmailTemplate VARCHAR(1000), @LayoutNumber VARCHAR(1000),
						@FromTrigger INT, @FunctionRef VARCHAR(7), @HideRoom VARCHAR(1000), @HideRoomGivenOverride VARCHAR(1000), @DetailHeading_Alt VARCHAR(1000), 
						@DetailSubHeading_Alt VARCHAR(1000), @EmailHeaderText_Alt VARCHAR(1000), @EmailSubTitle_Alt VARCHAR(1000), @IncludeSubjectInBody VARCHAR(1000), 
						@IncludeHostMBRNo VARCHAR(1000), @IncludeHostMBRTel VARCHAR(1000), @IncludeSessNo VARCHAR(1000), @IncludeBookingStatus VARCHAR(1000), 
						@HiddenRoomText VARCHAR(1000), @IncludeBookerMBRNo VARCHAR(1000), @IncludeBookerName VARCHAR(1000), @IncludeBookerMBRTel VARCHAR(1000),
						@IncOtherSession VARCHAR(1000), @UseMBRInternForNames VARCHAR(1000), @UseJobTitleForMBRIntern VARCHAR(1000), @IncludeMeetingType VARCHAR(1000), 
						@SendToDepartment VARCHAR(1000), @Department VARCHAR(1000), @DeptIncludeMailList VARCHAR(1000), @DeptExcludeMailList VARCHAR(1000),
						@EmailBodyFontColorDel VARCHAR(1000), @EmailBodyFontSizeDel VARCHAR(1000), @EmailBodyFontTypeDel VARCHAR(1000), @EmailBodyFontWeightDel VARCHAR(1000),
						@EmailBodyText VARCHAR(1000), @DebugFlag INT						
AS
BEGIN

	SET NOCOUNT ON;

	IF @DevOverride = 1
	BEGIN
		PRINT '******************************************************'
		PRINT 'CABS_AEF_SEND_PRQ: Entered Procedure CABS_AEF_SEND_PRQ' -- Amended TT - 29/06/2016					
		PRINT '******************************************************'
	END	

-- =============================================
-- DECLARATIONS
-- =============================================
	DECLARE @FREF varchar(7)	
	DECLARE @EMAIL varchar(100)
	DECLARE @CEMAIL varchar(100)
	DECLARE @BEMAIL varchar(100)	
	DECLARE @CONTACT varchar(50)
	DECLARE @EXTRAYN int
	DECLARE @PACKYN int
	DECLARE @MENUYN int
	DECLARE @DTYN int
	DECLARE @CANSEND varchar(3)
	DECLARE @SENT int
	DECLARE @FROOM varchar(100)	
	DECLARE @FSTARTDATETIME varchar(100)
	
-- =============================================
-- Set Type of Settings
-- =============================================		
		DECLARE @SettingsType VARCHAR(10)
		SET @SettingsType = 'S' 

-- =============================================
-- CHECK EXTRA REQUIRES PORTER
-- =============================================
	
	DECLARE @CostCentreExtrasReqPorter VARCHAR(1000)
	SET @CostCentreExtrasReqPorter = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, 'CostCentreExtrasReqPorter')), '')	
	
	--If CostCentreExtrasReqPorter key is missing from CABS Config then return
	IF @CostCentreExtrasReqPorter = ''
	BEGIN
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: CostCentreExtrasReqPorter is empty in X CABS CONFIG (section CABS_AEF_SEND_PRQ)' -- Amended TT - 28/06/2016					
		END	
		RETURN
	END

	-- =========================================================================
	-- CostCentreExtrasReqPorter is a comma separated list of Cost Centres
	-- Because the string is to used as part of a Dynamic SQL each cost centre 
	-- each item needs to be enclosed in quotes and any spaces must be removed
	-- =========================================================================
	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AEF_SEND_PRQ: From X CABS Config: @CostCentreExtrasReqPorter = ' +  @CostCentreExtrasReqPorter -- Amended TT - 28/06/2016					
	END
	-- Any strings need to be wrapped in single quotes
	SET @CostCentreExtrasReqPorter = CHAR(39) + REPLACE(@CostCentreExtrasReqPorter, ',', CHAR(39) + ',' + CHAR(39)) + CHAR(39)		
	-- Need to remove all spaces
	SET @CostCentreExtrasReqPorter = REPLACE(@CostCentreExtrasReqPorter, ' ','')
	
	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AEF_SEND_PRQ: Pre-Processed: @CostCentreExtrasReqPorter = ' +  @CostCentreExtrasReqPorter -- Amended TT - 28/06/2016					
	END	

-- =============================================
-- PREPARE EMAIL - START
-- =============================================
	DECLARE @EmailText VARCHAR(MAX)	
	DECLARE @RetChar VARCHAR(MAX)
	DECLARE @TabChar VARCHAR(MAX)

-- ================================================================
-- PREPARE EMAIL - START - Read from Section CABS_AUTO_EMAIL_FUNCS
-- ================================================================
	IF @EmailFormat = 'HTML'
	BEGIN
		SET @RetChar = '<br>'
		SET @TabChar = (CHAR(9))		
	END		

-- =============================================
-- Email Variables
-- =============================================
	DECLARE @AEF_KEY INT

-- ===================================================
-- Prepare Email Data - Cursor
-- Table AutoEmailFunction contains emails to be sent
-- ===================================================
	DECLARE
		email_cursor
	CURSOR FAST_FORWARD FOR
		-- Added inner join limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016
		SELECT
			AEF_KEY, AEF_FUNC_REF, AEF_ROOM, AEF_EMAIL, AEF_CEMAIL, AEF_BOOKER_EMAIL, AEF_CONTCT, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_DTYN, AEF_STARTDATETIME, AEF_CANSEND, AEF_SENT
		FROM
			AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF
		WHERE
			AEF_CANSEND = 'Yes'
		AND
			AEF_SENT = 0
		-- Added to limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016
		AND 
			AEF_FUNC_REF = @FunctionRef
		AND 
			AEFL_EMailType = @EmailTemplate		
		
	OPEN email_cursor

	FETCH NEXT FROM
		email_cursor
	INTO
		@AEF_KEY,
		@FREF,
		@FROOM,
		@EMAIL,
		@CEMAIL,
		@BEMAIL,
		@CONTACT,
		@EXTRAYN,
		@PACKYN,
		@MENUYN,
		@DTYN,
		@FSTARTDATETIME,
		@CANSEND,
		@SENT

	WHILE @@fetch_status = 0
	BEGIN		
		
		DECLARE @CountNo INT
		DECLARE @MatchedRecords INT = 0
		DECLARE @SQLString NVARCHAR(500)
		DECLARE @ParmDefinition NVARCHAR(500)					

	-- =========================================================================
	-- Build up the SQL string to be executed and setup the parameter list
	-- The string in CABS Config contains cost centres which require porters		
	-- =========================================================================		
		SET @SQLString = 'SELECT @CountNo = COUNT(AI_OPSHEET) FROM AI_FILE WHERE  AI_FREF = ' + CHAR(39) + @FREF + CHAR(39) +
								' AND AI_OPSHEET IN(' + @CostCentreExtrasReqPorter + ')' 
		SET @ParmDefinition = '@CountNo INT OUTPUT';  		
  
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @SQLString = ' +  @SQLString -- Amended TT - 28/06/2016					
			PRINT 'CABS_AEF_SEND_PRQ: @ParmDefinition = ' +  @ParmDefinition -- Amended TT - 28/06/2016					
		END
	-- =========================
	-- Execute the dynamic SQL 		
	-- =========================
		EXECUTE sp_executesql @SQLString, @ParmDefinition, @CountNo=@MatchedRecords OUTPUT;  

	-- ================================================
	-- If no matched records then check the next email 		
	-- ================================================
		SELECT @MatchedRecords;  	
		IF @MatchedRecords = 0
		BEGIN
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_PRQ: @MatchedRecords = ' +  CAST(@MatchedRecords AS VARCHAR)-- Amended TT - 28/06/2016									
			END
			-- =============================================
			-- Fetch Next Email
			-- =============================================
			FETCH NEXT FROM
				email_cursor
			INTO
				@AEF_KEY,
				@FREF,
				@FROOM,
				@EMAIL,
				@CEMAIL,
				@BEMAIL,			
				@CONTACT,
				@EXTRAYN,
				@PACKYN,
				@MENUYN,
				@DTYN,
				@FSTARTDATETIME,
				@CANSEND,
				@SENT
			CONTINUE
		END

	-- ================================================
	-- Get Room Name		
	-- ================================================
		DECLARE @RMNAME VARCHAR(100)
		SET @RMNAME = (SELECT RM_NAME FROM ROOMS WHERE RM_ABBR = @FROOM)
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @RMNAME = ' +  @RMNAME -- Amended TT - 28/06/2016									
		END
	-- =============================================
	-- GET EMAIL ADDRESSES BEGIN
	-- =============================================
		DECLARE @NoEmail INT
		SET @NoEmail = 0

		DECLARE @EMailAddr VARCHAR(512)
		SET @EMailAddr = ''

	-- ==========================================================
	-- DEPARTMENT EMAIL ADDRESS 
	-- This text is passed from section AEFCXL in X CABS Config 
	-- ==========================================================
		DECLARE @DeptEmailAddr VARCHAR(512) 
		SET @DeptEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @SendToDepartment = ' +  @SendToDepartment -- Amended TT - 28/06/2016			
			PRINT 'CABS_AEF_SEND_PRQ: @Department = ' +  @Department -- Amended TT - 28/06/2016						
		END

		IF @SendToDepartment = 1	
			SET @DeptEmailAddr = (SELECT [dbo].[uf_getDepteMail]('HELPDESK'))

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @DeptEmailAddr = ' +  @DeptEmailAddr -- Amended TT - 28/06/2016			
		END

	-- =============================================
	-- Concatenate Email Addresses
	-- =============================================
		SET @EMailAddr = COALESCE(@DeptEmailAddr, '')

		IF COALESCE(@EMailAddr, '') <> '' 
		BEGIN
			IF @DevOverride = 1 BEGIN
				PRINT 'CABS_AEF_SEND_PRQ: @EMailAddr = ' +  @EMailAddr -- Amended TT - 28/06/2016				
			END	
		END
		ELSE
		IF COALESCE(@EMailAddr, '') = '' 
		BEGIN
			SET @NoEmail = 1
			SET @EMailAddr = @AdminEmailAddr
		
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_PRQ: @NoEmail = ' +  CONVERT(VARCHAR, @NoEmail) -- Amended TT - 28/06/2016				
			END	
		END
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @FREF = ' +  @FREF -- Amended TT - 28/06/2016
		END

	-- ==============================================
	-- GET HOST INFORMATION  - USED FOR SUBJECT LINE
	-- ==============================================
		DECLARE @MBRNo VARCHAR(7)
		DECLARE @InternYN INT				
		DECLARE @Host VARCHAR(100)
								
		SET @MBRNo = (SELECT AEF_MBR_NO FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF)
	
		If @UseMBRInternForNames = 0
		BEGIN
			SET @InternYN = (SELECT AEF_INTERN FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF)
		END
		ELSE	
		If @UseMBRInternForNames = 1
		BEGIN
			SET @InternYN = (SELECT MBR_INTERN FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		END

		IF @InternYN = 1
		BEGIN
			SET @Host = (SELECT COALESCE(LTRIM(RTRIM( COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR2, CHAR(39), CHAR(146)))), '') + ' ' + 
								COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR1, CHAR(39), CHAR(146)))), '') + ' ' + 
								COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), ''))), '') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		END
		ELSE	
		IF @InternYN = 0
		BEGIN
			SET @Host = (SELECT COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), '') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		END

	-- =============================================
	-- Add Function Ref and Host to SubjectLine
	-- =============================================
		SET @SubjectLineText = ''
		IF @AddFuncRefToSubject = '1'
		BEGIN
			SET @SubjectLineText = COALESCE(@SubjectLineText, '') + ' ' + '(' + COALESCE(@FREF, '') + ')'
		END

		IF @AddHostToSubject = '1'
		BEGIN
			SET @SubjectLineText = COALESCE(@SubjectLineText, '') + ' ' + COALESCE(@Host, '')
		END

		SET @SubjectLineText = (COALESCE(@SubjectLine, '') + COALESCE(@SubjectLineText, ''))
		
	-- =============================================
	-- PREPARE EMAIL
	-- Currently only format supported is HTML
	-- =============================================
		IF @EmailFormat = 'HTML'
		BEGIN

	-- ==========================================================
	-- EMAIL HEADER
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================
			IF COALESCE(@EmailHeaderText, '') <> ''	 		 
				SET @EmailHeaderText = '<p style="color: ' + @EmailHeaderTextFontColor + 
									   '; font-weight: ' + @EmailHeaderTextFontWeight + 
									   '; font-family: ' + @EmailHeaderTextFontType + 
									   '; font-size: ' + @EmailHeaderTextFontSize + 
									   'pt;">' +  @EmailHeaderText + '</p>' 		

	-- =========================================================
	-- EMAIL SUB-TITLE
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================
			IF COALESCE(@EmailSubTitle, '') <> ''	 		 
				SET @EmailSubTitle = '<p style="color: ' + @EmailSubTitleFontColor + 
								     '; font-weight: ' +  @EmailSubTitleFontWeight + 
									 '; font-family: ' + @EmailSubTitleFontType + 
									 '; font-size: ' + @EmailSubTitleFontSize + 
									 'pt;">' +  @EmailSubTitle + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================
			IF COALESCE(@DetailHeading, '') <> ''
				SET @DetailHeading = '<p style="color: ' + @DetailHeadingFontColor + 
				  					 '; font-weight: ' +  @DetailHeadingFontWeight + 
									 '; font-family: ' + @DetailHeadingFontType + 
									 '; font-size: ' + @DetailHeadingFontSize + 
									 'pt;">' +  @DetailHeading + COALESCE(@FSTARTDATETIME, '') + ' in ' + COALESCE(@RMNAME, '') + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================		
			IF COALESCE(@DetailSubHeading, '') <> ''
				SET @DetailSubHeading = '<p style="color: ' + @DetailSubHeadingFontColor + 
									    '; font-weight: ' +  @DetailSubHeadingFontWeight + 
									    '; font-family: ' + @DetailSubHeadingFontType + 
									    '; font-size: ' + @DetailSubHeadingFontSize + 
									    'pt;">' +  @DetailSubHeading + '</p>' 

	-- =========================================================
	-- EMAIL BODY TEXT
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================		
			IF COALESCE(@EmailBodyText, '') <> ''
				SET @EmailBodyText = '<p style="color: ' + @EmailBodyFontColor + 
									 '; font-weight: ' +  @EmailBodyFontWeight + 
									 '; font-family: ' + @EmailBodyFontType + 
									 '; font-size: ' + @EmailBodyFontSize + 
									 'pt;">' +  @EmailBodyText + '</p>' 

	-- Added - TT - 05/07/2016
	-- =========================================================
	-- EMAIL Salutation
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================
			IF COALESCE(@EmailSalut, '') <> ''
				SET @EmailSalut = '<p style="color: ' + @EmailSalutFontColor + 
								  '; font-weight: ' +  @EmailSalutFontWeight + 
								  '; font-family: ' + @EmailSalutFontType + 
								  '; font-size: ' + @EmailSalutFontSize + 
								  'pt;">' +  @EmailSalut + '</p>' 			

	-- =========================================================
	-- EMAIL Signature
	-- This text is passed from section AEFPRQ in X CABS Config
	-- =========================================================
			IF COALESCE(@EmailSignature, '') <> ''		
				SET @EmailSignature = '<p style="color: ' + @EmailSignatureFontColor + 
									  '; font-weight: ' +  @EmailSignatureFontWeight + 
									  '; font-family: ' + @EmailSignatureFontType + 
									  '; font-size: ' + @EmailSignatureFontSize + 
									  'pt;">' +  @EmailSignature + '</p>' 
		END	

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @EmailHeaderText = ' +  @EmailHeaderText -- Amended TT - 28/06/2016		
			PRINT 'CABS_AEF_SEND_PRQ: @EmailSubTitle = ' +  @EmailSubTitle -- Amended TT - 28/06/2016			
			PRINT 'CABS_AEF_SEND_PRQ: @DetailHeading = ' +  @DetailHeading -- Amended TT - 28/06/2016			
			PRINT 'CABS_AEF_SEND_PRQ: @DetailSubHeading = ' +  @DetailSubHeading -- Amended TT - 28/06/2016
			PRINT 'CABS_AEF_SEND_PRQ: @EmailBodyText = ' +  @EmailBodyText -- Amended TT - 28/06/2016			
			PRINT 'CABS_AEF_SEND_PRQ: @EmailSalut = ' +  @EmailSalut -- Amended TT - 05/07/2016			
			PRINT 'CABS_AEF_SEND_PRQ: @EmailSignature = ' +  @EmailSignature -- Amended TT - 05/07/2016		
		END	

	-- =============================================
	-- Build Up Email
	-- =============================================
		IF @NoEmail = 1
			SET @EmailText = '*** NO RECIPIENT EMAIL ADDRESS - IN CABS CONFIG, SECTION DeptEmailAddresses, ADD KEY-VALUE PAIR HELPDESK-EMAIL ADDRRESS *** ' + @EmailHeaderText
		ELSE			
			SET @EmailText = @EmailHeaderText

		-- Added  + @EmailSalut + @EmailSignature - TT - 05/07/2016
		SET @EmailText = @EmailText + @EmailSubTitle + @DetailHeading + @DetailSubHeading + @EmailBodyText + @EmailSalut + @EmailSignature
				
	-- =============================================
	-- Get Email Address String If Blank
	-- =============================================
		DECLARE @EmailAddressType VARCHAR(3)
		SET @EmailAddressType = '(N)'

		IF COALESCE(@EMailAddr, '') = '' --If Email Address is Blank
		BEGIN
			IF COALESCE(@AdminEmailAddr, '') <> '' --If Admin Email Address is NOT Blank
			BEGIN
				SET @EMailAddr = @AdminEmailAddr
				SET @EmailAddressType = '(A)'
				
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_PRQ: @AdminEmailAddr = ' +  @AdminEmailAddr -- Amended TT - 28/06/2016							
				END	
			END
			ELSE
				SET @EmailAddressType = '(X)'			
		END

		SET @SubjectLineText = (COALESCE(@SubjectLineText, ''))

	-- ============================================================
	-- Get Specific Email Profile
	-- Email profiles are used to configure the From Email Address
	-- ============================================================
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailTemplate AND [KEY] = 'EmailProfile') > 0
		BEGIN
			SET @EmailProfile = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailTemplate AND [KEY] = 'EmailProfile')
		END
		
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @EmailProfile = ' +  @EmailProfile -- Amended TT - 28/06/2016			
		END	
	-- =============================================
	-- Send the Email
	-- =============================================
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @EmailAddressType = ' +  @EmailAddressType -- Amended TT - 28/06/2016
			PRINT 'CABS_AEF_SEND_PRQ: @EMailAddr = ' +  @EMailAddr -- Amended TT - 28/06/2016
			PRINT 'CABS_AEF_SEND_PRQ: @SubjectLineText = ' +  @SubjectLineText -- Amended TT - 28/06/2016			
		END	
	-- =============================================
	-- CREATE Calendar And Attachments
	-- =============================================	
		DECLARE @SendCalendarSQL VARCHAR (MAX)	
		-- Changed the declaration of @SendEMailSQL from VARCHAR to NVARCHAR -- Amended 10/10/2016
		DECLARE @SendEMailSQL NVARCHAR(MAX)
		DECLARE @SendAttachmentSQL VARCHAR (MAX)
	
		SET @SendAttachmentSQL = ''
		SET @SendCalendarSQL = ''

	-- =============================================
	-- GENERATE Email
	-- ============================================= 
		-- Changed how the dynamic sql to send an email is built - it now uses sp_executesql
		-- which enables the mailitem_id to be returned (this is from a sys table [sysmail_allitems]
		-- in database msdb). This will enable more robust auditing of which emails are sent.
		-- TT - 10/10/2016
		DECLARE @MailItemID INT		
		DECLARE @PARAMS NVARCHAR(100)

		SET @SendEMailSQL = N'EXEC msdb.dbo.sp_send_dbmail ' +  
							'@profile_name = ' + CHAR(39) + @EmailProfile + CHAR(39) + ', ' + 
							'@recipients = ' + CHAR(39) + @EMailAddr + CHAR(39) + ',' + 
							'@subject = ' + CHAR(39) + @SubjectLineText + CHAR(39) + ',' + 
							'@body = ' + CHAR(39) + @EmailText + CHAR(39) + ',' + 
							'@body_format = ' + CHAR(39) + @EmailFormat + CHAR(39) + ',' + 
							'@importance = ' + CHAR(39) + @Importance + CHAR(39) + ',' + 
							'@sensitivity = ' + CHAR(39) + @Sensitivity + CHAR(39) + ',' +  							
							'@mailitem_id = @MailID OUTPUT'										
		
		SET @PARAMS = N'@MailID INT OUTPUT';		
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_PRQ: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
			PRINT 'CABS_AEF_SEND_PRQ: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
		END	
		-- End of Changes - TT - 10/10/2016
	-- =====================================================================
	-- CAPTURE SEND INFO
	-- Table AutoEmailFunction_SEND_PARAMS is used for Auditing information
	-- =====================================================================
		if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_SEND_PARAMS]')) = 1
		BEGIN
			INSERT INTO AutoEmailFunction_SEND_PARAMS
			SELECT @AEF_KEY, @EmailProfile, @EMailAddr,
			@EmailFormat, @Importance, @Sensitivity, @FromTrigger, @FREF, GETUTCDATE()
		END
	-- =====================================================================
	-- SEND EMAIL USING DBMAIL
	-- =============================================
		IF @EmailAddressType <> '(X)'
		BEGIN --Email Address Type
			IF @DevOverride = 0 OR @DebugFlag  = 1 -- Amended TT - 28/06/2016 - Added to ensure that the email is sent even when Debug flag is set on X CABS Config			
			BEGIN
				-- Replaced the EXEC command for an EXEC sp_executesql command to enable data to be returned - TT - 10/10/2016				 
				--EXEC(@SendEMailSQL)
				EXEC sp_executesql @SendEMailSQL, @PARAMS, @MailID = @MailItemID OUTPUT;
				-- Capture the MailItemId (from [sysmail_allitems]) - TT - 10/10/2016
				SELECT @MailItemID
				
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_PRQ: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
				END	
				-- End of changes - TT - 10/10/2016
			END
		END --Email Address Type
		ELSE
			PRINT 'CABS_AEF_SEND_PRQ: No Valid Email Address'

	-- =============================================
	-- Update the Sent Flag
	-- =============================================
		UPDATE AutoEmailFunction
		SET AEF_SENT = 1, AEF_SENT_DATE = GETUTCDATE()
		WHERE AEF_FUNC_REF = @FREF

	-- =====================================================================
	-- Trigger Updates
	-- Table AutoEmailFunction_FromTrigger is used for Auditing information
	-- Delete current record from table AutoEmailFunction 
	-- =====================================================================	
		IF @FromTrigger = 1
		BEGIN
			if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_FromTrigger]')) = 1
			BEGIN
				--	Changed SPROC to 'CABS_AEF_SEND_PRQ'+'-'+@EmailTemplate to assist with debugging - TT - 02/08/2016
				-- Added @MailItemID to INSERT statement - TT - 10/10/2016
				INSERT INTO AutoEmailFunction_FromTrigger
				SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
				AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
				AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AEF_SEND_PRQ'+'-'+@EmailTemplate, AEF_DTYN, @MailItemID
				FROM AutoEmailFunction
				WHERE AEF_FUNC_REF = @FunctionRef
				AND (AEF_FROM_TRIGGER = 1 OR AEF_FROM_TRIGGER = 2)
			END
		
			IF (SELECT COUNT(*) FROM AutoEmailFunction_FromTrigger WHERE AEF_FUNC_REF = @FunctionRef) > 0
			BEGIN
				DELETE FROM AutoEmailFunction
				WHERE AEF_FUNC_REF = @FunctionRef
				AND AEF_FROM_TRIGGER = 1
			END	
		END
	
	-- =============================================
	-- Remove Amendments
	-- =============================================		
		EXEC ae_UPD_AEF_Amendments @FunctionRef
		EXEC ae_DEL_AEF_Amendments @FunctionRef, 1, 1	

-- =============================================
-- Fetch Next Email
-- =============================================
		FETCH NEXT FROM
			email_cursor
		INTO
			@AEF_KEY,
			@FREF,
			@FROOM,
			@EMAIL,
			@CEMAIL,
			@BEMAIL,			
			@CONTACT,
			@EXTRAYN,
			@PACKYN,
			@MENUYN,
			@DTYN,
			@FSTARTDATETIME,
			@CANSEND,
			@SENT
	END

	CLOSE email_cursor
	DEALLOCATE email_cursor

	IF @DevOverride = 1
	BEGIN
		PRINT '******************************************************'
		PRINT 'CABS_AEF_SEND_PRQ: Leaving Procedure CABS_AEF_SEND_PRQ' -- Amended TT - 29/06/2016					
		PRINT '******************************************************'
	END	

END

GO

