-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_SEND_FFC'
SET @SPROC_Name = 'CABS_AEF_SEND_FFC'

IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_FFC]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_FFC]
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

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/09/2016
-- Description:	This stored procedure is used within the CABS AutoEMail functionality
--				This specific procedure is used to send an email to request feedback from customer
--              All components of this email are configured via X CABS Config settings (section AEFEFF)
--				Not all arguments passed are required but there are a number of similar stored
--				procedures and the it means the interface can is consistent between all.
--
--				The stored procedure currently only supports HTML email
-- =====================================================================================================
-- Version:		5
-- Date:		09/01/2017
-- =====================================================================================================
-- Changes:		TT: 08/09/2016: Original Version
--
-- Changes:		TT: 10/10/2016: Added code to add the mailitem_id from table sysmail_allitems into
--	(2)							audit table AutoEmailFunction_FromTrigger. This will occur when a call 
--								to sp_send_dbmail is made. This will enable better audit/diagnostic 
--								reports to be run
-- Changes:		TT: 16/11/2016: Changed Cursor SQL
-- (3)
--
-- Changes:		TT: 19/12/2016:	Added ability to send emails to MBR Contact and Booker via a config 
--	(4)							setting (SentToBooker, SendToContact)
--								Added code to check for ClassConstraint1	
--
-- Changes:		TT: 09/01/2017:	Made changes to code to enable the Function Date to be added to the 
--	(5)							Subject Line of the email instead of the Event Start Date
-- =====================================================================================================

CREATE PROCEDURE [dbo].CABS_AEF_SEND_FFC 
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
		PRINT 'CABS_AEF_SEND_FFC: Entered Procedure CABS_AEF_SEND_FFC'					
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
	DECLARE @FROOM varchar(100)	
	DECLARE @FSTARTDATETIME varchar(100)
	DECLARE @MBRNO VARCHAR(7)
	DECLARE @FDATE datetime -- Added to enable Function Date to be included on Subject Line - TT - 09/01/2017

-- =============================================
-- Set Type of Settings
-- =============================================		
	DECLARE @SettingsType VARCHAR(10)
	SET @SettingsType = 'S' 

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

		-- Changed Cursor SQL - TT - 16/11/2016
		SELECT
			-- Added AEF_DATE - TT - 09/01/2017
			AEF_KEY, AEF_FUNC_REF, AEF_MBR_NO, AEF_EMAIL, AEF_CEMAIL, AEF_DATE 
		FROM				
			AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF
		WHERE
			AEF_CANSEND = 'Yes'
		AND
			AEF_SENT = 0		
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
		@MBRNO,		
		@EMAIL,
		@CEMAIL,
		-- Added F_DATE - TT - 09/01/2017
		@FDATE		
	
	WHILE @@fetch_status = 0
	BEGIN		
	
		-- Added code to check for any class constraints
		-- This code checks X CABS Config for a a key ClassConstraint1  
		-- If it exists and it value is 1 then email will only be sent if the AC_OWNER in AC10 has the 
		-- classification of 'HELP' TT - 19/12/2016
		DECLARE @ClassConstraint1 VARCHAR(10)

		-- Check to see if any class constraints are to be applied to this autoemail
		SET @ClassConstraint1 = ''
		SET @ClassConstraint1 = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'ClassConstraint1')), '0')
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @ClassConstraint1 = ' + @ClassConstraint1
		END

		-- If class constraint is configured ..
		IF @ClassConstraint1 = 1
		BEGIN
			-- If in this block then class constraints are applied
			DECLARE @RecCount INT
			SET @RecCount = 0

			-- Ensure that only when an event has a business type of Help Desk should this email be sent
			SET @RecCount = (SELECT COUNT(AEF_MBR_NO) FROM AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF			
															   INNER JOIN AC10 ON AEF_MBR_NO = AC_OWNER	
							 WHERE
								AEF_CANSEND = 'Yes' AND AEF_SENT = 0 AND 
								AEF_FUNC_REF = @FunctionRef AND AEFL_EMailType = @EmailTemplate AND 
								AC_CODE = 'HELP')

			-- If the record count is not 1 (or > 0) this email should not be sent
			IF @RecCount < 1
			BEGIN
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_FFC: Email will not be sent due to classification constraint'
				END
				-- Dont like GoTo's but need to tidy up !
				GOTO DO_NOT_SEND_EMAIL
			END
			ELSE
			BEGIN
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_FFC: Email will be sent due to classification constraint'
				END				
			END
		END
		-- End of Changes - TT - 19/12/2016

	-- =============================================
	-- GET EMAIL ADDRESSES BEGIN
	-- =============================================
		DECLARE @NoEmail INT
		SET @NoEmail = 0			

		DECLARE @EMailAddr VARCHAR(512)
		SET @EMailAddr = ''

		-- =============================================
		-- Client Contact Email Address
		-- =============================================
		DECLARE @ClientEmailAddr VARCHAR(512) 
		DECLARE @SendToClient VARCHAR(100)

		SET @ClientEmailAddr = ''
		
		SET @SendToClient = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EMailTemplate, 'SendToClient')), '')
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @SendToClient = ' + @SendToClient		
		END

		IF @SendToClient = 1
		BEGIN
		
			SET @ClientEmailAddr = @CEMAIL
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_FFC: @ClientEmailAddr (CEMAIL) = ' + @ClientEmailAddr		
			END

			IF COALESCE(@ClientEmailAddr,'') = ''
			BEGIN
				SET @ClientEmailAddr = (SELECT COALESCE(CT_EMAIL, '') FROM CONTACTS INNER JOIN MBRFILE ON MBR_CONTNO = CT_SYSNO WHERE MBR_SYSNO = @MBRNo)
				IF @DevOverride = 1
					BEGIN
					PRINT 'CABS_AEF_SEND_FFC: @ClientEmailAddr (CT_EMAIL) = ' + @ClientEmailAddr		
				END
			END

			-- Added after discussion with client and PAS - TT - 01/08/2016
			IF COALESCE(@ClientEmailAddr,'') = ''
			BEGIN
				SET @ClientEmailAddr = @EMAIL
				IF @DevOverride = 1
					BEGIN
					PRINT 'CABS_AEF_SEND_FFC: @ClientEmailAddr (EMAIL) = ' + @EMAIL		
				END
			END		
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @ClientEmailAddr (Final) = ' + @ClientEmailAddr				
		END

		-- Added ability to send to Booker and MBR Contact - TT - 19/12/2016
		SET @MBRNo = (SELECT COALESCE(F_MBR_NO, '') FROM FUNC_FIL WHERE F_REF = @FREF)

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @MBRNo = ' + @MBRNo
		END

	-- =============================================
	-- MBR Contact Email Address
	-- =============================================
		DECLARE @SendToContact VARCHAR(32)
		DECLARE @ContactEmailAddr VARCHAR(512) 		
		SET @ContactEmailAddr = ''	
		
		-- Check the SendToContact setting on the email template
		SET @SendToContact = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'SendToContact')), '0')			

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @SendToContact = ' + @SendToContact
		END

		IF @SendToContact = 1
		BEGIN
			SET @ContactEmailAddr = (SELECT COALESCE(MBR_CEMAIL, '') FROM MBRFILE 
									 WHERE MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @ContactEmailAddr = ' + @ContactEmailAddr
		END

	-- =============================================
	-- Booker Email Address
	-- =============================================
		DECLARE @BookerEmailAddr VARCHAR(512) 
		SET @BookerEmailAddr = ''		

		DECLARE @BookerID VARCHAR(7)
		SET @BookerID = (SELECT COALESCE(F_BOOKER, '') FROM FUNC_FIL
						 WHERE F_REF = @FREF)

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @SendToBooker = ' + @SendToBooker
			PRINT 'CABS_AEF_SEND_FFC: @BookerID = ' + @BookerID
		END

		IF @SendToBooker = 1
		BEGIN
			SET @BookerEmailAddr = (SELECT COALESCE(B.MBR_EMAIL, '') FROM MBRFILE A, MBRFILE B 
									WHERE B.MBR_EMAIL <> '' AND NOT B.MBR_EMAIL IS NULL AND @BookerID = B.MBR_IMPKEY AND A.MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @BookerEmailAddr = ' + @BookerEmailAddr
		END
		-- End of Changes - TT - 19/12/2016

	-- =============================================
	-- Concatenate Email Addresses
	-- =============================================	
		-- Added - TT - 19/12/2016
		-- Add MBR Contact and Booker Addresses and Department Addresses
		-- SET @EMailAddr = COALESCE(@ClientEmailAddr, '')
		
		IF COALESCE(@ClientEmailAddr, '') <> '' BEGIN
			SET @ClientEmailAddr = (@ClientEmailAddr + '; ')
		END 

		IF COALESCE(@BookerEmailAddr, '') <> '' BEGIN
			SET @BookerEmailAddr = (@BookerEmailAddr + '; ')
		END 

		IF COALESCE(@ContactEmailAddr, '') <> '' BEGIN
			SET @ContactEmailAddr = (@ContactEmailAddr + '; ')
		END 

		SET @EMailAddr = @ClientEmailAddr + @BookerEmailAddr + @ContactEmailAddr
		
		-- End of Changes - TT - 19/12/2016

		IF COALESCE(@EMailAddr, '') <> '' 
		BEGIN
			IF @DevOverride = 1 BEGIN
				PRINT 'CABS_AEF_SEND_FFC: @EMailAddr = ' +  @EMailAddr				
			END	
		END
		ELSE
		IF COALESCE(@EMailAddr, '') = '' 
		BEGIN
			SET @NoEmail = 1
			SET @EMailAddr = @AdminEmailAddr
		
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_FFC: @NoEmail = ' +  CONVERT(VARCHAR, @NoEmail)				
			END	
		END
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @FREF = ' +  @FREF
		END

	-- ==============================================
	-- GET HOST INFORMATION  - USED FOR SUBJECT LINE
	-- ==============================================		
		DECLARE @InternYN INT				
		DECLARE @Host VARCHAR(100)
								
		-- SET @MBRNo = (SELECT AEF_MBR_NO FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF) - Removed as variable declared and set ealrier in code - TT - 19/12/2016											
	
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
		DECLARE @MBR_Event_Title VARCHAR(100)
		SET @MBR_Event_Title = ''
		SET @MBR_Event_Title = COALESCE((SELECT MBR_EVENT FROM MBRFILE WHERE MBR_SYSNO = @MBRNo), '')

		DECLARE @MBR_Event_Start VARCHAR(30)
		SET @MBR_Event_Start = SUBSTRING(CONVERT(VARCHAR,(SELECT MBR_FROM FROM MBRFILE WHERE MBR_SYSNO = @MBRNo), 20), 1, 10)
		
		-- Changed the Event Start Date to the Function Date - TT - 09/01/2017
		--SET @SubjectLineText = COALESCE(@SubjectLine, '') + ': ' + COALESCE(@MBR_Event_Title, '') + ' Starting On ' + COALESCE(@MBR_Event_Start, '')
		SET @SubjectLineText = COALESCE(@SubjectLine, '') + ': ' + COALESCE(@MBR_Event_Title, '') + ' Starting On ' + CONVERT( VARCHAR(10), COALESCE(@FDATE,''), 103 )
				
	-- =============================================
	-- PREPARE EMAIL
	-- Currently only format supported is HTML
	-- =============================================
		DECLARE @HTMLHEAD VARCHAR(MAX)
		IF @EmailFormat = 'HTML'
		BEGIN

	-- ==========================================================
	-- EMAIL TABLE STYLING
	-- =========================================================		 
			SET @HTMLHEAD = '<head>' + 
							'<title>Boookings Details</title>' +		
							'<style>' +
							'table.details td {' +								
								'color: ' + @EmailBodyFontColor + ';' +
								'font-weight: ' +  @EmailBodyFontWeight + ';' +
								'font-family: ' + @EmailBodyFontType  + ';' +
								'font-size: ' + @EmailBodyFontSize  + 'pt;' +	
							'}' +							
							'table.extras {' +
								'border-collapse: collapse;' +
							'}' +
							'table.extras td {' +
								'border: 1px solid black;' +
								'padding: 2px 5px 2px 5px;' +
								'color: ' + @EmailBodyFontColor + ';' +
								'font-weight: ' +  @EmailBodyFontWeight + ';' +
								'font-family: ' + @EmailBodyFontType  + ';' +
								'font-size: ' + @EmailBodyFontSize  + 'pt;' +							
							'}'	+	
							'.bodyfontstyle {' +
								'color: ' + @EmailBodyFontColor + ';' +
								'font-weight: ' +  @EmailBodyFontWeight + ';' +
								'font-family: ' + @EmailBodyFontType  + ';' +
								'font-size: ' + @EmailBodyFontSize  + 'pt;' +							
							'}' +
							'.headertextfontstyle {' +
								'color: ' + @EmailHeaderTextFontColor + ';' +
								'font-weight: ' +  @EmailHeaderTextFontWeight + ';' +
								'font-family: ' + @EmailHeaderTextFontType  + ';' +
								'font-size: ' + @EmailHeaderTextFontSize  + 'pt;' +							
							'}' +
							'.subtitlefontstyle {' +
								'color: ' + @EmailSubTitleFontColor + ';' +
								'font-weight: ' +  @EmailSubTitleFontWeight + ';' +
								'font-family: ' + @EmailsubtitleFontType  + ';' +
								'font-size: ' + @EmailSubTitleFontSize  + 'pt;' +							
							'}' +
							'.detailheadingfontstyle {' +
								'color: ' + @DetailHeadingFontColor + ';' +
								'font-weight: ' +  @DetailHeadingFontWeight + ';' +
								'font-family: ' + @DetailHeadingFontType  + ';' +
								'font-size: ' + @DetailHeadingFontSize  + 'pt;' +							
							'}' +
							'.detailsubheadingfontstyle {' +
								'color: ' + @DetailSubHeadingFontColor + ';' +
								'font-weight: ' +  @DetailSubHeadingFontWeight + ';' +
								'font-family: ' + @DetailSubHeadingFontType  + ';' +
								'font-size: ' + @DetailSubHeadingFontSize  + 'pt;' +							
							'}' +
							'.emailsalutfontstyle {' +
								'color: ' + @EmailSalutFontColor + ';' +
								'font-weight: ' +  @EmailSalutFontWeight + ';' +
								'font-family: ' + @EmailSalutFontType  + ';' +
								'font-size: ' + @EmailSalutFontSize  + 'pt;' +							
							'}' +
							'.emailsignaturefontstyle {' +
								'color: ' + @EmailSignatureFontColor + ';' +
								'font-weight: ' +  @EmailSignatureFontWeight + ';' +
								'font-family: ' + @EmailSignatureFontType  + ';' +
								'font-size: ' + @EmailSignatureFontSize  + 'pt;' +							
							'}' +
						'</style>' +
					'</head>'	
	-- ==========================================================
	-- EMAIL HEADER
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================		 
		IF COALESCE(@EmailHeaderText, '') <> ''
			SET @EmailHeaderText = '<p class="headertextfontstyle">' +  @EmailHeaderText + '</p>' 		

	-- =========================================================
	-- EMAIL SUB-TITLE
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSubTitle, '') <> ''
			SET @EmailSubTitle = '<p class-"subtitlefontstyle">' +  @EmailSubTitle + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================
		IF COALESCE(@DetailHeading, '') <> ''		
			SET @DetailHeading = '<p class="detailheadingfontstyle">' +  @DetailHeading + '</p>' 						
		
	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================		
		IF COALESCE(@DetailSubHeading, '') <> ''		
			SET @DetailSubHeading = '<p class="detailsubheadingfontstyle">' +  @DetailSubHeading + '</p>' 					

	-- =========================================================
	-- EMAIL BODY TEXT
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailBodyText, '') <> ''		
			SET @EmailBodyText = '<p class="bodyfontstyle">' +  @EmailBodyText + '</p>'					
		
	-- =========================================================
	-- EMAIL Salutation
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSalut, '') <> ''
			SET @EmailSalut = '<p class="emailsalutfontstyle">' +  @EmailSalut + '</p>' 			

	-- =========================================================
	-- EMAIL Signature
	-- This text is passed from section AEFECC in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSignature, '') <> ''		
			SET @EmailSignature = '<p class="emailsignaturefontstyle">' +  @EmailSignature + '</p>' 								  

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @HTMLHEAD = ' +  @HTMLHEAD
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailHeaderText = ' +  @EmailHeaderText
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSubTitle = ' +  @EmailSubTitle
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailHeading = ' +  @DetailHeading
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailSubHeading = ' +  @DetailSubHeading
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailBodyText = ' +  @EmailBodyText
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSalut = ' +  @EmailSalut
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSignature = ' +  @EmailSignature
		END	
				
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
					PRINT 'CABS_AEF_SEND_FFC: @AdminEmailAddr = ' +  @AdminEmailAddr							
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
			PRINT 'CABS_AEF_SEND_FFC: @EmailProfile = ' +  @EmailProfile			
		END	
	-- =============================================
	-- Send the Email
	-- =============================================
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_FFC: @EmailAddressType = ' +  @EmailAddressType
			PRINT 'CABS_AEF_SEND_FFC: @EMailAddr = ' +  @EMailAddr
			PRINT 'CABS_AEF_SEND_FFC: @SubjectLineText = ' +  @SubjectLineText			
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
			PRINT 'CABS_AEF_SEND_FFC: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
			PRINT 'CABS_AEF_SEND_FFC: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
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
			IF @DevOverride = 0 OR @DebugFlag  = 1 -- Ensures that the email is sent even when Debug flag is set on X CABS Config			
			BEGIN
				-- Replaced the EXEC command for an EXEC sp_executesql command to enable data to be returned - TT - 10/10/2016				 
				--EXEC(@SendEMailSQL)
				EXEC sp_executesql @SendEMailSQL, @PARAMS, @MailID = @MailItemID OUTPUT;
				-- Capture the MailItemId (from [sysmail_allitems]) - TT - 10/10/2016
				SELECT @MailItemID
					
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_FFC: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
				END	
				-- End of changes - TT - 10/10/2016
			END
		END --Email Address Type
		ELSE
			PRINT 'CABS_AEF_SEND_FFC: No Valid Email Address'

