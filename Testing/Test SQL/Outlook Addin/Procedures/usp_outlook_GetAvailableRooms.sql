SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_outlook_GetAvailableRooms]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_outlook_GetAvailableRooms]	
	PRINT 'usp_outlook_GetAvailableRooms: Dropped Procedure usp_outlook_GetAvailableRooms'
END
ELSE
BEGIN	
	PRINT 'usp_outlook_GetAvailableRooms: usp_outlook_GetAvailableRooms -  Does Not Already Exist !'
END

PRINT 'usp_outlook_GetAvailableRooms: Creating Procedure usp_outlook_GetAvailableRooms'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	26/05/2017
-- Description:	Gets available rooms for location, room use and covers.
-- Product:		CABS
-- Module:		Outlook Addin
-- Parameters:	@Location VARCHAR(6), @RoomUse VARCHAR(6), @Covers INT, @Date DATE, @StartTime TIME, @EndTime TIME
-- Returns:		TABLE
-- Switches:	N/A
-- Test:		EXEC usp_outlook_GetAvailableRooms @Location, @RoomUse, @Covers, @Date, @StartTime, @EndTime
-- Called By:	N/A
-- Calls:		N/A
-- ====================================================================================================================
-- Version:		1.0
-- Date:		26/05/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 26/05/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_outlook_GetAvailableRooms
	@Dates tvp_outlook_timeslot READONLY,
	@Location VARCHAR(6),
	@RoomUse VARCHAR(6),
	@UseRoomGroups BIT,
	@RoomGroups tvp_outlook_roomGroup READONLY,
	@Covers INT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Rooms TABLE
	(
		RM_ABBR varchar(6),
		RM_NAME varchar(50),
		US_RM_USE varchar(6),
		US_MIN int,
		US_MAX int,
		US_SETUP varchar(5),
		US_BDOWN varchar(5)
	)

	;WITH RoomsCte AS
	(
		SELECT TOP 2147483647 RM_ABBR,
			RM_NAME,
			US_RM_USE,
			US_MIN,
			US_MAX,
			US_SETUP,
			US_BDOWN,
			ROW_NUMBER() OVER (PARTITION BY RM_ABBR ORDER BY RM_ABBR) AS ROW_ID
		FROM ROOMS
		INNER JOIN RM_USE
		ON US_RM_CODE = RM_ABBR
		LEFT JOIN RMGROUPS
		ON RG_RMABBR = RM_ABBR
		LEFT JOIN @RoomGroups
		ON [@RoomGroups].RG_GRPCODE = RMGROUPS.RG_GRPCODE
		WHERE RM_LOC = @Location
			AND US_RM_USE = @RoomUse
			AND @Covers BETWEEN US_MIN AND US_MAX
			AND CASE @UseRoomGroups
				WHEN 1
				THEN (	CASE
						WHEN [@RoomGroups].RG_GRPCODE = RMGROUPS.RG_GRPCODE
						THEN 1
						ELSE 0
						END)
				ELSE 1
				END = 1
		ORDER BY RM_NAME
	)
	INSERT @Rooms
	SELECT RM_ABBR, RM_NAME, US_RM_USE, US_MIN, US_MAX, US_SETUP, US_BDOWN
	FROM RoomsCte
	WHERE ROW_ID = 1
	
	DECLARE @Output TABLE
	(
		RM_ABBR VARCHAR(7),
		RM_NAME VARCHAR(50),
		US_RM_USE VARCHAR(6),
		US_MIN INT,
		US_MAX INT,
		START_DATETIME DATETIME,
		END_DATETIME DATETIME,
		AVAILABLE BIT
	)

	DECLARE @RoomCursor CURSOR,
		@RM_ABBR VARCHAR(7),
		@RM_NAME VARCHAR(50),
		@US_RM_USE VARCHAR(6),
		@US_MIN INT,
		@US_MAX INT,
		@US_SETUP VARCHAR(5),
		@US_BDOWN VARCHAR(5)

	SET @RoomCursor = CURSOR FAST_FORWARD FOR	SELECT RM_ABBR, RM_NAME, US_RM_USE, US_MIN, US_MAX, US_SETUP, US_BDOWN
												FROM @Rooms

	OPEN @RoomCursor

	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM @RoomCursor INTO @RM_ABBR, @RM_NAME, @US_RM_USE, @US_MIN, @US_MAX, @US_SETUP, @US_BDOWN
		IF @@FETCH_STATUS <> 0 BREAK

		DECLARE @DateCursor CURSOR,
			@StartDateTime DATETIME,
			@EndDateTime DATETIME

		SET @DateCursor = CURSOR FAST_FORWARD FOR	SELECT START_DATETIME, END_DATETIME
													FROM @Dates

		OPEN @DateCursor

		WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM @DateCursor INTO @StartDateTime, @EndDateTime
			IF @@FETCH_STATUS <> 0 BREAK

			DECLARE @AvailResult INT

			EXEC @AvailResult = cabs_check_av '', @StartDateTime, @EndDateTime, @RM_ABBR, @US_SETUP, @US_BDOWN

			INSERT @Output
			VALUES
			(
				@RM_ABBR,
				@RM_NAME,
				@US_RM_USE,
				@US_MIN,
				@US_MAX,
				@StartDateTime,
				@EndDateTime,
				CASE @AvailResult WHEN 1 THEN 1 ELSE 0 END
			)
		END
	END

	SELECT *
	FROM @Output
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_outlook_GetAvailableRooms]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_outlook_GetAvailableRooms: usp_outlook_GetAvailableRooms Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_GetAvailableRooms: usp_outlook_GetAvailableRooms Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_outlook_GetAvailableRooms: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_GetAvailableRooms]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_GetAvailableRooms') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_outlook_GetAvailableRooms: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_GetAvailableRooms: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_GetAvailableRooms]
							   ,@name = N'Module' 
							   ,@value = N'Outlook Addin'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_GetAvailableRooms') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_outlook_GetAvailableRooms: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_GetAvailableRooms: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_GetAvailableRooms]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_GetAvailableRooms') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_outlook_GetAvailableRooms: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_GetAvailableRooms: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017