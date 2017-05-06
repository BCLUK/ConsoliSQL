-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_IsDateABankHoliday'
SET @Func_Name = 'uf_IsDateABankHoliday'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_IsDateABankHoliday]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    DROP FUNCTION [dbo].[uf_IsDateABankHoliday]
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
-- Create date: 6th MAy 2015
-- Description:	Decides whether a date passed is a Bank Holiday
--				currently only UK
-- Easter Algorithm
-- a = J Mod 19
--    b = J Mod 4
--    c = J Mod 7
--    d = (19 * a + 24) Mod 30
--    e = (2 * b + 4 * c + 6 * d + 5) Mod 7
--    OT = 22 + d + e
--    OM = 3
--    If OT > 31 Then
--       OT = d + e - 9
--       OM = 4
--    End If
--    If OT = 26 And OM = 4 Then
--       OT = 19
--    End If
--    If OT = 25 And OM = 4 And d = 28 And e = 6 And a > 10 Then
--       OT = 18
--    End If
--Where
--J= Number of the year
--OM= Month of the Easter Sunday
--OT= Day of the Easter Sunday in this month
-- =============================================
CREATE FUNCTION [dbo].[uf_IsDateABankHoliday] 
(
	-- Add the parameters for the function here
	@QueryDate datetime
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int
	Declare @Year int
	Declare @Month Int
	Declare @Day Int
	Declare @Weekday Int
	Declare @a int
	Declare @b int
	Declare @c int
	Declare @d int
	Declare @e int
	Declare @OM int
	declare @OT int
	Declare @OMStr VarChar(2)
	Declare @OTStr VarChar(2)
	Declare @EasterFriday datetime
	Declare @EasterMonday datetime
	Declare @EasterSunday datetime
	-- Add the T-SQL statements to compute the return value here
	Set @Year = DATEPART(yyyy,@Querydate)
	Set @Month = DATEPART(mm,@Querydate)
	Set @Day = DATEPART(dd,@Querydate)
	Set @Weekday = DATEPART(dw,@QueryDate)
	Set @Result = 0
	-- Check for Christmas
	if @Month = 12 begin
		set @result = (Select Case @Day when 25 then Case @Weekday when 1 then 0 when 7 then 0 else 1 end
										when 26 then Case @Weekday when 1 then 0 when 7 then 0 else 1 end
										when 27 then Case @Weekday when 2 then 1 when 3 then 1 else 0 end
										when 28 then Case @Weekday when 2 then 1 else 0 end
										else 0 end)
	end
	-- check for New Year
	if @Month = 1 begin
		set @result = (Select Case @Day when 1 then Case @Weekday when 1 then 0 when 7 then 0 else 1 end
										when 2 then Case @Weekday when 2 then 1 else 0 end 
										else 0 end)
	end
	-- check for Mayday / Whit 
	if @Month = 5 begin
		set @result = (Select case @Weekday when 2 then Case @day when 1 then 1 when 2 then 1 when 3 then 1 when 4 then 1 when 5 then 1 when 6 then 1 when 7 then 1 when 25 then 1 when 26 then 1 when 27 then 1 when 28 then 1 when 29 then 1 when 30 then 1 when 31 then 1 else 0 end
											else 0 end)
	end
	-- check for AugustBankHol
	if @Month = 8 begin
		if @weekday = 2 begin
			set @Result = (Select Case @Day when 31 then 1 when 30 then 1 when 29 then 1 when 28 then 1 when 27 then 1 when 26 then 1 when 25 then 1 else 0 end)
		end 
	end
	-- check for Easter
	  Set @a = @Year % 19
	  Set @b = @Year % 4
      Set @c = @year % 7
      Set @d = (19 * @a + 24) % 30
      Set @e = (2 * @b + 4 * @c + 6 * @d + 5) % 7
      Set @OT = 22 + @d + @e
      Set @OM = 3
	    If @OT > 31 Begin
			set @OT = @d + @e - 9
			set @OM = 4
	    End 
		If @OT = 26 And @OM = 4 Begin
			Set @OT = 19
		End
		If @OT = 25 And @OM = 4 And @d = 28 And @e = 6 And @a > 10 Begin
			Set @OT = 18
		End

		set @OMStr = Cast(@OM as Varchar(2))
		while Len(@OMStr) < 2 begin
			set @OMStr = '0'+@OMStr
		end
		set @OTStr = Cast(@OT as Varchar(2))
		while Len(@OTStr) < 2 begin
			set @OTStr = '0'+@OTStr
		end
		Set @EasterSunday = Cast((Cast(@Year as Varchar(4))+ @OMStr + @OTStr) as Datetime) --DatefromParts(@Year,@OM,@OT)
		Set @EasterFriday = Dateadd(dd,-2,@EasterSunday)
		Set @EasterMonday = Dateadd(dd,1,@EasterSunday)

		IF @QueryDate = @EasterFriday set @result = 1
		IF @QueryDate = @EasterMonday set @result = 1

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_IsDateABankHoliday: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsDateABankHoliday]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsDateABankHoliday') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_IsDateABankHoliday: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsDateABankHoliday: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsDateABankHoliday]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsDateABankHoliday') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_IsDateABankHoliday: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsDateABankHoliday: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsDateABankHoliday]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsDateABankHoliday') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_IsDateABankHoliday: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsDateABankHoliday: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO