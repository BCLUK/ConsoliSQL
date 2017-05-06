-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

if exists (select * from sys.objects where object_id = object_id(N'[AE_MenuActivityCountDEL]') and OBJECTPROPERTY(object_id, N'IsTrigger') = 1)
BEGIN
	DROP TRIGGER [AE_MenuActivityCountDEL]
	PRINT 'trAE_MenuActivityCountDEL: Dropped Trigger AE_MenuActivityCountDEL on MADEMENU'
END
ELSE
BEGIN
	PRINT 'trAE_MenuActivityCountDEL: Trigger AE_MenuActivityCountDEL on MADEMENU Does Not Exist !'
END
PRINT 'trAE_MenuActivityCountDEL: Creating Trigger AE_MenuActivityCountDEL on MADEMENU'
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================================= 
-- Author:		Mark Birch
-- Create date: 11-SEP-2015
-- Description:	To captue Menu Item Activity (Update|Delete 
--				- only required for deletions) 
-- ============================================================================= 
-- Version: 2
-- Date: 23/03/2017
-- ============================================================================= 
-- Changes: 11/09/2015: MCB: Original
-- Changes: 23/03/2017: TT: Removed call to stored procedure 
--	(2)						CABS_CREATE_AUTOEMAILER_TABLES as it 
--							should not be needed if the build processs is robust
--							Removed check for table AEF_LINK
--							Changed dbo.sysobjects to sys.objects as it is 
--							depricated 	 
-- ============================================================================= 
CREATE TRIGGER [dbo].[AE_MenuActivityCountDEL]
   ON  [dbo].[MADEMENU]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- ================================================
-- Create Tables
-- ================================================
	-- Removed call to CABS_CREATE_AUTOEMAILER_TABLES - TT - 23/03/2017
	-- EXEC CABS_CREATE_AUTOEMAILER_TABLES
-- ================================================
-- DECLRATIONS
-- ================================================	
	DECLARE @MEN_MENU_CODE VARCHAR(10), @MEN_DEL_COUNT INT, @MenuDate DATETIME
-- ================================================
-- GET VALUES
-- ================================================	
	SET @MEN_DEL_COUNT = (SELECT COUNT(*) FROM DELETED)
	SET @MEN_MENU_CODE = (SELECT TOP 1 MEN_MENU_CODE FROM DELETED)
	SET @MenuDate = (SELECT DISTINCT(F_DAY) FROM FUNC_FIL
					INNER JOIN MASTMENU ON F_REF = MNM_OWNER
					INNER JOIN DELETED ON MNM_CODE = MEN_MENU_CODE
					WHERE MEN_MENU_CODE = @MEN_MENU_CODE)
-- ================================================
-- The Work
-- ================================================	
	-- Changed sysobjects to sys.objects - TT - 23/03/2017
	--IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[MenuActivityCount]')) = 1
	IF (SELECT COUNT(*) FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[MenuActivityCount]')) = 1
	BEGIN
		IF (SELECT COUNT(*) FROM MenuActivityCount WHERE MEN_MENU_CODE = @MEN_MENU_CODE AND MEN_REC_TYPE = 'D') = 0 
		BEGIN
			INSERT INTO MenuActivityCount 
			SELECT @MEN_MENU_CODE, @MEN_DEL_COUNT, 'D', @MenuDate
		END
		ELSE
		IF (SELECT COUNT(*) FROM MenuActivityCount WHERE MEN_MENU_CODE = @MEN_MENU_CODE AND MEN_REC_TYPE = 'D') > 0
		BEGIN
			UPDATE MenuActivityCount
			SET
			MEN_DEL_COUNT = (@MEN_DEL_COUNT),
			MEN_DATE = @MenuDate
			WHERE MEN_MENU_CODE = @MEN_MENU_CODE
			AND MEN_REC_TYPE = 'D'
		END 
	END
-- ================================================
END
GO

PRINT '*****************************************************************************'								   
PRINT 'AE_MenuActivityCountDEL: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MADEMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [AE_MenuActivityCountDEL]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AE_MenuActivityCountDEL') AND [name] = 'Product')
BEGIN		
	PRINT 'AE_MenuActivityCountDEL: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AE_MenuActivityCountDEL: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MADEMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [AE_MenuActivityCountDEL]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AE_MenuActivityCountDEL') AND [name] = 'Module')
BEGIN		
	PRINT 'AE_MenuActivityCountDEL: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AE_MenuActivityCountDEL: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MADEMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [AE_MenuActivityCountDEL]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('AE_MenuActivityCountDEL') AND [name] = 'Version')
BEGIN		
	PRINT 'AE_MenuActivityCountDEL: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'AE_MenuActivityCountDEL: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
