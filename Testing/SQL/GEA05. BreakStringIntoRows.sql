-- =============================================
-- Author: Mark Birch
-- Script Name: BreakStringIntoRows.sql
-- Create date: 27-APR-2016
-- Description:	Create BreakStringIntoRows
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 1
-- Date: 27/04/2016
-- =============================================
-- Changes: 27/04/2016: MCB: 
-- =============================================
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[BreakStringIntoRows]') and xtype in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[BreakStringIntoRows]
END
GO

CREATE FUNCTION dbo.BreakStringIntoRows (@CommadelimitedString   varchar(1000))
RETURNS   @Result TABLE (Column1   VARCHAR(100))
AS
BEGIN
        DECLARE @IntLocation INT
        WHILE (CHARINDEX(',',    @CommadelimitedString, 0) > 0)
        BEGIN
              SET @IntLocation =   CHARINDEX(',',    @CommadelimitedString, 0)      
              INSERT INTO   @Result (Column1)
              --LTRIM and RTRIM to ensure blank spaces are   removed
              SELECT RTRIM(LTRIM(SUBSTRING(@CommadelimitedString,   0, @IntLocation)))   
              SET @CommadelimitedString = STUFF(@CommadelimitedString,   1, @IntLocation,   '') 
        END
        INSERT INTO   @Result (Column1)
        SELECT RTRIM(LTRIM(@CommadelimitedString))--LTRIM and RTRIM to ensure blank spaces are removed
        RETURN 
END
GO

