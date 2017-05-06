--===================================================================--


/****** Object:  StoredProcedure [dbo].[usp_getFIExportForOneTransaction2]    Script Date: 27/09/2016 00:59:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 3rd October 2012
-- Description:	Collates all the rows for one Foltran Row and collects them as a string (CR,LF separated)
-- Purpose:		Created from usp_getFIExportForOneTransaction to work with HALSUM and to allow for modification
--				No longer used(?) since consolidation of major procs
-- Changes:		PLG Dimensions to Finance
-- =============================================
ALTER PROCEDURE [dbo].[usp_getFIExportForOneTransaction2]
	-- Add the parameters for the stored procedure here
	@MOdule Varchar(50),
	@MUMode VARCHAR(10),
	@ID Varchar(15), 
	@OutputStringT nVarchar(MAX) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @LineID Int
	declare @outputString1 nVarchar(4000)
	declare @param nVarchar (255)
	declare @SQLVar nvarchar(4000)

SET CONCAT_NULL_YIELDS_NULL OFF
	
IF @MUMode = 'HALSUM'
BEGIN
PRINT '@ID'
PRINT @ID

	declare ExportCursor_HALSUM Cursor Fast_forward for Select ID from FI_Export_Finance_HALSUM WHERE [ID] = @ID order by id
	 
   -- Insert statements for procedure here
	OPEN ExportCursor_HALSUM
	set @OutputStringT = ''
	Fetch Next from ExportCursor_HALSUM into @LineID
	While @@FETCH_STATUS <> -1 begin
		set @SQLVar = 'usp_getFIExportRowAsString2 ' + @Module +','+ @MUMode + ', @RowNo, @OutputString OUTPUT'
		Set @Param = '@RowNo Int, @OutputString nVarchar(4000) OUTPUT'
		exec sp_executeSQL @SQLVAr, @Params=@Param,@RowNo=@LineID, @OutputString=@OutputString1 OUTPUT
		 
		set @OutputStringT = @OutputStringT + @outputString1 --+ Char(13) + Char(10)
		PRINT '@@outputString1'
		PRINT @outputString1
		
		Fetch Next from ExportCursor_HALSUM into @LineID

	end

	close ExportCursor_HALSUM
	deallocate ExportCursor_HALSUM
END	

IF @MUMode = 'HAL'
BEGIN
PRINT '@ID'
PRINT @ID

	declare ExportCursor_HAL Cursor Fast_forward for Select ID from FI_Export_HAL WHERE F_Tranno = @ID order by id
	 
   -- Insert statements for procedure here
	OPEN ExportCursor_HAL
	set @OutputStringT = ''
	Fetch Next from ExportCursor_HAL into @LineID
	While @@FETCH_STATUS <> -1 begin
		set @SQLVar = 'usp_getFIExportRowAsString ' + @MUMode + ', @RowNo, @OutputString OUTPUT'
		Set @Param = '@RowNo Int, @OutputString nVarchar(4000) OUTPUT'
		exec sp_executeSQL @SQLVAr, @Params=@Param,@RowNo=@LineID, @OutputString=@OutputString1 OUTPUT
		 
		set @OutputStringT = @OutputStringT + @outputString1 + Char(13) + Char(10)
		PRINT '@@outputString1'
		PRINT @outputString1
		
		Fetch Next from ExportCursor_HAL into @LineID

	end

	close ExportCursor_HAL
	deallocate ExportCursor_HAL
END	

IF @MUMode = 'GNT'
BEGIN
	declare ExportCursor_GNT Cursor Fast_forward for Select ID from FI_Export_GNT WHERE F_Tranno = @ID order by id
	 
    -- Insert statements for procedure here
	OPEN ExportCursor_GNT
	set @OutputStringT = ''
	Fetch Next from ExportCursor_GNT into @LineID
	While @@FETCH_STATUS <> -1 begin
		set @SQLVar = 'usp_getFIExportRowAsString ' + @MUMode + ', @RowNo, @OutputString OUTPUT'
		Set @Param = '@RowNo Int, @OutputString nVarchar(4000) OUTPUT'
		exec sp_executeSQL @SQLVAr, @Params=@Param,@RowNo=@LineID, @OutputString=@OutputString1 OUTPUT
		 
		set @OutputStringT = @OutputStringT + @outputString1 + Char(13) + Char(10)

		Fetch Next from ExportCursor_GNT into @LineID

	end
  PRINT @OutputStringT
	close ExportCursor_GNT
	deallocate ExportCursor_GNT
END	

	SET CONCAT_NULL_YIELDS_NULL ON

	SELECT @OutputStringT
	

END


