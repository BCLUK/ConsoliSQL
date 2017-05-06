-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'ae_INS_AEF_Amendments'
SET @SPROC_Name = 'ae_INS_AEF_Amendments'
if exists (select * from sys.objects where object_id = object_id(N'[ae_INS_AEF_Amendments]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [ae_INS_AEF_Amendments]
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
-- Description:	To insert records into AEF_Amendments
-- =============================================
-- Version: 5
-- Date: 24/11/2015 
-- =============================================
-- Changes: 16/03/2015: MCB: Changed @AEFA_PRIKEY varchar(100)
-- Changes: 17/04/2015: MCB: Remove update; always insert
-- Changes: 17/04/2015: MCB: Only update Extras
-- Changes: 24/11/2015: MCB: Changed @AEFA_CODE to VARCHAR(100)
-- =============================================
CREATE PROCEDURE [dbo].[ae_INS_AEF_Amendments]
	@AEFA_FREF varchar(7), @AEFA_PRIKEY varchar(100), @AEFA_CODE VARCHAR(100), @AEFA_START varchar(5), @AEFA_END varchar(5), @AEFA_COVERS varchar(5), @AEFA_CHARGE DECIMAL (10, 2), @AEFA_NOTES TEXT, @Action VARCHAR(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF LEFT(@AEFA_PRIKEY, 1) = '0' BEGIN --Only update Extras
		IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF AND AEFA_PRIKEY = @AEFA_PRIKEY) = 0 BEGIN
			INSERT INTO AEF_Amendments
			SELECT @AEFA_FREF, @AEFA_PRIKEY, @AEFA_CODE, @AEFA_START, @AEFA_END, @AEFA_COVERS, @AEFA_CHARGE, @AEFA_NOTES, @Action
		END
		ELSE	
		IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF AND AEFA_PRIKEY = @AEFA_PRIKEY) > 0 BEGIN
			UPDATE AEF_Amendments
			SET AEFA_START = @AEFA_START,
				AEFA_END = @AEFA_END,
				AEFA_COVERS = @AEFA_COVERS,
				AEFA_CHARGE = @AEFA_CHARGE,
				AEFA_NOTES = @AEFA_NOTES,
				AEFA_Action = @Action
			WHERE @AEFA_FREF = AEFA_FREF
			AND @AEFA_PRIKEY = AEFA_PRIKEY
 		END	
	END
	ELSE
	--IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF AND AEFA_PRIKEY = @AEFA_PRIKEY) = 0 BEGIN
		INSERT INTO AEF_Amendments
		SELECT @AEFA_FREF, @AEFA_PRIKEY, @AEFA_CODE, @AEFA_START, @AEFA_END, @AEFA_COVERS, @AEFA_CHARGE, @AEFA_NOTES, @Action
	--END
	--ELSE	
	--IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_FREF = @AEFA_FREF AND AEFA_PRIKEY = @AEFA_PRIKEY) > 0 BEGIN
	--	UPDATE AEF_Amendments
	--	SET AEFA_START = @AEFA_START,
	--		AEFA_END = @AEFA_END,
	--		AEFA_COVERS = @AEFA_COVERS,
	--		AEFA_CHARGE = @AEFA_CHARGE,
	--		AEFA_NOTES = @AEFA_NOTES,
	--		AEFA_Action = @Action
	--	WHERE @AEFA_FREF = AEFA_FREF
	--	AND @AEFA_PRIKEY = AEFA_PRIKEY
 	--END
END
GO

PRINT '*****************************************************************************'

PRINT 'ae_INS_AEF_Amendments: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_AEF_Amendments]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_AEF_Amendments') AND [name] = 'Product')
BEGIN		
	PRINT 'ae_INS_AEF_Amendments: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_AEF_Amendments: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_AEF_Amendments]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_AEF_Amendments') AND [name] = 'Module')
BEGIN		
	PRINT 'ae_INS_AEF_Amendments: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_AEF_Amendments: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_AEF_Amendments]
							   ,@name = N'Version' 
							   ,@value = N'5.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_AEF_Amendments') AND [name] = 'Version')
BEGIN		
	PRINT 'ae_INS_AEF_Amendments: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_AEF_Amendments: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO