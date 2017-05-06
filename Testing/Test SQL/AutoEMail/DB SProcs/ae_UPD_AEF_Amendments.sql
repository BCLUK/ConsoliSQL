-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'ae_UPD_AEF_Amendments'
SET @SPROC_Name = 'ae_UPD_AEF_Amendments'
if exists (select * from sys.objects where object_id = object_id(N'[ae_UPD_AEF_Amendments]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [ae_UPD_AEF_Amendments]
	PRINT @FileName + ': Dropped Procedure ' + @SPROC_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @SPROC_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Procedure ' + @SPROC_Name
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mark Birch
-- Create date: 12-MAR-2015
-- Description:	To update status for records in AEF_Amendments
-- =============================================
-- Version: 3
-- Date: 22/04/2015 
-- =============================================
-- Changes: 13/04/2015: MCB: Added different logic
-- Changes: 22/04/2015: MCB: Added Deleted Items to Update List
-- =============================================
CREATE PROCEDURE [dbo].[ae_UPD_AEF_Amendments]
	@AEFA_FREF varchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF) = 0 BEGIN
		RETURN
	END
	ELSE	
	IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF) > 0 BEGIN
		UPDATE AEF_Amendments
		SET AEFA_Action = CASE AEFA_Action WHEN 'I' THEN 'X' WHEN 'U' THEN 'X' WHEN 'D' THEN '*' ELSE AEFA_Action END
		WHERE @AEFA_FREF = AEFA_FREF
		AND LEFT(AEFA_PRIKEY, 1) = '0'
	END
END
GO
PRINT '*****************************************************************************'

PRINT 'ae_UPD_AEF_Amendments: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_UPD_AEF_Amendments]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_UPD_AEF_Amendments') AND [name] = 'Product')
BEGIN		
	PRINT 'ae_UPD_AEF_Amendments: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_UPD_AEF_Amendments: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_UPD_AEF_Amendments]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_UPD_AEF_Amendments') AND [name] = 'Module')
BEGIN		
	PRINT 'ae_UPD_AEF_Amendments: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_UPD_AEF_Amendments: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_UPD_AEF_Amendments]
							   ,@name = N'Version' 
							   ,@value = N'3.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_UPD_AEF_Amendments') AND [name] = 'Version')
BEGIN		
	PRINT 'ae_UPD_AEF_Amendments: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_UPD_AEF_Amendments: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO