SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ============================================= 
Name			: fn_GetLocalDateTime
Type			: Function
Purpose			: This function is meant to be used to convert
				: a Date Time value into its' Local equivalent based
				: on its location.
Pre-requisites	: Function 'fn_GetDaylightSavingsDate'
Parameters		: IN - GMT DateTime
				: OUT - Local DateTime
Description		: Can be called from a query to convert a GMT Datetime
				: value into a Local Datetime value
Returns			: A Local Datetime value
Notes			: Definitions:
				: Week -	The week begining from the start of the month, or
				:		the week finishing off on the last day of the month
Created			: 22/02/2007 
Author			: Martin Baud
Change History	: <date>		<initials>	<Change made>
				:  25-09-2015	:PLG		:from fn_GetLocalDateTime
				:							:checks before trying to do things
================================================ */
CREATE FUNCTION [dbo].[uf_GetLocalDateTime]
(
	@vcLocation	VARCHAR(6),	-- The location 
	@dtGMTDateTime	DATETIME	-- The GMT DateTime
)
RETURNS DATETIME
AS
BEGIN
	-- Declare the return variable here
	DECLARE
		@intSiteID INT,
		@dtLocalDateTime DATETIME

	DECLARE
		@chBookingYear CHAR(4),
		@vcDSStartLaw VARCHAR(9), @vcDSEndLaw VARCHAR(9),
		@dtDSStartDate DATETIME, @dtDSEndDate DATETIME,
		@dtReturnDate DATETIME,
		@dtDSStartDatePrev DATETIME, @dtDSEndDatePrev DATETIME,
		@chBookingYearPrev CHAR(4),
		@Timezones Varchar(10)

	DECLARE	@sintStatus SMALLINT, @sintStatusPrev SMALLINT -- (0 - success, 1 - failure)
	set @dtReturnDate = @dtGMTDateTime	
	--initial checks PLG
	-- is timezones enabled?
	set @Timezones = ( Select dbo.uf_xCABS_CONFIG_ReadString ('','System', 'UseTimeZones'))
	if @TimeZones = '1' begin -- if no timezones forget it!    1 - Timezonesenables
		if exists (Select ST_LOC from SYS_ABBR where ST_CODE = @vcLocation and ST_TYPE = 'LOC') begin  -- 2.  the location exists
			-- now check for the site-loc
			if exists (Select SL_ID from SITE_LOCS where SL_LOC = @vcLocation) begin   -- 3. the siteloc exists
			-- Selects the site id, based on the passed in location
				SELECT	@intSiteID = sl.sl_id 
				FROM	site_locs sl 
				WHERE	sl.sl_loc = @vcLocation

				-- Extract the law components for the Daylight Savings Start time
				SET @chBookingYear = DATEPART(year, @dtGMTDateTime) -- Year of the booking date

				-- Get laws for Daylight savings Start and End time
				SELECT	@vcDSStartLaw = site_dl_startlaw, 
					@vcDSEndLaw = site_dl_endlaw 
				FROM	sites 
				WHERE	site_id = @intSiteID -- e.g 10,-1,1

				-- The booking date is compared against two sets of Daylight Savings (DS) date ranges.
				-- The first range is for the booking year, and the second is for the previous year 
				-- of the booking date (suffixed with a 'Prev'). This is designed to handle a booking 
				-- date, in a region where the DS range falls over two subsequent years. For example a 
				-- booking date in january might not fall within the DS range for it's year, BUT might 
				-- fall within the DS range of the previous year and hence needs to be checked for that.
				SET @sintStatus = 0
				SET @sintStatusPrev = 0
				SET @dtDSStartDate = CAST('01/01/1900' as DATETIME)
				SET @dtDSEndDate = CAST('01/01/1900' as DATETIME)
				SET @dtDSStartDatePrev = CAST('01/01/1900' as DATETIME)
				SET @dtDSEndDatePrev = CAST('01/01/1900' as DATETIME)

				IF ((ISNULL(@vcDSStartLaw,'') <> '') OR (ISNULL(@vcDSEndLaw,'') <> '')) BEGIN  -- 4. Non empty DL Law
					SELECT	@dtDSStartDate = ds_start_date, @dtDSEndDate = ds_end_date, @sintStatus = [status] 
					FROM dbo.fn_GetDaylightSavingsDate (@vcDSStartLaw, @vcDSEndLaw, @chBookingYear) 

					SET @chBookingYearPrev = CAST(CAST(@chBookingYear as SMALLINT) - 1 as CHAR(4))

					SELECT	@dtDSStartDatePrev = ds_start_date, @dtDSEndDatePrev = ds_end_date, @sintStatusPrev = [status]
					FROM dbo.fn_GetDaylightSavingsDate (@vcDSStartLaw, @vcDSEndLaw, @chBookingYearPrev) 
				END   -- 4. non empty DL Law

				-- If we have daylight saving laws (i.e. status is 0 for success)
				IF ((@sintStatus = 0) AND (@sintStatusPrev = 0)) BEGIN   --4a 
					-- Adds the GMT bias, in minutes, for the site selected from the above SQL, and allows for 
					-- daylight saving. Addition is in minutes to allow for adding fractional hours to the datetime
					-- E.g. For Adelaide, where the GMT time has a bias of 9.5 hours, adding that to the datetime 
					-- ignores the fractional part of the value. To work around this, the hours is converted to 
					-- minutes by multiplying by 60 and then adding those minutes to the datetime.
					SELECT	@dtLocalDateTime = CASE 
						WHEN ((ISNULL(s.site_dl_startlaw,'') = '')
								AND (ISNULL(s.site_dl_endlaw,'') = '')) THEN
							-- STD time, use site bias as is
							DATEADD(MINUTE, ((CONVERT(FLOAT, s.site_bias)) * 60), @dtGMTDateTime)

						WHEN (((@dtGMTDateTime >= @dtDSStartDate) 
								AND (@dtGMTDateTime < @dtDSEndDate)) 
								OR ((@dtGMTDateTime >= @dtDSStartDatePrev) 
								AND (@dtGMTDateTime < @dtDSEndDatePrev))) THEN
							-- Daylight saving period, add 1 hour to the site bias
							DATEADD(MINUTE, ((CONVERT(FLOAT, s.site_bias + 1)) * 60), @dtGMTDateTime)
				
						ELSE
							-- STD time, use site bias as is
							DATEADD(MINUTE, ((CONVERT(FLOAT, s.site_bias)) * 60), @dtGMTDateTime)
						END
					FROM	sites s 
					WHERE	s.site_id = @intSiteID

					-- Set the result of the function
					SET @dtReturnDate = @dtLocalDateTime
				END  -- 4a.
				ELSE BEGIN  --4b
					-- ERROR Result
					-- SET @dtReturnDate = CAST('01/01/1900' as DATETIME)
					-- PLG Changed to return original date
					Set @dtReturnDate = @dtGMTDateTime
				END  -- 4b
			END -- 3
		END --2
	END -- 1
	-- Return the result
	RETURN @dtReturnDate
END