-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'fn_GetHiddenRoomText'
SET @Func_Name = 'fn_GetHiddenRoomText'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetHiddenRoomText]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[fn_GetHiddenRoomText]
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
-- Author:		Mark Birch
-- Create date: 20-AUG-2014
-- Description:	Return Hidden Room Text For Auto-Emailer
-- =============================================
CREATE FUNCTION [dbo].[fn_GetHiddenRoomText]
(
	-- Add the parameters for the function here
	@StartText VARCHAR(1000), @Frequency VARCHAR(1000)
)
RETURNS VARCHAR(1000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ReplaceText VARCHAR(1)
	DECLARE @TextFind VARCHAR(3)
	DECLARE @TextReplace VARCHAR(10)
	DECLARE @EndText VARCHAR(1000)
	-- Declarations  
	--DECLARE @StrLen INT
	DECLARE @Pos INT
	--DECLARE @SubStr VARCHAR(255)
	--DECLARE @SubStrLen INT
  
	-- Add the T-SQL statements to compute the return value here
	SET @Pos = PATINDEX( '%<%', @StartText )
	IF @Pos > 0
	BEGIN
		SET @ReplaceText = SUBSTRING(@StartText, @Pos +1, 1)
		SET @TextFind = '<' + @ReplaceText + '>'
		SET @TextReplace = (SELECT [dbo].[fn_GetTimeValue](@Frequency, @ReplaceText))
		SET @EndText = REPLACE(@StartText, @TextFind, @TextReplace)
	END
	ELSE
	IF @Pos = 0
	BEGIN
		SET @EndText = @StartText
	END	
	
	-- Return the result of the function
	RETURN @EndText

END
GO

PRINT '*****************************************************************************'								   
PRINT 'fn_GetHiddenRoomText: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetHiddenRoomText]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetHiddenRoomText') AND [name] = 'Product')
BEGIN		
	PRINT 'fn_GetHiddenRoomText: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetHiddenRoomText: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetHiddenRoomText]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetHiddenRoomText') AND [name] = 'Module')
BEGIN		
	PRINT 'fn_GetHiddenRoomText: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetHiddenRoomText: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [fn_GetHiddenRoomText]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('fn_GetHiddenRoomText') AND [name] = 'Version')
BEGIN		
	PRINT 'fn_GetHiddenRoomText: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'fn_GetHiddenRoomText: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO