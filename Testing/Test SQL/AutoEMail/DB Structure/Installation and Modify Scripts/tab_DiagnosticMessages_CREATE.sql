-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 16/02/2017
-- Description:	Script to create DiagnosticMessages Table.
--				This table is used to convert return codes into human readable, understandable messages
--				Intended to be used during diagnostic processes
--
-- =====================================================================================================
-- Version:		1
-- Date:		16/02/2017
-- =====================================================================================================
-- Changes:		TT: 16/02/2017: Original Version
--	 (1)
-- =====================================================================================================

SET NOCOUNT ON;

-- *****************************************
-- If table does not already exist create it
-- *****************************************
IF (SELECT COUNT(*) FROM sys.objects WHERE object_id = object_id(N'[DiagnosticMessages]')) > 0
BEGIN
	DROP TABLE [dbo].[DiagnosticMessages]
	IF @@ERROR = 0
		PRINT 'tab_DiagnosticMessages_CREATE: Table DiagnosticMessages Already Exists - Dropped'
	ELSE
		PRINT 'tab_DiagnosticMessages_CREATE: Error Dropping Table DiagnosticMessages ! Error Code: ' + CONVERT(VARCHAR(20), @@ERROR) 
END
GO

CREATE TABLE [DiagnosticMessages]
(
	[DM_ID] [INT] IDENTITY(1,1) PRIMARY KEY,
	[DM_USED_IN] [VARCHAR](128) NULL,
	[DM_CODE] [INT] NULL UNIQUE,
	[DM_STATUS] [VARCHAR](32) NULL,		
	[DM_DESCRIPTION] [VARCHAR](512) NULL,		
	[DM_LAST_UPDATE] [DATETIME] NULL
)

IF @@ERROR = 0
	PRINT 'tab_DiagnosticMessages_CREATE: Table DiagnosticMessages Created'
ELSE
	PRINT 'tab_DiagnosticMessages_CREATE: Error Creating Table DiagnosticMessages ! Error Code: ' + CONVERT(VARCHAR(20), @@ERROR) 

-- =====================================================================================================
PRINT 'tab_DiagnosticMessages_CREATE: Inserting Diagnostic Data For Function uf_AEF_Link_Sendable '
-- =====================================================================================================

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1001,'NOT SENDABLE', 'Email could already have been sent or is not enabled or for recurring emails, the sent flag still needs to be reset', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1002,'NOT SENDABLE', 'The last change is still within the Work In Progress Window - Not enough time elapsed since last update - Check WIPWindow setting in section CABS_AUTO_EMAIL_FUNCS in System Defaults', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1003,'NOT SENDABLE', 'Email Type - AEFECC - Event MBR is not current (MBR EndDate is in tha past', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1004,'NOT SENDABLE', 'The SendTime is NULL. However, the derived SendTime based on the Frequency setting is in the future', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1005,'NOT SENDABLE', 'The SendTime is in the future', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1006,'NOT SENDABLE', 'Autoemail relates to a function that is not within the Sendable Window - Check STARTWINDOW and RESETDURATION settings in section AEFxxx in System Defaults', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', -1007,'NOT SENDABLE', 'Autoemail relates to a function that is in the past', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', 1001,'SENDABLE', 'Email Type - AEFECC - Event MBR is still current (MBR EndDate is in the future', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_AEF_Link_Sendable', 1002,'SENDABLE', 'AEFL_Sent is 0 and AEFL_CanSend = 1', GETDATE())

-- =====================================================================================================
PRINT 'tab_DiagnosticMessages_CREATE: Inserting Diagnostic Data For Function ufAEF_MatchCriteria'
-- =====================================================================================================

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1020, 'NOT MATCHED', '', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1021, 'NOT MATCHED', 'The Autoemail is not enabled - Check switches Enabled, EnabledB, EnabledE and EnabledC in Section AEFxxx in System Defaults', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1022, 'NOT MATCHED', 'The Autoemail is not configured to be sent for the current Status Code - Check switch StatusCode in Section AEFxxx in System Defaults', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1023, 'NOT MATCHED', 'SOURCE does not contain correct information', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1024, 'NOT MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Given, Room Not Changed, Not Only Booker to be Updated', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1025, 'NOT MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Given, Room Not Changed, Only Booker to be Updated but Booker Not Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1026, 'NOT MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Not Given, Not Only Booker to be Updated', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1027, 'NOT MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Not Given, Only Booker to be Updated and Booker Not Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1028, 'NOT MATCHED', 'Switches OnlySendBookerUpdate set to 1 and OnlySendRoomGiven set to 0 in System Defaults, Section AEFxxx - Room has Not Changed and Not Only Booker to be Updated', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', -1029, 'NOT MATCHED', 'Switches OnlySendBookerUpdate set to 1 and OnlySendRoomGiven set to 0 in System Defaults, Section AEFxxx - Room has Not Changed, Only Booker to be Updated and Booker Not Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1020, 'MATCHED', 'Autoemail is of type AEFUPE, AEFUIE or AEFSWR', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1021, 'MATCHED', 'SOURCE contains correct information', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1022, 'MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Given and Room Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1023, 'MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Given, Room Not Changed, Only Booker to be Updated and Booker Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1024, 'MATCHED', 'OnlySendBookerUpdate and OnlySendRoomGiven switches set to 1 in System Defaults, Section AEFxxx - Room Not Given, Only Booker to be Updated and Booker Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1025, 'MATCHED', 'Switches OnlySendBookerUpdate set to 1 and OnlySendRoomGiven set to 0 in System Defaults, Section AEFxxx - Room has Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1026, 'MATCHED', 'Switches OnlySendBookerUpdate set to 1 and OnlySendRoomGiven set to 0 in System Defaults, Section AEFxxx - Room has Not Changed, Only Booker to be Updated and Booker Changed', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('ufAEF_MatchCriteria', 1027, 'MATCHED', 'Extra, Menu, Package or Drinks Trolley changed or switch OnlySendRoomUpdate set to 0 (in System Defaults, Section AEFxxx)', GETDATE())

-- =====================================================================================================
PRINT 'tab_DiagnosticMessages_CREATE: Inserting Diagnostic Data For Function uf_IsSendableSessBooking'
-- =====================================================================================================

INSERT INTO DiagnosticMessages
VALUES ('uf_IsSendableSessBooking', 0, 'NOT SENDABLE', 'Booking is not Session Sendable (Default Value)', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_IsSendableSessBooking', 1040, 'SENDABLE', 'Booking is not part of a Session', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_IsSendableSessBooking', 1041, 'SENDABLE', 'The switch @IgnoreSessionStatus is set to 1 in System Defaults, Section AEFxxx - The booking will be treated as if it is not in a session', GETDATE())

INSERT INTO DiagnosticMessages
VALUES ('uf_IsSendableSessBooking', 1042, 'SENDABLE', 'The Function (TOP 1) from the Session has not been sent', GETDATE())

IF @@ERROR = 0
	PRINT 'tab_DiagnosticMessages_CREATE: Inserting Data Completed'
ELSE
	PRINT 'tab_DiagnosticMessages_CREATE: Error Inserting Data into Table DiagnosticMessages ! Error Code: ' + CONVERT(VARCHAR(20), @@ERROR) 

GO

PRINT '*****************************************************************************'								   
PRINT 'DiagnosticMessages: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [DiagnosticMessages]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('DiagnosticMessages') AND [name] = 'Product')
BEGIN		
	PRINT 'DiagnosticMessages: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'DiagnosticMessages: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [DiagnosticMessages]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('DiagnosticMessages') AND [name] = 'Module')
BEGIN		
	PRINT 'DiagnosticMessages: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'DiagnosticMessages: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [DiagnosticMessages]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('DiagnosticMessages') AND [name] = 'Version')
BEGIN		
	PRINT 'DiagnosticMessages: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'DiagnosticMessages: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

