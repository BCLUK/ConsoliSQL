
-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_GEAccommDataForMBR]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_GEAccommDataForMBR]	
	PRINT 'usp_GEAccommDataForMBR: Dropped Procedure usp_GEAccommDataForMBR'
END
ELSE
BEGIN	
	PRINT 'usp_GEAccommDataForMBR: usp_GEAccommDataForMBR -  Does Not Already Exist !'
END

PRINT 'usp_GEAccommDataForMBR: Creating Procedure usp_GEAccommDataForMBR'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	21/04/2017
-- Description:	Step in process of converting global extras to accomodation bookings for a single MBR
-- Product:		CABS
-- Module:		MBRCopier
-- Parameters:	MBRSysNo
-- Returns:		Insert Data Type
-- Switches:	GlobalExtras_AccomCodes	Include
-- Test:		Insert How to Test
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		21/04/2017
-- ====================================================================================================================
-- Changes (1.0): PLG: 21/04/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_GEAccommDataForMBR 
	-- Add the parameters for the stored procedure here
	@MBRSysNo Varchar(10) = '',
	@RunDate DATETIME,
	@RunId INT OUT
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	
	-- Insert statements for procedure here
	
	DECLARE @ID INT
	DECLARE @SettingsType VARCHAR(10), @SP_TRG VARCHAR(100), @CodesToInclude VARCHAR(1000)
	SET @SettingsType = 'S'
	SET @SP_TRG = 'GlobalExtras_AccomCodes'
	SET @CodesToInclude = (SELECT COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Include')), 'AllCodes'))
	-- plg this setting determines which codes are to be converted

	EXEC CABS_Create_GE_Tables

	CREATE TABLE 
	#CodesToInclude
	(
		CTI_CODE VARCHAR(6)
	)

	CREATE TABLE
	#GEAccommData
	(
		AI_PRIKEY VARCHAR(10) NULL,
		AI_FREF VARCHAR(7) NULL,
		AI_CODE VARCHAR(6) NULL,
		AI_COVERS DECIMAL (10, 4) NULL,
		AI_GEDATE DATETIME NULL,
		Processed INT,
		LINK_ID INT
	)

	CREATE TABLE
	#GEAccommData_Grouped
	(
		ID INT NULL,
		AI_PRIKEY VARCHAR(10) NULL,
		AI_FREF VARCHAR(7) NULL,
		AI_CODE VARCHAR(6) NULL,
		AI_COVERS DECIMAL (10, 4) NULL,
		AI_GEDATE DATETIME NULL,
		AI_GEDATE2 DATETIME NULL,
		Processed INT
	)

	IF @CodesToInclude = 'AllCodes' BEGIN
		INSERT INTO #CodesToInclude
		SELECT DISTINCT(COALESCE(AI_CODE, '')) FROM AI_FILE WHERE LEFT(AI_FREF, 1) = 'M'
		-- this is potentialy dangerous so we should ensure that settings are put in or change the default to 'NONE'
	END
	ELSE
	IF @CodesToInclude <> 'AllCodes' BEGIN
		INSERT INTO #CodesToInclude
		SELECT * FROM [dbo].[BreakStringIntoRows] (@CodesToInclude) 
	END

	INSERT INTO #GEAccommData
	SELECT
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		0,
		0
	FROM AI_FILE
--	WHERE LEFT(AI_FREF, 1) = 'M'
	WHERE AI_FREF = @MBRSysNo
	AND AI_CODE COLLATE database_default IN(SELECT CTI_CODE FROM #CodesToInclude)
	AND NOT AI_PRIKEY IN(SELECT COALESCE(AI_PRIKEY, '') FROM GEAccommData_Detail)	
	ORDER BY AI_FREF, AI_GEDATE, AI_CODE

	DECLARE
		@AI_PRIKEY VARCHAR(10),
		@AI_FREF VARCHAR(7),
		@AI_CODE VARCHAR(6),
		@AI_COVERS DECIMAL (10, 2),
		@AI_GEDATE DATETIME

	DECLARE
		AccommData_Cur
	CURSOR FAST_FORWARD for
		
		SELECT 	
			AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE
		FROM #GEAccommData
		WHERE Processed = 0  -- only get those not processed
		order by AI_GEDATE -- PLG order by clause added because later we rely on the fact that the first one we get is the earliest!
		
	OPEN AccommData_Cur

	FETCH NEXT FROM
		AccommData_Cur
	INTO
		@AI_PRIKEY, @AI_FREF, @AI_CODE, @AI_COVERS, @AI_GEDATE

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @ToDate DATETIME,
		@Count INT

		SET @Count = (SELECT COUNT(*) FROM AI_FILE WHERE AI_FREF = @AI_FREF AND AI_CODE = @AI_CODE)
		SET @ToDate = DATEADD (day, 1, @AI_GEDATE)
		
		UPDATE #GEAccommData
		SET Processed = 1  
		WHERE AI_PRIKEY = @AI_PRIKEY -- set this one to processed and then get related ones
		
		UPDATE #GEAccommData
		SET Processed = 3
		WHERE AI_FREF = @AI_FREF AND AI_CODE = @AI_CODE AND Processed = 0
		
		IF @Count > 1 BEGIN						
			SET @ToDate = (SELECT MAX(AI_GEDATE) FROM #GEAccommData WHERE AI_FREF = @AI_FREF AND AI_CODE = @AI_CODE AND Processed = 3)
		END	

		EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'A', @ID OUTPUT
				
		INSERT INTO #GEAccommData_Grouped
		(ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_GEDATE2, Processed)
		VALUES
		(@ID, @AI_PRIKEY, @AI_FREF, @AI_CODE, @AI_COVERS, @AI_GEDATE, @ToDate, 2)

		FETCH NEXT FROM 
			AccommData_Cur
		INTO
			@AI_PRIKEY,
			@AI_FREF,
			@AI_CODE,
			@AI_COVERS,
			@AI_GEDATE
	END

	CLOSE AccommData_Cur
	DEALLOCATE AccommData_Cur

	UPDATE #GEAccommData
	SET LINK_ID = ID
	FROM #GEAccommData_Grouped
	WHERE #GEAccommData_Grouped.AI_FREF = #GEAccommData.AI_FREF
	AND #GEAccommData_Grouped.AI_CODE = #GEAccommData.AI_CODE
	AND #GEAccommData.AI_GEDATE BETWEEN #GEAccommData_Grouped.AI_GEDATE AND #GEAccommData_Grouped.AI_GEDATE2

	INSERT INTO GEAccommData_Detail
	SELECT
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		LINK_ID
	FROM #GEAccommData

	EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'AX', @ID OUT
	SET @RunId = @ID

	INSERT INTO GEAccommData_Full
	SELECT
		ID, 
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		DATEADD (DAY, 1, AI_GEDATE),
		(SELECT COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, AI_CODE)), 'N/A')),
		'',
		'',
		'',
		AI_COVERS,
		ID,
		0,
		0,
		@ID,
		@RunDate
	FROM #GEAccommData_Grouped

	RETURN
	
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_GEAccommDataForMBR]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_GEAccommDataForMBR: usp_GEAccommDataForMBR Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_GEAccommDataForMBR: usp_GEAccommDataForMBR Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_GEAccommDataForMBR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_GEAccommDataForMBR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_GEAccommDataForMBR') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_GEAccommDataForMBR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_GEAccommDataForMBR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_GEAccommDataForMBR]
							   ,@name = N'Module' 
							   ,@value = N'MBRCopier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_GEAccommDataForMBR') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_GEAccommDataForMBR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_GEAccommDataForMBR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_GEAccommDataForMBR]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_GEAccommDataForMBR') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_GEAccommDataForMBR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_GEAccommDataForMBR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017