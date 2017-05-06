-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AUTO_BOOKING_UPDATE'
SET @SPROC_Name = 'CABS_AUTO_BOOKING_UPDATE'
if exists (select * from sys.objects where object_id = object_id(N'[CABS_AUTO_BOOKING_UPDATE]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [CABS_AUTO_BOOKING_UPDATE]
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

CREATE PROCEDURE [dbo].[CABS_AUTO_BOOKING_UPDATE]
AS
BEGIN
	-- =============================================
	-- Author:		Mark Birch
	-- Create date: 21-MAR-2014
	-- Description:	Update Booking Details Automatically
	-- Version 3.0
	-- CHANGES:	31-OCT-2014: MCB: Updated Passes to only update FUNC_FIL once to eliminate duplicates.	
	-- CHANGES:	03-DEC-2014: MCB: Updated Passes to check for Session Number, not blank		
	-- =============================================

	SET NOCOUNT ON;
-- =============================================
-- CABS CONFIGURATION - GENERIC
-- =============================================
-- =============================================
-- OBJECT HEADER
-- =============================================
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'CABS_AUTO_BOOKING_UPDATE' --The Object Name

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) = 0 -- Object Doesn't Exist; Run As Normal
	BEGIN -- No Settings Begin
		RETURN
	END -- No Settings End
	ELSE
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) > 0 -- Object Exists; Settings to Consider
	BEGIN --Settings Begin
-- =============================================
-- Dev Overide - Manually run through SQL:
-- =============================================
		DECLARE @DevOverride VARCHAR(1000)
		SET @DevOverride = 0
-- =============================================
-- DECLARATIONS
-- =============================================
		DECLARE
		  @OldStatusCode VARCHAR(1000), @NewStatusCode VARCHAR(1000), @Enabled VARCHAR(1000), @DaysB4 VARCHAR(1000), @OldRoomGiven VARCHAR(1000), @NewRoomGiven VARCHAR(1000)
-- =============================================
-- GET DEFAULT SETTINGS
-- =============================================
	-- =========================================
	-- Administration
	-- =========================================
		SET @Enabled = '1'
	-- =========================================
	-- BOOKING CRITERIA
	-- =========================================
		SET @OldStatusCode = 'CONFRM'
		SET @NewStatusCode = 'PROVNL'
		SET @DaysB4 = 'D:1;H:0;M:0'
		SET @OldRoomGiven = 'No'
		SET @NewRoomGiven = 'Yes'
-- =============================================
-- GET SETTINGS
-- =============================================
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled') > 0
		BEGIN
			SET @Enabled = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled')
		END
		
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'OldStatusCode') > 0
		BEGIN
			SET @OldStatusCode = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'OldStatusCode')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'NewStatusCode') > 0
		BEGIN
			SET @NewStatusCode = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'NewStatusCode')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DaysB4') > 0
		BEGIN
			SET @DaysB4 = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DaysB4')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'OldRoomGiven') > 0
		BEGIN
			SET @OldRoomGiven = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'OldRoomGiven')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'NewRoomGiven') > 0
		BEGIN
			SET @NewRoomGiven = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'NewRoomGiven')
		END
-- =============================================
-- BEGIN THE WORK
-- =============================================		
		IF @Enabled = 0
		BEGIN
			RETURN
		END
		ELSE		
		IF @Enabled = 1
		BEGIN
			EXEC CABS_CREATE_BOOKING_UPDATE_TABLES
			
			DECLARE @DATE_TODAY DATETIME, @MAX_DATE DATETIME
			SET @DATE_TODAY = CONVERT(DATETIME, (CONVERT(VARCHAR(11), (GETDATE()), 20)), 20)
			SET @MAX_DATE = DATEADD (day, CONVERT(INT, @DaysB4), CONVERT(DATETIME, (CONVERT(VARCHAR(11), (GETDATE()), 20)), 20))
			
			IF @DevOverride = 1 BEGIN
				PRINT '@DevOverride'
				PRINT @DevOverride
				PRINT '@Enabled'
				PRINT @Enabled + CHAR(10)
				PRINT '@DATE_TODAY'
				PRINT CONVERT(VARCHAR, (CONVERT(VARCHAR(11), (@DATE_TODAY), 103))) + CHAR(10)
				PRINT '@MAX_DATE'
				PRINT CONVERT(VARCHAR, (CONVERT(VARCHAR(11), (@MAX_DATE), 103))) + CHAR(10)
				PRINT '@DaysB4'
				PRINT @DaysB4 + CHAR(10)
				PRINT '@OldStatusCode'
				PRINT @OldStatusCode + CHAR(10)
				PRINT '@NewStatusCode'
				PRINT @NewStatusCode + CHAR(10)				
				PRINT '@OldStatusCode'
				PRINT @OldStatusCode + CHAR(10)				
				PRINT '@NewStatusCode'
				PRINT @NewStatusCode + CHAR(10)				
			END
		-- =============================================
		-- CURSOR
		-- =============================================			
			If @DevOverride = 1 BEGIN
				SELECT F_REF AS 'FuncRef', (CONVERT(VARCHAR(11), (F_DAY), 103)) As 'FuncDate', F_STATUS As 'FuncStatusCode', DATEDIFF(dd, @DATE_TODAY, F_DAY) As 'DateDiff' 
				FROM FUNC_FIL
				WHERE (F_STATUS = @OldStatusCode OR F_STATUS = @NewStatusCode)
				AND F_RMGIVEN = @OldRoomGiven
				AND DATEDIFF(dd, @DATE_TODAY, F_DAY) <= @DaysB4
				AND F_DAY <= @MAX_DATE
				AND F_STARTDATETIME >= @DATE_TODAY
				AND ( F_OWNER IS NULL
					OR F_OWNER = ''
					OR F_OWNER = F_REF
					)
				AND NOT F_SESSNO IN(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger WHERE AEF_SENT = 0 AND AEF_SENT_SESSION = 0 AND LEFT(F_SESSNO, 1) = 'S')
				ORDER BY F_DAY
			END
			ELSE	
			If @DevOverride = 0 BEGIN
				DECLARE
					@FREF VARCHAR(7)

				DECLARE
					STATUS_UPDATE_CURSOR
				CURSOR FAST_FORWARD for
					
					SELECT F_REF
					FROM FUNC_FIL
					WHERE DATEDIFF(dd, F_DAY, @DATE_TODAY) <= @DaysB4
					AND F_DAY <= @MAX_DATE
					AND F_STARTDATETIME >= @DATE_TODAY
					AND (F_STATUS = @OldStatusCode OR F_STATUS = @NewStatusCode)
					AND F_RMGIVEN = @OldRoomGiven
					--AND NOT F_SESSNO IN(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger WHERE AEF_SENT = 0 AND AEF_SENT_SESSION = 0)
					AND NOT F_SESSNO IN(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger WHERE AEF_SENT = 0 AND AEF_SENT_SESSION = 0 AND LEFT(F_SESSNO, 1) = 'S')
					AND ( F_OWNER IS NULL
							OR F_OWNER = ''
							OR F_OWNER = F_REF
						)
					UNION
					SELECT F_REF
					FROM FUNC_FIL
					WHERE DATEDIFF(dd, F_DAY, @DATE_TODAY) <= @DaysB4
					AND F_DAY <= @MAX_DATE
					AND F_STARTDATETIME >= @DATE_TODAY
					AND F_STATUS = @OldStatusCode
					AND (F_RMGIVEN = @OldRoomGiven OR F_RMGIVEN = @OldRoomGiven)
					--AND NOT F_SESSNO IN(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger WHERE AEF_SENT = 0 AND AEF_SENT_SESSION = 0)
					AND NOT F_SESSNO IN(SELECT AEF_SESSNO FROM AutoEmailFunction_FromTrigger WHERE AEF_SENT = 0 AND AEF_SENT_SESSION = 0 AND LEFT(F_SESSNO, 1) = 'S')
					AND ( F_OWNER IS NULL
							OR F_OWNER = ''
							OR F_OWNER = F_REF
						)
																									 
				OPEN STATUS_UPDATE_CURSOR

				FETCH NEXT FROM
					STATUS_UPDATE_CURSOR
				INTO
					@FREF

				WHILE @@FETCH_STATUS = 0
				BEGIN
					--UPDATE FUNC_FIL
					--SET F_STATUS = @NewStatusCode
					--WHERE F_REF = @FREF
					--AND F_STATUS = @OldStatusCode
					
					--UPDATE FUNC_FIL
					--SET F_RMGIVEN = @NewRoomGiven
					--WHERE F_REF = @FREF
					--AND F_RMGIVEN = @OldRoomGiven
					
					UPDATE FUNC_FIL
					SET F_STATUS = @NewStatusCode,
					F_RMGIVEN = @NewRoomGiven
					WHERE F_REF = @FREF
					AND ((F_STATUS = @OldStatusCode)
					OR (F_RMGIVEN = @OldRoomGiven))
															
					INSERT INTO AutoBookingUpdate
					SELECT @FREF, @OldStatusCode, @NewStatusCode, @OldRoomGiven, @NewRoomGiven, GETDATE()

					FETCH NEXT FROM 
						STATUS_UPDATE_CURSOR
					INTO
						@FREF
				END

				CLOSE STATUS_UPDATE_CURSOR
				DEALLOCATE STATUS_UPDATE_CURSOR	
			END			
		END
	END
END
GO

PRINT '*****************************************************************************'

PRINT 'CABS_AUTO_BOOKING_UPDATE: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_BOOKING_UPDATE]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_BOOKING_UPDATE') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_BOOKING_UPDATE]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_BOOKING_UPDATE') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AUTO_BOOKING_UPDATE]
							   ,@name = N'Version' 
							   ,@value = N'3.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AUTO_BOOKING_UPDATE') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AUTO_BOOKING_UPDATE: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO