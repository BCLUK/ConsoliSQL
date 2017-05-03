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
	@ConvertedRestaurantCount INT OUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Continue INT
	SET @Continue = 0

	--Gather Data
	IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_GERestDataForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 1 BEGIN
		EXEC usp_GERestDataForMBR @MbrSysNo
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
			EXEC usp_CABS_REST_BOOK_GE_ForMBR @MbrSysNo, @ClassCodes, @ConvertedRestaurantCount OUT
			SET @Continue = 1
		END
		ELSE
		IF (select COUNT(*) from dbo.sysobjects where id = object_id(N'[usp_CABS_REST_BOOK_GE_ForMBR]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) = 0 BEGIN	
			PRINT 'Not all Stored Procedures are present'
			RETURN
		END
	END
END
GO


