-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_SEND_SWR'
SET @SPROC_Name = 'CABS_AEF_SEND_SWR'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_SWR]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_SWR]
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
-- Create date: 28/11/2016
-- Description:	This stored procedure is used within the CABS AutoEMail functionality
--				This specific procedure is used to send a weekly email to detail up and coming bookings
--
--              All components of this email are configured via X CABS Config settings (section AEFSWR)
--				Not all arguments passed are required but there are a number of similar stored
--				procedures and the it means the interface can is consistent between all.
--
--				The stored procedure currently only supports HTML email
-- =====================================================================================================--
-- Version:		2
-- Date:		01/12/2016
-- =====================================================================================================
-- Changes:		TT: 28/11/2016: Original Version
--	(1)
-- Changes:		TT: 01/12/2016: Changed how the Booker Email is determined
--	(2)
-- =====================================================================================================

CREATE PROCEDURE [dbo].[CABS_AEF_SEND_SWR] 
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
		PRINT 'CABS_AEF_SEND_SWR: Entered Procedure CABS_AEF_SEND_SWR' -- Amended TT - 29/06/2016					
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
		PRINT 'CABS_AEF_SEND_SWR: Debugging Turned on in X CABS Config'

-- =============================================
-- Set Type of Settings
-- =============================================		
		DECLARE @SettingsType VARCHAR(10)
		SET @SettingsType = 'S' 

-- =============================================
-- PREPARE EMAIL - START
-- =============================================
	DECLARE @EmailText VARCHAR(MAX)	
	DECLARE @RetChar VARCHAR(10)
	DECLARE @TabChar VARCHAR(10)

	DECLARE @HTMLHEAD VARCHAR(MAX)
	DECLARE @EmailHeaderTextOrig VARCHAR(MAX)
	DECLARE @EmailSubTitleOrig VARCHAR(MAX)
	DECLARE @DetailHeadingOrig VARCHAR(MAX)
	DECLARE @DetailSubHeadingOrig VARCHAR(MAX)
	DECLARE @EmailBodyTextOrig VARCHAR(MAX)
	DECLARE @EmailSalutOrig VARCHAR(MAX)
	DECLARE @EmailSignatureOrig VARCHAR(MAX)
						
-- ================================================================
-- PREPARE EMAIL - START - Read from Section CABS_AUTO_EMAIL_FUNCS
-- ================================================================
	IF @EmailFormat = 'HTML'
	BEGIN
		SET @RetChar = '<br>'
		SET @TabChar = (CHAR(9))
		
		-- Added Styling changes - TT - 07/09/2016
		-- =========================================================		 
		-- EMAIL TABLE STYLING
		-- =========================================================		 
		SET @HTMLHEAD = '<head>' + 
						'<title>Weekly Summary</title>' +		
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
		
		SET @EmailSubTitleOrig = @EmailSubTitle		
		SET @EmailHeaderTextOrig = @EmailHeaderText
		SET @EmailSubTitleOrig = @EmailSubTitle
		SET @DetailHeadingOrig = @DetailHeading
		SET @DetailSubHeadingOrig = @DetailSubHeading
		SET @EmailBodyTextOrig = @EmailBodyText
		SET @EmailSalutOrig = @EmailSalut
		SET @EmailSignatureOrig = @EmailSignature
	END		

-- =============================================
-- Email Variables
-- =============================================
	DECLARE @AEF_KEY INT

-- =======================================================================
-- Get the HyperLink to CABS WEB from X CABS Config
-- =======================================================================
	DECLARE @HyperLink1 VARCHAR(1000)
	DECLARE @HyperLink1_DisplayText VARCHAR(1000)
	DECLARE @HyperLink1_HTML VARCHAR(1000)
		
	SET @HyperLink1 = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, 'HyperLink1')), '')	
	SET @HyperLink1_DisplayText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, 'HyperLink1_DisplayText')), '')	
	SET @HyperLink1_HTML = 'No Link Configured !'

	IF (@HyperLink1 <> '') AND (@HyperLink1_DisplayText <> '')
	BEGIN
		SET @HyperLink1_HTML = '<a href="' + @HyperLink1 + '">' + @HyperLink1_DisplayText + '</a>'
	END

	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AEF_SEND_SWR: @HyperLink1 = ' +  @HyperLink1
		PRINT 'CABS_AEF_SEND_SWR: @HyperLink1_DisplayText = ' +  @HyperLink1_DisplayText
		PRINT 'CABS_AEF_SEND_SWR: @HyperLink1_HTML = ' +  @HyperLink1_HTML
	END

	DECLARE @ReportStartFromNowInDays VARCHAR(10)
	DECLARE @ReportDurationInDays VARCHAR(10)
	DECLARE @ReportStartDate DATETIME
	DECLARE @ReportEndDate DATETIME

	SET @ReportStartFromNowInDays = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, 'ReportStartFromNowInDays')), '7')	
	SET @ReportDurationInDays = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailTemplate, 'ReportDurationInDays')), '7')	

	SET @ReportStartDate = DATEADD(d, CONVERT(INT, @ReportStartFromNowInDays), GETDATE())
	SET @ReportStartDate = CONVERT(DATETIME, CONVERT(VARCHAR, @ReportStartDate, 103), 103)
	SET @ReportEndDate = DATEADD(d, CONVERT(INT, @ReportDurationInDays), @ReportStartDate)

	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AEF_SEND_SWR: @ReportStartFromNowInDays = ' +  @ReportStartFromNowInDays		
		PRINT 'CABS_AEF_SEND_SWR: @ReportDurationInDays = ' +  @ReportDurationInDays
		PRINT 'CABS_AEF_SEND_SWR: @ReportStartDate = ' +  CONVERT(VARCHAR, @ReportStartDate, 103)
		PRINT 'CABS_AEF_SEND_SWR: @ReportEndDate = ' +  CONVERT(VARCHAR, @ReportEndDate, 103)
	END

	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AEF_SEND_SWR: Prior to Cursor "email_cursor"'
		PRINT 'CABS_AEF_SEND_SWR: @FunctionRef = ' +  @FunctionRef
		PRINT 'CABS_AEF_SEND_SWR: @EmailTemplate = ' +  @EmailTemplate		
	END
-- ===================================================
-- Prepare Email Data - Cursor
-- Table AutoEmailFunction contains emails to be sent
-- ===================================================

	IF @DevOverride = 1
	BEGIN			
		DECLARE @CursourRecCount INT
		SET @CursourRecCount = (SELECT COUNT(AEF_KEY) FROM AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF
									WHERE AEF_CANSEND = 'Yes' AND AEF_SENT = 0 AND AEF_FUNC_REF = @FunctionRef AND AEFL_EMailType = @EmailTemplate)
		IF @CursourRecCount = 0
		BEGIN
			PRINT 'CABS_AEF_SEND_SWR: Records in Cursor email_cursor = ' + CONVERT(VARCHAR, @CursourRecCount) + ' - No Autoemails To Process !'
		END
		ELSE
		BEGIN
			PRINT 'CABS_AEF_SEND_SWR: Records in Cursor email_cursor = ' + CONVERT(VARCHAR, @CursourRecCount) + ' - Autoemails To Process'
		END
	END	

	DECLARE
		email_cursor
	CURSOR FAST_FORWARD FOR
		-- Added inner join limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016
		SELECT
			--AEF_KEY, AEF_FUNC_REF, AEF_ROOM, AEF_EMAIL, AEF_CEMAIL, AEF_BOOKER_EMAIL, AEF_CONTCT, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_DTYN, AEF_STARTDATETIME, AEF_CANSEND, AEF_SENT
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
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_SWR: In Cursor Loop "email_cursor"'
		END	

		DECLARE @FBOOKER VARCHAR(100)			
		DECLARE @SITENAME VARCHAR(100)
		DECLARE @RM_LOC VARCHAR(100)
		
		IF @DevOverride = 1
		BEGIN			
			DECLARE @CursourRecCount2 INT
			SET @CursourRecCount2 = (SELECT COUNT(*) FROM  (SELECT DISTINCT F_BOOKER, SITE_NAME FROM FUNC_FIL INNER JOIN ROOMS ON F_ROOM = RM_ABBR 								
																							 INNER JOIN SITE_LOCS ON RM_LOC = SL_LOC
																							 INNER JOIN SITES ON SITE_ID = SL_ID
																			   WHERE F_BOOKER <> '' AND  F_BOOKER IS NOT NULL AND
																					 F_STARTDATETIME BETWEEN @ReportStartDate AND @ReportEndDate) AS BookerPerSite) 
			IF @CursourRecCount2 = 0
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: Records in Cursor SWR_CURSOR = ' + CONVERT(VARCHAR, @CursourRecCount2) + ' - No Bookers To Process !'
			END
			ELSE
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: Records in Cursor SWR_CURSOR = ' + CONVERT(VARCHAR, @CursourRecCount2) + ' - Bookers To Process At This Site'
			END
		END	

		DECLARE
			SWR_CURSOR
		CURSOR FAST_FORWARD FOR
		-- Get list of Bookers per site that have confirmed functions during following configured time period				
		SELECT DISTINCT F_BOOKER, SITE_NAME, RM_LOC FROM FUNC_FIL INNER JOIN ROOMS ON F_ROOM = RM_ABBR 								
														  INNER JOIN SITE_LOCS ON RM_LOC = SL_LOC
														  INNER JOIN SITES ON SITE_ID = SL_ID
											WHERE F_BOOKER <> '' AND  F_BOOKER IS NOT NULL AND
												  F_STARTDATETIME BETWEEN @ReportStartDate AND @ReportEndDate
											ORDER BY F_BOOKER, SITE_NAME
																																									 
		OPEN SWR_CURSOR

		FETCH NEXT FROM
			SWR_CURSOR
		INTO
			@FBOOKER,
			@SITENAME,
			@RM_LOC			

		WHILE @@fetch_status = 0
		BEGIN
						
			-- If there is no Booker go to the next record
			IF @FBOOKER = ''
			BEGIN
				FETCH NEXT FROM
					SWR_CURSOR
				INTO
					@FBOOKER,
					@SITENAME,
					@RM_LOC					
				CONTINUE
			END									
													
			IF @DevOverride = 1
			BEGIN				
				PRINT 'CABS_AEF_SEND_SWR: @FBOOKER = ' +  @FBOOKER
				PRINT 'CABS_AEF_SEND_SWR: @SITENAME = ' +  @SITENAME
				PRINT 'CABS_AEF_SEND_SWR: @UseMBRInternForNames = ' +  @UseMBRInternForNames									
			END				

			DECLARE @FtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @FHeadtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @FDettableHTML  VARCHAR(MAX) ; --VARCHAR(8000) ;

			SET @FHeadtableHTML =				
					--'<table class="extras" cols=4><tr><td colspan=4 align ="center"><b>Extra Details</b></td></tr>' + 
					'<table class="extras">' + 
					'<tr><td align=center><b>Boooking Ref</b></td>' +
					'<td align=center><b>Date</b></td>' +
					'<td align=center><b>Time</b></td>' +
					'<td align=center><b>Meeting Title</b></td>' +
					'<td align=center><b>Room</b></td>' +
					'<td align=center><b>Host</b></td>' +
					'<td align=center><b>Attendees</b></td></tr>'	

			-- This code returns the list of extras for the given FREF and produces a single row of text containing
			-- delimited table cells and delimited rows e.g.:
			--
			--	<tr><td>data1</td><td>data2</td><td>data3</td></tr><tr><td>data4</td><td>data5</td><td>data6</td></tr>
			--
			SET @FDettableHTML = 			
			CAST 
			( 
				( SELECT F_REF AS td,
						 DATENAME(dw, F_DAY) + ',' + DATENAME(d, F_DAY) + ' ' + DATENAME(mm, F_DAY) + ' ' + DATENAME(yy, F_DAY) AS td,						
						 F_START + ' - ' + F_END AS td,
						 ISNULL(REPLACE(F_COMMENT, CHAR(39), CHAR(146)), 'N/A') AS td,
						 ISNULL(RM_NAME, 'N/A') AS td, 
						 ISNULL(dbo.[uf_GetMBRName](F_REF, @UseMBRInternForNames ), 'N/A') AS td, 
						 ISNULL(CONVERT(VARCHAR, F_PAX_ACT), 'N/A') AS td
						 FROM FUNC_FIL INNER JOIN ROOMS ON F_ROOM = RM_ABBR 
						 WHERE F_STARTDATETIME BETWEEN @ReportStartDate AND @ReportEndDate AND
													   F_BOOKER = @FBOOKER
						ORDER BY F_DAY, F_START
					FOR XML RAW('tr'), ELEMENTS 			
				)	 AS VARCHAR(MAX) 
			) + 
			'</table><br>'																								

			IF COALESCE(@FDettableHTML, '') = '' BEGIN
				SET @FtableHTML = ''
			END
			ELSE
			BEGIN
				SET @FtableHTML = (COALESCE(@FHeadtableHTML, '') + COALESCE(@FDettableHTML, ''))
				IF @DevOverride = 1
					BEGIN
					PRINT 'CABS_AEF_SEND_SWR: @FtableHTML = ' + @FtableHTML	
				END	
			END

			-- =============================================
			-- GET EMAIL ADDRESSES BEGIN
			-- =============================================
			DECLARE @NoEmail INT
			SET @NoEmail = 0

			DECLARE @EMailAddr VARCHAR(512)
			SET @EMailAddr = ''

			-- =============================================
		-- Booker Email Address
		-- =============================================
			DECLARE @BookerEmailAddr VARCHAR(512) 
			SET @BookerEmailAddr = ''

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @SendToBooker = ' + @SendToBooker		
			END

			IF @SendToBooker = 1
			BEGIN
				-- Replaced by TT - 22/11/2016
				-- SET @BookerEmailAddr = (SELECT COALESCE(B.MBR_EMAIL, '') FROM MBRFILE A, MBRFILE B WHERE B.MBR_EMAIL <> '' AND NOT B.MBR_EMAIL IS NULL AND @BookerID = B.MBR_IMPKEY AND A.MBR_SYSNO = @MBRNo)
				-- SET @BookerEmailAddr = COALESCE(@BEMAIL, '')
				-- Changed how the Booker Email is determined - TT - 01/12/2016
				SET @BookerEmailAddr = (SELECT TOP 1 MBR_EMAIL FROM MBRFILE WHERE MBR_IMPKEY = @FBOOKER)
			END

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @BookerEmailAddr = ' + @BookerEmailAddr				
			END

			-- =============================================
			-- Concatenate Email Addresses
			-- =============================================			
			SET @EMailAddr = COALESCE(@BookerEmailAddr, '')

			IF COALESCE(@EMailAddr, '') <> '' 
			BEGIN
				IF @DevOverride = 1 BEGIN
					PRINT 'CABS_AEF_SEND_SWR: @EMailAddr = ' +  @EMailAddr
				END				
			END
			ELSE
			IF COALESCE(@EMailAddr, '') = '' 
			BEGIN
				SET @NoEmail = 1
				SET @EMailAddr = @AdminEmailAddr
		
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_SWR: @NoEmail = ' +  CONVERT(VARCHAR, @NoEmail) -- Amended TT - 28/06/2016				
				END							
			END
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @FREF = ' +  @FREF -- Amended TT - 28/06/2016
			END		

/*		
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
*/
			-- =============================================
			-- Build Subject Line
			-- =============================================
			SET @SubjectLineText = ''
			SET @SubjectLineText = (COALESCE(@SubjectLine, '') + COALESCE(@SubjectLineText, '')) + '- Site: ' + @SITENAME
		
			-- =============================================
			-- PREPARE EMAIL
			-- Currently only format supported is HTML
			-- =============================================
			IF @EmailFormat = 'HTML'
			BEGIN

				-- ==========================================================
				-- EMAIL HEADER
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================
				SET @EmailHeaderText = @EmailHeaderTextOrig
				IF COALESCE(@EmailHeaderText, '') <> ''
					SET @EmailHeaderText = '<p class="headertextfontstyle">' +  @EmailHeaderText + '</p>'  			

				-- =============================================================
				-- EMAIL SUB-TITLE
				-- This text is passed from section AEFSWR in X CABS Config
				-- Added **FNAME** to be replaced later by the Bookers Firstname
				-- =============================================================			
				SET @EmailSubTitle = @EmailSubTitleOrig
				IF COALESCE(@EmailSubTitle, '') <> ''
				BEGIN
					DECLARE @FirstName VARCHAR(100)					
					SET @FirstName	= COALESCE((SELECT TOP 1 MBR_ADDR1 FROM MBRFILE INNER JOIN FUNC_FIL ON MBR_IMPKEY = F_BOOKER 
												WHERE  F_BOOKER = @FBOOKER AND F_BOOKER <> '' AND  F_BOOKER IS NOT NULL) , '*** First Name Not Available ! ***') 					
					IF @NoEmail = 0
						SET @EmailSubTitle = '<p class="subtitlefontstyle">' +  REPLACE(@EmailSubTitle, '**FNAME**', @FirstName) + '</p>' 	
					ELSE
						SET @EmailSubTitle = '<p class="subtitlefontstyle">' +  '*** BOOKER EMAIL ADDRESS COULD NOT BE FOUND ***<BR><BR>' + REPLACE(@EmailSubTitle, '**FNAME**', @FirstName) + '</p>'
						
				END							

				-- =========================================================
				-- EMAIL DETAIL HEADING
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================
				SET @DetailHeading = @DetailHeadingOrig
				IF COALESCE(@DetailHeading, '') <> ''
					SET @DetailHeading = '<p class="detailheadingfontstyle">' +  @DetailHeading + '</p>'

				DECLARE @BookingSite VARCHAR(100)
				SET @BookingSite = @SITENAME
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_SWR: @BookingSite = ' +  @BookingSite
				END		
				-- =========================================================
				-- EMAIL DETAIL HEADING
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================		
				SET @DetailSubHeading = @DetailSubHeadingOrig
				IF COALESCE(@DetailSubHeading, '') <> ''
				BEGIN
					SET @DetailSubHeading = '<p class="detailsubheadingfontstyle">' + REPLACE(@DetailSubHeading,'**LINK**', @HyperLink1_HTML) + '</p>'
					SET @DetailSubHeading = REPLACE(@DetailSubHeading,'**BSITE**', @BookingSite)
				END

				-- =========================================================
				-- EMAIL BODY TEXT
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================		
				SET @EmailBodyText = @EmailBodyTextOrig
				IF COALESCE(@EmailBodyText, '') <> ''		
						SET @EmailBodyText = '<p class="bodyfontstyle">' +  @EmailBodyText + '</p>'
									 				
				-- =========================================================
				-- EMAIL Salutation
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================
				SET @EmailSalut = @EmailSalutOrig
				IF COALESCE(@EmailSalut, '') <> ''
					SET @EmailSalut = '<p class="emailsalutfontstyle">' +  @EmailSalut + '</p>' 	

				-- =========================================================
				-- EMAIL Signature
				-- This text is passed from section AEFSWR in X CABS Config
				-- =========================================================
				SET @EmailSignature = @EmailSignatureOrig
				IF COALESCE(@EmailSignature, '') <> ''		
					SET @EmailSignature = '<p class="emailsignaturefontstyle">' +  REPLACE(@EmailSignature, '**BSITE**', @BookingSite) + '</p>'

			END	

			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @EmailHeaderText = ' +  @EmailHeaderText -- Amended TT - 28/06/2016		
				PRINT 'CABS_AEF_SEND_SWR: @EmailSubTitle = ' +  @EmailSubTitle -- Amended TT - 28/06/2016			
				PRINT 'CABS_AEF_SEND_SWR: @DetailHeading = ' +  @DetailHeading -- Amended TT - 28/06/2016			
				PRINT 'CABS_AEF_SEND_SWR: @DetailSubHeading = ' +  @DetailSubHeading -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_SWR: @EmailBodyText = ' +  @EmailBodyText -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_SWR: @EmailSalut = ' +  @EmailSalut -- Amended TT - 05/07/2016			
				PRINT 'CABS_AEF_SEND_SWR: @EmailSignature = ' +  @EmailSignature -- Amended TT - 05/07/2016					
			END						

			-- =============================================
			-- Build Up Email
			-- =============================================
			SET @EmailText = '<!DOCTYPE html><html>' + @HTMLHEAD + '<body>'						
						
			SET @EmailText = @EmailText + 
							 @EmailHeaderText +
							 @EmailSubTitle + 
							 @DetailHeading + 
							 @DetailSubHeading + 
							 @EmailBodyText + 
							 @FtableHTML +
							 @EmailSalut + 
							 @EmailSignature + 
							 '</body></html>'
				
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
						PRINT 'CABS_AEF_SEND_SWR: @AdminEmailAddr = ' +  @AdminEmailAddr -- Amended TT - 28/06/2016							
					END									
				END
				ELSE
					SET @EmailAddressType = '(X)'			
			END

			SET @SubjectLineText = (COALESCE(@SubjectLineText, ''))

			--- =============================================
			-- Get Booking Location
			-- =============================================
			DECLARE @LOC VARCHAR(6)
			SET @LOC = @RM_LOC
	
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @LOC = ' + CONVERT(VARCHAR, @LOC)
			END	

			-- ============================================================
			-- Get Specific Email Profile
			-- Email profiles are used to configure the From Email Address
			-- ============================================================

			IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailProfiles' AND [KEY] = @LOC) > 0
			BEGIN
				SET @EmailProfile = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailProfiles' AND [KEY] = @LOC)
			END
			ELSE		
			IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailTemplate AND [KEY] = 'EmailProfile') > 0
			BEGIN
				SET @EmailProfile = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @EmailTemplate AND [KEY] = 'EmailProfile')
			END
		
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @EmailProfile = ' +  @EmailProfile
			END	
		
			-- =============================================
			-- Send the Email
			-- =============================================
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AEF_SEND_SWR: @EmailAddressType = ' +  @EmailAddressType -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_SWR: @EMailAddr = ' +  @EMailAddr -- Amended TT - 28/06/2016
				PRINT 'CABS_AEF_SEND_SWR: @SubjectLineText = ' +  @SubjectLineText -- Amended TT - 28/06/2016			
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
				PRINT 'CABS_AEF_SEND_SWR: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
				PRINT 'CABS_AEF_SEND_SWR: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
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
						PRINT 'CABS_AEF_SEND_SWR: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
					END	
					-- End of changes - TT - 10/10/2016
				END
			END --Email Address Type
			ELSE
				PRINT 'CABS_AEF_SEND_SWR: No Valid Email Address'

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
					--	Changed SPROC to 'CABS_AEF_SEND_SWR'+'-'+@EmailTemplate to assist with debugging - TT - 02/08/2016
					-- Added @MailItemID to INSERT statement - TT - 10/10/2016
					INSERT INTO AutoEmailFunction_FromTrigger
					SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
					AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
					AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AEF_SEND_SWR'+'-'+@EmailTemplate, AEF_DTYN, @MailItemID
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
	
		-- Only use for debugging - BREAK
		
		FETCH NEXT FROM
			SWR_CURSOR
		INTO
			@FBOOKER,
			@SITENAME,
			@RM_LOC								
		END

		CLOSE SWR_CURSOR
		DEALLOCATE SWR_CURSOR

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
		PRINT 'CABS_AEF_SEND_SWR: Leaving Procedure CABS_AEF_SEND_SWR' -- Amended TT - 29/06/2016					
		PRINT '******************************************************'
	END	
END

GO

PRINT '*****************************************************************************'

PRINT 'CABS_AEF_SEND_SWR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_SWR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_SWR') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_SEND_SWR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_SWR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_SWR]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_SWR') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_SEND_SWR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_SWR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_SWR]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_SWR') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_SEND_SWR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_SWR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO