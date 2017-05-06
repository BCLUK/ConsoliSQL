-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_getExtraDescription'
SET @Func_Name = 'uf_getExtraDescription'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_getExtraDescription]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[uf_getExtraDescription]
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
-- Create date: 12th MAr 2015
-- Description:	gets the description for an extra code
-- =============================================
CREATE FUNCTION [dbo].[uf_getExtraDescription] 
(
	-- Add the parameters for the function here
	@PCode varchar(10)
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(50)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = isnull((Select REPLACE(P_Desc, CHAR(39), CHAR(146)) from Post_Def where P_Code = @PCode),'No Description Found')
	

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_getExtraDescription: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getExtraDescription]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getExtraDescription') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_getExtraDescription: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getExtraDescription: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getExtraDescription]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getExtraDescription') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_getExtraDescription: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getExtraDescription: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getExtraDescription]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getExtraDescription') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_getExtraDescription: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getExtraDescription: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO