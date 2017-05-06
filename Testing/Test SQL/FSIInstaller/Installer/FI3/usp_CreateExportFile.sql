/****** Object:  StoredProcedure [dbo].[usp_CreateExportFile]    Script Date: 31/01/2017 16:33:31 ******/
if exists(select Object_id from sys.objects where name = N'usp_CreateExportFile') begin
	DROP PROCEDURE [dbo].[usp_CreateExportFile]
end
GO

/****** Object:  StoredProcedure [dbo].[usp_CreateExportFile]    Script Date: 31/01/2017 16:33:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:           Peter Green
-- Create date: 18th Jul 2013
-- Description:      Acts as a switch between the (two) sprocs _HAL and _GNT
--                         Requires
--  Added Batch number control, Archiving of FI_Export and Creation of clean FI_Export Table
--  Added filter on records selected
--  Changes: 07-OCT-2013: See Notes 
--  Changes: 05-DEC-2013: See Notes 
--  Changes: 01-JAN-2016: Added options f0r GNTSUM
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateExportFile]
       -- Add the parameters for the stored procedure here
       @LAST_DATE DATETIME, @UP_UNTIL_DATE DATETIME, @Module VARCHAR(50), @Sub_Module VARCHAR(50), @Internal int, @Transferred int
AS
BEGIN --SPROC BEGINS
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;
/****************************************************************************************************************************
CABS CONFIGURATION - GENERIC
****************************************************************************************************************************/
--OBJECT HEADER
-- =============================================
-- MCB: REMOVED: 07-OCT-2013: NOT REQUIRED(?)
-- =============================================
     --DECLARE @SP_TRG VARCHAR(100)
     --SET @SP_TRG = 'usp_CreateExportFile' --The Object Name
-- =============================================
-- MCB: ADDED: 07-OCT-2013: GNT/HAL DECLARATIONS
-- =============================================
	DECLARE @GNT_ENABLED INT
	DECLARE @HAL_ENABLED INT
	DECLARE @HALSUM_ENABLED INT
	DECLARE @GNTSUM_ENABLED INT
	DECLARE @GNT_SPROC VARCHAR(100)
	DECLARE @HAL_SPROC VARCHAR(100)	
	DECLARE @HALSUM_SPROC VARCHAR(100)	
	DECLARE @GNTSUM_SPROC VARCHAR(100)	
-- =============================================
	SET @GNT_SPROC = 'usp_CreateExportFile_GNT'
	SET @HAL_SPROC = 'usp_CreateExportFile_HAL'
	SET @HALSUM_SPROC = 'usp_CreateExportFile_HALSUM'
	SET @GNTSUM_SPROC = 'usp_CreateExportFile_GNTSUM'
-- =============================================	
-- =============================================
-- MCB: ADDED: 07-OCT-2013: GET SPROC ENABLED FLAG 
-- =============================================
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @GNT_SPROC AND [KEY] = 'Enabled') > 0
	BEGIN
		SET @GNT_ENABLED = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @GNT_SPROC AND [KEY] = 'Enabled')
	END	

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @HAL_SPROC AND [KEY] = 'Enabled') > 0
	BEGIN
		SET @HAL_ENABLED = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @HAL_SPROC AND [KEY] = 'Enabled')
	END

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @HALSUM_SPROC AND [KEY] = 'Enabled') > 0
	BEGIN
		SET @HALSUM_ENABLED = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @HALSUM_SPROC AND [KEY] = 'Enabled')
	END
				
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @GNTSUM_SPROC AND [KEY] = 'Enabled') > 0
	BEGIN
		SET @GNTSUM_ENABLED = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @GNTSUM_SPROC AND [KEY] = 'Enabled')
	END

	DECLARE @MUMode Varchar(10)
    DECLARE @ModuleCount Int
    if (Select Count(MUMode) from FI_Header where Module = @Module and SubModule = @Sub_Module and Direction = 'OUT') > 0 begin --Header Exists
		SET @MUMOde = (SELECT TOP 1 MUMode from FI_Header where Module = @Module and SubModule = @Sub_Module and Direction = 'OUT')
-- =============================================
-- MCB: ADDED: 07-OCT-2013: GNT PROCESSING
-- =============================================
		if @MUMode = 'GNT' BEGIN --GNT SELECTED
			IF @GNT_ENABLED = 1 BEGIN --GNT ENABLED
				exec usp_CreateExportFile_GNT @LAST_DATE, @UP_UNTIL_DATE, @Module, @Sub_Module, @Internal, @Transferred  
			END --GNT ENABLED
			ELSE
			IF @GNT_ENABLED = 0 BEGIN --GNT DISBLED
				RETURN --Do Nothing; Not enabled
			END --GNT DISBLED
		END --GNT SELECTED
-- =============================================
-- MCB: ADDED: 07-OCT-2013: HAL PROCESSING
-- =============================================			
		if @MuMode = 'HAL' BEGIN --HAL SELECTED
			IF @HAL_ENABLED = 1 BEGIN --HAL ENABLED
				exec usp_CreateExportFile_HAL @LAST_DATE, @UP_UNTIL_DATE, @Module, @Sub_Module, @Internal, @Transferred
			END --HAL ENABLED
			ELSE
			IF @HAL_ENABLED = 1 BEGIN --HAL DISABLED
				RETURN
			END --HAL DISABLED
		END --HAL SELECTED	
-- =============================================
-- MCB: ADDED: 05-DEC-2013: HALSUM PROCESSING
-- =============================================			
		if @MuMode = 'HALSUM' BEGIN --HAL SELECTED
			IF @HALSUM_ENABLED = 1 BEGIN --HAL ENABLED
				exec usp_CreateExportFile_HALSUM @LAST_DATE, @UP_UNTIL_DATE, @Module, @Sub_Module, @Internal, @Transferred
			END --HALSUM ENABLED
			ELSE
			IF @HALSUM_ENABLED = 1 BEGIN --HAL DISABLED
				RETURN
			END --HALSUM DISABLED
		END --HALSUM SELECTED	
				
		if @MuMode = 'GNTSUM' BEGIN --HAL SELECTED
			IF @GNTSUM_ENABLED = 1 BEGIN --HAL ENABLED
				exec usp_CreateExportFile_GNTSUM @LAST_DATE, @UP_UNTIL_DATE, @Module, @Sub_Module, @Internal, @Transferred
			END --HALSUM ENABLED
			ELSE
			IF @GNTSUM_ENABLED = 1 BEGIN --HAL DISABLED
				RETURN
			END --HALSUM DISABLED
		END --HALSUM SELECTED	
    END --Header Exists
END --SPROC ENDS

GO


