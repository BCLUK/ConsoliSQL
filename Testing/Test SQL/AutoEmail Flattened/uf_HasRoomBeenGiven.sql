-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_HasRoomBeenGiven'
SET @Func_Name = 'uf_HasRoomBeenGiven'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_HasRoomBeenGiven]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    DROP FUNCTION [dbo].[uf_HasRoomBeenGiven]
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
-- Create date: 22-JAN-2015
-- Description:	To Return A Room Given Flag Of Yes|No
-- =============================================
CREATE FUNCTION [dbo].[uf_HasRoomBeenGiven]
(
	@Ref VARCHAR(10)
)
RETURNS VARCHAR(3)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result VARCHAR(3)

	IF LEFT(@Ref, 1) = 'F' BEGIN
		SET @Result = (SELECT F_RMGIVEN FROM FUNC_FIL WHERE F_REF = @Ref)
	END

	-- Return the result of the function
	RETURN COALESCE(@Result, 'Yes')
END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_HasRoomBeenGiven: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_HasRoomBeenGiven]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_HasRoomBeenGiven') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_HasRoomBeenGiven: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_HasRoomBeenGiven: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_HasRoomBeenGiven]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_HasRoomBeenGiven') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_HasRoomBeenGiven: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_HasRoomBeenGiven: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_HasRoomBeenGiven]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_HasRoomBeenGiven') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_HasRoomBeenGiven: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_HasRoomBeenGiven: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO