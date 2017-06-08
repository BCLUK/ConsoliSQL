
-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_AddExternalVisitorWithDetails]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_AddExternalVisitorWithDetails]	
	PRINT 'usp_AddExternalVisitorWithDetails: Dropped Procedure usp_AddExternalVisitorWithDetails'
END
ELSE
BEGIN	
	PRINT 'usp_AddExternalVisitorWithDetails: usp_AddExternalVisitorWithDetails -  Does Not Already Exist !'
END

PRINT 'usp_AddExternalVisitorWithDetails: Creating Procedure usp_AddExternalVisitorWithDetails'
GO

-- ====================================================================================================================
-- Author:		Corey Bradford				
-- Create Date:	24/05/2017
-- Description:	Adds an external visitor and lets you pass an email address for them
-- Product:		CABS
-- Module:		Core
-- Parameters:	Insert Parameter List
-- Returns:		Insert Data Type
-- Switches:	Insert CABS Switches Used
-- Test:		Insert How to Test
-- Called By:	usp_AddExternalVisitor
-- Calls:	
-- Error Codes:
-- 0x00:		Success
-- 0x01:		Booking does not exist.
-- 0x02:		Failed to get new visitor sys no.
-- 0x04:		Visitor does not exist.	
-- ====================================================================================================================
-- Version:		1.0
-- Date:		24/05/2017
-- ====================================================================================================================
-- Changes		
-- 24/05/2017	1.0 - Corey Bradford 
--					- Original Version taken from usp_AddExternalVisitor which now points here
--					- Added Email and telephone
-- ====================================================================================================================
CREATE PROCEDURE [dbo].[usp_AddExternalVisitorWithDetails]
	-- Add the parameters for the stored procedure here
	@BookingRef		VARCHAR( 7 ),
	@SysNo			VARCHAR( 10 ) OUT,
	@OperatorId		VARCHAR( 32 ),
	@Title			VARCHAR( 10 ),
	@Forename		VARCHAR( 30 ),
	@Surname		VARCHAR( 40 ),
	@Company		VARCHAR( 40 ),
	@ExpectedTime	VARCHAR( 5 ),
	@Note			VARCHAR( 1024 ),
	@Email			VARCHAR( 100 ),
	@Telephone		VARCHAR( 50 ),
	@ErrorCode		INT OUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

	DECLARE 
		@CreatedSysNo		INT,
		@Hostname			VARCHAR( 100 )	= '',
		@Date				DATETIME		= '1900-01-01 00:00:00.000',
		@HostMbr			VARCHAR( 7 )	= '',
		@Room				VARCHAR( 6 )	= '',
		@Location			VARCHAR( 6 )	= '',
		@ExpectedDateTime	DATETIME

	SET @ErrorCode = 0x00

	IF NOT EXISTS( SELECT 0 FROM FUNC_FIL WHERE F_REF = @BookingRef )
	BEGIN
		SET @ErrorCode = 0x01
		RETURN
	END

	SELECT 
		@Hostname	= F_MBR_NAME,
		@Date		= F_DAY,
		@HostMbr	= F_MBR_NO,
		@Room		= F_ROOM,
		@Location	= RM_LOC
	FROM FUNC_FIL
	INNER JOIN ROOMS
		ON F_ROOM	= RM_ABBR
	WHERE F_REF		= @BookingRef

	SET @ExpectedDateTime = DATEADD(HH, DATEPART(HH, @ExpectedTime), DATEADD(MI, DATEPART(MI, @ExpectedTime), @Date))

	IF @SysNo = ''
	BEGIN
		EXECUTE @CreatedSysNo = cabs_get_next_num @num_type = 5
		IF @CreatedSysNo < 1
		BEGIN
			SET @ErrorCode = 0x02
			RETURN
		END

		SET @SysNo = 'V' + REPLACE(STR(@CreatedSysNo, 9), SPACE(1), '0')

		INSERT INTO VISITORS
		(
			V_SYSNO,V_HOSTNAME,V_DATE,V_EXPECTED,V_TITLE
			,V_FORENAME,V_SURNAME,V_COMPANY,V_TYPE,V_HOSTMBR
			,V_ROOM,V_FUNCNO,V_LOC,V_EXP_DATETIME
			,V_OPID, V_EMAIL, V_TELNO
		)
		VALUES 
		(
			@SysNo, @Hostname, @Date, @ExpectedTime, @Title
			,@Forename, @Surname, @Company, 'NORM', @HostMbr
			,@Room, @BookingRef, @Location, @ExpectedDateTime
			,@OperatorId, @Email, @Telephone
		)

		IF @Note <> ''
		BEGIN
			INSERT INTO VIS_NOTES 
				( VN_SYSNO, VN_DATESTAMP, VN_OPID, VN_TEXT )
			VALUES 
				( @SysNo, GETDATE(), @OperatorId, @Note )
		END
	END
	ELSE IF @SysNo LIKE 'V%'
	BEGIN
		IF NOT EXISTS(SELECT 0 FROM VISITORS WHERE V_SYSNO = @SysNo)
		BEGIN
			SET @ErrorCode = 0x04
			RETURN
		END

		UPDATE VISITORS
		SET V_HOSTNAME = @Hostname,
			V_DATE = @Date,
			V_EXPECTED = @ExpectedTime,
			V_TITLE = @Title,
			V_FORENAME = @Forename,
			V_SURNAME = @Surname,
			V_COMPANY = @Company,
			V_HOSTMBR = @HostMbr,
			V_ROOM = @Room,
			V_FUNCNO = @BookingRef,
			V_LOC = @Location,
			V_EXP_DATETIME = @ExpectedDateTime,
			V_OPID = @OperatorId,
			V_EMAIL = @Email,
			V_TELNO = @Telephone
		WHERE V_SYSNO = @SysNo

		IF @Note = ''
		BEGIN
			IF EXISTS(SELECT 0 FROM VIS_NOTES WHERE VN_SYSNO = @SysNo)
			BEGIN
				DELETE FROM VIS_NOTES
				WHERE VN_SYSNO = @SysNo
			END
		END
		ELSE BEGIN
			IF EXISTS(SELECT 0 FROM VIS_NOTES WHERE VN_SYSNO = @SysNo)
			BEGIN
				UPDATE VIS_NOTES
				SET VN_TEXT = @Note
				WHERE VN_SYSNO = @SysNo
			END
			ELSE BEGIN
				INSERT INTO VIS_NOTES (
					VN_SYSNO,VN_DATESTAMP,VN_OPID,VN_TEXT)
				VALUES (
					@SysNo,
					GETDATE(),
					@OperatorId,
					@Note)
			END
		END
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_AddExternalVisitorWithDetails]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_AddExternalVisitorWithDetails: usp_AddExternalVisitorWithDetails Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_AddExternalVisitorWithDetails: usp_AddExternalVisitorWithDetails Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_AddExternalVisitorWithDetails: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_AddExternalVisitorWithDetails]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_AddExternalVisitorWithDetails') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_AddExternalVisitorWithDetails: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_AddExternalVisitorWithDetails: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_AddExternalVisitorWithDetails]
							   ,@name = N'Module' 
							   ,@value = N'Core'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_AddExternalVisitorWithDetails') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_AddExternalVisitorWithDetails: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_AddExternalVisitorWithDetails: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_AddExternalVisitorWithDetails]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_AddExternalVisitorWithDetails') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_AddExternalVisitorWithDetails: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_AddExternalVisitorWithDetails: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017