-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'fn_GetTimeValue'
SET @Func_Name = 'fn_GetTimeValue'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetTimeValue]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[fn_GetTimeValue]
	PRINT @FileName + ': Dropped Function ' + @Func_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @Func_Name + ' -  Does Not Already Exist !'
END
	PRINT @FileName + ': Creating Function ' + @Func_Name
GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[fn_GetTimeValue]
	(
		@vcString	VARCHAR(255),
		@DMH VARCHAR(3)
	)  
RETURNS int 
/* **************************************************************************** 
	FUNCTION :	fn_GetMinsValue
	DESCRIPTION : Calculates the number of minutes from a string of Days, Hours and Minutes		
	PARAMETERS : String of Days, Hours and Minutes e.g. D:1;H:1;M:1;	
	RETURN : Number of minutes as an integer	
	AUTHOR : Martin Baud
	TEST : SELECT [dbo].[fn_GetMinsValue]( 'D:1;H:1;M:1' ) 	
	MODIFICATIONS : 
**************************************************************************** */
AS  
BEGIN 
  -- 'D:1;H:1;M:1'
  Declare @Days   int
  Declare @Hours  int
  Declare @Mins   int
  
  Declare @StrLen int
  Declare @Pos    int
  Declare @SubStr    varchar(255)
  Declare @SubStrLen int
  
  Declare @RETURN int
  
  -- Ensure there is a semi-colon at the end of the string
  If SUBSTRING( @vcString, Len(@vcString), 1) <> ';'
    set @vcString = @vcString + ';'
    
  -- How long is the input string
  set @StrLen = LEN( @vcString )  
  
  -- Does the input string have a Days element
  set @Pos = PATINDEX( '%D%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end 
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Days value
      set @Days   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Days = 0
    
  -- Does the input string have an Hours element
  set @Pos = PATINDEX( '%H%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Hours value
      set @Hours   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Hours = 0
    
  -- Does the input string have a Minutes element
  set @Pos = PATINDEX( '%M%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Minutes value
      set @Mins   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Mins = 0
    
  -- Calculate thenumebr of minutes from input string values
	IF @DMH = 'D'
	BEGIN
		SET @RETURN = (@Days) 
	END
	ELSE  
	IF @DMH = 'H'
	BEGIN
		SET @RETURN = (@Days * 24) + ( @Hours ) 	
	END
	ELSE
	IF @DMH = 'M'
	BEGIN
		SET @RETURN = ( @Days * 24 * 60 ) +
		  		      ( @Hours * 60 ) +
					  ( @Mins ) 	
	END	
	ELSE
		SET @RETURN = ( @Days * 24 * 60 ) +
		  		      ( @Hours * 60 ) +
					  ( @Mins ) 

  -- Return result
  RETURN (@RETURN)

END
GO

PRINT '*****************************************************************************'								   
PRINT 'fn_GetTimeValue: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetTimeValue]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetTimeValue') AND [name] = 'Product')
BEGIN		
	PRINT 'fn_GetTimeValue: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetTimeValue: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetTimeValue]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetTimeValue') AND [name] = 'Module')
BEGIN		
	PRINT 'fn_GetTimeValue: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetTimeValue: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetTimeValue]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetTimeValue') AND [name] = 'Version')
BEGIN		
	PRINT 'fn_GetTimeValue: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetTimeValue: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO