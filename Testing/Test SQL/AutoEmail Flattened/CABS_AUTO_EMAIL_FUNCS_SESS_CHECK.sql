-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK'
SET @SPROC_Name = 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]
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

-- ================================================================================================================
-- Author:		Mark Birch
-- Create date: 14-JAN-2015
-- Description:	To gather data for sending Emails off of a Trigger
-- ================================================================================================================
-- Version: 19
-- Date: 16/02/2017
-- ================================================================================================================
-- Changes: MCB: 15/01/2015: Added MatchCriteria to the selection criteria
-- Changes: MCB: 22/01/2015: Added RoomGiven to the Headings criteria
-- Changes: MCB: 23/01/2015: Added UPDATE to the Headings criteria
-- Changes: MCB: 27/01/2015: Added Seperate Session and Non-Session Sent Flag Updates
-- Changes: MCB: 03/02/2015: Added Seperate Session and Non-Session @IncOtherSession
-- Changes: MCB: 03/02/2015: Added @CreateDayCutOff handling
-- Changes: MCB: 04/02/2015: Removed @CreateDayCutOff handling
-- Changes: MCB: 18/02/2015: Added @Department handling
-- Changes: MCB: 20/02/2015: Added Email Type Headings
-- Changes: MCB: 12/03/2015: Added Delete Handling
-- Changes: MCB: 31/03/2015: Added NOCHNG to get specific email text; NOCHNG is used if the last package 
--							 item isn't change, but some of the others may have been
-- Changes: MCB: 01/06/2016: Added @EmailSPROC
-- Changes: TT:  20/06/2016: Moved reset of AEFL_Sent = 1 to after call of CABS_AUTO_EMAIL_FUNCS 
-- Changes: TT:  29/06/2016: Added Debugging information to assist with testing
-- Changes: TT:  05/07/2016: Added new parameters in code @EmailSalut_Alt, @EmailSignature_Alt
-- Changes: TT:  01/08/2016: Added default values of 0 to @SendToHost_Alt, @SendToDepartment_Alt, @SendToBooker_Alt
-- Changes: TT:	 12/09/2016: Added code to implement an autoemail send window
-- Changes: TT:  10/10/2016: Changed code to reset AEFL_Sent for Functions in a Session
-- Changes: TT:	 02/11/2016: Changes required to fix autoemail send window implementation
--	(16) 	
-- Changes: TT:	 29/11/2016: Added more diagnostic code to help trace issues during testing/devlopment
--	(17)
-- Changes: TT:  07/02/2017: Added a check of switch IgnoreSessionStatus set to 1 in the email template section of 
--	(18)					 x cabs config. If it is then autoemails for functions in a session are treated 
--							 individually when being considered for transmission
-- Changes: TT:	 16/02/2016: The value of Sendable in vw_AEFLINK has been changed from 0 and 1 to -ve and +ve 
--  (19)					 values. This is to enable better diagnostic investigations of the automail process. 
--							 A description of the meaning of the return code can be found in a new table called 
--							 DiagnosticMessages. A return code which is -ve means that an autoemail is not 
--							 sendable. A code that is +ve is sendable.
--							 The value of MatchCriteria in vw_AEFLINK has been changed from 0 and 1 to -ve and +ve
--							 values. A return code which is -ve means that the criteria to send an autoemail is not 
--							 . A code that is +ve means criteria is matched.
-- ================================================================================================================

CREATE PROCEDURE [dbo].[CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]
AS
BEGIN
	SET NOCOUNT ON;
-- =============================================
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'CABS_AUTO_EMAIL_FUNCS_Trigger' --The Object Name

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) = 0 -- Object Doesn't Exist; Run As Normal
	BEGIN -- No Settings Begin
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: No CABS_AUTO_EMAIL_FUNCS_Trigger sectionin X CABS CONFIG' -- Added - TT - 29/09/2016
		RETURN
	END -- No Settings End
	ELSE
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) > 0 -- Object Exists; Settings to Consider
	BEGIN --Settings Begin
	
-- =============================================
-- DECLARATIONS
-- =============================================
		DECLARE
			@SettingsType VARCHAR(10)
			
		DECLARE
			@Enabled VARCHAR(1000),

			@DetailHeading VARCHAR(1000),
			@DetailSubHeading VARCHAR(1000),
			@EmailHeaderText VARCHAR(1000),
			@EmailSubTitle VARCHAR(1000),

			@SessionDetailHeading VARCHAR(1000),
			@SessionDetailSubHeading VARCHAR(1000),
			@SessionEmailHeaderText VARCHAR(1000),
			@SessionEmailSubTitle VARCHAR(1000),
			
			@DetailHeading_Alt VARCHAR(1000),
			@DetailSubHeading_Alt VARCHAR(1000),
			@EmailHeaderText_Alt VARCHAR(1000),
			@EmailSubTitle_Alt VARCHAR(1000),

			-- 08/06/2016 - TT
			-- Added new variables for email template specific config settings
			@SubjectLine_Alt VARCHAR(1000), 
			@SendToHost_Alt VARCHAR(1000),
			@SendToDepartment_Alt VARCHAR(1000),
			@SendToBooker_Alt VARCHAR(1000),
			@EmailBodyText_Alt VARCHAR(1000),
			-- End of changes - 08/06/2016 - TT

			-- Added - TT - 05/07/2016
			@EmailSalut_Alt VARCHAR(1000),
			@EmailSignature_Alt VARCHAR(1000),
			-- End of changes - 05/07/2016 - TT

			@IncOtherSession INT

-- =============================================
-- GET DEFAULT SETTINGS
-- =============================================
		SET @SettingsType = 'S'
		
		SET @DetailHeading_Alt = ''
		SET @DetailSubHeading_Alt = ''
		SET @EmailHeaderText_Alt = ''
		SET @EmailSubTitle_Alt = ''
				
		-- 08/06/2016 - TT
		-- Initialise new variables for email template specific config settings
		SET	@SubjectLine_Alt = ''
		SET	@SendToHost_Alt = ''
		SET	@SendToDepartment_Alt  = ''-- Added by TT - 20/06/2016
		SET	@SendToBooker_Alt  = ''
		SET	@EmailBodyText_Alt  = ''
		-- End of changes - 08/06/2016 - TT

		-- Added - TT - 05/07/2016
		SET	@EmailSalut_Alt = ''
		SET	@EmailSignature_Alt = ''
			-- End of changes - 05/07/2016 - TT

		SET @IncOtherSession = 0		

		DECLARE @DebugFlag INT -- Added by TT - 29/06/2016
		SET @DebugFlag = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DebugFlag')), '0')  -- Added by TT - 29/06/2016		

		IF @DebugFlag = 1
		BEGIN
			PRINT '************************************************************************************'
			PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Entered Procedure CABS_AUTO_EMAIL_FUNCS_SESS_CHECK' -- Amended TT - 29/06/2016					
			PRINT '************************************************************************************'
		END			
-- =============================================
-- GET SETTINGS
-- =============================================
		SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Enabled')), '0')

		-- Added by TT - 29/06/2016
		IF @Enabled = 0
		BEGIN
			IF @DebugFlag = 1
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Functionality not enabled in X CABS Config'
			RETURN
		END

		SET @DetailHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailHeading')), '')
		SET @DetailSubHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'DetailSubHeading')), '')			
		SET @EmailHeaderText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailHeaderText')), '')						
		SET @EmailSubTitle = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'EmailSubTitle')), '')									

--Sessions
		SET @SessionDetailHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SessionDetailHeading')), '')															
		SET @SessionDetailSubHeading = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SessionDetailSubHeading')), '')																		
		SET @SessionEmailHeaderText = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SessionEmailHeaderText')), '')																					
		SET @SessionEmailSubTitle = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'SessionEmailSubTitle')), '')																								
	END --Settings End
-- =============================================
	-- Moved code to earlier in procedure to stop unecessary processing - TT - 29/06/2016
	--IF @Enabled = 0
	--BEGIN
	--	RETURN
	--END
	--ELSE
	IF @Enabled = 1
	BEGIN
    -- Insert statements for procedure here
		DECLARE
			@ID INT,
			@FunctionRef VARCHAR(7),
			@SessionNo VARCHAR(7),
			@Source VARCHAR(100),
			@RoomGiven VARCHAR(3),
			@Department VARCHAR(1000),
			@EmailType VARCHAR(100), -- 01/06/2016 - TT - Added for New Auto Email Templates
			@EmailSPROC VARCHAR(200) -- 01/06/2016 - TT - Added for New Auto Email Templates

		-- Added Diagnostic information - TT - 29/11/2016
		IF @DebugFlag = 1
		BEGIN			
			DECLARE @CursourRecCount INT
			-- Changed condition Sendable = 1 to Sendable > 0 as Sendable can have values other than just 0 and 1. A +ve value ,means email is Sendable - TT - 16/02/2017
			-- Changed condition MatchCriteria = 1 to MatchCriteria > 0 as MatchCriteria can have values other than just 0 and 1. A +ve value ,means criteria are matched - TT - 16/02/2017
			SET @CursourRecCount = (SELECT Count(AEFL_ID) FROM vw_AEFLink WHERE AEFL_Sent = 0 AND Sendable > 0 AND MatchCriteria > 0 AND DATEDIFF ( minute , GETDATE() ,  AEFL_SendTime ) <=0)
			IF @CursourRecCount = 0
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Records in Cursor SS_CURSOR = ' + CONVERT(VARCHAR, @CursourRecCount) + ' - No Autoemails To Process !'
			END
			ELSE
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Records in Cursor SS_CURSOR = ' + CONVERT(VARCHAR, @CursourRecCount) + ' - Autoemails To Process'
			END
		END
		-- End of changes - TT - 29/11/2016
						
		DECLARE
			SS_CURSOR
		CURSOR FAST_FORWARD for

			-- 01/06/2016 - TT - Added AEFL_EmailSPROC for New Auto Email Templates
			SELECT AEFL_ID, AEFL_FREF, AEFL_SessNo, AEFL_Source, (SELECT [dbo].[uf_HasRoomBeenGiven] (AEFL_FREF)), AEFL_Department, AEFL_EMailType, AEFL_EmailSPROC
			FROM vw_AEFLink
			WHERE AEFL_Sent = 0
			-- Changed condition Sendable = 1 to Sendable > 0 as Sendable can have values other than just 0 and 1. A +ve value ,eams email is Sendable - TT - 16/02/2017			
			AND Sendable > 0
			-- Changed condition MatchCriteria = 1 to MatchCriteria > 0 as MatchCriteria can have values other than just 0 and 1. A +ve value ,means criteria are matched - TT - 16/02/2017
			AND MatchCriteria > 0
			AND DATEDIFF ( minute , GETDATE() ,  AEFL_SendTime ) <=0
			
		OPEN SS_CURSOR

		FETCH NEXT FROM
			SS_CURSOR
		INTO
			@ID,
			@FunctionRef,
			@SessionNo,
			@Source,
			@RoomGiven,
			@Department,
			@EmailType,
			@EmailSPROC -- 01/06/2016 - TT - Added @EmailSPROC for New Auto Email Templates

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			-- Changes added to implement an auto email send window - TT - 12/09/2016

			-- Declare required variables
			DECLARE @StartWindow DateTime			
			DECLARE @EndWindow DateTime
			DECLARE @NewStartWindow DateTime			
			DECLARE @ResetDuration Int

			-- Get the relevant config setting from X_CABS_CONFIG (System Defaults)
			-- These are set on a per email type basis
			-- String not converted to datetime intrinsically - added convert - TT - 02/11/2016
			--SET @StartWindow = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'STARTWINDOW')), '2000-01-01')  
			SET @StartWindow = CONVERT(datetime, COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'STARTWINDOW')), '2000-01-01'), 103) 			
			SET @ResetDuration = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'RESETDURATION')), '0')

			-- Added Diagnostic information - TT - 02/11/2016
			IF @DebugFlag = 1
			BEGIN			
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @emailType = ' + @emailType
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @StartWindow = ' + CONVERT(VARCHAR, @StartWindow, 103)
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @ResetDuration = ' + CONVERT(VARCHAR, @ResetDuration)				
			END

			-- End of Changes - TT - 02/11/2016

			-- Ensure Config settings are present i.e. they are not set to their default values
			IF (@StartWindow <> '2000-01-01') AND (@ResetDuration > 0)
			BEGIN

				-- Calculate the end of the reset duration
				SET @EndWindow = DATEADD(day, @ResetDuration, @StartWindow )
				-- Calculate what would be the new start window date					
				SET @NewStartWindow = @StartWindow

				-- Added Diagnostic information - TT - 02/11/2016
				IF @DebugFlag = 1
				BEGIN			
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: AutoEmail Send Window Configured'					
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EndWindow = ' + CONVERT(VARCHAR, @EndWindow, 103)	
				END

				-- Has the reset period expired (is it in the past ?)
				-- Changed IF for a WHILE as the End Window must end up being in the future and used < instaed of > - TT - 02/11/2016
				--IF (DATEDIFF(minute, @EndWindow, getdate()) < 0)
				WHILE (DATEDIFF(minute, @EndWindow, getdate()) > 0)
				BEGIN
					-- If it is calculate the new start window date					
					SET @StartWindow = DATEADD(day, @ResetDuration, @StartWindow)					

					-- Added - TT - 02/11/2016
					-- Re-calculate the end of the reset duration
					SET @EndWindow = DATEADD(day, @ResetDuration, @EndWindow )

					-- Added Diagnostic information - TT - 02/11/2016
					IF @DebugFlag = 1
					BEGIN		
						PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EndWindow in the Past'
						PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: New @StartWindow = ' + CONVERT(VARCHAR, @StartWindow, 103)	
						PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: New @EndWindow = ' + CONVERT(VARCHAR, @EndWindow, 103)	
					END

					-- Update the X CABS Config setting for that particular email type
					-- Need to do an UPDATE and not an INSERT - TT - 02/11/2016
					UPDATE xCABS_CONFIG_TABLE SET [VALUE] = CONVERT(VARCHAR, CAST(@StartWindow AS DATE), 103), [CHANGE_BY] = 'INS', CHANGE_UTC = GETUTCDATE()
					WHERE [TYPE] = 'S' AND SECTION = @emailType AND [KEY] = 'StartWindow'  
					--INSERT INTO xCABS_CONFIG_TABLE
					--	([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])		
					--VALUES						
					--(@SettingsType, '', @emailType, 'STARTWINDOW', @NewStartWindow, 0, 'INS', GETUTCDATE()) 					
				END
			END
			-- Added diagnostic information - TT - 02/11/2016
			ELSE
			BEGIN
				IF @DebugFlag = 1
				BEGIN			
					PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: AutoEmail Send Window Not Configured'										
				END
			END
			-- End of changes - TT - 02/11/2016
			-- End of changes - TT - 12/09/2016

			--Get Headings		
			--IF COALESCE(@SessionNo, '') = '' AND @RoomGiven = 'No' AND (substring(@Source,1,6) IN('INSERT', 'UPDATE'))
			--BEGIN 
			--	SET @DetailHeading_Alt = @DetailHeading
			--	SET @DetailSubHeading_Alt = @DetailSubHeading
			--	SET @EmailHeaderText_Alt = @EmailHeaderText
			--	SET @EmailSubTitle_Alt = @EmailSubTitle
			--END
			--ELSE
			--IF COALESCE(@SessionNo, '') <> '' AND @RoomGiven = 'No' AND (substring(@Source,1,6) IN('INSERT', 'UPDATE'))
			--BEGIN 
			--	SET @DetailHeading_Alt = @SessionDetailHeading
			--	SET @DetailSubHeading_Alt = @SessionDetailSubHeading
			--	SET @EmailHeaderText_Alt = @SessionEmailHeaderText
			--	SET @EmailSubTitle_Alt = @SessionEmailSubTitle
			--END	

			-- Removed session specific conditions as email detail now defined at the specific email level - TT - 13/07/2016
			--IF COALESCE(@SessionNo, '') = '' AND (substring(@Source,1,6) IN('INSERT', 'UPDATE', 'DELETE', 'NOCHNG')) BEGIN
			IF SUBSTRING(@Source,1,6) IN('INSERT', 'UPDATE', 'DELETE', 'NOCHNG') BEGIN
				SET @DetailHeading_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'DetailHeading')), @DetailHeading)
				SET @DetailSubHeading_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'DetailSubHeading')), @DetailSubHeading)			
				SET @EmailHeaderText_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'EmailHeaderText')), @EmailHeaderText)						
				SET @EmailSubTitle_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'EmailSubTitle')), @EmailSubTitle)																	
			END
			/* Removed session specific conditions as email detail now defined at the specific email level - TT - 13/07/2016
			ELSE
			IF COALESCE(@SessionNo, '') <> '' AND (substring(@Source,1,6) IN('INSERT', 'UPDATE', 'DELETE', 'NOCHNG')) BEGIN
				SET @DetailHeading_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SessionDetailHeading')), @SessionDetailHeading)															
				SET @DetailSubHeading_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SessionDetailSubHeading')), @SessionDetailSubHeading)																		
				SET @EmailHeaderText_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SessionEmailHeaderText')), @SessionEmailHeaderText)																					
				SET @EmailSubTitle_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SessionEmailSubTitle')), @SessionEmailSubTitle)
			END		
			*/
			-- 08/06/2016 - TT
			-- Added setting new variables for email template specific config settings
			-- 01/08/2016 - TT - Added default values of 0 to @SendToHost_Alt, @SendToDepartment_Alt, @SendToBooker_Alt
			SET @SubjectLine_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SubjectLine')), '')
			SET @SendToHost_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SendToHost')), '0')
			SET @SendToDepartment_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SendToDepartment')), '0')
			SET @SendToBooker_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'SendToBooker')), '0')
			SET @EmailBodyText_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'EmailBodyText')), '')
			-- End of changes - 08/06/2016 - TT

			-- 05/07/2016 - TT
			-- Added setting new variables for email template specific config settings
			SET @EmailSalut_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'EmailSalut')), '')
			SET @EmailSignature_Alt = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @EmailType, 'EmailSignature')), '')
			-- End of changes - 05/07/2016 - TT

			-- Added - TT - 05/07/2016
			IF @DebugFlag = 1
			BEGIN			
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @DetailHeading_Alt = ' + @DetailHeading_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @DetailSubHeading_Alt = ' + @DetailSubHeading_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EmailHeaderText_Alt = ' + @EmailSPROC
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EmailSubTitle_Alt = ' + @EmailSPROC
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @SubjectLine_Alt = ' + @SubjectLine_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @SendToHost_Alt = ' + @SendToHost_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @SendToDepartment_Alt = ' + @SendToDepartment_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @SendToBooker_Alt = ' + @SendToBooker_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EmailBodyText_Alt = ' + @EmailBodyText_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EmailSalut_Alt = ' + @EmailSalut_Alt
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @EmailSignature_Alt = ' + @EmailSignature_Alt
			END

			--Update Sent Flag/Include Other Sessions
			IF COALESCE(@SessionNo, '') = ''
			BEGIN
			/* 
				Moved code to after call of CABS_AUTO_EMAIL_FUNCS - TT - 20/06/2016

				UPDATE AEF_Link
				SET AEFL_Sent = 1
				WHERE AEFL_ID = @ID

			*/				
				SET @IncOtherSession = 0
			END
			ELSE	
			IF COALESCE(@SessionNo, '') <> ''
			BEGIN
			/* 
				Moved code to after call of CABS_AUTO_EMAIL_FUNCS - TT - 20/06/2016

				UPDATE AEF_Link
				SET AEFL_Sent = 1
				WHERE AEFL_SessNo = @SessionNo
			*/				
				SET @IncOtherSession = 1							
			END

			-- Added - TT - 29/06/2016
			IF @DebugFlag = 1
			BEGIN
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Calling CABS_AUTO_EMAIL_FUNCS with:'
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK:     @FunctionRef = ' + @FunctionRef
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK:     @EmailType = ' + @EmailType
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK:     @EmailSPROC = ' + @EmailSPROC
			END

			-- Added @EmailSalut_Alt, @EmailSignature_Alt to parameter list - TT - 05/07/2016
			-- Passed additional parameters @EmailSPROC and @EmailType to CABS AUTO_EMAIL_FUNCS - TT - 07/06/2016
			EXEC CABS_AUTO_EMAIL_FUNCS 1, @FunctionRef, @DetailHeading_Alt, @DetailSubHeading_Alt, @EmailHeaderText_Alt, 
										@EmailSubTitle_Alt, @IncOtherSession, @Department, @EmailSPROC, @EmailType,
										@SubjectLine_Alt, @SendToHost_Alt, @SendToDepartment_Alt, @SendToBooker_Alt, 
										@EmailBodyText_Alt, @EmailSalut_Alt, @EmailSignature_Alt
			
			-- Added Code to read new config setting - TT - 07/02/2017
			DECLARE @IgnoreSessionStatus VARCHAR(10) 
			SET @IgnoreSessionStatus = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'IgnoreSessionStatus')), '0')
			IF @DebugFlag = 1
			BEGIN				
				PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: @IgnoreSessionStatus = ' + @IgnoreSessionStatus
			END
			-- End of Changes - TT - 07/02/2017

			/* 
				Added code to reset AEFL_SENT column - TT - 20/06/2016
			*/
			-- Added criteria @IgnoreSessionStatus to AEFL_SENT column reset - TT - 07/02/2017
			-- IF COALESCE(@SessionNo, '') = ''
			IF (COALESCE(@SessionNo, '') = '') OR (@IgnoreSessionStatus = '1')
			BEGIN
				UPDATE AEF_Link
				SET AEFL_Sent = 1
				WHERE AEFL_ID = @ID								
			END
			ELSE	
			IF COALESCE(@SessionNo, '') <> ''
			BEGIN
				UPDATE AEF_Link
				SET AEFL_Sent = 1
				WHERE AEFL_SessNo = @SessionNo							
				-- Added Code to only reset AEFL_SessNo for teh specific template type - TT - 10/10/2016
				AND AEFL_EMailType = @EmailType
			END
			/* 
				End of reset AEFL_SENT column changes - TT - 20/06/2016
			*/

			FETCH NEXT FROM 
				SS_CURSOR
			INTO
				@ID,
				@FunctionRef,
				@SessionNo,
				@Source,
				@RoomGiven,
				@Department,
				@EmailType,
				@EmailSPROC
		END

		CLOSE SS_CURSOR
		DEALLOCATE SS_CURSOR
	END --Not Enabled

	IF @DebugFlag = 1
	BEGIN
		PRINT '************************************************************************************'
		PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Leaving Procedure CABS_AUTO_EMAIL_FUNCS_SESS_CHECK' -- Amended TT - 29/06/2016					
		PRINT '************************************************************************************'
	END			
END

GO

PRINT '*****************************************************************************'

PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SESS_CHECK') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SESS_CHECK') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_EMAIL_FUNCS_SESS_CHECK]
							   ,@name = N'Version' 
							   ,@value = N'19.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_EMAIL_FUNCS_SESS_CHECK') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO