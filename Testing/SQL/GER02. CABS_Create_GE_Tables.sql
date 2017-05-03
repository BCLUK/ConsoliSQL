if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_Create_GE_Tables]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [CABS_Create_GE_Tables]
END
GO

CREATE PROCEDURE [CABS_Create_GE_Tables]
AS
BEGIN
	-- =============================================
	-- Author: Mark Birch
	-- Script Name: Create Tables for 
	-- Create date: 27-APR-2016
	-- Description:	To get next number for GE Import 
	-- =============================================
	-- Usage : Run through SQL Query Analyser
	-- Error Handling : None Expected
	-- =============================================
	-- Version: 3
	-- Date: 16/08/2016
	-- =============================================
	-- Changes: 10/05/2016: MCB: Added GERestData_Detail Table  
	-- Changes: 10/05/2016: MCB: Added GERestData_Full Table
	-- Changes: 16/08/2016: MCB: Added RUN_ID INT NULL, RUN_DATE DATETIME NULL
	-- =============================================
	IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GEAccommData_Detail]')) = 0
	BEGIN
		CREATE TABLE GEAccommData_Detail
		(
			AI_PRIKEY VARCHAR(10) NULL,
			AI_FREF VARCHAR(7) NULL,
			AI_CODE VARCHAR(6) NULL,
			AI_COVERS DECIMAL (10, 4) NULL,
			AI_GEDATE DATETIME NULL,
			LINK_ID INT
		)
	END

	IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GEAccommData_Full]')) = 0
	BEGIN
		CREATE TABLE GEAccommData_Full
		(
			ID INT NULL,
			AI_PRIKEY VARCHAR(10) NULL,
			AI_FREF VARCHAR(7) NULL,
			AI_CODE VARCHAR(6) NULL,
			AI_COVERS DECIMAL (10, 4) NULL,
			AI_GEDATE DATETIME NULL,
			AI_GEDATE2 DATETIME NULL,
			AI_CODE_SELECTION VARCHAR(100) NULL,
			AI_CODE_BOOKED VARCHAR(6) NULL,
			BLOCK_NO VARCHAR(7) NULL,
			FOLIO_NO VARCHAR(7) NULL,
			AI_COVERS_START DECIMAL (10, 4) NULL,
			ID_START INT NULL,
			Processed INT,
			Success INT,
			RUN_ID INT NULL,
			RUN_DATE DATETIME NULL
		)
	END

	IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GERestData_Detail]')) = 0
	BEGIN
		CREATE TABLE GERestData_Detail
		(
			AI_PRIKEY VARCHAR(10) NULL,
			AI_FREF VARCHAR(7) NULL,
			AI_CODE VARCHAR(6) NULL,
			AI_COVERS DECIMAL (10, 4) NULL,
			AI_GEDATE DATETIME NULL,
			AI_TIME VARCHAR(5) NULL, 
			AI_ENDTIME VARCHAR(5) NULL, 
			LINK_ID INT
		)
	END

	IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GERestData_Full]')) = 0
	BEGIN
		CREATE TABLE GERestData_Full
		(
			ID INT NULL,
			AI_PRIKEY VARCHAR(10) NULL,
			AI_FREF VARCHAR(7) NULL,
			AI_CODE VARCHAR(6) NULL,
			AI_COVERS DECIMAL (10, 4) NULL,
			AI_GEDATE DATETIME NULL,
			AI_TIME VARCHAR(5) NULL, 
			AI_ENDTIME VARCHAR(5) NULL, 
			AI_CODE_SELECTION VARCHAR(100) NULL,
			FUNC_NO VARCHAR(7) NULL,
			Processed INT,
			Success INT,
			RUN_ID INT NULL,
			RUN_DATE DATETIME NULL
		)
	END

END
GO



