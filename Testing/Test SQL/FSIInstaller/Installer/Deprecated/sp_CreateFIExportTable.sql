If exists(select OBJECT_ID from sys.objects where name = N'sp_CreateFIExportTable') begin
	DROP PROCEDURE sp_CreateFIExportTable
end
go
/****** Object:  StoredProcedure [dbo].[sp_CreateFIExportTable]    Script Date: 19/03/2016 16:30:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green	
-- Create date: 23rd Sept 2012
-- Description:	Creates the FI Export Table(s) for use in other stored procs
--		18 Jul 2013 Modified to pass an extension to enable multiple tables to be created when using different export types
--		30 nOV 2016 Amended to be drop and create
--					Changed size of extension
-- =============================================
CREATE PROCEDURE [dbo].[sp_CreateFIExportTable]
	-- Add the parameters for the stored procedure here
	@Extension Varchar(100) = ''
	
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
	
	SET @SQLCreate = 'CREATE TABLE dbo.FI_Export_' +@Extension + ' ( ID Int Identity, '
	
	DECLARE @MIN_HEAD_ID INT
	SET @MIN_HEAD_ID = (SELECT MIN(FI_Header_ID) FROM FI_Template)

	Declare CursorFI_Template Cursor Fast_forward for Select [Name],[StartPos],[EndPos] from FI_Template where FI_Header_ID = @MIN_HEAD_ID	Order By StartPos 
	Open CursorFI_template

	Fetch Next from CursorFI_template into @FieldName, @StartPos, @EndPos
	
	While (@@FETCH_STATUS <> -1) begin 
		SET @FieldLength = @EndPos - @StartPos + 1
		Set @FieldType = 'Varchar(' + Convert(Varchar(4),@FieldLength) + ')'
		Set @SQLCREATE = @SQLCreate + ' ' + @FieldNAme + ' ' + @FieldType + ','
	
		Fetch Next from CursorFI_template into @FieldName, @StartPos, @EndPos
	
	End
	
	Close CursorFI_template
	
	Deallocate CursorFI_template
	
	-- Now add checkfields
	Set @SQLCREATE = @SQLCreate + ' Exported Int,  ExportedDate Datetime, F_Tranno Varchar(10), Batch_No Varchar(20) )   ';
	
	EXECUTE (@SQLCreate)

    -- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
END

GO


