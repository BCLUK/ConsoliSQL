IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_GERestDataForMBR]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_GERestDataForMBR]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author: Mark Birch
-- Script Name: usp_GERestData.sql
-- Create date: 10-MAY-2016
-- Description:	Gather Data for Global Extras Transfer (Rest)
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 2
-- Date: 16/08/2016
-- =============================================
-- Changes: 16/08/2016: MCB: Added RUN_ID and RUN_DATE
-- Changes: 16/08/2016: MCB: Added Check for present/future dates only
-- =============================================
CREATE PROCEDURE [dbo].[usp_GERestDataForMBR]
	@MbrSysNo VARCHAR(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ID INT
	DECLARE @SettingsType VARCHAR(10), @SP_TRG VARCHAR(100), @CodesToInclude VARCHAR(1000)
	SET @SettingsType = 'S'
	SET @SP_TRG = 'GlobalExtras_RestCodes'
	SET @CodesToInclude = (SELECT COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'Include')), 'AllCodes'))

	EXEC CABS_Create_GE_Tables

	DECLARE @RUN_ID INT, @RUN_DATE DATETIME 
	
	EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'RX', @RUN_ID OUTPUT
	SET @RUN_DATE = GETDATE()

	CREATE TABLE 
	#CodesToInclude
	(
		CTI_CODE VARCHAR(6)
	)

	CREATE TABLE
	#GERestData
	(
		AI_PRIKEY VARCHAR(10) NULL,
		AI_FREF VARCHAR(7) NULL,
		AI_CODE VARCHAR(6) NULL,
		AI_COVERS DECIMAL (10, 4) NULL,
		AI_GEDATE DATETIME NULL,
		AI_TIME VARCHAR(5) NULL, 
		AI_ENDTIME VARCHAR(5) NULL, 
		Processed INT,
		LINK_ID INT
	)

	CREATE TABLE
	#GERestData_Grouped
	(
		ID INT NULL,
		AI_PRIKEY VARCHAR(10) NULL,
		AI_FREF VARCHAR(7) NULL,
		AI_CODE VARCHAR(6) NULL,
		AI_COVERS DECIMAL (10, 4) NULL,
		AI_GEDATE DATETIME NULL,
		AI_TIME VARCHAR(5) NULL, 
		AI_ENDTIME VARCHAR(5) NULL, 		
		Processed INT
	)

	IF @CodesToInclude = 'AllCodes' BEGIN
		INSERT INTO #CodesToInclude
		SELECT DISTINCT(COALESCE(AI_CODE, '')) FROM AI_FILE WHERE LEFT(AI_FREF, 1) = 'M'
	END
	ELSE
	IF @CodesToInclude <> 'AllCodes' BEGIN
		INSERT INTO #CodesToInclude
		SELECT * FROM [dbo].[BreakStringIntoRows] (@CodesToInclude) 
	END

	INSERT INTO #GERestData
	SELECT
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		AI_TIME, 
		AI_ENDTIME, 
		0,
		0
	FROM AI_FILE
	--WHERE LEFT(AI_FREF, 1) = 'M'
	WHERE AI_FREF = @MbrSysNo
	AND AI_CODE COLLATE database_default IN(SELECT CTI_CODE FROM #CodesToInclude)
	AND NOT AI_PRIKEY IN(SELECT COALESCE(AI_PRIKEY, '') FROM GERestData_Detail)	
	AND AI_GEDATE >= CONVERT(DATETIME, (CONVERT(VARCHAR(11), (GETDATE()), 20)), 20)
	ORDER BY AI_FREF, AI_GEDATE, AI_CODE

	DECLARE
		@AI_PRIKEY VARCHAR(10),
		@AI_FREF VARCHAR(7),
		@AI_CODE VARCHAR(6),
		@AI_COVERS DECIMAL (10, 2),
		@AI_GEDATE DATETIME,
		@AI_TIME VARCHAR(5), 
		@AI_ENDTIME VARCHAR(5)

	DECLARE
		RestData_Cur
	CURSOR FAST_FORWARD for
		
		SELECT 	
			AI_PRIKEY,
			AI_FREF,
			AI_CODE,
			AI_COVERS,
			AI_GEDATE,
			AI_TIME, 
			AI_ENDTIME
		FROM #GERestData
		WHERE Processed = 0  
		
	OPEN RestData_Cur

	FETCH NEXT FROM
		RestData_Cur
	INTO
		@AI_PRIKEY,
		@AI_FREF,
		@AI_CODE,
		@AI_COVERS,
		@AI_GEDATE,
		@AI_TIME, 
		@AI_ENDTIME

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		UPDATE #GERestData
		SET Processed = 1
		WHERE AI_PRIKEY = @AI_PRIKEY

		EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'R', @ID OUTPUT

		INSERT INTO #GERestData_Grouped
		(ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_TIME, AI_ENDTIME, Processed)
		VALUES
		(@ID, @AI_PRIKEY, @AI_FREF, @AI_CODE, @AI_COVERS, @AI_GEDATE, @AI_TIME, @AI_ENDTIME, 0)
					
		FETCH NEXT FROM 
			RestData_Cur
		INTO
			@AI_PRIKEY,
			@AI_FREF,
			@AI_CODE,
			@AI_COVERS,
			@AI_GEDATE,
			@AI_TIME, 
			@AI_ENDTIME
	END

	CLOSE RestData_Cur
	DEALLOCATE RestData_Cur

	UPDATE #GERestData
	SET LINK_ID = ID
	FROM #GERestData_Grouped
	WHERE #GERestData_Grouped.AI_PRIKEY = #GERestData.AI_PRIKEY

	INSERT INTO GERestData_Detail
	SELECT
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		AI_TIME, 
		AI_ENDTIME,
		LINK_ID
	FROM #GERestData

	INSERT INTO GERestData_Full
	SELECT
		ID, 
		AI_PRIKEY,
		AI_FREF,
		AI_CODE,
		AI_COVERS,
		AI_GEDATE,
		AI_TIME, 
		AI_ENDTIME,
		(SELECT COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, AI_CODE)), 'N/A')),
		'',
		0,
		0,
		@RUN_ID,
		@RUN_DATE
	FROM #GERestData_Grouped

	RETURN

END

GO


