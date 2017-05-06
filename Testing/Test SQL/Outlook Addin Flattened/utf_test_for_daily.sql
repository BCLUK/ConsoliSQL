SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 12/06/2014
-- Description:	Test for daily CABS Outlook bookings
-- =============================================
CREATE FUNCTION [dbo].[utf_test_for_daily]
(
	-- Add the parameters for the function here
	@StartDate varchar(20),
	@EndDate varchar(20), 
	@StartTime varchar(6), 
	@EndTime varchar(6), 
	@ReccurenceType int, 
	@Instance int, 
	@Occurence int, 
	@DayOfWeek int, 
	@DayOfMonth int, 
	@MonthOfYear int, 
	@Interval int, 
	@Room varchar(50)
)
RETURNS 

@DailyBookingDates TABLE 
(
	-- Add the column definitions for the TABLE variable here
	ID int, 
	DailyBookingDates Datetime,
	Availabilty Smallint
)

AS
BEGIN
	-- Fill the table variable with the rows for your result set
	Declare @loopcount int
	Declare @LastDate datetime
	Declare @thisdate datetime
	Declare @bookstart datetime
	Declare @bookend datetime
	-- create bookstart and book end by adding date and time together 

	Set @loopcount = 0
	Set @LastDate = @StartDate

	While (@loopcount < @occurence) begin
		Set @thisdate = dateadd(DD, (@loopcount * @interval), @lastdate)
	    set @bookstart = @StartDate + ' ' + @StartTime 
	    set @bookend = @EndDate + ' ' + @EndTime 
		Insert into @DailyBookingDates VALUES (@loopcount + 1, @thisdate,[dbo].[uf_isRoomFree](@room, @Bookstart ,@Bookend, ''))

		SET	@loopcount = @loopcount + 1
	End

	RETURN 
END