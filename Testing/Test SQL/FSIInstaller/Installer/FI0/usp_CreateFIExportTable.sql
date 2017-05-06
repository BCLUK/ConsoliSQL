IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'usp_CreateFIExportTable') begin
	Drop Procedure usp_CreateFIExportTable
END
Go

/****** Object:  StoredProcedure [dbo].[usp_CreateFIExportTable]    Script Date: 20/09/2016 09:20:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green	
-- Create date: 23rd Sept 2012
-- Description:	Creates the FI Export Table(s) for use in other stored procs
--		18 Jul 2013 Modified to pass an extension to enable multiple tables to be created when using different export types
--	     5 Dec 2013 Renamed to usp_ from sp_ to prevent errors with old programs
--                  Changed to allow module and mode to be passed with larger parameters
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateFIExportTable]
	-- Add the parameters for the stored procedure here
	@Module    Varchar(50),
	@Extension Varchar(10) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLCreate Varchar(8000)
	DECLARE @FieldName Varchar(50)
    DECLARE @FieldType VarChar(50)
    DECLARE @StartPos Int
    DECLARE @EndPos Int
	DECLARE @FieldLength Int
	DECLARE @SQLAlter Varchar(8000)
	SET @SQLAlter = ''
	--SET @SQLCreate = 'CREATE TABLE dbo.FI_Export_' +@Extension + ' ( ID Int Identity, '
	--  **** look at putting an if exists clause in here and doing a rename
	SET @SQLCreate = 'CREATE TABLE dbo.FI_Export_' + @Module + '_' + @Extension + ' ( ID Int Identity )'  -- changed 5 12 13 plg
	EXECUTE (@SQLCreate)
	
	DECLARE @MIN_HEAD_ID INT
	SET @MIN_HEAD_ID = (SELECT TOP 1 ID FROM FI_HEADER WHERE Module = @Module and MUMode = @Extension)  -- changed 5 12 13 plg

	Declare CursorFI_Template Cursor Fast_forward for Select [Name],[StartPos],[EndPos] from FI_Template where FI_Header_ID = @MIN_HEAD_ID	Order By StartPos 
	Open CursorFI_template

	Fetch Next from CursorFI_template into @FieldName, @StartPos, @EndPos
	
	While (@@FETCH_STATUS <> -1) begin 
		Set @SQLAlter = ''
		SET @FieldLength = @EndPos - @StartPos + 1
		Set @FieldType = 'char(' + Convert(Varchar(4),@FieldLength) + ')'
		if @Module = 'Dimensions' 		Set @FieldType = 'Varchar(' + Convert(Varchar(4),@FieldLength) + ')'
		--Set @SQLCREATE = @SQLCreate + ' ' + @FieldNAme + ' ' + @FieldType + ','
		--Set @SQLAlter = @SQLAlter + ' ' + @FieldNAme + ' ' + @FieldType + ','
		Set @SQLAlter = @SQLAlter + ' ' + 'ALTER TABLE FI_Export_' + @Module +'_' +@Extension + ' ADD ' + @FieldNAme + ' ' + @FieldType
		
		EXECUTE (@SQLAlter)
		
		Fetch Next from CursorFI_template into @FieldName, @StartPos, @EndPos
	
	End
	
	Close CursorFI_template
	
	Deallocate CursorFI_template
	
	-- Now add checkfields
	--Set @SQLCREATE = @SQLCreate + ' Exported Int,  ExportedDate Datetime, F_Tranno Varchar(10), Batch_No Varchar(20) )   ';
	
--	Set @SQLAlter = ' Exported Int,  ExportedDate Datetime, F_Tranno Varchar(10), Batch_No Varchar(20) )   ';
	Set @SQLAlter = 'ALTER TABLE FI_Export_' + @Module + '_' + @Extension + ' ADD Exported Int,  ExportedDate Datetime, F_Tranno Varchar(10), Batch_No Varchar(20)'   -- changed 5 12 13 plg
	EXECUTE (@SQLAlter)

    -- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
END

GO

