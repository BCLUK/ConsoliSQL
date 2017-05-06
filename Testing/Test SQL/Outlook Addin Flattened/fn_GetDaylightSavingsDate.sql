SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ============================================= 
Name			: fn_GetDaylightSavingsDate
Type			: Function
Purpose			: This function finds the calender date for when 
			: Daylight Savings either starts or end, based on the 
			: law supplied as a parameter
Pre-requisites	: None
Parameters		: IN 1 - Daylight Savings law passed as a String.
				See Notes.
				IN 2 - The year for which the Law applies
			: OUT 1 - DS Start Calender Date (Time just defaults to 00:00:00)
			: OUT 2 - DS End Calender Date (Time just defaults to 00:00:00)
			: OUT 3 - Status (0 - success, 1 - failure)
			: NOTE - All output values are returned in as columns in a single table
Description		: Can be called from a query or stored procedure to find the
					calender date for when the Daylight Savings starts or ends.
Returns			: A Datetime value of the correct daylight Savings date
Notes			: Rule Definitions:
			: NOTE - A week starts from Sunday to Saturday (1 to 7)
			: Format	- <month>,<sign><week>,<day>
			: Example 1	- 10,-1,1	
						October, 1st week from the END(-) of the month, Sunday
			: Example 2	- 03,2,3
						March, 2nd week from the START of the month, Tuesday
Created			: 29/08/2006 
Author			: *****
Change History	: <date> <initials>	<Change made>
================================================ */
CREATE FUNCTION [dbo].[fn_GetDaylightSavingsDate]
(
	@chDaylightSavingStartLaw	VARCHAR(9),	-- The Daylight Saving Start Law
	@chDaylightSavingEndLaw		VARCHAR(9),	-- The Daylight Saving End Law
	@chBookingYear				CHAR(4)		-- The year of the booking
)
RETURNS @tblDSDates TABLE (ds_start_date DATETIME,
				ds_end_date DATETIME, 
				status SMALLINT)
AS
BEGIN
	-- Declare common variables here
	DECLARE @intDSLawIndex SMALLINT, @strDefaultDate VARCHAR(10)

	-- Declare the START Date variables here
	DECLARE @chDaylightSavingStartLawStrip VARCHAR(9), @chDSStartYear CHAR(4),
			@chDSStartMonth CHAR(2),@chDSStartWeekNo CHAR(2), @chDSStartDayNo CHAR(2),@chDSStartDay CHAR(2),
			@vcDSStartDate VARCHAR(10), @chDSStartMonthLastDay CHAR(2), @chDSStartMonthWeekLastDay CHAR(2),
			@chDSStartMonthWeekLastDayName VARCHAR(9), @chDSStartMonthWeekLastDayNo CHAR(2), 
			@intDSStartDayDiff SMALLINT, @chDSStartMonthFirstDay CHAR(2), @chDSStartMonthWeekFirstDay CHAR(2),
			@chDSStartMonthWeekFirstDayName VARCHAR(9), @chDSStartMonthWeekFirstDayNo CHAR(2)

	-- Declare the END Date variables here
	DECLARE @chDaylightSavingEndLawStrip VARCHAR(9), @chDSEndYear CHAR(4),
			@chDSEndMonth CHAR(2),@chDSEndWeekNo CHAR(2), @chDSEndDayNo CHAR(2),@chDSEndDay CHAR(2),
			@vcDSEndDate VARCHAR(10), @chDSEndMonthLastDay CHAR(2), @chDSEndMonthWeekLastDay CHAR(2),
			@chDSEndMonthWeekLastDayName VARCHAR(9), @chDSEndMonthWeekLastDayNo CHAR(2), 
			@intDSEndDayDiff SMALLINT, @chDSEndMonthFirstDay CHAR(2), @chDSEndMonthWeekFirstDay CHAR(2),
			@chDSEndMonthWeekFirstDayName VARCHAR(9), @chDSEndMonthWeekFirstDayNo CHAR(2)

	SET @strDefaultDate = '01/01/1900'

	-- ERROR CHECK: Check to ensure that there are parameters passed in
	IF ((ISNULL(@chDaylightSavingStartLaw,'') = '') 
			OR (ISNULL(@chDaylightSavingEndLaw,'') = '') 
				OR (ISNULL(@chBookingYear,'') = ''))
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME),CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- ######## Extract parameter values from the START law ########

	-- Extract the DS start month from the start daylight saving law
	SET @intDSLawIndex = PATINDEX('%,%',@chDaylightSavingStartLaw) -- e.g 3
	-- ERROR CHECK: Check to ensure that the law is delimited by commas	
	IF (@intDSLawIndex = 0)
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	SET @chDSStartMonth = LEFT(@chDaylightSavingStartLaw,@intDSLawIndex-1) -- e.g 10
	-- ERROR CHECK: Check to ensure that the month is a valid month
	IF ((CAST(@chDSStartMonth as SMALLINT) < 1) 
			OR (CAST(@chDSStartMonth as SMALLINT) > 12)) 
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Since the DS start month has been extracted, strip it out of the DS law string to extract the other values in it
	SET @chDaylightSavingStartLawStrip = SUBSTRING(@chDaylightSavingStartLaw, PATINDEX('%,%',@chDaylightSavingStartLaw)+1, LEN(@chDaylightSavingStartLaw)) -- e.g -1,1
	SET @intDSLawIndex = PATINDEX('%,%', @chDaylightSavingStartLawStrip) -- e.g 3
	-- ERROR CHECK: Check to ensure that the law is delimited by commas	
	IF (@intDSLawIndex = 0)
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Extract the start week no from the law
	SET @chDSStartWeekNo = LEFT(@chDaylightSavingStartLawStrip, @intDSLawIndex - 1) -- e.g -1
	-- ERROR CHECK: Check to ensure that the week is a valid week
	IF ((CAST(@chDSStartWeekNo as SMALLINT) < -4) 
			OR (CAST(@chDSStartWeekNo as SMALLINT) > 4)) 
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Extract the start day no from the law
	SET @chDSStartDayNo = SUBSTRING(@chDaylightSavingStartLawStrip, PATINDEX('%,%', @chDaylightSavingStartLawStrip)+1, LEN(@chDaylightSavingStartLawStrip)) -- e.g 1
	-- ERROR CHECK: Check to ensure that the start day no is valid
	IF ((CAST(@chDSStartDayNo as SMALLINT) < 1) 
			OR (CAST(@chDSStartDayNo as SMALLINT) > 7))
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- ######## Extract parameter values from the END law ########

	-- Extract the DS end month from the start daylight saving law
	SET @intDSLawIndex = PATINDEX('%,%', @chDaylightSavingEndLaw) -- e.g 3
	-- ERROR CHECK: Check to ensure that the law is delimited by commas	
	IF (@intDSLawIndex = 0)
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	SET @chDSEndMonth = LEFT(@chDaylightSavingEndLaw, @intDSLawIndex-1) -- e.g 10
	-- ERROR CHECK: Check to ensure that the month is a valid month
	IF ((CAST(@chDSEndMonth as SMALLINT) < 1) 
			OR (CAST(@chDSEndMonth as SMALLINT) > 12)) 
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Since the DS end month has been extracted, strip it out of the DS law string to extract the other values in it
	SET @chDaylightSavingEndLawStrip = SUBSTRING(@chDaylightSavingEndLaw, PATINDEX('%,%',@chDaylightSavingEndLaw)+1, LEN(@chDaylightSavingEndLaw)) -- e.g -1,1
	SET @intDSLawIndex = PATINDEX('%,%', @chDaylightSavingEndLawStrip) -- e.g 3
	-- ERROR CHECK: Check to ensure that the law is delimited by commas	
	IF (@intDSLawIndex = 0)
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Extract the end week no from the law
	SET @chDSEndWeekNo = LEFT(@chDaylightSavingEndLawStrip, @intDSLawIndex - 1) -- e.g -1
	-- ERROR CHECK: Check to ensure that the week is a valid week
	IF ((CAST(@chDSEndWeekNo as SMALLINT) < -4) 
			OR (CAST(@chDSEndWeekNo as SMALLINT) > 4))
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Extract the end day no from the law
	SET @chDSEndDayNo = SUBSTRING(@chDaylightSavingEndLawStrip, PATINDEX('%,%',@chDaylightSavingEndLawStrip)+1, LEN(@chDaylightSavingEndLawStrip)) -- e.g 1
	-- ERROR CHECK: Check to ensure that the end day no is valid
	IF ((CAST(@chDSEndDayNo as SMALLINT) < 1) 
			OR (CAST(@chDSEndDayNo as SMALLINT) > 7)) 
	BEGIN
		-- Insert the error values into the table
		INSERT INTO @tblDSDates
		SELECT CAST(@strDefaultDate as DATETIME), CAST(@strDefaultDate as DATETIME), 1
		-- Return the table of date values
		RETURN 
	END

	-- Check if the DS start date is greater than the DS end date, to determine if
	-- the daylight saving times crosses over two subsequent years
	IF (CAST(@chDSStartMonth as SMALLINT) > CAST(@chDSEndMonth as SMALLINT)) 
	BEGIN
		-- if it does, then make the end year, one year ahead
		SET @chDSStartYear = @chBookingYear
		SET @chDSEndYear = CAST(CAST(@chBookingYear as SMALLINT) + 1 as CHAR(4)) 
	END
	ELSE
	BEGIN
		-- else remain the same
		SET @chDSStartYear = @chBookingYear
		SET @chDSEndYear = @chBookingYear
	END

	-- ######## Start calculating the Daylight Saving Start date ########

	-- if the week no is negative, we should start the week count from the end of the month, 
	-- else from the begining of the month
	IF (CAST(@chDSStartWeekNo as SMALLINT) < 0)
	BEGIN
		-- remove the negetive sign from the week number
		SET @chDSStartWeekNo = SUBSTRING(@chDSStartWeekNo, 2, LEN(@chDSStartWeekNo))

		-- Get the last day of the month
		SET @chDSStartMonthLastDay = DAY(DATEADD(d, -DAY(DATEADD(m, 1, CAST(@chDSStartYear + '-' + @chDSStartMonth + '-01' as datetime))), DATEADD(m, 1, CAST(@chDSStartYear + '-' + @chDSStartMonth + '-01' as datetime))))
		-- Find the last day of the week, based on the week number supplied in the law
		SET @chDSStartMonthWeekLastDay = CAST(@chDSStartMonthLastDay as SMALLINT) - ((CAST(@chDSStartWeekNo as SMALLINT) - 1) * 7)
		SET @chDSStartMonthWeekLastDayName = DATENAME(weekday,CAST(@chDSStartYear + '-' + @chDSStartMonth + '-' + @chDSStartMonthWeekLastDay as DATETIME))

		-- Find the day no of the week 
		IF (@chDSStartMonthWeekLastDayName = 'Sunday') 
			SET @chDSStartMonthWeekLastDayNo = 1
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Monday') 
			SET @chDSStartMonthWeekLastDayNo = 2
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Tuesday') 
			SET @chDSStartMonthWeekLastDayNo = 3
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Wednesday') 
			SET @chDSStartMonthWeekLastDayNo = 4
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Thursday') 
			SET @chDSStartMonthWeekLastDayNo = 5
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Friday') 
			SET @chDSStartMonthWeekLastDayNo = 6
		ELSE IF (@chDSStartMonthWeekLastDayName = 'Saturday') 
			SET @chDSStartMonthWeekLastDayNo = 7

		-- Check if the day asked for falls before the last day of the month. Applies only to the last week.
		IF (@chDSStartWeekNo = 1 AND (@chDSStartDayNo > @chDSStartMonthWeekLastDayNo)) 
			SET @chDSStartMonthWeekLastDay = @chDSStartMonthWeekLastDay - 7
			
		-- Calculate how many days of difference do we have from the end of the month to the Daylight 
		-- Savings date
		SET @intDSStartDayDiff = CAST(@chDSStartMonthWeekLastDayNo as SMALLINT) - CAST(@chDSStartDayNo as SMALLINT)
		SET @chDSStartDay = CAST(CAST(@chDSStartMonthWeekLastDay as SMALLINT) - @intDSStartDayDiff as CHAR(2))
		SET @vcDSStartDate = @chDSStartYear + '-' + @chDSStartMonth + '-' + @chDSStartDay
	END
	ELSE
	BEGIN
		-- Get the first day of the month
		SET @chDSStartMonthFirstDay = '1'
		-- Find the first day of the week, based on the week number supplied in the law
		SET @chDSStartMonthWeekFirstDay = CAST(@chDSStartMonthFirstDay as SMALLINT) + ((CAST(@chDSStartWeekNo as SMALLINT) - 1) * 7)
		SET @chDSStartMonthWeekFirstDayName = DATENAME(weekday, CAST(@chDSStartYear + '-' + @chDSStartMonth + '-' + @chDSStartMonthWeekFirstDay as DATETIME))

		-- Find the day no of the week 
		IF (@chDSStartMonthWeekFirstDayName = 'Sunday') 
			SET @chDSStartMonthWeekFirstDayNo = 1
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Monday') 
			SET @chDSStartMonthWeekFirstDayNo = 2
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Tuesday') 
			SET @chDSStartMonthWeekFirstDayNo = 3
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Wednesday') 
			SET @chDSStartMonthWeekFirstDayNo = 4
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Thursday') 
			SET @chDSStartMonthWeekFirstDayNo = 5
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Friday') 
			SET @chDSStartMonthWeekFirstDayNo = 6
		ELSE IF (@chDSStartMonthWeekFirstDayName = 'Saturday') 
			SET @chDSStartMonthWeekFirstDayNo = 7

		-- Check if the day asked for falls before the first day of the month. Applies only to the first week.
		IF (@chDSStartDayNo < @chDSStartMonthWeekFirstDayNo)
			SET @chDSStartMonthWeekFirstDay = CAST(@chDSStartMonthWeekFirstDay as SMALLINT) + 7

		-- Calculate how many days differecne do we have from the end of the month to the Daylight 
		-- Savings date		
		SET @intDSStartDayDiff = CAST(@chDSStartDayNo as SMALLINT) - CAST(@chDSStartMonthWeekFirstDayNo as SMALLINT)
		SET @chDSStartDay = CAST(CAST(@chDSStartMonthWeekFirstDay as SMALLINT) + @intDSStartDayDiff as CHAR(2))
		SET @vcDSStartDate = @chDSStartYear + '-' + @chDSStartMonth + '-' + @chDSStartDay
	END

	-- ######## Start calculating the Daylight Saving End date ########

	-- if the week no is negative, we should start the week count from the end of the month, 
	-- else from the begining of the month
	IF (CAST(@chDSEndWeekNo as SMALLINT) < 0) 
	BEGIN
		-- remove the negetive sign from the week number
		SET @chDSEndWeekNo = SUBSTRING(@chDSEndWeekNo, 2, LEN(@chDSEndWeekNo))

		-- Get the last day of the month
		SET @chDSEndMonthLastDay = DAY(DATEADD(d, -DAY(DATEADD(m, 1, CAST(@chDSEndYear + '-' + @chDSEndMonth + '-01' as datetime))), DATEADD(m, 1, CAST(@chDSEndYear + '-' + @chDSEndMonth + '-01' as datetime))))
		SET @chDSEndMonthWeekLastDay = CAST(@chDSEndMonthLastDay as SMALLINT) - ((CAST(@chDSEndWeekNo as SMALLINT) - 1) * 7)
		SET @chDSEndMonthWeekLastDayName = DATENAME(weekday, CAST(@chDSEndYear + '-' + @chDSEndMonth + '-' + @chDSEndMonthWeekLastDay as DATETIME))

		-- Find the day no of the week 
		IF (@chDSEndMonthWeekLastDayName = 'Sunday') 
			SET @chDSEndMonthWeekLastDayNo = 1
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Monday') 
			SET @chDSEndMonthWeekLastDayNo = 2
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Tuesday') 
			SET @chDSEndMonthWeekLastDayNo = 3
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Wednesday') 
			SET @chDSEndMonthWeekLastDayNo = 4
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Thursday') 
			SET @chDSEndMonthWeekLastDayNo = 5
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Friday') 
			SET @chDSEndMonthWeekLastDayNo = 6
		ELSE IF (@chDSEndMonthWeekLastDayName = 'Saturday') 
			SET @chDSEndMonthWeekLastDayNo = 7

		-- Check if the day asked for falls before the last day of the month. Applies only to the last week.
		IF (@chDSEndWeekNo = 1 AND (@chDSEndDayNo > @chDSEndMonthWeekLastDayNo)) 
			SET @chDSEndMonthWeekLastDay = @chDSEndMonthWeekLastDay - 7
			
		-- Calculate how many days of difference do we have from the end of the month to the Daylight 
		-- Savings date
		SET @intDSEndDayDiff = CAST(@chDSEndMonthWeekLastDayNo as SMALLINT) - CAST(@chDSEndDayNo as SMALLINT)
		SET @chDSEndDay = CAST(CAST(@chDSEndMonthWeekLastDay as SMALLINT) - @intDSEndDayDiff as CHAR(2))
		SET @vcDSEndDate = @chDSEndYear + '-' + @chDSEndMonth + '-' + @chDSEndDay
	END
	ELSE
	BEGIN
		-- Get the first day of the month
		SET @chDSEndMonthFirstDay = '1'
		-- Find the first day of the week, based on the week number supplied in the law
		SET @chDSEndMonthWeekFirstDay = CAST(@chDSEndMonthFirstDay as SMALLINT) + ((CAST(@chDSEndWeekNo as SMALLINT) - 1) * 7)
		SET @chDSEndMonthWeekFirstDayName = DATENAME(weekday, CAST(@chDSEndYear + '-' + @chDSEndMonth + '-' + @chDSEndMonthWeekFirstDay as DATETIME))

		-- Find the day no of the week 
		IF (@chDSEndMonthWeekFirstDayName = 'Sunday') 
			SET @chDSEndMonthWeekFirstDayNo = 1
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Monday') 
			SET @chDSEndMonthWeekFirstDayNo = 2
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Tuesday') 
			SET @chDSEndMonthWeekFirstDayNo = 3
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Wednesday') 
			SET @chDSEndMonthWeekFirstDayNo = 4
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Thursday') 
			SET @chDSEndMonthWeekFirstDayNo = 5
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Friday') 
			SET @chDSEndMonthWeekFirstDayNo = 6
		ELSE IF (@chDSEndMonthWeekFirstDayName = 'Saturday') 
			SET @chDSEndMonthWeekFirstDayNo = 7

		-- Check if the day asked for falls before the first day of the month. Applies only to the first week.
		IF (@chDSEndDayNo < @chDSEndMonthWeekFirstDayNo)
			SET @chDSEndMonthWeekFirstDay = CAST(@chDSEndMonthWeekFirstDay as SMALLINT) + 7

		-- Calculate how many days differecne do we have from the end of the month to the Daylight 
		-- Savings date		
		SET @intDSEndDayDiff = CAST(@chDSEndDayNo as SMALLINT) - CAST(@chDSEndMonthWeekFirstDayNo as SMALLINT)
		SET @chDSEndDay = CAST(CAST(@chDSEndMonthWeekFirstDay as SMALLINT) + @intDSEndDayDiff as CHAR(2))
		SET @vcDSEndDate = @chDSEndYear + '-' + @chDSEndMonth + '-' + @chDSEndDay
	END

	-- Insert the date values into the table
	INSERT INTO @tblDSDates
	SELECT CAST(@vcDSStartDate as DATETIME), CAST(@vcDSEndDate as DATETIME), 0
		
	-- Return the table of date values
	RETURN 
END