-- =============================================
-- Author: Mark Birch
-- Script Name: GEImportData_ID.sql
-- Create date: 27-APR-2016
-- Description:	Create and populate next number table for import
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 1
-- Date: dd/mm/yyyy
-- =============================================
-- Changes: dd/mm/yyyy: XXX: 
-- =============================================
IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GEImportData_ID]')) = 0
BEGIN
CREATE TABLE GEImportData_ID
(
	GE_ACCOM_ID INT NULL,
	GE_REST_ID INT NULL,
	GE_ARUN_ID INT NULL,
	GE_RRUN_ID INT NULL 
)
END

IF (SELECT COUNT(*) FROM dbo.sysobjects where id = object_id(N'[GEImportData_ID]')) = 1
BEGIN
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'GE_ARUN_ID'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GEImportData_ID') = 0
	BEGIN
		ALTER TABLE GEImportData_ID ADD GE_ARUN_ID INT
	END
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'GE_RRUN_ID'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GEImportData_ID') = 0
	BEGIN
		ALTER TABLE GEImportData_ID ADD GE_RRUN_ID INT
	END
END
GO

IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[GEImportData_ID]')) = 1
BEGIN
	IF (SELECT COUNT(*) FROM GEImportData_ID) = 0 
	BEGIN
		INSERT INTO GEImportData_ID
		SELECT 1, 1, 2, 2
	END
END
GO

UPDATE GEImportData_ID SET GE_RRUN_ID = 2
		WHERE COALESCE(GE_RRUN_ID, 0) = 0
UPDATE GEImportData_ID SET GE_ARUN_ID = 2
		WHERE COALESCE(GE_ARUN_ID, 0) = 0
