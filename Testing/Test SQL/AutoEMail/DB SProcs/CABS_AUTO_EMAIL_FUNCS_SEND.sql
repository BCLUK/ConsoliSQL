-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AUTO_EMAIL_FUNCS_SEND'
SET @SPROC_Name = 'CABS_AUTO_EMAIL_FUNCS_SEND'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AUTO_EMAIL_FUNCS_SEND]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS_SEND]
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

CREATE PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS_SEND] 
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
	-- Author:		Mark Birch
	-- Create date: 30-JUN-2011
	-- Description:	Send Emails to Function Contacts
	-- ====================================================================================================================
	-- Version 10
	-- Date: 06/03/2017
	-- ====================================================================================================================
	-- Changes: MCB: 06-JUL-2011: Added IncludeWeekends Handling
	-- Changes: MCB: 03-JAN-2013: Added Location Specific Email Profile Handling
	-- Changes: MCB: 21-MAR-2013: Added @CreateDayCutOff Handling
	-- Changes: MCB: 08-APR-2013: Added Handling for HTML and Text
	-- Changes: MCB: 12-APR-2013: Added additional Handling for Attachements
	-- Changes: MCB: 12-APR-2013: Added Handling for Calendar Attachement
	-- Changes: MCB: 12-APR-2013: Changed Handling for Sending the Email (SQL Script)
	-- Changes: MCB: 22-MAY-2013: Changed Extra Email Handling
	-- Changes: MCB: 10-MAY-2013: Reset @SubjectLineText (Line 824)
	-- Changes: MCB: 24-JUN-2013: Added @SP_TRG 
	-- Changes: MCB: 24-JUN-2013: Set Default @EmailProfile if Location Profile doesn't exist
	-- Changes: MCB: 24-JUN-2013: Added @LayoutNumber	
	-- Changes: MCB: 25-JUN-2013: Changed Session Handling to limit Room Length		
	-- Changes: MCB: 12-AUG_2013: Changed NVARCHAR(MAX) To VARCHAR(8000) 
	-- Changes: MCB: 14-AUG_2013: Set @TabChar in HTML 
	-- Changes: MCB: 28-AUG-2013: Handled apostrophe in Company Name
	-- Changes: MCB: 28-AUG-2013: Handled apostrophe in Room Name		 
	-- Changes: MCB: 04-SEP-2013: Handled apostrophe in Company Name
	-- Changes: MCB: 04-SEP-2013: Handled apostrophe in Room Name	
	-- Changes: MCB: 15-JAN-2014: Added NULL Prints For @DevOverride
	-- Changes: MCB: 15-JAN-2014: Amended SELECT Cursor to include AEF_KEY 
	-- Changes: MCB: 15-JAN-2014: Added Record Into AutoEmailFunction_SEND_PARAMS	
	-- Changes: MCB: 17-JAN-2014: Added From Trigger Handling
	-- Changes: MCB: 31-MAR-2014: Added HideRoom Handling	
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
    -- Changes: MCB: 22-AUG-2014: @IncOtherSession	
    -- Changes: MCB: 04-SEP-2014: Added Hide Room handling for Sessions In Booking 
    -- Changes: MCB: 08-SEP-2014: Fixed Other Session Format
    -- Changes: MCB: 08-SEP-2014: Added Future Date Check To Other Session Section
	-- Changes: MCB: 23-SEP-2014: Update CANSEND = 'No' based on Rooms     
	-- Changes: MCB: 23-SEP-2014: Added @UseMBRInternForNames  	
	-- Changes: MCB: 25-SEP-2014: Added @UseJobTitleForMBRIntern
	-- Changes: MCB: 31-OCT-2014: Fixed Duplicate Emails		
	-- Changes: MCB: 12-NOV-2014: Changed @EmailText from VARCHAR(8000) to NVARCHAR(MAX) to try and alleviate incorrect syntax issue 		
	-- Changes: MCB: 18-NOV-2014: Handled Apostrophe in Purpose field	
	-- Changes: MCB: 20-NOV-2014: Handled Apostrophe in MBR fields
	-- Changes: MCB: 20-NOV-2014: Handled Apostrophe in MBR fields Update
	-- Changes: MCB: 24-NOV-2014: Changed @EmailText from NVARCHAR(MAX) to VARCHAR(MAX) to try and alleviate incorrect syntax issue 			
	-- Changes: MCB: 27-NOV-2014: Handled Apostrophe in MBR fields for Host and Booker
	-- Changes: MCB: 01-DEC-2014: Changed the following to VARCHAR(MAX) to alleviate incorrect syntax issue:
								--@EmailTitle
								--@EmailSubTitle
								--@DetailHeading
								--@DetailSubHeading
								--@SBODY
								--@FBody
								--@EBody
								--@FSBODY
								--@EmailSalut
								--@EmailFooter
								--@EmailLink01_Text
								--@EmailLink02_Text
								--@SendEMailSQL
								--@RetChar
								--@TabChar
	-- Changes: MCB: 15-DEC-2014: Handled NULL Values for Booker Text
	-- Changes: MCB: 16-DEC-2014: Changed FromTrigger SQL to allow for re-sends of Emails already been sent. 	
	-- Changes: MCB: 18-DEC-2014: Changed the following to VARCHAR(MAX) to alleviate Target String Size To Small issue:	
								--@FStableHTML
								--@EDettableHTML
								--@TEtableHTML
	-- Changes: MCB: 19-DEC-2014: Added @IncludeMeetingType handling																	
	-- Changes: MCB: 22-JAN-2015: Changed all "AS VARCHAR(8000)" to "AS VARCHAR(MAX)"
	-- Changes: MCB: 29-JAN-2015: Fixed Extras Notes	
	-- Changes: MCB: 05-MAR-2015: Increased Extras Notes Field
	-- Changes: MCB: 11-MAR-2015: Added Packages, Menus and Drink Trolley Items
	-- Changes: MCB: 20-MAR-2015: Amended Packages, Menus and Drink Trolley Items	
	-- Changes: MCB: 26-MAR-2015: Changed Deleted Items Header		
	-- Changes: MCB: 30-MAR-2015: Changed the Session Gets to Only include the main Room (not Break-Out Rooms).	
	-- Changes: MCB: 08-APR-2015: Changed Deleted Items Header	
	-- Changes: MCB: 08-APR-2015: Added Package/Drink Trolley/Menu Header if Updated Or Deleted Items exist		
	-- Changes: MCB: 08-APR-2015: Handled NULLs for @Ebody and @XEBody		
	-- Changes: MCB: 08-APR-2015: Added ae_DEL_AEF_Amendments to remove amendments	
	-- Changes: MCB: 13-APR-2015: Added ae_UPD_AEF_Amendments to handle existing codes		
	-- Changes: MCB: 29-OCT-2015: Added Booking Ref; Date Stamp to AutoEmailFunction_SEND_PARAMS		
	-- Changes: MCB: 24-NOV-2015: Amended Menus and DT to show Notes without 0 x (Check for -2)			
	-- Changes: MCB: 24-NOV-2015: Added COALESCE To lines: 1218, 1240, 1384, 1396, 1509, 1534, 1587, 1613, 1666, 1691	
	-- Changes: MCB: 25-NOV-2015: Added check for Deleted Extras only (AEF_EXTRAYN = 1) 
	-- Changes: MCB: 25-NOV-2015: Added COALESCE Checks around Extras
	-- Changes: TT:  08-JUN-2016: Added new parameter for Email template specific settings 
	-- Changes: TT:  29/06/2016:  Added/amended debugging information to aid testing	
	-- Changes: TT:  04/07/2016:  Changed size of Decimal to VARCHAR conversion (from VARCHAR(3) to VARCHAR(10))
	--							  for AI_COVERS in line starting SET @EDettableHTML = 
	-- Changes: TT:  07/07/2016:  Added new HTML Formatting for EMails
	-- Changes: TT:  07/07/2016:  Significant changes for Project Pheonix. 
	--							  Removed code or commented code that is not relevant
	-- Changes: TT:  01/08/2016:  Changed ref to config section CABS_AUTO_EMAIL_FUNCS_SEND which is incorrect.
	--							  If MBR Client Email is missing and no Contact Email exists now uses MBR Principal Email
	-- Changes: TT:  02/08/2016	  Changed SPROC to 'CABS_AEF_SEND_ECC'+'-'+@EmailTemplate
	--							  in INSERT to AutoEmailFunction_FromTrigger
	-- Changes: TT:	 02/08/2016:  Added code to cursor query records to limit 
	--							  returned records to only those that are relevant 
	--							  to FREF and Email Type
	-- Changes:	TT:  07/09/2016:  Added code to ensure that only when an event has a business type of 
	--							  Help Desk should this email be sent - uses classification table
	--
	-- Changes:	TT: 10/10/2016:	  Added code to add the mailitem_id from table sysmail_allitems into
	--	(4)						  audit table AutoEmailFunction_FromTrigger. This will occur when a call 
	--							  to sp_send_dbmail is made. This will enable better audit/diagnostic 
	--							  reports to be run
	--
	-- Changes:	TT: 25/10/2016:	  Removed the classification table constraint on the cursor (AC10) and replaced it
	--	(5)						  with a specific block of code which is executed dependant on a key in X CABS Config 
	--							  called ClassConstraint1
	--			TT: 25/10/2016:	  Added some additional diagnostic information before the start of the cursor code
	--			TT: 25/10/2016:	  Added the function date into the email table as it was mistakenly missed off
	--	 
	-- Changes:	TT: 05/12/2016:	  Added ability to get Layout number from X CABS Config 
	--  (6)						  Added code to display email in a different format depending on LayoutNumber setting. 
	--							  Default value is 1.
	--		  					  Added ability to get FuncNotes and Visitor names
	--							  Added new mechanism to get recipient email address from Location Extra
	--							  Implemented a 2nd email layout
	--							  Improved the structure of the Email HTML
	--
	-- Changes:	TT: 19/12/2016:	  Added ability to send emails to MBR Contact via a config 
	--	(7)						  setting (SendToContact)
	--							  Added Total Price column to tthe Extra Table
	--
	-- Changes:	TT: 17/01/2017:	  Added ability to send emails to a specific user via a config 
	--	(8)						  setting (SendToSpecific) and deptemailaddresses department specific
	--							  Added code for a new layout (@LayoutNumber = 3)
	--							  Resolved some HTML issues
	--
	-- Changes:	TT: 07/02/2017:	  Added code to ensure that if a Function was not part of a Session Booking 
	--  (9)						  then the **SESSNO** text is removed from the email
	--
	-- Changes: TT: 06/03/2017:	  Removed the EmailAddressType information from 
	--	(10)					  the Email Subject Line at a clients request having checced internally nobody uses it.
	--	
	--							  Added additional diagnostic information related to AutoEMailFunction table updates
	-- ====================================================================================================================

	SET NOCOUNT ON;

	IF @DevOverride = 1
	BEGIN
		PRINT '************************************************************************'
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Entered Procedure CABS_AUTO_EMAIL_FUNCS_SEND' -- Amended TT - 29/06/2016					
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' +
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' + 
				  '@EmailType = ' + '''' + 'S' + '''' + ' AND @OnlyIncludeAssignedExtras = 1 AND @ExtraCCToInclude <> ' + ''''''				  
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Table AutoEmailFunction Update SQL (@SQL): ' + @SQL
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: AEF_CANSEND Set to ' + '''' + 'No' + '''' + ' in table AutoEMailFunction due to ' + 
				  '@EmailType = ' + '''' + 'E' + '''' + ' AND @ExtraCCToInclude <> ' + ''''''				  
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Table AutoEmailFunction Update SQL (@SQL): ' + @SQL
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
		UPDATE AutoEmailFunction
	SET AEF_CANSEND = 'No'
	WHERE AEF_FUNC_REF in(SELECT F_REF FROM FUNC_FIL WHERE F_STATUS = 'CANCEL' AND COALESCE(F_STATUS, '') <> '')
	
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
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Table AutoEmailFunction could have been updated'			  
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

	-- Added ability to get autoemail specific layout number - TT - 05/12/2016
	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @LayoutNumber (Generic) = ' +  @LayoutNumber 
	END	

	SET @LayoutNumber = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'LayoutNumber')), @LayoutNumber)

	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @LayoutNumber (Local) = ' +  @LayoutNumber 
	END	
	-- End of Changes - TT - 05/12/2016

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
						-- Changed title to Updated Booking Details - TT - 05/12/2016
						'<title>Updated Booking Details</title>' +		
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
						-- Added <body> tag to end of head tag - TT - 17/01/2017
					'</head><body>'
	-- End of changes - TT - 07/07/2016
	-- ==========================================================
	-- EMAIL HEADER
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================		 
		IF COALESCE(@EmailHeaderText, '') <> ''
			SET @EmailHeaderText = '<p class="headertextfontstyle">' +  @EmailHeaderText + '</p>' 		

	-- =========================================================
	-- EMAIL SUB-TITLE
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSubTitle, '') <> ''
			-- Corrected HTML type - TT - 17/01/2017
			--SET @EmailSubTitle = '<p class-"subtitlefontstyle">' +  @EmailSubTitle + '</p>' 	
			SET @EmailSubTitle = '<p class="subtitlefontstyle">' +  @EmailSubTitle + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================
		IF COALESCE(@DetailHeading, '') <> ''
			SET @DetailHeading = '<p class="detailheadingfontstyle">' +  @DetailHeading + COALESCE(@FREF, '') + '</p>' 	

	-- =========================================================
	-- EMAIL DETAIL HEADING
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================		
		IF COALESCE(@DetailSubHeading, '') <> ''
			SET @DetailSubHeading = '<p class="detailsubheadingfontstyle">' +  @DetailSubHeading + '</p>' 

	-- =========================================================
	-- EMAIL BODY TEXT
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailBodyText, '') <> ''		
			SET @EmailBodyText = '<p class="bodyfontstyle">' +  @EmailBodyText + '</p>'
	
	-- Added - TT - 05/07/2016
	-- =========================================================
	-- EMAIL Salutation
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSalut, '') <> ''
			SET @EmailSalut = '<p class="emailsalutfontstyle">' +  @EmailSalut + '</p>' 			

	-- =========================================================
	-- EMAIL Signature
	-- This text is passed from section AEFUPD in X CABS Config
	-- =========================================================
		IF COALESCE(@EmailSignature, '') <> ''		
			SET @EmailSignature = '<p class="emailsignaturefontstyle">' +  @EmailSignature + '</p>' 								  

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @HTMLHEAD = ' +  @HTMLHEAD -- Amended TT - 07/07/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailHeaderText = ' +  @EmailHeaderText -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSubTitle = ' +  @EmailSubTitle -- Amended TT - 28/06/2016			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailHeading = ' +  @DetailHeading -- Amended TT - 28/06/2016			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailSubHeading = ' +  @DetailSubHeading -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailBodyText = ' +  @EmailBodyText -- Amended TT - 28/06/2016	
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSalut = ' +  @EmailSalut -- Amended TT - 05/07/2016			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSignature = ' +  @EmailSignature -- Amended TT - 05/07/2016			
		END	
		
		SET @EmailSalut = @EmailSalut + @EmailSignature

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

	-- Added to aid development and fault diagnosis - TT - 25/10/2016
	IF @DevOverride = 1
	BEGIN
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Preparing Cursor for FREF = ' + @FunctionRef + ', EmailTemplate = ' + @EmailTemplate
	END
-- =============================================
-- Prepare Email Data - Cursor
-- =============================================
	DECLARE 
		email_cursor
	CURSOR FAST_FORWARD for
		-- Added inner join limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016		
		SELECT
			AEF_KEY, AEF_FUNC_REF, AEF_EMAIL, AEF_CEMAIL, AEF_BOOKER_EMAIL, AEF_CONTCT, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_DTYN, AEF_CANSEND, AEF_SENT
		FROM
			AutoEmailFunction INNER JOIN vw_AEFLink ON AEFL_FREF = AEF_FUNC_REF
			-- Added to ensure that only when an event has a business type of Help Desk should this email be sent - TT - 07/09/2016
			-- INNER JOIN AC10 ON AEF_MBR_NO = AC_OWNER	- Removed code and implemented it elsewhere in a separate code block - TT-25/10/2016
		WHERE
			AEF_CANSEND = 'Yes'
		AND
			AEF_SENT = 0
		-- Added to limit returned records to only those that are relevant to FREF and Email Type - TT - 02/08/2016 
		AND 
			AEF_FUNC_REF = @FunctionRef
		AND 
			AEFL_EMailType = @EmailTemplate
		-- Added to ensure that only when an event has a business type of Help Desk should this email be sent - TT - 07/09/2016
		-- Removed code and implemented it elsewhere in a separate code block - TT-25/10/2016
		-- AND
		-- AC_CODE = 'HELP'
		--End of changes - TT - 25/10/2016
		
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
		@SENT

	WHILE @@fetch_status = 0
	BEGIN

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FREF = ' + @FREF -- Amended TT - 28/06/2016
		END

		-- Added code to check for any class constraints
		-- This code checks X CABS Config for a a key ClassConstraint1  
		-- If it exists and it value is 1 then email will only be sent if the AC_OWNER in AC10 has the 
		-- classification of 'HELP' TT - 25/10/2016
		DECLARE @ClassConstraint1 VARCHAR(10)

		-- Check to see if any class constraints are to be applied to this autoemail
		SET @ClassConstraint1 = ''
		SET @ClassConstraint1 = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'ClassConstraint1')), '0')
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @ClassConstraint1 = ' + @ClassConstraint1
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
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Email will not be sent due to classification constraint'
				END
				-- Dont like GoTo's but need to tidy up !
				GOTO DO_NOT_SEND_EMAIL
			END
			ELSE
			BEGIN
				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Email will be sent due to classification constraint'
				END				
			END

		END
		-- End of Changes - TT - 25/10/2016
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

	-- =============================================
	-- HOST
	-- =============================================
	/*
		IF @EmailFormat = 'HTML'
		BEGIN
			IF COALESCE(@Host, '') <> ''
				SET @Host = '<p style="color: ' + @EmailBodyFontColor + 
							'; font-weight: ' +  @EmailBodyFontWeight + 
							'; font-family: ' + @EmailBodyFontType + 
							'; font-size: ' + @EmailBodyFontSize + 
							'pt;">Contact Name: ' + @Host + '</p>' 		
		END	
	*/
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
				@BookerTel VARCHAR(100),
				@FuncNote VARCHAR(MAX), -- Added - TT - 05/12/2016
				@Visitors VARCHAR(MAX) -- Added - TT - 05/12/2016

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

		-- Added code to store any Function Notes (from vw_FUNC_NOTES) and Visitors (from the Visitor table) - TT - 05/12/2016
		-- Needed to turn on CONCAT_NULL_YIELDS_NULL for the followin queries to work - 
		-- turning this value off in future versions of SQL will cause an error - this wil need to be re-worked.
		-- Results are stored in a variable with records being being separated by a CRLF character(s)
		SET CONCAT_NULL_YIELDS_NULL ON		
		SET @FuncNote = ''
		SET @FuncNote = (SELECT Notes + @RetChar FROM vw_FuncNotes WHERE F_REF = @FREF AND Notes IS NOT NULL AND Notes <> '' 
							ORDER BY NoteDate
							FOR XML PATH(''), TYPE).value('.[1]', 'varchar(max)')
		SET @Visitors = (SELECT 
							CASE WHEN (COALESCE(V_TITLE, '') + ' ' + COALESCE(V_FORENAME, '') + ' ' + COALESCE(V_SURNAME, '')) = '  ' 
							THEN  'N/A' + @RetChar
							ELSE LTRIM((COALESCE(V_TITLE, '') + ' ') + COALESCE(V_FORENAME, '') + ' ' + COALESCE(V_SURNAME, '') + @RetChar)   
							END 							  	
						FROM VISITORS
						WHERE V_FUNCNO = @FREF 
						ORDER BY V_SURNAME, V_FORENAME
						FOR XML PATH(''), TYPE).value('.[1]', 'varchar(max)')
		SET CONCAT_NULL_YIELDS_NULL OFF
		-- End of changes - TT - 05/12/2016
	--========================================
	--========================================
		DECLARE @IncBookerDetails INT
		SET @IncBookerDetails = 0
		IF (@IncludeBookerMBRNo = 1 OR @IncludeBookerName = 1 OR @IncludeBookerMBRTel = 1)
		BEGIN
			SET @IncBookerDetails = 1
		END
	-- =============================================
	-- Contact Name
	-- =============================================
		DECLARE @ContactInfo VARCHAR(500)
		IF @EmailFormat = 'HTML'
		BEGIN					
			-- Added code to display email in a different format depending on LayoutNumber setting - defualt value is 1 - TT - 05/12/2016
			IF @LayoutNumber = 1
			BEGIN
				SET @ContactInfo = '<table class="details" cols=2><tr><td colspan=2 align=left><b><u>Contact Details</u></b></td></tr>' + 
									'<tr><td><b>Contact Name:</b></td><td>' + COALESCE(@CONTACT, '') + '</td></tr>' + 
									'<tr><td><b>Number:</b></td><td>' + @HostTel + '</td></tr>' + '</table><br>'							  
			END			
			ELSE IF @LayoutNumber = 2
			BEGIN
				SET @ContactInfo = '<table class="extras" cols=2><tr><td colspan=2 align="center"><b>Host Details</b></td></tr>' + 
									'<tr><td><b>Location:</b></td><td>' + COALESCE(@Location, '') + '</td></tr>' + 
									'<tr><td><b>MBR:</b></td><td>' + COALESCE(@Host, '') + '</td></tr>' + 
									'<tr><td><b>Booker:</b></td><td>' + COALESCE(@Booker, '') + '</td></tr>' + 
									'<tr><td><b>Booker Ext Number:</b></td><td>' + @BookerTel + '</td></tr>'
			END
			-- End of Changes - TT - 05/12/2016
			-- Added Code to display a new layout - TT - 17/01/2017
			ELSE IF @LayoutNumber = 3
			BEGIN
				SET @ContactInfo = ''				
			END
			-- End of Changes - TT - 17/01/2017
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @CONTACT = ' +  @CONTACT -- Amended TT - 05/07/2016
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @HostTel = ' +  @HostTel -- Amended TT - 05/07/2016
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Booker = ' +  @Booker -- Amended TT - 05/12/2016
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @BookerTel = ' +  @BookerTel -- Amended TT - 05/12/2016
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Location = ' +  @Location -- Amended TT - 05/12/2016
			END	
		END	
	
	--=======================================================================================================
	-- Host Details
	--
	-- Most of the functionality here is removed as not required for Project Phoenix - TT - 06/07/2016
	--
	--=======================================================================================================
		IF @EmailFormat = 'HTML'
		BEGIN		
			SET @tableHTML = @ContactInfo
		END	
	--=======================================================================================================
	-- Booking Details
	--
	-- Changes - TT - 06/07/2016
	--
	--=======================================================================================================
		IF @EmailType = 'S'
		BEGIN
			IF @EmailFormat = 'HTML'
			BEGIN
				-- Added code to display email in a different format depending on LayoutNumber setting - defualt value is 1 - TT - 05/12/2016			
				IF @LayoutNumber = 1
				BEGIN
					SET @BtableHTML = '<table class="details" cols=2><tr><td colspan=2 align=left><b><u>Booking Details</u></b></td></tr>' + 
									  '<tr><td><b>Booking Ref:</b></td><td>' + @FREF + '</td></tr>' + 
									  '<tr><td><b>Room:</b></td><td>' + @RoomName + '</td></tr>' + 	
									  -- Added the function date into the email table as it was mistakenly missed off - TT - 25/10/2016 
									  '<tr><td><b>Date:</b></td><td>' + @FuncDate + '</td></tr>' + 									  						  
									  '<tr><td><b>Booking Times:</b></td><td>' + @FuncTimes + '</td></tr>' + 
									  '<tr><td><b>Location:</b></td><td>' + @Location + '</td></tr>' + 
									  '<tr><td><b>Room Use:</b></td><td>' + @RoomUse + '</td></tr>' + 
									  '<tr><td><b>Number Of People:</b></td><td>' + CONVERT(VARCHAR, @PAX) + '</td></tr>' + 
									  '<tr><td><b>Meeting Purpose:</b></td><td>' + @Purpose + '</td></tr>' + 
									  '<tr><td><b>Cost Code:</b></td><td>' + @CostCent + '</td></tr>' + 
									  '</table><br>'							  
										  							 							  							  
									  /* Not needed for Project Phoenix - TT - 06/07/2016
									  CASE @IncludeMeetingType WHEN 1 THEN
										'<b>Meeting Type: </b>' + @MeetType + '<br>' 								
									  ELSE ''
									  END + 	
									  CASE @IncludeSessNo WHEN 1 THEN
										'<b>Session No: </b>' + @SessNo + '<br>'
									  ELSE ''
									  END +
									  CASE @IncludeBookingStatus WHEN 1 THEN 
										'<b>Status: </b>' + @Status + '<br>'												
									  ELSE ''	
									  END +						  						  
									  '<b>Room Charge: </b>' + @CurrencySymbol + @RoomCharge + '<br>' +
									  */							  
				END
				ELSE IF @LayoutNumber = 2
				BEGIN
					SET @BtableHTML = '<tr><td colspan=2 align="center"><b>Booking Details</b></td></tr>' + 
									  '<tr><td><b>Room:</b></td><td>' + @RoomName + '</td></tr>' + 		
									  '<tr><td><b>Meeting Layout:</b></td><td>' + @RoomUse + '</td></tr>' + 								  
									  '<tr><td><b>Function Date:</b></td><td>' + @FuncDate + '</td></tr>' + 									  						  
									  '<tr><td><b>Start and Finish Time:</b></td><td>' + @FuncTimes + '</td></tr>' + 
									  '<tr><td><b>Attendees:</b></td><td>' + CONVERT(VARCHAR, @PAX) + '</td></tr>' + 
									  '<tr><td><b>Meeting Purpose:</b></td><td>' + @Purpose + '</td></tr>' + 
									  '<tr><td><b>Charge Code:</b></td><td>' + @CostCent + '</td></tr>'	+								  

									  '<tr><td colspan=2 align="center"><b>Other Details</b></td></tr>' + 
									  '<tr><td><b>Status:</b></td><td>' + @Status + '</td></tr>' + 		
									  '<tr><td><b>Function Notes:</b></td><td>' + @FuncNote + '</td></tr>' + 		
									  '<tr><td><b>Visitors:</b></td><td>' + @Visitors + '</td></tr>' + 		
									  '</table><br>'									  				 							  							  									 
				END
				-- End of Changes - TT - 05/12/2016
				-- Added code for new layout 3 - TT - 17/01/2017
				ELSE IF @LayoutNumber = 3
				BEGIN
					SET @BtableHTML = ''
				END
				-- End of CHanges - TT - 17/01/2017

				IF @DevOverride = 1
				BEGIN
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FREF = ' +  @FREF -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @RoomName = ' +  @RoomName -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FuncDate = ' +  @FuncDate -- Amended TT - 05/07/2016 
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FuncTimes = ' +  @FuncTimes -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Location = ' +  @Location -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @RoomUse = ' +  @RoomUse -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @PAX = ' +  CONVERT(VARCHAR, @PAX) -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Purpose = ' +  @Purpose -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @CostCent = ' +  @CostCent -- Amended TT - 05/07/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @RoomUse = ' +  @RoomUse -- Amended TT - 05/12/2016					
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Status = ' +  @Status -- Amended TT - 05/12/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FuncNote = ' +  @FuncNote -- Amended TT - 05/12/2016
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Visitors = ' +  @Visitors -- Amended TT - 05/12/2016
				END			
				SET @FBODY = (@tableHTML + @BtableHTML)
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
	-- Host Email Address
	-- =============================================
		DECLARE @HostEmailAddr VARCHAR(512) 
		SET @HostEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToHost = ' + @SendToHost -- Amended TT - 28/06/2016		
		END
		IF @SendToHost = 1
		BEGIN
			SET @HostEmailAddr = (SELECT COALESCE(MBR_EMAIL, '') FROM MBRFILE WHERE MBR_EMAIL <> '' AND NOT MBR_EMAIL IS NULL AND MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @HostEmailAddr = ' + @HostEmailAddr -- Amended TT - 28/06/2016				
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToContact = ' + @SendToContact
		END

		IF @SendToContact = 1
		BEGIN
			SET @ContactEmailAddr = (SELECT COALESCE(MBR_CEMAIL, '') FROM MBRFILE 
									 WHERE MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @ContactEmailAddr = ' + @ContactEmailAddr
		END

	-- =============================================
	-- Booker Email Address
	-- =============================================
		DECLARE @BookerEmailAddr VARCHAR(512) 
		SET @BookerEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToBooker = ' + @SendToBooker -- Amended TT - 28/06/2016		
		END

		IF @SendToBooker = 1
		BEGIN
			SET @BookerEmailAddr = (SELECT COALESCE(B.MBR_EMAIL, '') FROM MBRFILE A, MBRFILE B WHERE B.MBR_EMAIL <> '' AND NOT B.MBR_EMAIL IS NULL AND @BookerID = B.MBR_IMPKEY AND A.MBR_SYSNO = @MBRNo)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @BookerEmailAddr = ' + @BookerEmailAddr -- Amended TT - 28/06/2016				
		END
	-- =============================================
	-- Department Email Address
	-- =============================================
		DECLARE @DeptEmailAddr VARCHAR(512) 
		SET @DeptEmailAddr = ''

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToDepartment = ' + @SendToDepartment -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Department = ' + @Department -- Amended TT - 28/06/2016
		END

		IF @SendToDepartment = 1
		BEGIN
			--SET @DeptEmailAddr = (SELECT [dbo].[uf_getFunctionDeptEmails] (@FREF, @Department, NULL, NULL))
			SET @DeptEmailAddr = (SELECT [dbo].[uf_getFunctionDeptEmails] (@FREF, @Department, @DeptIncludeMailList, @DeptExcludeMailList))
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DeptEmailAddr = ' + @DeptEmailAddr -- Amended TT - 28/06/2016				
		END
	-- Added - TT - 07/07/2016
	-- =============================================
	-- Client Contact Email Address
	-- =============================================
		DECLARE @ClientEmailAddr VARCHAR(512) 
		DECLARE @SendToClient VARCHAR(100)

		SET @ClientEmailAddr = ''

		-- Changed CABS_AUTO_EMAIL_FUNCS_SEND which is incorrect to Config section passed in - TT - 01/08/2016
		--SET @SendToClient = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', 'CABS_AUTO_EMAIL_FUNCS_SEND', 'SendToClient')), '')
		SET @SendToClient = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'SendToClient')), '')
	
		IF @DevOverride = 1
		BEGIN
			-- Changed ClientEmailAddr to @SendToClient - TT - 01/08/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToClient = ' + @SendToClient		
		END

		IF @SendToClient = 1
		BEGIN
		
			SET @ClientEmailAddr = @CEMAIL

			IF COALESCE(@ClientEmailAddr,'') = ''
				SET @ClientEmailAddr = (SELECT COALESCE(CT_EMAIL, '') FROM CONTACTS INNER JOIN MBRFILE ON MBR_CONTNO = CT_SYSNO WHERE MBR_SYSNO = @MBRNo)

			-- Added after discussion with client and PAS - TT - 01/08/2016
			IF COALESCE(@ClientEmailAddr,'') = ''
				SET @ClientEmailAddr = @EMAIL
		
		END
		-- Added new mechanism to get recipient email address from Location Extra - TT - 05/12/2016
		-- =============================================
		-- Location Recipient Email Address
		-- =============================================
		DECLARE @LocationEmailAddr VARCHAR(512) 
		DECLARE @SendToLocation VARCHAR(100)

		SET @LocationEmailAddr = ''		
		SET @SendToLocation = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'SendToLocation')), '')
	
		IF @DevOverride = 1
		BEGIN			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToLocation = ' + @SendToLocation		
		END

		IF @SendToLocation = 1
		BEGIN
			SET @LocationEmailAddr = (SELECT COALESCE(P_EMAIL, '') FROM FUNC_FIL 
											INNER JOIN ROOMS ON F_ROOM = RM_ABBR
											INNER JOIN POST_DEF ON RM_LOC = P_CODE 
										WHERE F_REF = @FREF)
		END

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @LocationEmailAddr = ' + @LocationEmailAddr				
		END
	-- End of changes - TT - 05/12/2016
	-- Added new mechanism to get recipient email address from SPECIFIC department in section DeptEmailAddresses - TT - 17/01/2017
		-- =============================================
		-- Specific Recipient Email Address
		-- =============================================
		DECLARE @SpecificEmailAddr VARCHAR(512) 
		DECLARE @SendToSpecific VARCHAR(100)

		SET @SpecificEmailAddr = ''		
		SET @SendToSpecific = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailTemplate, 'SendToSpecific')), '')
	
		IF @DevOverride = 1
		BEGIN			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendToSpecific = ' + @SendToSpecific		
		END
		
		IF @SendToSpecific = 1	
			SET @SpecificEmailAddr = (SELECT [dbo].[uf_getDepteMail]('SPECIFIC'))

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SpecificEmailAddr = ' + @SpecificEmailAddr				
		END
	-- End of changes - TT - 17/01/2017
	-- =============================================
	-- Contact Email Addresses
	-- =============================================
		-- Added Contact Email Address - TT - 19/12/2016
		IF COALESCE(@ContactEmailAddr, '') <> '' BEGIN
			SET @ContactEmailAddr = (@ContactEmailAddr + '; ')
		END 
		-- End of Changes - TT - 19/12/2016

		-- Added -TT - 05/12/2016
		IF COALESCE(@LocationEmailAddr, '') <> '' BEGIN
			SET @LocationEmailAddr = (@LocationEmailAddr + '; ')		
		END	    
		--End of Add - TT - 05/12/2016
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
		-- Added -TT - 17/01/2017
		IF COALESCE(@SpecificEmailAddr, '') <> '' BEGIN
			SET @SpecificEmailAddr = (@SpecificEmailAddr + '; ')
		END
		-- Added @ClientEmailAddr - TT - 07/07/2016
		-- Added + @LocationEmailAddr - TT - 05/12/2016		
		-- Added + @ContactEmailAddr - TT - 19/12/2016
		-- Added + @SpecificEmailAddr - TT - 17/01/2017
		SET @EMailAddr = COALESCE(@ClientEmailAddr, '') + COALESCE(@HostEmailAddr, '') + COALESCE(@BookerEmailAddr, '') + 
						 COALESCE(@DeptEmailAddr, '') + COALESCE(@LocationEmailAddr, '') + COALESCE(@ContactEmailAddr, '') + 
						 COALESCE(@SpecificEmailAddr, '')

		IF COALESCE(@EMailAddr, '') <> '' BEGIN
			IF @DevOverride = 1 BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EMailAddr = ' + @EMailAddr -- Amended TT - 28/06/2016			
			END	
		END
		ELSE
		IF COALESCE(@EMailAddr, '') = '' BEGIN
			SET @NoEmail = 1
			SET @EMailAddr = @AdminEmailAddr
		
			IF @DevOverride = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @NoEmail = ' + CONVERT(VARCHAR, @NoEmail) -- Amended TT - 28/06/2016			
			END	
		END
	-- =============================================
	--EMAIL BODY				
	--Extra Details
	-- =============================================
	--Extras
		SET @EBody = ''
		SET @XEBody = ''
		IF @EXTRAYN = 1
		BEGIN
		
			DECLARE @EtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @EHeadtableHTML  VARCHAR(MAX) ;--NVARCHAR(MAX) ;
			DECLARE @EDettableHTML  VARCHAR(MAX) ; --VARCHAR(8000) ;
		
			IF @EmailFormat = 'HTML'
			BEGIN				
				-- Added code to display email in a different format depending on LayoutNumber setting - defualt value is 1 - TT - 05/12/2016			
				IF @LayoutNumber = 1
				BEGIN
					-- Added Total Proce Column - TT - 19/12/2016					
					SET @EHeadtableHTML =			
						-- Added missing <tr> tag to table row - TT - 17/01/2017	
						'<table class="extras"><tr><td colspan=4 align ="center"><b>Extra Details</b></td></tr><tr>' + 
						'<td align=center><b>Time</b></td>' +
						'<td align=center><b>Covers</b></td>' +
						'<td align=center><b>Extra</b></td>'+ 
						'<td align=center><b>Total Price</b></td></tr>'												

					-- Added - TT - 07/07/2016
					-- This code returns the list of extras for the given FREF and produces a single row of text containing
					-- delimited table cells and delimited rows e.g.:
					--
					--	<tr><td>data1</td><td>data2</td><td>data3</td></tr><tr><td>data4</td><td>data5</td><td>data6</td></tr>
					--
					
					SET @EDettableHTML = 			
					CAST 
					( 
						( SELECT AI_TIME + '-' + AI_ENDTIME AS td,  
								 CONVERT(VARCHAR(10), AI_COVERS) AS td, 
								 P_DESC AS td,
								 CONVERT(VARCHAR, CONVERT(DECIMAL(8,2), AI_COVERS * AI_CHARGE)) AS td -- Added Total Price Column - TT - 19/12/2016
							FROM vw_Extras
							WHERE AI_FREF = @FREF 
							ORDER BY AI_PRIKEY, OrderBy ASC
							FOR XML RAW('tr'), ELEMENTS 			
						)	 AS VARCHAR(MAX) 
					) + 
					'</table>'
				END
				ELSE IF @LayoutNumber = 2
				BEGIN
					SET @EHeadtableHTML = ''
				END
				-- End of Changes - TT - 05/12/2016
				-- Added code for new layout 3 - TT - 17/01/2017
				ELSE IF @LayoutNumber = 3
				BEGIN
					SET @EHeadtableHTML =				
						'<table class="extras"><tr><td colspan=3 align ="center"><b>Extra Details</b></td></tr><tr>' + 
						'<td align=center><b>Time</b></td>' +
						'<td align=center><b>Covers</b></td>' +
						'<td align=center><b>Extra</b></td></tr>'	

					SET @EDettableHTML = 			
					CAST 
					( 
						( SELECT AI_TIME + '-' + AI_ENDTIME AS td,  
								 CONVERT(VARCHAR(10), AI_COVERS) AS td, 
								 P_DESC AS td								 
							FROM vw_Extras
							WHERE AI_FREF = @FREF 
							ORDER BY AI_PRIKEY, OrderBy ASC
							FOR XML RAW('tr'), ELEMENTS 			
						)	 AS VARCHAR(MAX) 
					) + 
					'</table>'
				END
				-- End of Changes - TT - 17/01/2017
				IF COALESCE(@EDettableHTML, '') = '' BEGIN
					SET @EtableHTML = ''
				END
				ELSE
				BEGIN
					SET @EtableHTML = (COALESCE(@EHeadtableHTML, '') + COALESCE(@EDettableHTML, ''))
					IF @DevOverride = 1
						BEGIN
						PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EtableHTML = ' + @EtableHTML -- Amended TT - 06/07/2016			
					END	
				END
			END			

	-- =============================================
		END
	-- =============================================
	-- =============================================
	--Add Host to SubjectLine
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
		-- Amended code to improve the structure of the HTML - TT - 05/12/2016
		SET @EmailText = '<!DOCTYPE html><html>'
		IF @NoEmail = 1
			SET @EmailText = @EmailText + @HTMLHEAD + '*** EMAIL ADDRESS COULD NOT BE FOUND *** ' + @EmailHeaderText
		ELSE			
			-- Removed <body> tag - added to @HTMLHEAD - TT - 17/01/2017
			--SET @EmailText = @EmailText + @HTMLHEAD + @EmailHeaderText + '<body>'
			SET @EmailText = @EmailText + @HTMLHEAD + @EmailHeaderText 

		--IF @NoEmail = 1
		--	SET @EmailText = '*** NO HOST OR BOOKER OR DEPARTMENT HAS BEEN SENT THIS EMAIL - NO ADDRESSES *** ' + @EmailHeaderText
		--ELSE			
		--	SET @EmailText = @EmailHeaderText
		-- End of Changes - TT - 05/12/2016

		-- Added code to replace text with FREF - TT - 05/12/2016
		IF @LayoutNumber = 2
			IF COALESCE(@EmailBodyText, '') <> ''		
				SET @EmailBodyText = REPLACE(@EmailBodyText, '**FREF**', @FREF)

		-- Added code for new layout 3 - TT - 17/01/2017
		IF @LayoutNumber = 3
		BEGIN
			DECLARE @MBRInitials VARCHAR(100)
			SET @MBRInitials = (SELECT COALESCE(MBR_PCODE, '** Missing Initials **') FROM MBRFILE WHERE MBR_SYSNO = @MBRNo)		
			SET @EmailSubTitle = REPLACE(@EmailSubTitle, '**MBRI**', @MBRInitials)
			SET @EmailSubTitle = REPLACE(@EmailSubTitle, '**DATE**', @FuncDate)
			SET @EmailSubTitle = REPLACE(@EmailSubTitle, '**FREF**', @FREF)
			IF COALESCE(@SessNo, '') <> ''
				SET @EmailSubTitle = REPLACE(@EmailSubTitle, '**SESSNO**', '/'+ @SessNo)
			ELSE
			-- Added code to ensure that if a Function was not part of a Session Booking 
			-- then the **SESSNO** text is removed from the email - TT - 07/02/2017
				SET @EmailSubTitle = REPLACE(@EmailSubTitle, '**SESSNO**', @SessNo)

			SET @DetailHeading = REPLACE(@DetailHeading, '**TIME**', @FuncTimes)
		END
		-- End of Changes - TT - 17/01/2017

		IF @EmailType = 'S'
		BEGIN -- EmailType

			-- Amended code - TT - 05/12/2016
			-- Added code for new layout = 3 - TT - 17/01/2017
			IF @LayoutNumber = 1 OR @LayoutNumber = 2
			BEGIN
				SET @EmailText = 
						@EmailText +					
						@EmailTitle +				
						@EmailSubTitle +							
						@SBODY +				
						@DetailHeading +				
						@DetailSubHeading +							
						@EmailBodyText +
						@FBody +						
						@EtableHTML +				
						@EmailSalut	+ 				
						'</body></html>' -- TT - 05/12/2016		 
			END
			ELSE IF @LayoutNumber = 3
			BEGIN
				SET @EmailText = 
						@EmailText +					
						@EmailTitle +				
						@EmailSubTitle +							
						@SBODY +				
						@DetailHeading +																	
						@EmailBodyText +
						@FBody +						
						@EtableHTML +
						@DetailSubHeading +				
						@EmailSalut	+ 				
						'</body></html>'
			END
			-- End of Changes - TT - 17/01/2017

		END --EMailType
		/*ELSE
		IF @EmailType = 'E'
		BEGIN --EMailType	
			SET @EmailText = @EmailText +					
				@HostName +									
				@RetChar +
				@EmailFooter
		END --EMailType			
		*/
	--- =============================================
	-- Get Booking Location
	-- =============================================
		DECLARE @LOC VARCHAR(6)
		SET @LOC = (SELECT RM_LOC FROM FUNC_FIL, ROOMS WHERE F_ROOM = RM_ABBR AND F_REF = @FREF)
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @LOC = ' + CONVERT(VARCHAR, @LOC) -- Amended TT - 28/06/2016
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailProfile = ' + @EmailProfile -- Amended TT - 28/06/2016
		END	
	-- =============================================
	-- Get Location Specific Email Address (Default)
	-- =============================================
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailAddress' AND [KEY] = @LOC) > 0
		BEGIN
			SET @LocEmailAddress = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = 'LocationEmailAddress' AND [KEY] = @LOC)
		END
	
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @LocEmailAddress = ' + @LocEmailAddress -- Amended TT - 28/06/2016
		END	
	-- =============================================
	-- Get Email Address String If Blank
	-- =============================================
		DECLARE @EmailAddressType VARCHAR(3)
		SET @EmailAddressType = '(N)'

		IF COALESCE(@EMailAddr, '') = '' --If Email Address is Blank
		BEGIN
			IF COALESCE(@LocEmailAddress, '') = '' --If Location Email Address is Blank
			BEGIN
				IF COALESCE(@AdminEmailAddr, '') <> '' --If Admin Email Address is NOT Blank
				BEGIN
					SET @EMailAddr = @AdminEmailAddr
					SET @EmailAddressType = '(A)'
				
					IF @DevOverride = 1
					BEGIN
						PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @AdminEmailAddr = ' + @AdminEmailAddr -- Amended TT - 28/06/2016					
					END	
				END
				ELSE
					SET @EmailAddressType = '(X)'
			END
			ELSE
				SET @EMailAddr = @LocEmailAddress
				SET @EmailAddressType = '(L)'
		END

		-- Removed EmailAddressType information from the Email subject line - TT - 06/03/2017
		SET @SubjectLineText = (COALESCE(@SubjectLineText, '')) -- + ' ' + COALESCE(@EmailAddressType, ''))
	-- =============================================
	-- Send the Email
	-- =============================================
		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailAddressType = ' + @EmailAddressType -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EMailAddr = ' + @EMailAddr -- Amended TT - 28/06/2016				
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SubjectLineText = ' + @SubjectLineText -- Amended TT - 28/06/2016				
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
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendEMailSQL = ' +  @SendEMailSQL --Amended TT - 10/10/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @PARAMS = ' +  @PARAMS  -- Amended TT - 10/10/2016
		END	
		-- End of Changes - TT - 10/10/2016	

		IF @DevOverride = 1
		BEGIN
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendEMailSQL = ' + @SendEMailSQL -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailHeader = ' + @EmailHeader -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailTitle = ' + @EmailTitle -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSubTitle = ' + @EmailSubTitle -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailLink02_Text = ' + @EmailLink02_Text -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailHeading = ' + @DetailHeading -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailLink01_Text = ' + @EmailLink01_Text -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailSubHeading = ' + @DetailSubHeading -- Amended TT - 28/06/2016		
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SBODY = ' + @SBODY -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FBody = ' + @FBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EBody = ' + @EBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @XEBody = ' + @XEBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @PBody = ' + @PBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @MBody = ' + @MBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DTBody = ' + @DTBody -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FSBODY = ' + @FSBODY -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSalut = ' + @EmailSalut -- Amended TT - 28/06/2016						
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailFooter = ' + @EmailFooter -- Amended TT - 28/06/2016						
	
			IF @EmailHeader IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailHeader IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailTitle IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailTitle IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailSubTitle IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSubTitle IS NULL' END -- Amended TT - 28/06/2016
			IF @DetailHeading IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @DetailHeading IS NULL' END -- Amended TT - 28/06/2016
			IF @SBODY IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SBODY IS NULL' END -- Amended TT - 28/06/2016
			IF @FBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FBody IS NULL' END -- Amended TT - 28/06/2016
			IF @EBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EBody IS NULL' END -- Amended TT - 28/06/2016
			IF @XEBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @XEBody IS NULL' END -- Amended TT - 28/06/2016
			IF @PBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @PBody IS NULL' END -- Amended TT - 28/06/2016
			IF @MBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @MBody IS NULL' END -- Amended TT - 28/06/2016
			IF @DTBody IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @MBody IS NULL' END -- Amended TT - 28/06/2016
			IF @FSBODY IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @FSBODY IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailSalut IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailSalut IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailFooter IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailFooter IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailLink01_Text IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailLink01_Text IS NULL' END -- Amended TT - 28/06/2016
			IF @EmailLink02_Text IS NULL BEGIN PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailLink02_Text IS NULL' END -- Amended TT - 28/06/2016
			
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailProfile = ' + @EmailProfile -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EMailAddr = ' + @EMailAddr -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SubjectLineText = ' + @SubjectLineText -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailText = ' + @EmailText -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: LEN(@EmailText) = ' + CAST(LEN(@EmailText) AS VARCHAR)-- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @EmailFormat = ' + @EmailFormat -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Importance = ' + @Importance -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @Sensitivity = ' + @Sensitivity -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendCalendarSQL = ' + @SendCalendarSQL -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendAttachmentSQL = ' + @SendAttachmentSQL -- Amended TT - 28/06/2016
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @SendEMailSQL = ' + @SendEMailSQL -- Amended TT - 28/06/2016
		
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
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: @MailItemID = ' +  CONVERT(VARCHAR, @MailItemID)
				END	
				-- End of changes - TT - 10/10/2016
			END
		END --Email Address Type
		ELSE
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: No Valid Email Address' -- Amended TT - 28/06/2016

-- Added Label used in classification constaint code block - TT - 25/10/2016
DO_NOT_SEND_EMAIL:
		
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
				--	Changed SPROC to 'CABS_AUTO_EMAIL_FUNCS_SEND'+'-'+@EmailTemplate to assist with debugging - TT - 02/08/2016
				-- Added @MailItemID to INSERT statement - TT - 10/10/2016
				INSERT INTO AutoEmailFunction_FromTrigger
				SELECT AEF_KEY, AEF_FUNC_REF, AEF_STATUS, AEF_STATUS_TEXT, AEF_ROOM, AEF_ROOM_TEXT, AEF_USE, AEF_USE_TEXT, AEF_PURPOSE, AEF_BOOKER, AEF_BOOKER_TEXT, AEF_BOOKER_EMAIL,
				AEF_DATE, AEF_START, AEF_END, AEF_SETUP, AEF_BDOWN, AEF_COVERS, AEF_MBR_NO, AEF_MBR_NAME, AEF_CONTCT, AEF_EMAIL, AEF_CEMAIL,
				AEF_INTERN, AEF_EXTRAYN, AEF_PACKYN, AEF_MENUYN, AEF_RMGIVEN, AEF_SESSNO, AEF_STARTDATETIME, 'No', AEF_SENT, AEF_SENT_DATE, 0, AEF_INSERTED_DATE, AEF_UPDATED_DATE, AEF_FROM_TRIGGER, 'CABS_AUTO_EMAIL_FUNCS_SEND'+'-'+@EmailTemplate, AEF_DTYN, @MailItemID
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
			@SENT
	END

	CLOSE email_cursor
	DEALLOCATE email_cursor

	IF @DevOverride = 1
	BEGIN
		PRINT '************************************************************************'
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Leaving Procedure CABS_AUTO_EMAIL_FUNCS_SEND' -- Amended TT - 29/06/2016					
		PRINT '************************************************************************'
	END	
END

GO

PRINT '*****************************************************************************'

PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SEND]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SEND') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SEND]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SEND') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SEND]
							   ,@name = N'Version' 
							   ,@value = N'10.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SEND') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SEND: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO