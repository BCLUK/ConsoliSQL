-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_SEND_DRM'
SET @SPROC_Name = 'CABS_AEF_SEND_DRM'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_DRM]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_DRM]
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

CREATE PROCEDURE [dbo].[CABS_AEF_SEND_DRM] 
						@StatusCode VARCHAR(1000), @EmailProfile VARCHAR(1000), @Company VARCHAR(1000), 
						@Enabled VARCHAR(1000),
						@AdminEmailAddr VARCHAR(1000), @EmailFormat VARCHAR(1000), @SubjectLine VARCHAR(1000), @SubjectLineText VARCHAR(1000), @EmailTitle VARCHAR(MAX), @EmailSubTitle VARCHAR(MAX),						
						@EmailSalut VARCHAR(MAX), @EmailSignature VARCHAR(1000), @DetailHeading VARCHAR(MAX), @DetailSubHeading VARCHAR(MAX), @SendToBooker VARCHAR(1000), 						
						@SendToHost VARCHAR(1000), @Bullet01 VARCHAR(1000), @Bullet02 VARCHAR(1000), @EmailLink01_Address VARCHAR(1000), @EmailLink02_Address VARCHAR(1000), @CurrencySymbol VARCHAR(1000),		
						@IncludeWeekends VARCHAR(1000), @Importance VARCHAR(1000), @Sensitivity VARCHAR(1000), @IncludeAttachments VARCHAR(1000), @FileAttachments VARCHAR(1000), @AddHostToSubject VARCHAR(1000), @DevOverride VARCHAR(1000),
						@OnlyIncludeAssignedExtras VARCHAR(1000), @ExtraCCToInclude VARCHAR(1000), @FirstRunDate VARCHAR(1000), @EmailType VARCHAR(1000), @EmailHeaderText VARCHAR(1000), @EmailFooterText VARCHAR(1000), @LocEmailAddress VARCHAR(1000), 
						@EmailTitleFontColor VARCHAR(1000), @EmailTitleFontSize VARCHAR(1000), @EmailTitleFontType VARCHAR(1000), @EmailTitleFontWeight VARCHAR(1000), @EmailSubTitleFontColor VARCHAR(1000), @EmailSubTitleFontSize VARCHAR(1000), @EmailSubTitleFontType VARCHAR(1000),
						@EmailSubTitleFontWeight VARCHAR(1000), @EmailSalutFontColor VARCHAR(1000), @EmailSalutFontSize VARCHAR(1000), @EmailSalutFontType VARCHAR(1000), @EmailSalutFontWeight VARCHAR(1000), @EmailSignatureFontColor VARCHAR(1000), @EmailSignatureFontSize VARCHAR(1000),
						@EmailSignatureFontType VARCHAR(1000), @EmailSignatureFontWeight VARCHAR(1000), @DetailHeadingFontColor VARCHAR(1000), @DetailHeadingFontSize VARCHAR(1000), @DetailHeadingFontType VARCHAR(1000), @DetailHeadingFontWeight VARCHAR(1000), @DetailSubHeadingFontColor VARCHAR(1000),
						@DetailSubHeadingFontSize VARCHAR(1000), @DetailSubHeadingFontType VARCHAR(1000), @DetailSubHeadingFontWeight VARCHAR(1000), @EmailHeaderTextFontColor VARCHAR(1000), @EmailHeaderTextFontSize VARCHAR(1000), @EmailHeaderTextFontType VARCHAR(1000), @EmailHeaderTextFontWeight VARCHAR(1000),
						@EmailFooterTextFontColor VARCHAR(1000), @EmailFooterTextFontSize VARCHAR(1000), @EmailFooterTextFontType VARCHAR(1000), @EmailFooterTextFontWeight VARCHAR(1000),
						@EmailBodyFontColor VARCHAR(1000), @EmailBodyFontSize VARCHAR(1000), @EmailBodyFontType VARCHAR(1000), @EmailBodyFontWeight VARCHAR(1000), @AddFuncRefToSubject VARCHAR(1000), @AttachCalendarFile VARCHAR(1000), @IncludeOtherSessionDetails VARCHAR(1000),
						@EmailLink01_DisplayText VARCHAR(1000), @EmailLink02_DisplayText VARCHAR(1000), @EmailTemplate VARCHAR(1000), @LayoutNumber VARCHAR(1000),
						@FromTrigger INT, @FunctionRef VARCHAR(7), @HideRoom VARCHAR(1000), @HideRoomGivenOverride VARCHAR(1000),
						@DetailHeading_Alt VARCHAR(1000), @DetailSubHeading_Alt VARCHAR(1000), @EmailHeaderText_Alt VARCHAR(1000), @EmailSubTitle_Alt VARCHAR(1000),
						@IncludeSubjectInBody VARCHAR(1000), @IncludeHostMBRNo VARCHAR(1000), @IncludeHostMBRTel VARCHAR(1000), @IncludeSessNo VARCHAR(1000), @IncludeBookingStatus VARCHAR(1000), @HiddenRoomText VARCHAR(1000),
						@IncludeBookerMBRNo VARCHAR(1000), @IncludeBookerName VARCHAR(1000), @IncludeBookerMBRTel VARCHAR(1000),
						@IncOtherSession VARCHAR(1000),
						@UseMBRInternForNames VARCHAR(1000), @UseJobTitleForMBRIntern VARCHAR(1000), @IncludeMeetingType VARCHAR(1000), @SendToDepartment VARCHAR(1000), @Department VARCHAR(1000), @DeptIncludeMailList VARCHAR(1000), @DeptExcludeMailList VARCHAR(1000),
						@EmailBodyFontColorDel VARCHAR(1000),
						@EmailBodyFontSizeDel VARCHAR(1000),
						@EmailBodyFontTypeDel VARCHAR(1000),
						@EmailBodyFontWeightDel VARCHAR(1000),
						@EmailBodyText VARCHAR(1000), -- 08/06/2016 - TT - Added new variable for email template specific config settings						
						@DebugFlag INT -- 28/06/2016 - TT - Added to ensure argment list is the same as other Email Template procedures to facilitate Dynamic SQL call in calling procedure

AS
BEGIN
	-- ====================================================================================================================
	-- Author:		Tony Tasker
	-- Create date: 22-Nov-2016
	-- Description:	Send a Booking Reminder Email to the Booker
	--				containing final details of event	
	--
	-- ====================================================================================================================
	-- Version 2
	-- Date: 06/03/2017
	-- ====================================================================================================================
	-- Changes: TT: 22/11/2016: Original Version
	--	(1)
	--
	-- Changes: TT: 06/03/2017: Removed the EmailAddressType information from 
	--	(2)					    the Email Subject Line at a clients request having checced internally nobody uses it.
	--	
	--							Added additional diagnostic information related to AutoEMailFunction table updates
	-- ====================================================================================================================
	SET NOCOUNT ON;

	IF @DevOverride = 1
	BEGIN
		PRINT '************************************************************************'
		PRINT 'CABS_AEF_SEND_DRM: Entered Procedure CABS_AEF_SEND_DRM'
		PRINT '************************************************************************'
	END	
-- =========================================
-- Update Function Records for Emailing
-- =========================================
	DECLARE @SQL VARCHAR(4000)
	IF @EmailType = 'S' AND @OnlyIncludeAssignedExtras = 1
		AND @ExtraCCToInclude = ''
	BEGIN
		UPDATE AutoEmailFunction
		SET AEF_CANSEND = 'No'
		WHERE NOT AEF_FUNC_REF IN(SELECT AI_FREF FROM AI_FILE)

		-- Added Additional Diagnostic Information - TT - 06/03/2017
		IF @DevOverride = 1
		BEGIN		
			PRINT 'CABS_AEF_SEND_DRM: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' +
				  '@EmailType = ' + '''' + 'S' + '''' +  ' AND @OnlyIncludeAssignedExtras = 1 AND @ExtraCCToInclude =' + ''''''
		END
		-- End of changes - 06/03/2017
	END
	ELSE
	IF @EmailType = 'S' AND @OnlyIncludeAssignedExtras = 1 AND @ExtraCCToInclude <> ''
	BEGIN
		SET @SQL = '
		UPDATE AutoEmailFunction
		SET AEF_CANSEND = ''No''
		WHERE NOT AEF_FUNC_REF IN(SELECT AI_FREF FROM AI_FILE, POST_DEF WHERE P_COSTCENT IN(' + @ExtraCCToInclude + '))'
	
		EXEC(@SQL)

		-- Added Additional Diagnostic Information - TT - 06/03/2017
		IF @DevOverride = 1
		BEGIN		
			PRINT 'CABS_AEF_SEND_DRM: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' + 
				  '@EmailType = ' + '''' + 'S' + '''' + ' AND @OnlyIncludeAssignedExtras = 1 AND @ExtraCCToInclude <> ' + ''''''				  
			PRINT 'CABS_AEF_SEND_DRM: Table AutoEmailFunction Update SQL (@SQL): ' + @SQL
		END
		-- End of changes - 06/03/2017
	END	
		
	IF @EmailType = 'E' AND @ExtraCCToInclude <> ''
	BEGIN
		SET @SQL = '
		UPDATE AutoEmailFunction
		SET AEF_CANSEND = ''No''
		WHERE NOT AEF_FUNC_REF IN(SELECT AI_FREF FROM AI_FILE, POST_DEF WHERE AI_CODE = P_CODE AND P_COSTCENT IN(' + @ExtraCCToInclude + '))'

		EXEC(@SQL)

		-- Added Additional Diagnostic Information - TT - 06/03/2017
		IF @DevOverride = 1
		BEGIN		
			PRINT 'CABS_AEF_SEND_DRM: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' + 
				  '@EmailType = ' + '''' + 'E' + '''' + ' AND @ExtraCCToInclude <> ' + ''''''				  
			PRINT 'CABS_AEF_SEND_DRM: Table AutoEmailFunction Update SQL (@SQL): ' + @SQL
		END
		-- End of changes - 06/03/2017
	END
-- =========================================
-- Refresh Function Lookup Data
-- =========================================
	UPDATE AutoEmailFunction
	SET AEF_ROOM = F_ROOM,
		AEF_USE = F_USE,
		AEF_PURPOSE = REPLACE(F_COMMENT, CHAR(39), CHAR(146)),
		AEF_BOOKER = F_BOOKER,
		AEF_START = F_START,
		AEF_END = F_END,
		AEF_SETUP = F_SETUP,
		AEF_BDOWN = F_BDOWN,
		AEF_COVERS = F_PAX_ACT,
		AEF_MBR_NO = F_MBR_NO,
		AEF_MBR_NAME = REPLACE(F_MBR_NAME, CHAR(39), CHAR(146)),
		AEF_INTERN = F_INTERN,
		AEF_STARTDATETIME = F_STARTDATETIME,
		AEF_UPDATED_DATE = GETUTCDATE(),
		AEF_RMGIVEN = F_RMGIVEN
	FROM FUNC_FIL
	WHERE AEF_FUNC_REF = F_REF
		AND ((AEF_ROOM <> F_ROOM)
		OR (AEF_USE <> F_USE)
		OR (AEF_PURPOSE <> REPLACE(F_COMMENT, CHAR(39), CHAR(146)))
		OR (AEF_BOOKER <> F_BOOKER)
		OR (AEF_START <> F_START)
		OR (AEF_END <> F_END)
		OR (AEF_SETUP <> F_SETUP)
		OR (AEF_BDOWN <> F_BDOWN)
		OR (AEF_COVERS <> F_PAX_ACT)
		OR (AEF_MBR_NO <> F_MBR_NO)
		OR (AEF_MBR_NAME <> REPLACE(F_MBR_NAME, CHAR(39), CHAR(146)))
		OR (AEF_INTERN <> F_INTERN)
		OR (AEF_STARTDATETIME <> F_STARTDATETIME))
-- =========================================
-- Refresh MBR Lookup Data
-- =========================================
	UPDATE AutoEmailFunction
	SET AEF_CONTCT = MBR_CONTCT,
		AEF_EMAIL = MBR_EMAIL,
		AEF_CEMAIL = MBR_CEMAIL,
		AEF_UPDATED_DATE = GETUTCDATE()
	FROM MBRFILE
	WHERE AEF_MBR_NO = MBR_SYSNO
		AND ((AEF_CONTCT <> MBR_CONTCT)
		OR (AEF_EMAIL <> MBR_EMAIL)
		OR (AEF_CEMAIL <> MBR_CEMAIL))
-- =========================================
-- Update Function Records for Emailing
-- =========================================	
	-- Removed code so email sent when status is cancelled - TT - 30/11/2016
	-- UPDATE AutoEmailFunction
	-- SET AEF_CANSEND = 'No'
	-- WHERE AEF_FUNC_REF in(SELECT F_REF FROM FUNC_FIL WHERE F_STATUS = 'CANCEL' AND COALESCE(F_STATUS, '') <> '')
	-- End of Changes - TT - 30/11/2016

	UPDATE AutoEmailFunction
	SET AEF_STATUS_TEXT = ST_DESC
	FROM SYS_ABBR
	WHERE ST_CODE = AEF_STATUS

	IF @HideRoom = 0 AND @HideRoomGivenOverride = 0 BEGIN
		UPDATE AutoEmailFunction
		SET AEF_ROOM_TEXT = REPLACE(RM_NAME, '''', CHAR(146))
		FROM ROOMS
		WHERE RM_ABBR = AEF_ROOM
	END

	IF @HideRoom = 1 AND @HideRoomGivenOverride = 0 BEGIN
		UPDATE AutoEmailFunction
		SET AEF_ROOM_TEXT = @HiddenRoomText
	END			

	IF @HideRoom = 0 AND @HideRoomGivenOverride = 1 BEGIN
		UPDATE AutoEmailFunction
		SET AEF_ROOM_TEXT = CASE AEF_RMGIVEN WHEN 'Yes' THEN REPLACE(RM_NAME, '''', CHAR(146)) ELSE @HiddenRoomText END
		FROM ROOMS
		WHERE RM_ABBR = AEF_ROOM
	END
						
	UPDATE AutoEmailFunction
	SET AEF_USE_TEXT = ST_DESC
	FROM SYS_ABBR 
	WHERE ST_CODE = AEF_USE

	IF @UseMBRInternForNames = 0
	BEGIN
		UPDATE AutoEmailFunction
		SET AEF_BOOKER_TEXT = REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146))
		FROM MBRFILE
		WHERE MBR_IMPKEY = AEF_BOOKER
		AND AEF_INTERN = 0

		UPDATE AutoEmailFunction
		SET AEF_BOOKER_TEXT =
		CASE @UseJobTitleForMBRIntern WHEN 0 THEN (REPLACE(COALESCE(MBR_ADDR2, ''), CHAR(39), CHAR(146)) + ' ' + REPLACE(COALESCE(MBR_ADDR1, ''), CHAR(39), CHAR(146)) + ' ' + REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146)))
		ELSE (MBR_ADDR1 + ' ' + REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146)) + ' (' + REPLACE(COALESCE(MBR_ADDR2, ''), CHAR(39), CHAR(146)) + ')') END
		FROM MBRFILE
		WHERE MBR_IMPKEY = AEF_BOOKER
		AND AEF_INTERN = 1
	END
	ELSE
	IF @UseMBRInternForNames = 1
	BEGIN
		UPDATE AutoEmailFunction
		SET AEF_BOOKER_TEXT = REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146))
		FROM MBRFILE
		WHERE MBR_IMPKEY = AEF_BOOKER
		AND MBR_INTERN = 0
		
		UPDATE AutoEmailFunction
		SET AEF_BOOKER_TEXT =
		CASE @UseJobTitleForMBRIntern WHEN 0 THEN (REPLACE(COALESCE(MBR_ADDR2, ''), CHAR(39), CHAR(146)) + ' ' + REPLACE(COALESCE(MBR_ADDR1, ''), CHAR(39), CHAR(146)) + ' ' + REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146)))
		ELSE (MBR_ADDR1 + ' ' + REPLACE(COALESCE(MBR_CMPNAM, ''), CHAR(39), CHAR(146)) + ' (' + REPLACE(COALESCE(MBR_ADDR2, ''), CHAR(39), CHAR(146)) + ')') END
		FROM MBRFILE
		WHERE MBR_IMPKEY = AEF_BOOKER
		AND MBR_INTERN = 1
	END

	UPDATE AutoEmailFunction
	SET AEF_EXTRAYN = 1
	WHERE (AEF_FUNC_REF in(SELECT COALESCE(AI_FREF, '') FROM AI_FILE WHERE AI_CODE <> 'AUTOEZ') OR
	AEF_FUNC_REF in(SELECT COALESCE(AEFA_FREF, '') FROM AEF_Amendments WHERE AEFA_ACTION = 'D' AND AEFA_CODE <> 'AUTOEZ'))

	UPDATE AutoEmailFunction
	SET AEF_PACKYN = 1
	WHERE AEF_FUNC_REF in(SELECT COALESCE(PH_OWNER, '') FROM PKGHEAD)

	UPDATE AutoEmailFunction
	SET AEF_MENUYN = 1
	WHERE AEF_FUNC_REF in(SELECT COALESCE(MNM_OWNER, '') FROM MASTMENU)
	
	UPDATE AutoEmailFunction
	SET AEF_DTYN = 1
	WHERE AEF_FUNC_REF IN(SELECT COALESCE(DTH_OWNER, '') FROM DrinkTrolleyHead) 

	UPDATE AutoEmailFunction
	SET AEF_EMAIL = MBR_EMAIL
	FROM MBRFILE
	WHERE MBR_SYSNO = AEF_MBR_NO
	AND COALESCE(AEF_EMAIL, '') = ''
	
	UPDATE AutoEmailFunction
	SET AEF_BOOKER_EMAIL = MBR_EMAIL
	FROM MBRFILE
	WHERE MBR_IMPKEY = AEF_BOOKER

	-- Added Additional Diagnostic Information - TT - 06/03/2017
	IF @DevOverride = 1
	BEGIN		
		PRINT 'CABS_AEF_SEND_DRM: Table AutoEmailFunction could have been updated'			  
	END
	-- End of changes - 06/03/2017

-- =============================================
-- DECLARATIONS
-- =============================================
	DECLARE @FREF varchar(7)
	DECLARE @EMAIL varchar(100)
	DECLARE @CEMAIL varchar(100)
	DECLARE @BEMAIL varchar(100)
	DECLARE	@EMAILSTRING varchar(500)
	DECLARE @CONTACT varchar(50)
	DECLARE @EXTRAYN int
	DECLARE @PACKYN int
	DECLARE @MENUYN int
	DECLARE @DTYN int
	DECLARE @CANSEND varchar(3)
	DECLARE @SENT int
	DECLARE @FDATE datetime
	DECLARE @FSTART varchar(5)	

-- =============================================
-- PREPARE EMAIL - START
-- =============================================
	DECLARE @EmailText VARCHAR(MAX)	
	DECLARE @HostName VARCHAR(MAX)
	DECLARE @EmailHeader VARCHAR(MAX)
		
	DECLARE @EmailFooter VARCHAR(MAX)	
	DECLARE @BodyText VARCHAR(MAX)
	
	DECLARE @EmailLink01_Text VARCHAR(MAX)
	DECLARE @EmailLink02_Text VARCHAR(MAX)
			
	DECLARE @RetChar VARCHAR(MAX)
	DECLARE @TabChar VARCHAR(MAX)

	DECLARE @HTMLHEAD VARCHAR(MAX) -- Added - TT - 07/07/2016
-- =============================================
-- PREPARE EMAIL - START
-- =============================================
	IF @EmailFormat = 'HTML'
	BEGIN
		SET @RetChar = '<br>'
		SET @TabChar = (CHAR(9))
	END	
-- =============================================
-- PREPARE EMAIL
-- =============================================
	IF @EmailFormat = 'HTML'
	BEGIN
		
	-- Added - TT - 07/07/2016
	-- ==========================================================
	-- EMAIL TABLE STYLING
	-- =========================================================		 
	SET @HTMLHEAD = '<head>' + 
						'<title>Reminder Email</title>' +		
						'<style>' +
							'table.details td {' +								
								'color: ' + @EmailBodyFontColor + ';' +
								'font-weight: ' +  @EmailBodyFontWeight + ';' +
								'font-family: ' + @EmailBodyFontType  + ';' +
								'font-size: ' + @EmailBodyFontSize  + 'pt;' +	
							'}' +							
							'table.extras {' +
								'border-collapse: collapse;' +
								'empty-cells: show;' +
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
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @HTMLHEAD = ' +  @HTMLHEAD
		END
	END	
	
-- =============================================
-- EMAIL BODY TEXT
-- =============================================
-- =============================================
-- Email Variables
-- =============================================
	DECLARE @Header VARCHAR(MAX)
	DECLARE @Footer VARCHAR(MAX)	
	DECLARE @SBODY VARCHAR(MAX)	
	DECLARE @EBody VARCHAR(MAX)
	DECLARE @XEBody VARCHAR(MAX)	
	DECLARE @PBody VARCHAR(MAX)
	DECLARE @MBody VARCHAR(MAX)
	DECLARE @DTBody VARCHAR(MAX)

	DECLARE @tableHTML VARCHAR(MAX)
	DECLARE @BtableHTML VARCHAR(MAX)
	
	DECLARE @FStableHTML VARCHAR(MAX)
	DECLARE @FSHeadtableHTML VARCHAR(MAX)
	DECLARE @SHeadtableHTML VARCHAR(MAX)
		
	DECLARE @Salutation VARCHAR(100)
	DECLARE @AEF_KEY INT
-- =============================================
-- Prepare Email Data - Cursor
-- =============================================
	DECLARE 
		email_cursor
	CURSOR FAST_FORWARD for

		-- Added inner join limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016
		SELECT
			AEF_KEY, AEF_FUNC_REF, AEF_EMAIL, AEF_CEMAIL, AEF_BOOKER_EMAIL, AEF_CONTCT, AEF_EXTRAYN, AEF_PACKYN, 
			AEF_MENUYN, AEF_DTYN, AEF_CANSEND, AEF_SENT, AEF_DATE, AEF_START
		FROM
			AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF
		WHERE
			AEF_CANSEND = 'Yes'
		AND
			AEF_SENT = 0
		-- Added to limit returned records to only those that are relevant to FREF and Email Type - TT - 13/07/2016 
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
		@EMAIL,
		@CEMAIL,
		@BEMAIL,
		@CONTACT,
		@EXTRAYN,
		@PACKYN,
		@MENUYN,
		@DTYN,
		@CANSEND,
		@SENT,
		@FDATE,
		@FSTART

	WHILE @@fetch_status = 0
	BEGIN

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @FREF = ' + @FREF
		END

	-- =============================================
	-- EMAIL BODY TEXT
	-- =============================================
		DECLARE @MBRNo VARCHAR(7)
		DECLARE @InternYN INT				
		DECLARE @Host VARCHAR(100)
		DECLARE @HostEmail VARCHAR(100)
					
		DECLARE @Operator VARCHAR(31)
		DECLARE @OpName VARCHAR(300)
	
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
			SET @Host = (SELECT COALESCE(LTRIM(RTRIM( COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR2, CHAR(39), CHAR(146)))), '') + ' ' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR1, CHAR(39), CHAR(146)))), '') + ' ' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), ''))), '') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		END
		ELSE	
		IF @InternYN = 0
		BEGIN
			SET @Host = (SELECT COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), '') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		END

	-- ================================================
	-- FUNCTION DETAILS - STARTED
	-- ================================================
	-- =============================================
	--EMAIL BODY				
	--Function Details
	-- =============================================
		DECLARE	@HostTel VARCHAR(200),
				@Booker VARCHAR(100),
				@BookerID VARCHAR(15),
				@BookerMBR VARCHAR(7),
				@Status VARCHAR(50),
				@FuncDate VARCHAR(50),
				@FuncTimes VARCHAR(20),
				@Event VARCHAR(100),
				@PAX INT,
				@MeetType VARCHAR(100),
				@Location VARCHAR(100),
				@CostCent VARCHAR(6),
				@RoomName VARCHAR(100),
				@RoomUse VARCHAR(100),
				@SessNo VARCHAR(7),
				@Purpose VARCHAR(100),
				@RoomCharge VARCHAR(10),
				@BookerTel VARCHAR(100)

		DECLARE @FBody  VARCHAR(MAX)
		SET @FBody= ''
	
		DECLARE @FSBody  VARCHAR(MAX)
		SET @FSBody= ''

		SET @HostTel =  (SELECT COALESCE(LTRIM(RTRIM(MBR_PHAX1)), '') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)
		SET @BookerID = (SELECT COALESCE(LTRIM(RTRIM(F_BOOKER)), '') FROM FUNC_FIL WHERE F_REF = @FREF)
	
		IF COALESCE(@BookerID, '') <> ''
		BEGIN
			SET @BookerMBR = (SELECT COALESCE(LTRIM(RTRIM(MBR_SYSNO)), '') FROM MBRFILE WHERE MBR_IMPKEY = @BookerID)
			SET @BookerTel = (SELECT COALESCE(LTRIM(RTRIM(MBR_PHAX1)), '') FROM MBRFILE WHERE MBR_IMPKEY = @BookerID)
		END

		IF @InternYN = 0
		BEGIN	
			SET @Booker = (SELECT COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), '') FROM MBRFILE WHERE MBR_SYSNO = @BookerMBR)
			SET @MeetType = 'Client'
		END
		ELSE
		IF @InternYN = 1
		BEGIN
			SET @Booker = CASE @UseJobTitleForMBRIntern WHEN 0 THEN (SELECT COALESCE(LTRIM(RTRIM( COALESCE(LTRIM(RTRIM(MBR_ADDR2)), '') + ' ' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR1, CHAR(39), CHAR(146)))), '') + ' ' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), ''))), '') FROM MBRFILE WHERE MBR_SYSNO = @BookerMBR)
						  ELSE (SELECT COALESCE(LTRIM(RTRIM(
						  COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR1, CHAR(39), CHAR(146)))), '') + ' ' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_CMPNAM, CHAR(39), CHAR(146)))), '')) + ' (' + COALESCE(LTRIM(RTRIM(REPLACE(MBR_ADDR2, CHAR(39), CHAR(146)))), '') + ')'), '') FROM MBRFILE WHERE MBR_SYSNO = @BookerMBR) END	
			SET @MeetType = 'Internal'
		END

		SET @Status = (SELECT COALESCE(LTRIM(RTRIM(ST_DESC)), '') FROM FUNC_FIL, SYS_ABBR WHERE F_REF = @FREF AND F_STATUS = ST_CODE AND ST_TYPE = 'RSC')
		SET @FuncDate = (SELECT DATENAME( dw, F_DAY ) + ', ' +
					DATENAME(  d, F_DAY ) + ' ' +
					DATENAME( mm, F_DAY ) + ' ' + 
					DATENAME( yy, F_DAY )
					FROM FUNC_FIL WHERE	F_REF = @FREF)
		SET @FuncTimes = (SELECT F_START + ' until ' + F_END FROM FUNC_FIL WHERE F_REF = @FREF)
		SET @Event = (SELECT COALESCE(LTRIM(RTRIM(F_COMMENT)), '') FROM FUNC_FIL WHERE F_REF = @FREF)

		SET @PAX = (SELECT F_PAX_ACT FROM FUNC_FIL WHERE F_REF = @FREF)
		SET @Location = (SELECT ST_DESC FROM FUNC_FIL, ROOMS, SYS_ABBR WHERE F_ROOM = RM_ABBR AND ST_CODE = RM_LOC AND F_REF = @FREF)
		SET @CostCent = (SELECT F_CBACK FROM FUNC_FIL WHERE F_REF = @FREF)
		SET @RoomName = (SELECT AEF_ROOM_TEXT FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF)
		SET @RoomUse = (SELECT AEF_USE_TEXT FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF)
		SET @SessNo = (SELECT F_SESSNO FROM FUNC_FIL WHERE F_REF = @FREF)
		SET @Purpose = (SELECT AEF_PURPOSE FROM AutoEmailFunction WHERE AEF_FUNC_REF = @FREF)
		SET @RoomCharge = (SELECT CONVERT(VARCHAR, CONVERT(MONEY, F_RM_CHG)) FROM FUNC_FIL WHERE F_REF = @FREF)

	--========================================
	--========================================
		DECLARE @IncBookerDetails INT
		SET @IncBookerDetails = 0
		IF (@IncludeBookerMBRNo = 1 OR @IncludeBookerName = 1 OR @IncludeBookerMBRTel = 1)
		BEGIN
			SET @IncBookerDetails = 1
		END
	
	-- =============================================
	-- GET EMAIL ADDRESSES BEGIN
	-- =============================================
		DECLARE @NoEmail INT
		SET @NoEmail = 0

		DECLARE @EMailAddr VARCHAR(512)
		SET @EMailAddr = ''
		/*
	-- =============================================
	-- Host Email Address
	-- =============================================
		DECLARE @HostEmailAddr VARCHAR(512) 
		SET @HostEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @SendToHost = ' + @SendToHost		
		END
		IF @SendToHost = 1
		BEGIN
			SET @HostEmailAddr = (SELECT COALESCE(MBR_EMAIL, '') FROM MBRFILE WHERE MBR_EMAIL <> '' AND NOT MBR_EMAIL IS NULL AND MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @HostEmailAddr = ' + @HostEmailAddr				
		END
		*/
	-- =============================================
	-- Booker Email Address
	-- =============================================
		DECLARE @BookerEmailAddr VARCHAR(512) 
		SET @BookerEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @SendToBooker = ' + @SendToBooker		
		END

		IF @SendToBooker = 1
		BEGIN
			-- Replaced by TT - 22/11/2016
			-- SET @BookerEmailAddr = (SELECT COALESCE(B.MBR_EMAIL, '') FROM MBRFILE A, MBRFILE B WHERE B.MBR_EMAIL <> '' AND NOT B.MBR_EMAIL IS NULL AND @BookerID = B.MBR_IMPKEY AND A.MBR_SYSNO = @MBRNo)
			SET @BookerEmailAddr = COALESCE(@BEMAIL, '')
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @BookerEmailAddr = ' + @BookerEmailAddr				
		END
		/*
		-- =============================================
		-- Department Email Address
		-- =============================================
		DECLARE @DeptEmailAddr VARCHAR(512) 
		SET @DeptEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @SendToDepartment = ' + @SendToDepartment
			PRINT 'CABS_AEF_SEND_DRM: @Department = ' + @Department
		END

		IF @SendToDepartment = 1
		BEGIN
			--SET @DeptEmailAddr = (SELECT [dbo].[uf_getFunctionDeptEmails] (@FREF, @Department, NULL, NULL))
			SET @DeptEmailAddr = (SELECT [dbo].[uf_getFunctionDeptEmails] (@FREF, @Department, @DeptIncludeMailList, @DeptExcludeMailList))
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @DeptEmailAddr = ' + @DeptEmailAddr				
		END
	-- Added - TT - 07/07/2016
	-- =============================================
	-- Client Contact Email Address
	-- =============================================
		DECLARE @ClientEmailAddr VARCHAR(512) 
		DECLARE @SendToClient VARCHAR(100)

		SET @ClientEmailAddr = ''

		SET @SendToClient = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', 'CABS_AEF_SEND_DRM', 'SendToClient')), '')
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @ClientEmailAddr = ' + @ClientEmailAddr		
		END

		IF @SendToClient = 1
		BEGIN
		
			SET @ClientEmailAddr = @CEMAIL

			IF COALESCE(@ClientEmailAddr,'') = ''
				SET @ClientEmailAddr = (SELECT COALESCE(CT_EMAIL, '') FROM CONTACTS INNER JOIN MBRFILE ON MBR_CONTNO = CT_SYSNO WHERE MBR_SYSNO = @MBRNo)
		
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @ClientEmailAddr = ' + @ClientEmailAddr				
		END
		-- End of changes - TT - 07/07/2016
		-- =============================================
		-- Contact Email Addresses
		-- =============================================
		-- Added - TT - 07/07/2016
		IF COALESCE(@ClientEmailAddr, '') <> '' BEGIN
			SET @ClientEmailAddr = (@ClientEmailAddr + '; ')
		--End of Add - TT - 07/07/2016
		END	    
		IF COALESCE(@HostEmailAddr, '') <> '' BEGIN
			SET @HostEmailAddr = (@HostEmailAddr + '; ')
		END	    
	
		IF COALESCE(@BookerEmailAddr, '') <> '' BEGIN
			SET @BookerEmailAddr = (@BookerEmailAddr + '; ')
		END  	

		IF COALESCE(@DeptEmailAddr, '') <> '' BEGIN
			SET @DeptEmailAddr = (@DeptEmailAddr + '; ')
		END	
		-- Added @ClientEmailAddr - TT - 07/07/2016
		SET @EMailAddr = COALESCE(@ClientEmailAddr, '') + COALESCE(@HostEmailAddr, '') + COALESCE(@BookerEmailAddr, '') + COALESCE(@DeptEmailAddr, '')
		*/
		IF @EmailFormat = 'HTML'
		BEGIN
			-- ==========================================================
	-- EMAIL HEADER
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================		 
		IF COALESCE(@EmailHeaderText, '') <> ''
			SET @EmailHeaderText = '<p class="headertextfontstyle">' +  @EmailHeaderText + '</p>' 		

	-- =============================================================
	-- EMAIL SUB-TITLE
	-- This text is passed from section AEFDRM in X CABS Config
	-- Added **FNAME** to be replaced later by the Bookers Firstname
	-- =============================================================			
		IF COALESCE(@EmailSubTitle, '') <> ''
		BEGIN
			DECLARE @FirstName VARCHAR(100)
			SET @FirstName	= COALESCE((SELECT MBR_ADDR1 FROM MBRFILE INNER JOIN FUNC_FIL ON MBR_IMPKEY = F_BOOKER 
										WHERE F_REF = @FREF AND F_BOOKER <> '' AND  F_BOOKER IS NOT NULL) , @Host) 
			SET @EmailSubTitle = '<p class-"subtitlefontstyle">' +  REPLACE(@EmailSubTitle, '**FNAME**', @FirstName) + '</p>' 	
		END			
	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================
		IF COALESCE(@DetailHeading, '') <> ''
			SET @DetailHeading = '<p class="detailheadingfontstyle">' +  @DetailHeading + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================		
		IF COALESCE(@DetailSubHeading, '') <> ''
			SET @DetailSubHeading = '<p class="detailsubheadingfontstyle">' +  @DetailSubHeading  + '</p>' 

	-- =========================================================
	-- EMAIL BODY TEXT
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================
		DECLARE @BookingSite VARCHAR(100)
		SET @BookingSite = COALESCE((SELECT SITE_NAME FROM FUNC_FIL INNER JOIN ROOMS ON F_ROOM = RM_ABBR 								
																	INNER JOIN SITE_LOCS ON RM_LOC = SL_LOC
																	INNER JOIN SITES ON SITE_ID = SL_ID
																	WHERE F_REF = @FREF) , '') 

																	 
		IF COALESCE(@EmailBodyText, '') <> ''		
		BEGIN					
			SET @EmailBodyText = '<p class="bodyfontstyle">' +  @EmailBodyText + '</p>'
		END
	
	-- Added - TT - 05/07/2016
	-- =========================================================
	-- EMAIL Salutation
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSalut, '') <> ''
			SET @EmailSalut = '<p class="emailsalutfontstyle">' +  REPLACE(@EmailSalut, '**BSITE**', @BookingSite) + '</p>' 			

	-- =========================================================
	-- EMAIL Signature
	-- This text is passed from section AEFDRM in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSignature, '') <> ''		
			SET @EmailSignature = '<p class="emailsignaturefontstyle">' +  REPLACE(@EmailSignature, '**BSITE**', @BookingSite) + '</p>' 								  

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @HTMLHEAD = ' +  @HTMLHEAD
			PRINT 'CABS_AEF_SEND_DRM: @EmailHeaderText = ' +  @EmailHeaderText		
			PRINT 'CABS_AEF_SEND_DRM: @EmailSubTitle = ' +  @EmailSubTitle			
			PRINT 'CABS_AEF_SEND_DRM: @DetailHeading = ' +  @DetailHeading			
			PRINT 'CABS_AEF_SEND_DRM: @DetailSubHeading = ' +  @DetailSubHeading
			PRINT 'CABS_AEF_SEND_DRM: @EmailBodyText = ' +  @EmailBodyText	
			PRINT 'CABS_AEF_SEND_DRM: @EmailSalut = ' +  @EmailSalut			
			PRINT 'CABS_AEF_SEND_DRM: @EmailSignature = ' +  @EmailSignature			
		END	
		
		SET @EmailSalut = @EmailSalut + @EmailSignature	
			-- =============================================
			--EMAIL BODY				
			--Booking Details
			-- =============================================
			SET @BtableHTML = '<table class="details">' + 
								  '<tr><td><b>Booked By:</b></td><td>' + @Host + '</td></tr>' + 
								  '<tr><td><b>Booking Ref:</b></td><td>' + @FREF + '</td></tr>' + 
								  '<tr><td><b>Date:</b></td><td>' + @FuncDate + '</td></tr>' + 
								  '<tr><td><b>Time:</b></td><td>' + @FuncTimes + '</td></tr>' + 
								  '<tr><td><b>Room:</b></td><td>' + @RoomName + '</td></tr>' + 									  
								  '<tr><td><b>Status:</b></td><td>' + @Status + '</td></tr>' + 
								  '<tr><td><b>Layout:</b></td><td>' + @RoomUse + '</td></tr>' + 									  					  							  
								  '<tr><td><b>Attendees:</b></td><td>' + CONVERT(VARCHAR, @PAX) + '</td></tr>' + 
								  '<tr><td><b>Booking Name:</b></td><td>' + @Purpose + '</td></tr>' + 								  
								  '</table><br>'							  
										  							 							  							  								  		
			-- =============================================
			--EMAIL BODY				
			--Extra Details
			-- =============================================
			--Extras
			SET @EBody = ''
			SET @XEBody = ''
			--IF @EXTRAYN = 1
			--BEGIN
		
			DECLARE @EtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @EHeadtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @EDettableHTML  VARCHAR(MAX) ; --VARCHAR(8000) ;
										
			SET @EHeadtableHTML =				
					'<table class="extras" cols=4><tr><td colspan=4 align ="center"><b>Extra Details</b></td></tr>' + 
					'<tr><td align=center><b>Covers</b></td>' +
					'<td align=center><b>Extra</b></td>' +
					'<td align=center><b>Cost</b></td>' +
					'<td align=center><b>Additional Info</b></td></tr>'												

			-- This code returns the list of extras for the given FREF and produces a single row of text containing
			-- delimited table cells and delimited rows e.g.:
			--
			--	<tr><td>data1</td><td>data2</td><td>data3</td></tr><tr><td>data4</td><td>data5</td><td>data6</td></tr>
			--
			SET @EDettableHTML = 			
			CAST 
			( 
				( SELECT CONVERT(VARCHAR(10), AI_COVERS) AS td,
						 P_DESC AS td,
						CAST(CAST(AI_CHARGE AS DECIMAL(10,2)) AS VARCHAR(20)) AS td,
						ISNULL(AI_TEXT,'N/A') AS td
					FROM vw_Extras
					WHERE AI_FREF = @FREF 
					ORDER BY AI_TIME
					FOR XML RAW('tr'), ELEMENTS 			
				)	 AS VARCHAR(MAX) 
			) + 
			'</table><br>'																								

			IF COALESCE(@EDettableHTML, '') = '' BEGIN
				SET @EtableHTML = ''
			END
			ELSE
			BEGIN
				SET @EtableHTML = (COALESCE(@EHeadtableHTML, '') + COALESCE(@EDettableHTML, ''))
				IF @DevOverride = 1
					BEGIN
					PRINT 'CABS_AEF_SEND_DRM: @EtableHTML = ' + @EtableHTML	
				END	
			END

			-- =============================================
			--EMAIL BODY				
			--Visitor Details
			-- =============================================
			DECLARE @VtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @VHeadtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @VDettableHTML  VARCHAR(MAX) ; --VARCHAR(8000) ;
			SET @VHeadtableHTML =				
					'<table class="extras" cols=2><tr><td colspan=4 align ="center"><b>Visitors</b></td></tr>' + 
					'<tr><td align=center><b>Name</b></td>' +
					'<td align=center><b>Car Registration</b></td></tr>'												

			-- This code returns the list of visitors for the given FREF and produces a single row of text containing
			-- delimited table cells and delimited rows e.g.:
			--
			--	<tr><td>data1</td><td>data2</td><td>data3</td></tr><tr><td>data4</td><td>data5</td><td>data6</td></tr>
			--
			SET @VDettableHTML = 			
			CAST 
			( 
				( SELECT 
					CASE WHEN (COALESCE(V_TITLE, '') + ' ' + COALESCE(V_FORENAME, '') + ' ' + COALESCE(V_SURNAME, '')) = '  ' 
						THEN 'N/A' 
						ELSE (COALESCE(V_TITLE, '') + ' ' + COALESCE(V_FORENAME, '') + ' ' + COALESCE(V_SURNAME, '')) 
					END AS td,							  
					CASE WHEN V_CARREG IS NULL 
						THEN 'N/A' 
						ELSE V_CARREG 
					END AS td						
					FROM VISITORS
					WHERE V_FUNCNO = @FREF 
					ORDER BY V_SURNAME, V_FORENAME
					FOR XML RAW('tr'), ELEMENTS 			
				)	 AS VARCHAR(MAX) 
			) + 
			'</table>'													
			
			IF COALESCE(@VDettableHTML, '') = '' BEGIN
				SET @VtableHTML = ''
			END
			ELSE
			BEGIN
				SET @VtableHTML = (COALESCE(@VHeadtableHTML, '') + COALESCE(@VDettableHTML, ''))
				IF @DevOverride = 1
					BEGIN
					PRINT 'CABS_AEF_SEND_DRM: @VtableHTML = ' + @VtableHTML
				END	
			END
		END			

		-- =============================================
		--END
		-- =============================================
		-- =============================================
		--Add Host and Function Ref to SubjectLine
		-- =============================================
		SET @SubjectLineText = ''						

		-- Overwrite the @AddHostToSubject setting with a local one if configured
		SET @AddHostToSubject = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@EmailType, '', @EmailTemplate, 'AddHostToSubject')), @AddHostToSubject)
		IF @AddHostToSubject = '1'
		BEGIN
			SET @SubjectLineText = COALESCE(@SubjectLineText, '') + ' ' + COALESCE(@Host, '')
		END
		
		-- Overwrite the @AddFuncRefToSubject setting with a local one if configured
		SET @AddFuncRefToSubject = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@EmailType, '', @EmailTemplate, 'AddFuncRefToSubject')), @AddFuncRefToSubject)
		IF @AddFuncRefToSubject = '1'
		BEGIN			
			SET @SubjectLineText = COALESCE(@SubjectLineText, '') + ', ' + COALESCE(@FREF, '') + ', '
		END

		SET @SubjectLineText = COALESCE(@SubjectLineText, '') + ' Date: ' + CONVERT( VARCHAR(10), @FDATE, 103 ) + ' Time: ' + @FSTART

		SET @SubjectLineText = (COALESCE(@SubjectLine, '') + COALESCE(@SubjectLineText, ''))
	-- =============================================
	-- Subject Format
	-- =============================================
		IF @EmailFormat = 'HTML'
		BEGIN
			IF COALESCE(@SubjectLineText, '') <> ''
				SET @SHeadtableHTML = '<p class="bodyfontstyle">' + @SubjectLineText + '</p>' 		
		END	
	
		IF @IncludeSubjectInBody = 1
		BEGIN
			SET @SBODY = @SHeadtableHTML
		END
		ELSE
		IF @IncludeSubjectInBody = 0
		BEGIN
			SET @SBODY = COALESCE(@SBODY, '')
		END
		-- =============================================
		-- Build Up Email
		-- =============================================
		SET @EmailText = '<!DOCTYPE html><html>'
		IF @NoEmail = 1
			SET @EmailText = @HTMLHEAD + '*** EMAIL ADDRESS COULD NOT BE FOUND *** ' + @EmailHeaderText
		ELSE			
			SET @EmailText = @HTMLHEAD + @EmailHeaderText + '<body>'
	
		IF @EmailType = 'S'
		BEGIN -- EmailType
			SET @EmailText = 
				@EmailText +					
				@EmailTitle +				
				@EmailSubTitle +							
				@SBODY +				
				@DetailHeading +				
				@DetailSubHeading +							
				@EmailBodyText +
				@BtableHTML +						
				@EtableHTML +
				@VtableHTML +
				@EmailSalut	+ 
				'</body></html>'	
		END --EMailType
		
		--- =============================================
		-- Get Booking Location
		-- =============================================
		DECLARE @LOC VARCHAR(6)
		SET @LOC = (SELECT RM_LOC FROM FUNC_FIL, ROOMS WHERE F_ROOM = RM_ABBR AND F_REF = @FREF)
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @LOC = ' + CONVERT(VARCHAR, @LOC)
		END	
	
		-- =============================================
		-- Get Location Specific Email Profile
		-- =============================================
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
			PRINT 'CABS_AEF_SEND_DRM: @EmailProfile = ' + @EmailProfile
		END	
		/*
		-- =============================================
		--	Get Location Specific Email Address (Default)
		-- =============================================
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailAddress' AND [KEY] = @LOC) > 0
		BEGIN
			SET @LocEmailAddress = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailAddress' AND [KEY] = @LOC)
		END
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @LocEmailAddress = ' + @LocEmailAddress
		END	
		*/
		-- =============================================
		-- Get Email Address String If Blank
		-- =============================================
		DECLARE @EmailAddressType VARCHAR(3)
		SET @EmailAddressType = '(N)'

		IF COALESCE(@EMailAddr, '') = '' --If Email Address is Blank
		BEGIN	
			--IF COALESCE(@LocEmailAddress, '') = '' --If Location Email Address is Blank
			--BEGIN
				IF COALESCE(@AdminEmailAddr, '') <> '' --If Admin Email Address is NOT Blank
				BEGIN
					SET @EMailAddr = @AdminEmailAddr
					SET @EmailAddressType = '(A)'
				
					IF @DevOverride = 1
					BEGIN
						PRINT 'CABS_AEF_SEND_DRM: @AdminEmailAddr = ' + @AdminEmailAddr					
					END	
				END
				ELSE
					SET @EmailAddressType = '(X)'
			--END
			--ELSE
			--	SET @EMailAddr = @LocEmailAddress
			--	SET @EmailAddressType = '(L)'
		END

		-- Removed EmailAddressType information from the Email subject line - TT - 06/03/2017
		SET @SubjectLineText = (COALESCE(@SubjectLineText, '')) -- + ' ' + COALESCE(@EmailAddressType, ''))		
		-- =============================================
		-- Send the Email
		-- =============================================
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @EmailAddressType = ' + @EmailAddressType		
			PRINT 'CABS_AEF_SEND_DRM: @EMailAddr = ' + @EMailAddr				
			PRINT 'CABS_AEF_SEND_DRM: @SubjectLineText = ' + @SubjectLineText				
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
			PRINT 'CABS_AEF_SEND_DRM: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
			PRINT 'CABS_AEF_SEND_DRM: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
		END	
		-- End of Changes - TT - 10/10/2016	

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AEF_SEND_DRM: @SendEMailSQL = ' + @SendEMailSQL		
			PRINT 'CABS_AEF_SEND_DRM: @EmailHeader = ' + @EmailHeader		
			PRINT 'CABS_AEF_SEND_DRM: @EmailTitle = ' + @EmailTitle
			PRINT 'CABS_AEF_SEND_DRM: @EmailSubTitle = ' + @EmailSubTitle		
			PRINT 'CABS_AEF_SEND_DRM: @EmailLink02_Text = ' + @EmailLink02_Text		
			PRINT 'CABS_AEF_SEND_DRM: @DetailHeading = ' + @DetailHeading		
			PRINT 'CABS_AEF_SEND_DRM: @EmailLink01_Text = ' + @EmailLink01_Text		
			PRINT 'CABS_AEF_SEND_DRM: @DetailSubHeading = ' + @DetailSubHeading		
			PRINT 'CABS_AEF_SEND_DRM: @SBODY = ' + @SBODY						
			PRINT 'CABS_AEF_SEND_DRM: @FBody = ' + @FBody						
			PRINT 'CABS_AEF_SEND_DRM: @EBody = ' + @EBody						
			PRINT 'CABS_AEF_SEND_DRM: @XEBody = ' + @XEBody						
			PRINT 'CABS_AEF_SEND_DRM: @PBody = ' + @PBody						
			PRINT 'CABS_AEF_SEND_DRM: @MBody = ' + @MBody						
			PRINT 'CABS_AEF_SEND_DRM: @DTBody = ' + @DTBody						
			PRINT 'CABS_AEF_SEND_DRM: @FSBODY = ' + @FSBODY						
			PRINT 'CABS_AEF_SEND_DRM: @EmailSalut = ' + @EmailSalut						
			PRINT 'CABS_AEF_SEND_DRM: @EmailFooter = ' + @EmailFooter						
	
			IF @EmailHeader IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailHeader IS NULL' END
			IF @EmailTitle IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailTitle IS NULL' END
			IF @EmailSubTitle IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailSubTitle IS NULL' END
			IF @DetailHeading IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @DetailHeading IS NULL' END
			IF @SBODY IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @SBODY IS NULL' END
			IF @FBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @FBody IS NULL' END
			IF @EBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EBody IS NULL' END
			IF @XEBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @XEBody IS NULL' END
			IF @PBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @PBody IS NULL' END
			IF @MBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @MBody IS NULL' END
			IF @DTBody IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @MBody IS NULL' END
			IF @FSBODY IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @FSBODY IS NULL' END
			IF @EmailSalut IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailSalut IS NULL' END
			IF @EmailFooter IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailFooter IS NULL' END
			IF @EmailLink01_Text IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailLink01_Text IS NULL' END
			IF @EmailLink02_Text IS NULL BEGIN PRINT 'CABS_AEF_SEND_DRM: @EmailLink02_Text IS NULL' END
			
			PRINT 'CABS_AEF_SEND_DRM: @EmailProfile = ' + @EmailProfile
			PRINT 'CABS_AEF_SEND_DRM: @EMailAddr = ' + @EMailAddr
			PRINT 'CABS_AEF_SEND_DRM: @SubjectLineText = ' + @SubjectLineText
			PRINT 'CABS_AEF_SEND_DRM: @EmailText = ' + @EmailText
			PRINT 'CABS_AEF_SEND_DRM: LEN(@EmailText) = ' + CAST(LEN(@EmailText) AS VARCHAR)
			PRINT 'CABS_AEF_SEND_DRM: @EmailFormat = ' + @EmailFormat
			PRINT 'CABS_AEF_SEND_DRM: @Importance = ' + @Importance
			PRINT 'CABS_AEF_SEND_DRM: @Sensitivity = ' + @Sensitivity
			PRINT 'CABS_AEF_SEND_DRM: @SendCalendarSQL = ' + @SendCalendarSQL
			PRINT 'CABS_AEF_SEND_DRM: @SendAttachmentSQL = ' + @SendAttachmentSQL
			PRINT 'CABS_AEF_SEND_DRM: @SendEMailSQL = ' + @SendEMailSQL
		
		END					
		-- =============================================
		-- =============================================
		-- CAPTURE SEND INFO
		-- ============================================= 
		if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_SEND_PARAMS]')) = 1
		BEGIN
			INSERT INTO AutoEmailFunction_SEND_PARAMS
			SELECT @AEF_KEY, @EmailProfile, @EMailAddr,
			@EmailFormat, @Importance, @Sensitivity, @FromTrigger, @FREF, GETUTCDATE()
		END
		-- =============================================
		IF @EmailAddressType <> '(X)'
		BEGIN --Email Address Type
			IF @DevOverride = 0 OR @DebugFlag = 1 -- Added TT - 28/06/2016 - Send email even when debug flag is set in X CABS Config
			BEGIN
				-- Replaced the EXEC command for an EXEC sp_executesql command to enable data to be returned - TT - 10/10/2016				 
				--EXEC(@SendEMailSQL)
				EXEC sp_executesql @SendEMailSQL, @PARAMS, @MailID = @MailItemID OUTPUT;
				-- Capture the MailItemId (from [sysmail_allitems]) - TT - 10/10/2016
				SELECT @MailItemID
					
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AEF_SEND_DRM: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
				END	
				-- End of changes - TT - 10/10/2016
			END
		END --Email Address Type
		ELSE
			PRINT 'CABS_AEF_SEND_DRM: No Valid Email Address'
		
		-- =============================================
		-- Update the Sent Flag
		-- =============================================
		UPDATE AutoEmailFunction
		SET AEF_SENT = 1, AEF_SENT_DATE = GETUTCDATE()
		WHERE AEF_FUNC_REF = @FREF
		-- =============================================
		-- Trigger Updates
		-- =============================================	
		IF @FromTrigger = 1
		BEGIN
			if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_FromTrigger]')) = 1
			BEGIN
			--	Changed SPROC to 'CABS_AEF_SEND_DRM-' + @EmailTemplate to assist with debugging - TT - 02/08/2016
			-- Added @MailItemID to INSERT statement - TT - 10/10/2016
				INSERT INTO AutoEmailFunction_FromTrigger
				SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
				AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
				AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AEF_SEND_DRM-' + @EmailTemplate, AEF_DTYN, @MailItemID
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
	
		--Remove Amendments
		EXEC ae_UPD_AEF_Amendments @FunctionRef
		EXEC ae_DEL_AEF_Amendments @FunctionRef, 1, 1	
-- =============================================
-- Fetch Next
-- =============================================
	fetch next from
		email_cursor
	into
		@AEF_KEY,
		@FREF,
		@EMAIL,
		@CEMAIL,
		@BEMAIL,
		@CONTACT,
		@EXTRAYN,
		@PACKYN,
		@MENUYN,
		@DTYN,
		@CANSEND,
		@SENT,
		@FDATE,
		@FSTART
	END

	CLOSE email_cursor
	DEALLOCATE email_cursor

	IF @DevOverride = 1
	BEGIN
		PRINT '************************************************************************'
		PRINT 'CABS_AEF_SEND_DRM: Leaving Procedure CABS_AEF_SEND_DRM'				
		PRINT '************************************************************************'
	END	
END

GO

PRINT '*****************************************************************************'

PRINT 'CABS_AEF_SEND_DRM: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_DRM]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_DRM') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_SEND_DRM: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_DRM: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_DRM]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_DRM') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_SEND_DRM: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_DRM: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_SEND_DRM]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_SEND_DRM') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_SEND_DRM: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_SEND_DRM: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO