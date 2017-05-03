if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_GET_NEXT_GE_CONVERT_NUM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [CABS_GET_NEXT_GE_CONVERT_NUM]
END
GO

CREATE PROCEDURE [dbo].[CABS_GET_NEXT_GE_CONVERT_NUM](@TYPE VARCHAR(10), @NEXT_NUM INT OUTPUT) 
AS
BEGIN
-- =============================================
-- Author: Mark Birch
-- Script Name: CABS_GET_NEXT_GE_CONVERT_NUM
-- Create date: 27-APR-2016
-- Description:	To get next number for GE Import 
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 2
-- Date: 16/08/2016
-- =============================================
-- Changes: 16/08/2016: MCB: Added GE_ARUN_ID and GE_RRUN_ID get
--			21/04/2017: PLG: Changed to use sys.objects
-- =============================================
SET NOCOUNT ON;

	IF (SELECT COUNT(*) FROM SYS.OBJECTS WHERE object_id = OBJECT_ID(N'[GEImportData_ID]')) = 1
	BEGIN
		IF @TYPE = 'A' BEGIN --Accommodation	
			SET @NEXT_NUM = (SELECT COALESCE(GE_ACCOM_ID, 0) FROM GEImportData_ID)

			UPDATE GEImportData_ID
			SET GE_ACCOM_ID = (@NEXT_NUM + 1)
		END

		IF @TYPE = 'R' BEGIN --Restaurant	
			SET @NEXT_NUM = (SELECT COALESCE(GE_REST_ID, 0) FROM GEImportData_ID)

			UPDATE GEImportData_ID
			SET GE_REST_ID = (@NEXT_NUM + 1)
		END

		IF @TYPE = 'AX' BEGIN --Accom Run	
			SET @NEXT_NUM = (SELECT COALESCE(GE_ARUN_ID, 0) FROM GEImportData_ID)

			UPDATE GEImportData_ID
			SET GE_ARUN_ID = (@NEXT_NUM + 1)
		END

		IF @TYPE = 'RX' BEGIN --Rest Run	
			SET @NEXT_NUM = (SELECT COALESCE(GE_RRUN_ID, 0) FROM GEImportData_ID)

			UPDATE GEImportData_ID
			SET GE_RRUN_ID = (@NEXT_NUM + 1)
		END

	END
END
GO


