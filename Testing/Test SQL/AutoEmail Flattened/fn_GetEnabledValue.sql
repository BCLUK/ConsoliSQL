-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'fn_GetEnabledValue'
SET @Func_Name = 'fn_GetEnabledValue'

if exists (select * from sys.objects where object_id = object_id(N'[dbo].[fn_GetEnabledValue]') and type in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[fn_GetEnabledValue]
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

CREATE FUNCTION [dbo].[fn_GetEnabledValue]
	(
		@vcString VARCHAR(255),
		@Action	VARCHAR(1)
	)  
RETURNS int 
/* **************************************************************************** 
	FUNCTION :	fn_GetMinsValue
	DESCRIPTION : Get Enabled values for InsertUpdateDelete		
	PARAMETERS : String of Insert, Update and Delete e.g. I:1;U:1;D:1;	
	RETURN : Number of minutes as an integer	
	AUTHOR : Mark Birch
	TEST : SELECT [dbo].[fn_GetEnabledValue]( 'I:1;U:1;D:1', 'D' ) 	
	MODIFICATIONS : 
**************************************************************************** */
AS  
BEGIN 
  -- 'D:1;H:1;M:1'
  Declare @Insert   int
  Declare @Update  int
  Declare @Delete   int
  
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
  
  -- Does the input string have a INSERT element
  set @Pos = PATINDEX( '%I%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end 
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Days value
      set @Insert   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Insert = 0
    
  -- Does the input string have an Update element
  set @Pos = PATINDEX( '%U%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Hours value
      set @Update   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Update = 0
    
  -- Does the input string have a Delete element
  set @Pos = PATINDEX( '%D%', @vcString )
  If @Pos > 0
    begin
      -- Get the substring from after the semi-colon to the end
      set @SubStr = SUBSTRING( @vcString, @Pos +2, @StrLen ) 
      -- Get the end position of the current value being calculated
      set @Pos    = PATINDEX( '%;%', @SubStr )
      set @SubStrLen = LEN( @SubStr )
      -- Minutes value
      set @Delete   = SUBSTRING( @SubStr, 1, @Pos -1 )
    end
  Else
    set @Delete = 0

	SET @RETURN = CASE @Action
				WHEN 'I' THEN @Insert
				WHEN 'U' THEN @Update
				WHEN 'D' THEN @Delete
			  ELSE (@Insert + @Update + @Delete)   
	END		  

  -- Return result
  RETURN (@RETURN)

END
GO

PRINT '*****************************************************************************'								   
PRINT 'fn_GetEnabledValue: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetEnabledValue]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetEnabledValue') AND [name] = 'Product')
BEGIN		
	PRINT 'fn_GetEnabledValue: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetEnabledValue: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetEnabledValue]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetEnabledValue') AND [name] = 'Module')
BEGIN		
	PRINT 'fn_GetEnabledValue: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetEnabledValue: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetEnabledValue]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetEnabledValue') AND [name] = 'Version')
BEGIN		
	PRINT 'fn_GetEnabledValue: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetEnabledValue: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO