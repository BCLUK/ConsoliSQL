if exists (select * from dbo.sysobjects where id = object_id(N'[usp_CABS_ConvertGE_Rest_ForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [usp_CABS_ConvertGE_Rest_ForMBR] 
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Mark Birch
-- Script Name: CABS_ConvertGE_Rest.sql
-- Create date: 11-MAY-2016
-- Description:	Run Procedures
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 1
-- Date: 11/05/2016
-- =============================================
-- Changes: dd/mm/yyyy: XXX: 
-- =============================================
CREATE PROCEDURE usp_CABS_ConvertGE_Rest_ForMBR
	@MbrSysNo VARCHAR(7),
	@ClassCodes VARCHAR(MAX),
	@CompleteConversions INT OUT,
	@FailedConversions INT OUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Continue INT
	SET @Continue = 0
	
	DECLARE @RunDate DATETIME = GETDATE(),
		@RunId INT

	--Gather Data
	IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_GERestDataForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 1 BEGIN
		EXEC usp_GERestDataForMBR @MbrSysNo, @RunDate, @RunId OUT
		SET @Continue = 1
	END
	ELSE
	IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_GERestDataForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 0 BEGIN
		PRINT 'Not all Stored Procedures are present'
		RETURN
	END

	IF @Continue = 1 BEGIN 
		SET @Continue = 0
		IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_CABS_REST_BOOK_GE_ForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 1 BEGIN	
			EXEC usp_CABS_REST_BOOK_GE_ForMBR @MbrSysNo, @ClassCodes

			INSERT INTO #MBR_COPIER_OUTPUT
			SELECT MBR_SYSNO,
				MBR_CLIENT,
				MBR_CONTCT,
				@ClassCodes,
				MBR_EVENT,
				F_REF,
				CONVERT(VARCHAR(10), CASE WHEN F_REF IS NULL THEN AI_GEDATE ELSE F_DAY END, 103),
				--CASE WHEN F_REF IS NULL THEN P_DESC ELSE ST_DESC END,
				CASE WHEN F_REF IS NULL THEN P_DESC ELSE RM_NAME END,
				CASE WHEN F_REF IS NULL THEN AI_TIME ELSE F_START END,
				CASE WHEN F_REF IS NULL THEN AI_ENDTIME ELSE F_END END,
				CASE WHEN F_REF IS NULL THEN AI_COVERS ELSE F_PAX_ACT END,
				--AI_PRIKEY,
				AI_CODE,
				CASE Success WHEN 1 THEN 'Complete' ELSE 'Failed' END
			FROM GERestData_Full
			LEFT JOIN FUNC_FIL
			ON F_REF = FUNC_NO
			LEFT JOIN POST_DEF
			ON P_CODE = AI_CODE
			LEFT JOIN MBRFILE
			ON MBR_SYSNO = F_MBR_NO
			/*LEFT JOIN SYS_ABBR
			ON ST_TYPE = 'RUS'
				AND ST_CODE = F_USE*/
			LEFT JOIN ROOMS
			ON RM_ABBR = F_ROOM
			WHERE RUN_ID = @RunId

			SELECT @CompleteConversions = SUM(Success),
				@FailedConversions = SUM(CASE Success WHEN 0 THEN 1 ELSE 0 END)
			FROM GERestData_Full
			WHERE RUN_ID = @RunId
		END
		ELSE
		IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_CABS_REST_BOOK_GE_ForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 0 BEGIN	
			PRINT 'Not all Stored Procedures are present'
			RETURN
		END
	END
END
GO


