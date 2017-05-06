DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'RATIONALISE_BUILD'
SET @SPROC_Name = 'RATIONALISE_BUILD'

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 23/03/2017
-- Description:	This script is used to ensure that extended properties have been added to autoemail 
--				tables. 
--
--				This script also drops any AutoEMail SQL objects that have been depricated 
-- =====================================================================================================
-- Version:		01
-- Date:		23/03/2017
-- =====================================================================================================
-- Changes (1):	TT: 23/03/2017: Original Version
-- =====================================================================================================
SET NOCOUNT ON  

PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Table AEF_Amendments - Checking Extended Properties'

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Amendments]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName +  ': Table AEF_Amendments "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName +  ': Table AEF_Amendments "Product" Extended Property Not Created Successfully !'		
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Amendments]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName +  ': Table AEF_Amendments "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName +  ': Table AEF_Amendments "Module" Extended Property Not Created Successfully !'
	END			
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Version')
BEGIN
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Amendments]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Amendments') AND [name] = 'Version')
	BEGIN				
		PRINT @FileName +  ': Table AEF_Amendments "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName +  ': Table AEF_Amendments "Version" Extended Property Not Created Successfully !'
	END			
END

PRINT '*******************************************************************************'								   
PRINT @FileName + ': AEF_Link - Checking Extended Properties'

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Link]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName + ': Table AEF_LINK "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AEF_LINK "Product" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Link]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName + ': Table AEF_LINK "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AEF_LINK "Module" Extended Property Not Created Successfully !'
	END			
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Version')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AEF_Link]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AEF_Link') AND [name] = 'Version')
	BEGIN		
		PRINT @FileName + ': Table AEF_LINK "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AEF_LINK "Version" Extended Property Not Created Successfully !'
	END
END

PRINT '*******************************************************************************'								   							   
PRINT @FileName + ': AutoEmailFunction - Checking Extended Properties'

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction "Product" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction "Module" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Version')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction') AND [name] = 'Version')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction "Version" Extended Property Not Created Successfully !'
	END	
END

PRINT '*******************************************************************************'								   
PRINT @FileName + ': AutoEmailFunction_FromTrigger - Checking Extended Properties'

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_FromTrigger]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Product" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_FromTrigger]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Module" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Version')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_FromTrigger]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_FromTrigger') AND [name] = 'Version')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_FromTrigger "Version" Extended Property Not Created Successfully !'
	END	
END

PRINT '*******************************************************************************'								   							   
PRINT @FileName + ': AutoEmailFunction_SEND_PARAMS - Checking Extended Properties'

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Product" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Module" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Version')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [AutoEmailFunction_SEND_PARAMS]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AutoEmailFunction_SEND_PARAMS') AND [name] = 'Version')
	BEGIN		
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table AutoEmailFunction_SEND_PARAMS "Version" Extended Property Not Created Successfully !'
	END	
END

PRINT '*******************************************************************************'								   
PRINT @FileName + ': MenuActivityCount - Checking Extended Properties'							   

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Product')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [MenuActivityCount]
								   ,@name = N'Product' 
								   ,@value = N'CABS'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Product')
	BEGIN		
		PRINT @FileName + ': Table MenuActivityCount "Product" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table MenuActivityCount "Product" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Module')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [MenuActivityCount]
								   ,@name = N'Module' 
								   ,@value = N'AutoEmail'

	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Module')
	BEGIN		
		PRINT @FileName + ': Table MenuActivityCount "Module" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table MenuActivityCount "Module" Extended Property Not Created Successfully !'
	END	
END

IF NOT EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Version')
BEGIN		
	EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
								   ,@level0name = [dbo] 
								   ,@level1type = N'TABLE' 
								   ,@level1name = [MenuActivityCount]
								   ,@name = N'Version' 
								   ,@value = N'1.0'
								   
	IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('MenuActivityCount') AND [name] = 'Version')
	BEGIN		
		PRINT @FileName + ': Table MenuActivityCount "Version" Extended Property Created Successfully'
	END
	ELSE
	BEGIN
		PRINT @FileName + ': Table MenuActivityCount "Version" Extended Property Not Created Successfully !'
	END	
END
							   
PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Check Procedure CABS_AEF_SEND_SFD'

IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_SFD]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_SFD]
	PRINT @FileName + ': Dropped Procedure CABS_AEF_SEND_SFD'
END

PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Check Procedure CABS_AEF_SEND_ECC'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_ECC]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_ECC]
	PRINT @FileName + ': Dropped Procedure CABS_AEF_SEND_ECC'
END

PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Check Procedure CABS_AEF_SEND_PRQ'

IF EXISTS ( SELECT * FROM sys.objects 
            WHERE object_id = object_id(N'[dbo].[CABS_AEF_SEND_PRQ]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_AEF_SEND_PRQ]
	PRINT @FileName + ': Dropped Procedure CABS_AEF_SEND_PRQ'
END

PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Check Procedure CABS_AEF_SEND_CHN'

IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_SEND_CHN]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].CABS_AEF_SEND_CHN
	PRINT @FileName + ': Dropped Procedure CABS_AEF_SEND_CHN'
END

PRINT '*******************************************************************************'								   						   
PRINT @FileName + ': Check Procedure CABS_CREATE_AUTOEMAILER_TABLES'

IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_CREATE_AUTOEMAILER_TABLES]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_CREATE_AUTOEMAILER_TABLES]
	PRINT @FileName + ': Dropped Procedure CABS_CREATE_AUTOEMAILER_TABLES'
END

PRINT '*******************************************************************************'								   						   
GO
