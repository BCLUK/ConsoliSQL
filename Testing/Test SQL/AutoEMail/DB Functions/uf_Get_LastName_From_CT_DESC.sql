-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_Get_LastName_From_CT_DESC'
SET @Func_Name = 'uf_Get_LastName_From_CT_DESC'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_Get_LastName_From_CT_DESC')
BEGIN
	DROP FUNCTION [dbo].uf_Get_LastName_From_CT_DESC
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

-- ==========================================================
-- Version: 1.1 
-- Date: 11/07/2016
-- ==========================================================
-- Changes: 11/07/2016: TT: Original Version
--			25/07/2016	TT: Changed how LAST_NAME is 
--			    			calculated - issue occured due 
--							no spaces in last name resulting 
--							in return error
-- ==========================================================
CREATE FUNCTION [dbo].[uf_Get_LastName_From_CT_DESC]
(	
	-- Calling function/procedure supplies the EmailType
	@CT_DESC VARCHAR(100)
)
RETURNS VARCHAR(200)
AS
BEGIN	
	-- The return value defaults to an empty string	
	DECLARE @LASTNAME VARCHAR(200) = ''

	DECLARE @SPACEPOS INT
	DECLARE @STRLEN INT
	DECLARE @NAME VARCHAR(200)

	--Get the Firstname
	SET @NAME = RTRIM(LTRIM((SELECT @CT_DESC)))
	SET @STRLEN = LEN(@NAME)
	SET @SPACEPOS = CHARINDEX(' ', @NAME)				
	--SET @FIRSTNAME = RTRIM(LTRIM(SUBSTRING(@NAME, 0, @SPACEPOS)))

	--Get the Lastname
	SET @NAME = RTRIM(LTRIM(SUBSTRING(@NAME, @SPACEPOS + 1, @STRLEN)))
	SET @STRLEN = LEN(@NAME)
	SET @SPACEPOS = CHARINDEX(' ', @NAME)				
	--Changed how LASTNAME is caluclated - TT - 25/07/2016
	IF @SPACEPOS = 0
		SET @LASTNAME = @NAME
	ELSE
		SET @LASTNAME = RTRIM(LTRIM(SUBSTRING(@NAME, 0, @SPACEPOS)))

	-- Return the result of the function
	RETURN @LASTNAME

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_Get_LastName_From_CT_DESC: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_LastName_From_CT_DESC]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_LastName_From_CT_DESC') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_Get_LastName_From_CT_DESC: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_LastName_From_CT_DESC: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_LastName_From_CT_DESC]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_LastName_From_CT_DESC') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_Get_LastName_From_CT_DESC: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_LastName_From_CT_DESC: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_LastName_From_CT_DESC]
							   ,@name = N'Version' 
							   ,@value = N'1.1'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_LastName_From_CT_DESC') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_Get_LastName_From_CT_DESC: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_LastName_From_CT_DESC: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO