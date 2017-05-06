-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_CreateDateDiff'
SET @Func_Name = 'uf_CreateDateDiff'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_CreateDateDiff]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    DROP FUNCTION [dbo].[uf_CreateDateDiff]
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
-- Create date: 03-FEB-2015
-- Description:	To Return A Date Difference between Created Day and Booking Date
-- =============================================
CREATE FUNCTION [dbo].[uf_CreateDateDiff]
(
	@Ref VARCHAR(10)
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result INT
	DECLARE
		@BookingDate DATETIME,
		@CreateDate  DATETIME
	

	IF LEFT(@Ref, 1) = 'F' BEGIN
		SET @BookingDate = (SELECT F_DAY FROM FUNC_FIL WHERE F_REF = @Ref)
		SET @CreateDate = (SELECT COALESCE(F_CREATEDATE, F_DAY) FROM FUNC_FIL WHERE F_REF = @Ref)
		SET @Result = DATEDIFF(DD, @CreateDate, @BookingDate)
	END

	-- Return the result of the function
	RETURN COALESCE(@Result, 0)
END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_CreateDateDiff: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_CreateDateDiff]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_CreateDateDiff') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_CreateDateDiff: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_CreateDateDiff: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_CreateDateDiff]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_CreateDateDiff') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_CreateDateDiff: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_CreateDateDiff: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_CreateDateDiff]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_CreateDateDiff') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_CreateDateDiff: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_CreateDateDiff: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO