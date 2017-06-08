IF OBJECT_ID('[usp_AddExternalVisitor]') IS NOT NULL
DROP PROC [usp_AddExternalVisitor]

/****** Object:  StoredProcedure [dbo].[usp_AddExternalVisitor]    Script Date: 02/02/2017 12:05:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================================================================
-- Author:		Mike Edwards
-- Create date: 27/10/2016
-- Description:	Adds or updates an external visitor to a booking.
-- Version:		1
-- Updates:
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
-- 
-- 24/05/2017	1.0 - Mike Edwards
--					- Original Version
-- ====================================================================================================================
CREATE PROCEDURE [dbo].[usp_AddExternalVisitor]
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
	@ErrorCode		INT OUT
AS
BEGIN
	EXEC dbo.usp_AddExternalVisitorWithDetails
		@BookingRef,
		@SysNo,
		@OperatorId,
		@Title,
		@Forename,
		@Surname,
		@Company,
		@ExpectedTime,
		@Note,
		'',				/* Email */
		'',				/* Telephone */
		@ErrorCode
END
GO

