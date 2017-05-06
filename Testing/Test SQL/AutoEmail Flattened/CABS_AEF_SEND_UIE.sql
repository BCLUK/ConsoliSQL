-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_SEND_UIE'
SET @SPROC_Name = 'CABS_AEF_SEND_UIE'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_UIE]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_UIE]
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
-- Create date: 30/06/2016
--
-- Description:	This stored procedure is used within the CABS AutoEMail functionality
--				This specific procedure is used to send a weekly email to detail which completed events 
--				are still uninvoiced.
--              All components of this email are configured via X CABS Config settings (section AEFUIE)
--				Not all arguments passed are required but there are a number of similar stored
--				procedures and the it means the interface can is consistent between all.
--
--				The stored procedure currently only supports HTML email
-- =====================================================================================================
-- Version:		4
-- Date:		24/01/2017
-- =====================================================================================================
-- Changes:		TT: 08/06/2016: Original Version
-- Changes:		TT: 05/07/2016: Added @EmailSalut and @EmailSignature to the code
-- Changes:		TT: 02/08/2016	Changed SPROC to 'CABS_AEF_SEND_UIE-' + @EmailTemplate 
--								in INSERT to AutoEmailFunction_FromTrigger
-- Changes:		TT: 02/08/2016: Added code to cursor query records to limit 
--								returned records to only those that are relevant 
--								to FREF and Email Type
--				TT: 06/09/2016	Added nested cursor - should now send an email to all EC who have 
--								uninvoiced events
--								Added style	classes to the HTML header
--
-- Changes:		TT: 10/10/2016: Added code to add the mailitem_id from table sysmail_allitems into
--	(3)							audit table AutoEmailFunction_FromTrigger. This will occur when a call 
--								to sp_send_dbmail is made. This will enable better audit/diagnostic 
--
-- Changes:		TT: 24/01/2017: Added clause to select statement to ensure lines with a value of 0 will 
--	(4)							not be included
-- =====================================================================================================

CREATE PROCEDURE [dbo].[CABS_AEF_SEND_UIE] 
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
		PRINT 'CABS_AEF_SEND_UIE: Entered Procedure CABS_AEF_SEND_UIE' -- Amended TT - 29/06/2016					
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
	
	IF @DebugFlag = 1
		PRINT 'CABS_AEF_SEND_UIE: Debugging Turned on in X CABS Config'

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

	DECLARE @HTMLHEAD VARCHAR(MAX) -- Added - TT - 06/09/2016
	DECLARE @DetailSubHeadingOrig VARCHAR(MAX) -- Added - TT - 06/09/2016

-- ================================================================
-- PREPARE EMAIL - START - Read from Section CABS_AUTO_EMAIL_FUNCS
-- ================================================================
	IF @EmailFormat = 'HTML'
	BEGIN
		SET @RetChar = '<br>'
		SET @TabChar = (CHAR(9))
		-- Added Styling changes - TT - 06/09/2016
		-- =========================================================		 
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
		
		SET @DetailSubHeadingOrig = @DetailSubHeading
	-- End of changes - TT - 06/09/2016		
	END		

-- =============================================
-- Email Variables
-- =============================================
	DECLARE @AEF_KEY INT

-- =======================================================================
-- GET NO OF DAYS WITHIN WHICH INVOICE SHOULD BE SENT - DEFAULT IS 3 DAYS
-- =======================================================================
	DECLARE @InvoiceWithinDays VARCHAR(1000)
	SET @InvoiceWithinDays = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, '@InvoiceWithinDays')), '3')	

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
		--Added - TT - 06/09/2016
		DECLARE @AC_CODE VARCHAR(7)	
		DECLARE @EC_EMAIL VARCHAR(100)
		DECLARE @EC_NAME VARCHAR(100)
		
		DECLARE
			EC_CURSOR
		CURSOR FAST_FORWARD FOR
		-- Get list of EC Email Addresses that have email addresses in Op_File
		-- ECs that do not have a corresponding record will not get an email
		SELECT DISTINCT AC_CODE, COALESCE(O_EMAIL,''), CT_DESC FROM AC07
			INNER JOIN CT07 ON AC_CODE = CT_CODE
			INNER JOIN OP_FILE ON dbo.uf_Get_FirstName_From_CT_DESC(CT_DESC) = O_FIRST AND
			dbo.uf_Get_LastName_From_CT_DESC(CT_DESC) = O_LAST
		ORDER BY AC_CODE
				
		OPEN EC_CURSOR

		FETCH NEXT FROM
			EC_CURSOR
		INTO
			@AC_CODE,
			@EC_EMAIL,
			@EC_NAME

		WHILE @@fetch_status = 0
		BEGIN
			-- If the EC has no email address configured i.e. @EC_EMAIL is empty then get the next record
			IF @EC_EMAIL = ''
			BEGIN
				FETCH NEXT FROM
					EC_CURSOR
				INTO
					@AC_CODE,
					@EC_EMAIL,
					@EC_NAME

				CONTINUE
			END						

			--End of Added - TT - 06/09/2016
			-- =================================================================================
			-- GET the Function Refs for all of the Events that have ended but not yet invoiced
			-- The variable @FREFS will hold a list of comma separated Function Refs
			-- =================================================================================
			DECLARE @FREFS VARCHAR(2000)
			SET @FREFS = ''
			/*
				Replaced following code - TT - 06/09/2016 
				SELECT @FREFS = COALESCE(@FREFS + ',', '') + F_REF FROM FUNC_FIL FF INNER JOIN FOL_TRAN FT 
						ON FF.F_REF = FT.F_OWNER WHERE FT.F_INVDATE IS NULL AND FF.F_ENDDATETIME < GetDate()
			*/			
			SELECT  @FREFS = COALESCE(@FREFS + ',', '') + FT.F_OWNER FROM FOL_TRAN FT
				INNER JOIN FUNC_FIL ON F_REF = FT.F_OWNER 
				INNER JOIN AC07 ON F_SOURCE = AC_OWNER
				-- Added clause to select statment to ensure lines with a value of 0 will not be included - TT - 24/01/2017							
				--WHERE F_INVDATE IS NULL AND F_ENDDATETIME < GetDate() AND AC_CODE = @AC_CODE				
				WHERE F_INVDATE IS NULL AND F_ENDDATETIME < GetDate() AND F_VALUE <> 0 AND AC_CODE = @AC_CODE				
				GROUP BY FT.F_OWNER				
			-- If there are no functions to invoice then get the next record
			IF @FREFS = ''
			BEGIN
				FETCH NEXT FROM
					EC_CURSOR
				INTO
					@AC_CODE,
					@EC_EMAIL,
					@EC_NAME

				CONTINUE
			END
		
			-- End of Changes - TT - 06/09/2016

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @FREFS = ' +  @FREFS -- Amended TT - 28/06/2016						
				PRINT 'CABS_AEF_SEND_UIE: @AC_CDOE = ' +  @AC_CODE
				PRINT 'CABS_AEF_SEND_UIE: @EC_EMAIL = ' +  @EC_EMAIL
				PRINT 'CABS_AEF_SEND_UIE: @EC_NAME = ' +  @EC_NAME
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
			/* 
				Changed - TT - 09/06/2016

				Removed code as functionality requirements changed.

				Now sending Email to individual ECs

			DECLARE @DeptEmailAddr VARCHAR(512) 
			SET @DeptEmailAddr = ''

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @SendToDepartment = ' +  @SendToDepartment -- Amended TT - 28/06/2016			
				PRINT 'CABS_AEF_SEND_UIE: @Department = ' +  @Department -- Amended TT - 28/06/2016						
			END		

			IF @SendToDepartment = 1	
				SET @DeptEmailAddr = (SELECT [dbo].[uf_getDepteMail]('EVNTSADMIN'))

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @DeptEmailAddr = ' +  @DeptEmailAddr -- Amended TT - 28/06/2016			
			END
			*/
			-- =============================================
			-- Concatenate Email Addresses
			-- =============================================
			-- Changed @DeptEmailAddr to @EC_EMAIL - TT - 06/09/2016
			SET @EMailAddr = COALESCE(@EC_EMAIL, '')

			IF COALESCE(@EMailAddr, '') <> '' 
			BEGIN
				IF @DevOverride = 1 BEGIN
					PRINT 'CABS_AEF_SEND_UIE: @EMailAddr = ' +  @EMailAddr -- Amended TT - 28/06/2016				
				END			
			END
			ELSE
			IF COALESCE(@EMailAddr, '') = '' 
			BEGIN
				SET @NoEmail = 1
				SET @EMailAddr = @AdminEmailAddr
		
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_UIE: @NoEmail = ' +  CONVERT(VARCHAR, @NoEmail) -- Amended TT - 28/06/2016				
				END				
			END
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @FREF = ' +  @FREF -- Amended TT - 28/06/2016
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
			-- Build Subject Line
			-- =============================================
			SET @SubjectLineText = ''
			SET @SubjectLineText = (COALESCE(@SubjectLine, '') + COALESCE(@SubjectLineText, '')) + @EC_NAME -- Added - TT - 06/09/2016
		
			-- =============================================
			-- PREPARE EMAIL
			-- Currently only format supported is HTML
			-- =============================================
			IF @EmailFormat = 'HTML'
			BEGIN
	
				-- ==========================================================
				-- EMAIL HEADER
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================
				IF COALESCE(@EmailHeaderText, '') <> ''
					SET @EmailHeaderText = '<p class="headertextfontstyle">' +  @EmailHeaderText + '</p>'  		

				-- =========================================================
				-- EMAIL SUB-TITLE
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================				 	
				IF COALESCE(@EmailSubTitle, '') <> ''
					SET @EmailSubTitle = '<p class="subtitlefontstyle">' +  @EmailSubTitle + '</p>'

				-- =========================================================
				-- EMAIL DETAIL HEADING
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================						 
				IF COALESCE(@DetailHeading, '') <> ''
					SET @DetailHeading = '<p class="detailheadingfontstyle">' +  REPLACE(@DetailHeading,'**', @InvoiceWithinDays) + '</p>'

				-- =========================================================
				-- EMAIL DETAIL SUB HEADING
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================						 			
				IF COALESCE(@DetailSubHeading, '') <> ''
					SET @DetailSubHeading = '<p class="detailsubheadingfontstyle">' +  @DetailSubHeadingOrig + @RetChar + REPLACE(@FREFS,',',@RetChar) + '</p>'
		
				-- =========================================================
				-- EMAIL BODY TEXT
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================		
				IF COALESCE(@EmailBodyText, '') <> ''		
					SET @EmailBodyText = '<p class="bodyfontstyle">' +  @EmailBodyText + '</p>'
					
				-- =========================================================
				-- EMAIL Salutation
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================
				IF COALESCE(@EmailSalut, '') <> ''
					SET @EmailSalut = '<p class="emailsalutfontstyle">' +  @EmailSalut + '</p>' 			

				-- =========================================================
				-- EMAIL Signature
				-- This text is passed from section AEFUIE in X CABS Config
				-- =========================================================
				IF COALESCE(@EmailSignature, '') <> ''		
					SET @EmailSignature = '<p class="emailsignaturefontstyle">' +  @EmailSignature + '</p>' 	
			END	

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @EmailHeaderText = ' +  @EmailHeaderText -- Amended TT - 28/06/2016		
				PRINT 'CABS_AEF_SEND_UIE: @EmailSubTitle = ' +  @EmailSubTitle -- Amended TT - 28/06/2016			
				PRINT 'CABS_AEF_SEND_UIE: @DetailHeading = ' +  @DetailHeading -- Amended TT - 28/06/2016			
				PRINT 'CABS_AEF_SEND_UIE: @DetailSubHeading = ' +  @DetailSubHeading -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_UIE: @EmailBodyText = ' +  @EmailBodyText -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_UIE: @EmailSalut = ' +  @EmailSalut -- Amended TT - 05/07/2016			
				PRINT 'CABS_AEF_SEND_UIE: @EmailSignature = ' +  @EmailSignature -- Amended TT - 05/07/2016				
			END				

			-- =============================================
			-- Build Up Email
			-- =============================================
			IF @NoEmail = 1
				SET @EmailText = '*** NO RECIPIENT EMAIL ADDRESS - IN CABS CONFIG, SECTION DeptEmailAddresses, Add KEY-VALUE Pair EVNTSADMIN-EMAIL ADDRRESS *** ' + @EmailHeaderText
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
						PRINT 'CABS_AEF_SEND_UIE: @AdminEmailAddr = ' +  @AdminEmailAddr -- Amended TT - 28/06/2016							
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
				PRINT 'CABS_AEF_SEND_UIE: @EmailProfile = ' +  @EmailProfile -- Amended TT - 28/06/2016			
			END	
		
			-- =============================================
			-- Send the Email
			-- =============================================
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_UIE: @EmailAddressType = ' +  @EmailAddressType -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_UIE: @EMailAddr = ' +  @EMailAddr -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_UIE: @SubjectLineText = ' +  @SubjectLineText -- Amended TT - 28/06/2016			
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
				PRINT 'CABS_AEF_SEND_UIE: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
				PRINT 'CABS_AEF_SEND_UIE: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
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
						PRINT 'CABS_AEF_SEND_UIE: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
					END	
					-- End of changes - TT - 10/10/2016
				END
			END --Email Address Type
			ELSE
				PRINT 'CABS_AEF_SEND_UIE: No Valid Email Address'

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
					--	Changed SPROC to 'CABS_AEF_SEND_UIE'+'-'+@EmailTemplate to assist with debugging - TT - 02/08/2016
					-- Added @MailItemID to INSERT statement - TT - 10/10/2016
					INSERT INTO AutoEmailFunction_FromTrigger
					SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
					AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
					AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AEF_SEND_UIE'+'-'+@EmailTemplate, AEF_DTYN, @MailItemID
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
		
			-- Added - TT - 06/09/2016
			FETCH NEXT FROM
				EC_CURSOR
			INTO
				@AC_CODE,
				@EC_EMAIL,
				@EC_NAME
					
		END

		CLOSE EC_CURSOR
		DEALLOCATE EC_CURSOR
	-- End of Added - TT - 06/09/2016

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
		PRINT 'CABS_AEF_SEND_UIE: Leaving Procedure CABS_AEF_SEND_UIE' -- Amended TT - 29/06/2016					
		PRINT '******************************************************'
	END	
END

GO


PRINT '*****************************************************************************'

PRINT 'CABS_AEF_SEND_UIE: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_UIE]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_UIE') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_SEND_UIE: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_UIE: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_UIE]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_UIE') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_SEND_UIE: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_UIE: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_UIE]
							   ,@name = N'Version' 
							   ,@value = N'4.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_UIE') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_SEND_UIE: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_UIE: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO