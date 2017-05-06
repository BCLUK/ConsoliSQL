-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'ae_DEL_AEF_Amendments'
SET @SPROC_Name = 'ae_DEL_AEF_Amendments'
if exists (select * from sys.objects where object_id = object_id(N'[ae_DEL_AEF_Amendments]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [ae_DEL_AEF_Amendments]
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
-- Description:	To delete records from AEF_Amendments
-- =============================================
-- Version: 5
-- Date: 17/04/2015 
-- =============================================
-- Changes: 08/04/2015: MCB: Allow deletion of items only
-- Changes: 13/04/2015: MCB: Amended logic
-- Changes: 13/04/2015: MCB: Amended logic
-- Changes: 17/04/2015: MCB: Fixed logic
-- =============================================
CREATE PROCEDURE [dbo].[ae_DEL_AEF_Amendments]
	@AEFA_PRIKEY varchar(100), @ItemsOnly INT, @KeepAIItems INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @ItemsOnly = 0 BEGIN --@AEFA_PRIKEY is the primary key; delete one at a time
		IF @KeepAIItems = 1 BEGIN
			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_PRIKEY = @AEFA_PRIKEY) > 0 BEGIN
				DELETE FROM AEF_Amendments
				WHERE @AEFA_PRIKEY = AEFA_PRIKEY
				AND NOT LEFT(AEFA_PRIKEY, 1) = '0'
				--AND AEFA_ACTION IN('I', 'U', 'D')
			END	
 		END
 		ELSE
 		IF @KeepAIItems = 0 BEGIN
			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_PRIKEY = @AEFA_PRIKEY) > 0 BEGIN
				DELETE FROM AEF_Amendments
				WHERE @AEFA_PRIKEY = AEFA_PRIKEY
			END	 		
 		END
 	END
 	ELSE	
 	IF @ItemsOnly = 1 BEGIN --@AEFA_PRIKEY is the owner; delete multiple items
		IF @KeepAIItems = 1 BEGIN --Keep AI_FILE ITEMS
			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_PRIKEY) > 0 BEGIN
				DELETE FROM AEF_Amendments
				WHERE @AEFA_PRIKEY = AEFA_FREF
				AND NOT LEFT(AEFA_PRIKEY, 1) = '0'
				--AND AEFA_ACTION IN('I', 'U', 'D')
 			END
 		END
 		ELSE
 		IF @KeepAIItems = 0 BEGIN
			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_PRIKEY) > 0 BEGIN
				DELETE FROM AEF_Amendments
				WHERE @AEFA_PRIKEY = AEFA_FREF
			END
		END		 			 	
 	END
END
GO

PRINT '*****************************************************************************'

PRINT 'ae_DEL_AEF_Amendments: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_DEL_AEF_Amendments]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_DEL_AEF_Amendments') AND [name] = 'Product')
BEGIN		
	PRINT 'ae_DEL_AEF_Amendments: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_DEL_AEF_Amendments: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_DEL_AEF_Amendments]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_DEL_AEF_Amendments') AND [name] = 'Module')
BEGIN		
	PRINT 'ae_DEL_AEF_Amendments: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_DEL_AEF_Amendments: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_DEL_AEF_Amendments]
							   ,@name = N'Version' 
							   ,@value = N'5.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_DEL_AEF_Amendments') AND [name] = 'Version')
BEGIN		
	PRINT 'ae_DEL_AEF_Amendments: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_DEL_AEF_Amendments: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO