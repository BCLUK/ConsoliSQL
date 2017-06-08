SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_outlook_CheckRoomAvailability]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_outlook_CheckRoomAvailability]	
	PRINT 'usp_outlook_CheckRoomAvailability: Dropped Procedure usp_outlook_CheckRoomAvailability'
END
ELSE
BEGIN	
	PRINT 'usp_outlook_CheckRoomAvailability: usp_outlook_CheckRoomAvailability -  Does Not Already Exist !'
END

PRINT 'usp_outlook_CheckRoomAvailability: Creating Procedure usp_outlook_CheckRoomAvailability'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	30/05/2017
-- Description:	Checks if a room is available between a specific timeframe.
-- Product:		CABS
-- Module:		Outlook Addin
-- Parameters:	@Room VARCHAR(6), @Date DATE, @StartTime TIME, @EndTime TIME
-- Returns:		BIT
-- Switches:	N/A
-- Test:		Insert How to Test
-- Called By:	N/A
-- Calls:		N/A
-- ====================================================================================================================
-- Version:		1.0
-- Date:		30/05/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 30/05/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_outlook_CheckRoomAvailability
	@Room VARCHAR(6),
	@StartDateTime DATETIME,
	@EndDateTime DATETIME,
	@IsAvailable BIT OUT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Setup VARCHAR(5),
		@BDown VARCHAR(5),
		@AvailResult INT

	SELECT @Setup = US_SETUP,
		@BDown = US_BDOWN
	FROM ROOMS
	LEFT JOIN RM_USE
	ON US_RM_CODE = RM_ABBR
	WHERE RM_ABBR = @Room
	
	EXEC @AvailResult = cabs_check_av '', @StartDateTime, @EndDateTime, @Room, @Setup, @BDown

	SET @IsAvailable = CASE @AvailResult WHEN 1 THEN 1 ELSE 0 END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_outlook_CheckRoomAvailability]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_outlook_CheckRoomAvailability: usp_outlook_CheckRoomAvailability Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_CheckRoomAvailability: usp_outlook_CheckRoomAvailability Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_outlook_CheckRoomAvailability: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_CheckRoomAvailability]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_CheckRoomAvailability') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_outlook_CheckRoomAvailability: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_CheckRoomAvailability: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_CheckRoomAvailability]
							   ,@name = N'Module' 
							   ,@value = N'Outlook Addin'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_CheckRoomAvailability') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_outlook_CheckRoomAvailability: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_CheckRoomAvailability: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_outlook_CheckRoomAvailability]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_outlook_CheckRoomAvailability') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_outlook_CheckRoomAvailability: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_outlook_CheckRoomAvailability: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017