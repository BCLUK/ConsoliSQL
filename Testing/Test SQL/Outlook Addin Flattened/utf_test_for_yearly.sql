SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 23/06/2014
-- Description:	Test for yearly CABS Outlook bookings
-- =============================================

CREATE FUNCTION [dbo].[utf_test_for_yearly]
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
@YearlyBookingDates TABLE 
(
	-- Add the column definitions for the TABLE variable here
	ID int, 
	YearlyBookingDates Datetime,
	Availabilty Smallint
)
AS
BEGIN
-- Fill the table variable with the rows for your result set
DECLARE @loopcount int 
DECLARE @ThisDate datetime 
Declare @bookstart datetime
Declare @bookend datetime

set @loopcount = 0
set @ThisDate = @StartDate 

while (@loopcount < @occurence)
begin 

set @bookstart = @ThisDate + ' ' + @StartTime 
set @bookend = @ThisDate + ' ' + @EndTime 
insert into @YearlyBookingDates (ID, YearlyBookingDates,[Availabilty]) VALUES (@loopcount +1,@ThisDate,[dbo].[uf_isRoomFree](@room, @Bookstart ,@Bookend, ''))
set @thisdate = dateadd(mm,@interval,@thisdate)
set @loopcount = @loopcount + 1

end 
	Return 
END