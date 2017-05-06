SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 23/06/2014
-- Description:	Test for weekly CABS Outlook bookings
-- =============================================
CREATE FUNCTION [dbo].[utf_test_for_weekly]
(
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
@WeeklyBookingDates TABLE 
(
	-- Add the column definitions for the TABLE variable here
	ID int, 
	WeeklyBookingDates Datetime,
	Availabilty Smallint
)
AS
BEGIN
-- Fill the table variable with the rows for your result set
	Declare @loopcount int
	Declare @LastDate datetime
	Declare @wcDate datetime
	Declare @bookstart datetime
	Declare @bookend datetime
	Declare @Pattern int 
	Declare @bookingdate datetime

	Declare @bSun bit = 0
	Declare @bMon bit = 0
	Declare @bTue bit = 0
	Declare @bWed bit = 0
	Declare @bThu bit = 0
	Declare @bFri bit = 0
	Declare @bSat bit = 0

	Declare @ID int 

	-- create bookstart and book end by adding date and time together 
	

	Set @loopcount = 0
	Set @LastDate = @StartDate

	set @Pattern = @DayOfWeek 

	if @DayOfWeek > 63 begin
		set @bSat = 1 
		set @Pattern = @Pattern - 64
	end
	if @DayOfWeek > 31 and @DayOfWeek < 63 begin
		set @bFri = 1 
		set @Pattern = @Pattern - 32
	end
	if @DayOfWeek > 15 and @DayOfWeek < 31 begin
		set @bThu = 1 
		set @Pattern = @Pattern - 16
	end
	if @DayOfWeek > 7 and @DayOfWeek < 15 begin
		set @bWed = 1 
		set @Pattern = @Pattern - 8
	end
	if @DayOfWeek > 3 and @DayOfWeek < 7 begin
		set @bTue = 1 
		set @Pattern = @Pattern - 4
	end
	if @DayOfWeek > 1  and @DayOfWeek < 3 begin
		set @bMon = 1 
		set @Pattern = @Pattern - 2
	end
	if @DayOfWeek > 0 and @DayOfWeek < 1 begin
		set @bSun = 1 
		set @Pattern = @Pattern - 1
	end
	
	Set @wcDate = dbo.uf_getFirstDayOfWeek(@StartDate) 
	Set @ID = 1
	
	DECLARE @StartDate1 DATE
	DECLARE @EndDate1 DATE
	DECLARE @OkToInsert INT
	
	Set @StartDate1 = CONVERT(DATE, @StartDate, 103)
	Set @EndDate1 = CONVERT(DATE, @EndDate, 103) 
	SET @OkToInsert = 0
	SET @LASTDATE = @StartDate1
	
	While @LASTDATE <= @EndDate1
	BEGIN
		
	SET @OkToInsert = 0

	IF (SELECT [dbo].[fnCheckDate] (@LASTDATE, @DayOfWeek)) = 1
	BEGIN							
		set @bookstart = @LASTDATE + ' ' + @StartTime 
	    set @bookend = @LASTDATE + ' ' + @EndTime 			
		Insert into @WeeklyBookingDates VALUES (@ID, @LASTDATE,[dbo].[uf_isRoomFree](@room, @Bookstart ,@Bookend, ''))
		set @ID = @ID + 1 	
	END
	
	SET @LASTDATE = DATEADD(day, 1, @LASTDATE)
	END
	
	RETURN
END