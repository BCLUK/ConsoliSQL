SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 11th Sept 2015
-- Description:	create a date time from parts for SQL less than 2012
--				updated 25/11/2015 to compensate for single digit days or months being passed
-- =============================================
CREATE FUNCTION [dbo].[uf_DatetimefromParts] 
(
	-- Add the parameters for the function here
	@Yearin  Varchar(4),
	@Monthin Varchar(2),
	@Dayin Varchar(2),
	@TimeIn  Varchar(5)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result datetime

	-- Add the T-SQL statements to compute the return value here
	if len(@Yearin) =2 set @Yearin = '20'+@Yearin
	if len(@Monthin) =1 set @Monthin = '0' + @Monthin 
	if len(@Dayin) =1 set @Dayin = '0' + @Dayin 

--	SELECT @Result = @YearIn+@MonthIn+@DayIn

	-- Return the result of the function
		SET @Result = (CONVERT(DATETIME, (CONVERT(VARCHAR(11), (@YearIn+@MonthIn+@DayIn), 20)), 20))
		SET @Result = DATEADD (HOUR, Cast(Substring(@Timein,1,2) as Int), @Result)
		SET @Result = DATEADD (MINUTE, Cast(Substring(@Timein,4,2) as Int), @Result)

	RETURN @Result
END