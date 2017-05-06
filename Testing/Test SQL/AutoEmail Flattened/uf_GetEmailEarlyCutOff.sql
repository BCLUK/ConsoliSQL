-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_GetEmailEarlyCutOff'
SET @Func_Name = 'uf_GetEmailEarlyCutOff'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_GetEmailEarlyCutOff]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[uf_GetEmailEarlyCutOff]
	PRINT @FileName + ': Dropped Function ' + @Func_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @Func_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Function ' + @Func_Name
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 27th Jan 2015
-- Description:	Calculates the date and time an email should be sent based on the Email Type and the Function Ref
-- =============================================
-- Version: 6
-- Date: 09/09/2015
-- =============================================
-- Changes: 20/02/2015: PLG: Added Day handling
-- Changes: 20/02/2015: MCB: Added Weekend handling
-- Changes: 24/02/2015: MCB: Changed L handling
-- Changes: 24/07/2015: MCB: Changed DATETIMEFROMPARTS handling for SQL 2008 compatibility
-- Changes: 08/09/2015: MCB: Amended @SetMin value to look for (4, 2) instead of (3, 2)
--							 ERROR: Conversion when converting value :0 to Int 	
-- Changes: 09/09/2015: MCB: Added a check for @SetDay so if it's 0 do not remove any days from SendDate 
--							 ERROR (potential): Adding a value to a 'datetime' column caused an overflow.
-- Changes: 09/09/2015: MCB: changed incorrect logic for S & T checks 
-- =============================================
CREATE FUNCTION [dbo].[uf_GetEmailEarlyCutOff] 
(
	-- Add the parameters for the function here
	@EmailType Varchar(7),
	@FRef Varchar(7)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result datetime
	DECLARE @TimeType varchar(5) -- this is whether it should be B4 event time or after change time
	Declare @Mins int
	DECLARE @Frequency Varchar(1000)
	DECLARE @SP_TRG Varchar(1000)
	Declare @Days   int
	Declare @Hours  int
	Declare @WeekendsInc int
	
	Declare @StrLen int
	Declare @Pos    int
	Declare @SubStr    varchar(255)
	Declare @SubStrLen int
	Declare @VCString Varchar(255)
	Declare @SetDay int
	Declare @SetTime varchar(5)
	Declare @setHour int
	Declare @setMin int

	Declare @StartDate DateTime 

	set @SP_TRG = @EmailType
	-- Set the defaults
	
	SET @Frequency = 'D:0;H:0;M:0;W:0;L:B4;'
	-- THis is a template for the timing as follows:
	-- D indicates the number of days
	-- H           the number of hours
	-- M                         minutes
	-- W    if 0 means Weekends are ignored 
	--      if 1 means weekends are included
	-- S is for a set day,  0 means none any other is the day of the week
	-- T is for a set time on the set day in format 0930
	-- L is in response to the event date 
	--			B4 means calculate from event date backwards
	--			CR means calculate from the Creation Time


	Set @Mins = 0  -- i.e function date
	SET @TimeType = 'B4'
	Set @WeekendsInc = 0 -- default is only working days
	
	-- set the default as the function date so that if there is no cut off date we do not stop anything
	set @Result = '20000101'

	-- get the config settings
	
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'EarliestSend') > 0 
		BEGIN
			SET @Frequency = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'EarliestSend')
		

	-- Add the T-SQL statements to compute the return value here
	 -- Ensure there is a semi-colon at the end of the string
		If SUBSTRING( @Frequency, Len(@Frequency), 1) <> ';'
		set @Frequency = @Frequency + ';'

		set @StrLen = LEN( @Frequency )    -- how long is it
		-- Does the input string have a Weekend element
		set @Pos = PATINDEX( '%W%', @Frequency )
		If @Pos > 0
		begin
		-- Get the substring from before the W
			set @VCString = SUBSTRING(@Frequency, 1,@Pos -1) 
			set @WeekendsInc = Cast(SUBSTRING(@Frequency,@Pos+2,1) as int)
		end
		else begin -- send the whole string 
			set @VCString = @Frequency
		end
		-- now call the old function to convert this to minutes
		set @Mins = (SELECT dbo.fn_GetMinsValue(@vcString)  )

	
		-- find the L Type

		set @Pos = PATINDEX( '%L%', @Frequency )
		IF @Pos > 0 begin
			SET @TimeType = SUBSTRING( @Frequency, @Pos +2, (@StrLen-@Pos-2) )
		END	
	
		--MCB Commented Out: 24/02/15
		----set @Pos = PATINDEX( '%L%', @Frequency )
		----IF @Pos > 0 begin
		----	set @SubStr = SUBSTRING( @vcString, @Pos +2, (@StrLen-@Pos-1) ) 
		----	-- now check there's nothing else
		----	set @Pos    = PATINDEX( '%;%', @SubStr )
		----	-- set @SubStrLen = LEN( @SubStr )
		----	if @pos > 0 begin
		----		Set @TimeType = SUBSTRING(@SubStr,1,@Pos-1)
		----	end
		----	else begin
		----		Set @TimeType = @SubStr
		----	end
		----END
	
		If @TimeType = 'B4' begin
			-- do what's needed
			set @StartDate = (SELECT F_StartDAtetime from FUNC_FIL where F_REF = @FRef)
			set @Result = DATEADD(MINUTE,-@Mins,@StartDate)
			--if @WeekendsInc = 0 begin
			--	-- construct aloop to bring forward by a day until it is not a saturday or Sunday
			--	if DATEPART(WEEKDAY,@Result) = 1 begin -- i.e. Sunday
			--		set @Result = dateadd(d,-1,@result)
			--	End 
			--	if DATEPART(WEEKDAY,@Result) = 7 begin -- i.e. Saturday
			--		set @Result = dateadd(d,-1,@result)
			--	End 
			--end
		
		end
		else begin
			-- do what's needed for instant sends
			set @StartDate = (SELECT F_CREATEDATE from FUNC_FIL where F_REF = @FRef)
			set @result = DATEADD(MINUTE,@Mins,@StartDate)
		end
	
		set @pos = PATINDEX( '%S%', @Frequency )
		if @pos > 0 begin
			if @SetDay <> 0 begin
				Set @SetDay = Cast (SUBSTRING(@Frequency,@pos+2,1) as Int)
				While DATEPART(WEEKDAY,@Result) <> @setday begin -- keep taking a day earlier until we get to the right date
					set @Result = dateadd(d,-1,@result) 
				end
			end
		end
		
		set @pos = PATINDEX( '%T%', @Frequency )-- checks for set time for the cut off
		if @pos > 0 begin
			Set @SetTime = Cast (SUBSTRING(@Frequency,@pos+2,4) as varchar(5))
			Set @SetHour = Cast (Substring(@SetTime,1,2) as int)
			Set @SetMin = Cast (Substring(@SetTime,4,2) as int)

			--set @Result = DATETIMEFROMPARTS(Datepart(yyyy,@Result), Datepart(mm,@Result), DatePart(dd,@result),@sethour,@setMin,0,0)
			SET @Result = (CONVERT(DATETIME, (CONVERT(VARCHAR(11), (@Result), 20)), 20))
			SET @Result = DATEADD (HOUR, @setHour, @Result)
			SET @Result = DATEADD (MINUTE, @setMin, @Result)
		end

		if @WeekendsInc = 0 begin
			-- construct aloop to bring forward by a day until it is not a saturday or Sunday
			if DATEPART(WEEKDAY,@Result) = 1 begin -- i.e. Sunday
				set @Result = dateadd(d,-1,@result)
			End 
			if DATEPART(WEEKDAY,@Result) = 7 begin -- i.e. Saturday
				set @Result = dateadd(d,-1,@result)
			End 
		end
		
		
		
		--check to see if we have a date in the past and if so make it now
		--if DATEDIFF(minute,@result,getdate()) > 0 set @result = getdate()
		--if ((DATEDIFF(minute,@startdate,getdate())) > 0 AND (@timetype ='B4')) set @result = getdate()
		
		-- Return the result of the function
		END
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_GetEmailEarlyCutOff: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailEarlyCutOff]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailEarlyCutOff') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_GetEmailEarlyCutOff: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailEarlyCutOff: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailEarlyCutOff]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailEarlyCutOff') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_GetEmailEarlyCutOff: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailEarlyCutOff: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_GetEmailEarlyCutOff]
							   ,@name = N'Version' 
							   ,@value = N'6.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_GetEmailEarlyCutOff') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_GetEmailEarlyCutOff: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_GetEmailEarlyCutOff: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO