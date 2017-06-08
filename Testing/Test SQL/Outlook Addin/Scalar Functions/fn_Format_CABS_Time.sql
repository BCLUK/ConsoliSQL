SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   FUNCTION [dbo].[fn_Format_CABS_Time] 
	(
		@dtDate 	DATETIME
	)  
RETURNS VARCHAR(5) 
/* **************************************************************************** 
	FUNCTION :	fn_Format_CABS_Time
	DESCRIPTION :	This function formats the TIME from a DATE object into
			a CABS time format.

			eg. "13:45"
			
	PARAMETERS :	Date - (eg 26/05/2004 13:45:23:993)

	RETURN :	Function returns :
				Formatted Date (eg. 13:45)
	AUTHOR :	Corey Baker
	
	MODIFICATIONS : 26/05/2004 - v1.00
			- Original.
**************************************************************************** */
AS  
BEGIN 
	-- Local Declares
	DECLARE	@intHour	INTEGER,
		@intMinute	INTEGER,
		@vcTime		VARCHAR(5)

	-- Get the Hour and Minute parts from the DATE
	SET @intHour 	= DATEPART(hh, @dtDate)
	SET @intMinute 	= DATEPART(mi, @dtDate)
	
	-- An format these to a varchar
	IF @intHour 	< 10
	BEGIN
		-- Don't forget to add a leading ZERO if we are less than 10
		SET @vcTime = '0' + CONVERT(VARCHAR(1), @intHour) + ':'
	END
	ELSE
	BEGIN
		-- Just convert
		SET @vcTime = CONVERT(VARCHAR(2), @intHour) + ':'
	END
	-- Now do the Minute
	IF @intMinute 	< 10
	BEGIN
		-- Don't forget to add a leading ZERO if we are less than 10
		SET @vcTime = @vcTime + '0' + CONVERT(VARCHAR(1), @intMinute)
	END
	ELSE
	BEGIN
		-- Just convert
		SET @vcTime = @vcTime + CONVERT(VARCHAR(2), @intMinute)
	END
 
	-- and return the converted value.
	RETURN (@vcTime)

END