-- Added Label used in classification constaint code block - TT - 19/12/2016
DO_NOT_SEND_EMAIL:

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
				-- Added @MailItemID to INSERT statement - TT - 10/10/2016
				INSERT INTO AutoEmailFunction_FromTrigger
				SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
				AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
				AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AEF_SEND_FFC'+'-'+@EmailTemplate, AEF_DTYN, @MailItemID
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
		-- Changed Cursor SQL - TT - 16/11/2016
		INTO
			@AEF_KEY,
			@FREF,
			@MBRNO,		
			@EMAIL,
			@CEMAIL,			
			-- Added F_DATE - TT - 09/01/2017
			@FDATE		
	END

	CLOSE email_cursor
	DEALLOCATE email_cursor

	IF @DevOverride = 1
	BEGIN
		PRINT '******************************************************'
		PRINT 'CABS_AEF_SEND_FFC: Leaving Procedure CABS_AEF_SEND_FFC'
		PRINT '******************************************************'
	END	

END

GO

PRINT '*****************************************************************************'

PRINT 'CABS_AEF_SEND_FFC: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_FFC]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_FFC') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_SEND_FFC: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_FFC: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_FFC]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_FFC') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_SEND_FFC: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_FFC: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_FFC]
							   ,@name = N'Version' 
							   ,@value = N'5.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_FFC') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_SEND_FFC: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_FFC: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO