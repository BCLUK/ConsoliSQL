-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_getDeptCodes'
SET @Func_Name = 'uf_getDeptCodes'
if exists (select * from sys.objects where object_id = object_id(N'[dbo].[uf_getDeptCodes]') and type in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[uf_getDeptCodes]
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
-- Create date: 13-FEB-2015
-- Description:	Gets the Departments for an Extra Code
-- =============================================
-- Version: 4
-- Date: 05/03/2015
-- =============================================
-- Changes: 16/02/2015: MCB: Added better handling to add spaces etc. 
-- Changes: 18/02/2015: MCB: Removed code to remove ';'; it is required
-- Changes: 05/03/2015: MCB: Added Views for Packages and Drink Trolley
-- =============================================
CREATE FUNCTION [dbo].[uf_getDeptCodes] 
(
	-- Add the parameters for the function here
	@Code VARCHAR(10), @Location VARCHAR(10)
)
RETURNS varchar(4000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(4000),
			@DeptCode VARCHAR(6)

	SET @Result = ''
	-- Add the T-SQL statements to compute the return value here
	DECLARE
		myCURSOR1
	CURSOR FAST_FORWARD for
		
		SELECT DEPT
		FROM vw_ExtraCodeDept
		WHERE CODE = @Code
		AND LOC = @Location
		UNION 
		SELECT DEPT
		FROM vw_PackCodeDept
		WHERE PACK = @Code
		AND LOC = @Location
		UNION
		SELECT DEPT
		FROM vw_DTCodeDept
		WHERE DT = @Code
		AND LOC = @Location
		
	OPEN myCURSOR1

	FETCH NEXT FROM
		myCURSOR1
	INTO
		@DeptCode

	WHILE @@FETCH_STATUS = 0
	BEGIN
			SET @Result = (@Result + @DeptCode + ';')

		FETCH NEXT FROM 
			myCURSOR1
		INTO
			@DeptCode
	END

	CLOSE myCURSOR1
	DEALLOCATE myCURSOR1


	--Remove trailing comma
	--SET @Result = CASE RIGHT(LTRIM(RTRIM(@Result)), 1)
	--				WHEN ';' THEN Left( LTRIM(RTRIM(@Result)), Len(LTRIM(RTRIM(@Result))) -1 )
	--				ELSE @Result
	--			END
		
	-- Return the result of the function				
	
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_getDeptCodes: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDeptCodes]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDeptCodes') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_getDeptCodes: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDeptCodes: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDeptCodes]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDeptCodes') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_getDeptCodes: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDeptCodes: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getDeptCodes]
							   ,@name = N'Version' 
							   ,@value = N'4.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getDeptCodes') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_getDeptCodes: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getDeptCodes: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO