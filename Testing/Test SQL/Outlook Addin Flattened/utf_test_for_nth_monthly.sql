SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 23/06/2014
-- Description:	Test for nth monthly CABS Outlook bookings
-- =============================================
CREATE FUNCTION [dbo].[utf_test_for_nth_monthly]
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
@NthMonthlyBookingDates TABLE 
(
	-- Add the column definitions for the TABLE variable here
	ID int, 
	NthMonthlyBookingDates Datetime,
	Availabilty Smallint
)
AS
BEGIN
-- Fill the table variable with the rows for your result set
DECLARE @ID int 
DECLARE @Thisdate datetime 	
DECLARE @Loopcount int 
DECLARE @bookstart datetime
DECLARE @bookend datetime
DECLARE @Nthday datetime 

set @Loopcount = 0 
set @Thisdate = @StartDate

while (@loopcount < @occurence)
begin

set @Nthday = [dbo].[uf_getnthdayofweekofmonth] (DATEPART(dd,@Thisdate),@occurence,datepart(mm,@Thisdate),datepart(yyyy,@Thisdate))
set @bookstart = @thisdate + ' ' + @StartTime 
set @bookend = @thisdate + ' ' + @EndTime 
insert into @NthMonthlyBookingDates (ID,NthMonthlyBookingDates,Availabilty) VALUES (@Loopcount +1,@Thisdate,[dbo].[uf_isRoomFree](@room, @Bookstart ,@Bookend, '' ))
set @Thisdate = DATEADD(mm,@interval,@Nthday) 
set @Loopcount = @Loopcount + 1 
 
end 
	Return 

END