-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_Get_Acc_Man_Telephone'
SET @Func_Name = 'uf_Get_Acc_Man_Telephone'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_Get_Acc_Man_Telephone')
BEGIN
	DROP FUNCTION [dbo].[uf_Get_Acc_Man_Telephone]
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
-- Author:		Tony Tasker
-- Create date: 28/07/2016
-- Description:	Gets the Telephone No of the Account Manger 
--				from OP File from info stored in the 
--				classification table
-- ==========================================================
-- Version: 1 
-- Date: 28/07/2016
-- =============================================
-- Changes: 28/07/2016: TT: Original Version
-- =============================================
CREATE FUNCTION [dbo].[uf_Get_Acc_Man_Telephone]
(	
	-- Calling function/procedure supplies the EmailType
	@F_REF VARCHAR(7)
)
RETURNS VARCHAR(200)
AS
BEGIN	
	
	-- The return value defaults to an empty string
	DECLARE @TELNO VARCHAR(200) = ''

	-- ==================================================================================================================
	-- From FUNC_FIL with specific F_REF ..
	-- Link to AC05 on AC_OWNER (which is same as MBR_SYSNO) - Get AC_CODE from here which links to Account Manager
	-- Link to CT05 on AC_CODE to get CT_DESC which is a field containing 1st name, last name and tel no
	-- Link to OP_FILE ON extracted firstname and lastname to get Email address
	-- ==================================================================================================================
	SET @TELNO = (SELECT DISTINCT O_TEL
		FROM FUNC_FIL INNER JOIN AC05 ON AC_OWNER = F_MBR_NO
					  INNER JOIN CT05 ON AC_Code = CT_CODE
					  INNER JOIN OP_FILE 
							ON dbo.uf_Get_FirstName_From_CT_DESC(CT_DESC) = O_FIRST 
							AND dbo.uf_Get_LastName_From_CT_DESC(CT_DESC) = O_LAST		
		WHERE F_REF = @F_REF)		

	-- ==============
	-- Return Email
	-- ==============

	RETURN @TELNO

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_Get_Acc_Man_Telephone: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_Acc_Man_Telephone]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_Acc_Man_Telephone') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_Get_Acc_Man_Telephone: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_Acc_Man_Telephone: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_Acc_Man_Telephone]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_Acc_Man_Telephone') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_Get_Acc_Man_Telephone: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_Acc_Man_Telephone: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_Get_Acc_Man_Telephone]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_Get_Acc_Man_Telephone') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_Get_Acc_Man_Telephone: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_Get_Acc_Man_Telephone: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO