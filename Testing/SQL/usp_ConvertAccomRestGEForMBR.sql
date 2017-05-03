SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_ConvertAccomRestGEForMBR]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_ConvertAccomRestGEForMBR]	
	PRINT 'usp_ConvertAccomRestGEForMBR: Dropped Procedure usp_ConvertAccomRestGEForMBR'
END
ELSE
BEGIN	
	PRINT 'usp_ConvertAccomRestGEForMBR: usp_ConvertAccomRestGEForMBR -  Does Not Already Exist !'
END

PRINT 'usp_ConvertAccomRestGEForMBR: Creating Procedure usp_ConvertAccomRestGEForMBR'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	02/05/2017
-- Description:	Wrapper for procedures that convert accommodation and restaurant global extras to bookings.
-- Product:		CABS
-- Module:		Enhanced MBR Copier
-- Parameters:	@MbrSysNo, @ConvertAccommodation, @ConvertRestaurants
-- Returns:		TABLE
-- Switches:	N/A
-- Test:		EXEC usp_ConvertAccomRestGEForMBR @MbrSysNo, @ConvertAccommodation, @ConvertRestaurants
-- Called By:	N/A
-- Calls:		N/A
-- ====================================================================================================================
-- Version:		1.0
-- Date:		02/05/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 02/05/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_ConvertAccomRestGEForMBR
	@MbrSysNo VARCHAR(7),
	@ConvertAccommodation BIT,
	@ConvertRestaurants BIT,
	@ConvertedAccommodationCount INT OUT,
	@ConvertedRestaurantCount INT OUT
AS
BEGIN
	SET NOCOUNT ON
	
	IF OBJECT_ID('tempdb..#MBR_COPIER_OUTPUT') IS NOT NULL
	DROP TABLE #MBR_COPIER_OUTPUT

	CREATE TABLE #MBR_COPIER_OUTPUT
	(
		MBR_PRIKEY VARCHAR(7) COLLATE SQL_Latin1_General_CP1_CI_AS,
		CL_SYSNO VARCHAR(7) COLLATE SQL_Latin1_General_CP1_CI_AS,
		MBR_CONTCT VARCHAR(40) COLLATE SQL_Latin1_General_CP1_CI_AS,
		CLASS_CODES VARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS,
		MBR_EVENT VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS,
		F_REF VARCHAR(7) COLLATE SQL_Latin1_General_CP1_CI_AS,
		[DATE] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ROOM VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
		[START] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		[END] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		COVERS VARCHAR(13) COLLATE SQL_Latin1_General_CP1_CI_AS,
		AI_PRIKEY VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		EXTRA_DESC VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
	)

	DECLARE @ClassCodesTable INT = (SELECT dbo.uf_xCABS_CONFIG_ReadString('', 'EnhancedMBRCopier', 'ClassCodesTable'))

	DECLARE @ClassCodes TABLE (CT_DESC VARCHAR(50))
	INSERT @ClassCodes
	EXEC usp_GetSelectedClassCodes @MBRSysNo, @ClassCodesTable

	DECLARE @ClassCodesStr VARCHAR(MAX) = (SELECT STUFF((SELECT ', ' + CT_DESC FROM @ClassCodes FOR XML PATH('')), 1, 2, ''))

	INSERT INTO #MBR_COPIER_OUTPUT
	SELECT MBR_SYSNO,
		MBR_CLIENT,
		MBR_CONTCT,
		@ClassCodesStr,
		MBR_EVENT,
		'',
		'',
		'',
		'',
		'',
		'',
		'',
		'From ' + @MbrSysNo
	FROM MBRFILE
	WHERE MBR_SYSNO = @MbrSysNo
	
	SET @ConvertedAccommodationCount = 0
	SET @ConvertedRestaurantCount = 0

	IF @ConvertAccommodation = 1
	BEGIN
		EXEC usp_CABS_ConvertGE_AccomMBR @MbrSysNo, @ClassCodesStr, @ConvertedAccommodationCount OUT
	END
	
	IF @ConvertRestaurants = 1
	BEGIN
		EXEC usp_CABS_ConvertGE_Rest_ForMBR @MbrSysNo, @ClassCodesStr, @ConvertedRestaurantCount OUT
	END

	-- Only select log if extras were converted
	IF (SELECT COUNT(*) FROM #MBR_COPIER_OUTPUT) > 1
	BEGIN
		SELECT *
		FROM #MBR_COPIER_OUTPUT
	END

	DROP TABLE #MBR_COPIER_OUTPUT
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_ConvertAccomRestGEForMBR]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_ConvertAccomRestGEForMBR: usp_ConvertAccomRestGEForMBR Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccomRestGEForMBR: usp_ConvertAccomRestGEForMBR Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_ConvertAccomRestGEForMBR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccomRestGEForMBR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccomRestGEForMBR') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_ConvertAccomRestGEForMBR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccomRestGEForMBR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccomRestGEForMBR]
							   ,@name = N'Module' 
							   ,@value = N'Enhanced MBR Copier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccomRestGEForMBR') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_ConvertAccomRestGEForMBR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccomRestGEForMBR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccomRestGEForMBR]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccomRestGEForMBR') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_ConvertAccomRestGEForMBR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccomRestGEForMBR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017