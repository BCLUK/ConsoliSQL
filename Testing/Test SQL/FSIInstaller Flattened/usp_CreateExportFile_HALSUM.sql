If exists(select OBJECT_ID from sys.objects where name = N'usp_CreateExportFile_HALSUM') begin
	Drop Procedure usp_CreateExportFile_HALSUM
end
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateExportFile_HALSUM]    Script Date: 10/11/2016 12:42:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Peter GReen
-- Create date: 4th July 2013
-- Description:	<Generates export transaction for a header and line configuration,,>
--				Headers, Footers, Item and Description lines can all be enabled or disabled
--				The default is all enabled
--				If one is to be disabled there should be a Row(s) in xCabs_Config as follows
--				Deleted = 0, Type = 'S', Section = 'usp_CreateExportFile_HALSUM', Key =<line type>, VALUE='Disabled'
--
-- Requires:	a Row in xCAbsConfig where Type = 'S' and Section = 'usp_CreateExportFile_HALSUM'
--
-- Changes:     4th December 2013 Created from usp_CreateExportFile_HAL
--                                Amendments made in line with Inner Temple requirements
--              5th December 2013
--				21st Nov 2015 created from original to reduce look ups
--				23rd Jun 2016 changed Transfrd update to ensure all are ticked 
--              30th Aug 2016 added linecount update to lines
--				28th Sept 2016 changed BatchNo references
--				10th Nov 2016 minor corrections
--				22nd Feb 2017 does tidy up before running
--				1st Mar 2017 added file extension and name length checks
--				9th Mar 2017 plg corrected suggestions from Code Guard
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateExportFile_HALSUM]
	-- Add the parameters for the stored procedure here
	@LAST_DATE DATETIME, @UP_UNTIL_DATE DATETIME, @Module VARCHAR(50), @Sub_Module VARCHAR(50), @Internal int, @Transferred int
AS
BEGIN --SPROC BEGINS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET CONCAT_NULL_YIELDS_NULL OFF
	-- if 1=1 begin
	-- create table plgtemp (last_date varchar(50), up_until varchar(50))
	-- insert into plgtemp VALUES (@last_date, @UP_UNTIL_DATE)
	--end 
	-- else begin

	--PRINT 'I AM HERE 1'
/****************************************************************************************************************************
CABS CONFIGURATION - GENERIC
****************************************************************************************************************************/
--OBJECT HEADER
--Checks that this sproc should run
	DECLARE @SP_TRG VARCHAR(100)
	DECLARE @MUMode Varchar(10)
	Set @MUMode = 'HALSUM'
	SET @SP_TRG = 'usp_CreateExportFile_HALSUM' --The Object Name

	IF not exists (SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG)  -- Object Doesn't Exist; Run As Normal
	BEGIN -- No Settings Begin
		RETURN -1
	END -- No Settings End
	ELSE
	IF exists (SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG)  -- Object Exists; Settings to Consider
	BEGIN --Settings Begin
-- =============================================
-- DECLARATIONS
-- =============================================
		DECLARE @Enabled VARCHAR(1000)

--		DECLARE @SQLServerName VARCHAR(1000)
--		DECLARE @SQLServerUser VARCHAR(1000)
--		DECLARE @SQLServerPW VARCHAR(1000)
--		DECLARE @SQLDatabaseName VARCHAR(1000)
		DECLARE @FileName VARCHAR(1000)
		DECLARE @Backslash VARCHAR(1)
		DECLARE @ExportPath VARCHAR(1000)

		Declare @FoltranID Varchar(10)
--		Declare @FIHeaderID Int
		Declare @Linetype Varchar(10)
		Declare @ItemNAme Varchar(50)
		Declare @ItemID int
		Declare @FIExportLineNo int
		Declare @SQLToDo Varchar(4000)
		Declare @ItemValue Varchar(500)
		Declare @FieldSize Int
		DECLARE @DATE_EXT VARCHAR(10)
		DECLARE @TIME_EXT VARCHAR(8)
--		DECLARE @File VARCHAR(1000)
		DECLARE @SelectFromTempFile VARCHAR(MAX)
--		DECLARE @DBAccess VARCHAR(255)
--		DECLARE @String VARCHAR(8000)
		DECLARE @BatchNumber Varchar(20)	-- added plg 8 Oct 2012
		DECLARE @NotInternal Int -- added plg to use a perverse piece of logic on Internal Selection
		-- @Internal is 0 for External, 1 for Internal, 2 for Both
		DECLARE @ThisInvNo VArchar(10) -- used for holding current invoice number to decide whether this is a new invoice
		DECLARE @LastInvNo VArchar(10) -- used for holding last invoice number to decide whether this is a new invoice
		Declare @NewInvoice Bit 
		Declare @TitlesEnabled Bit
		Declare @HeaderEnabled Bit
		Declare @ItemEnabled Bit
		Declare @DescEnabled Bit
		Declare @FooterEnabled Bit
		Declare @Decider Varchar(50)  -- used for bringing text fields and then using them temporarily fo switching
		Declare @InitialValue tinyint
		-- new fields added 
		-- Declare	@FieldNo int
		-- Declare @F_TranNo Varchar(10)
		Declare @mappingCount int
		Declare @ResultTable Varchar(100)
		declare @ResultField Varchar(100)
		declare @SelectionField Varchar(100)
		declare @DefaultValue Varchar(200)
		declare @Decplaces bit
		declare @Justification Varchar(6)
		declare @PadCharacter SmallInt
		declare @FieldLength Int
		declare @TableName Varchar(100)
		-- added 10/5/16
		declare @DateSelection Varchar(100)
		declare @F_SOURCE varchar(8) 
		declare @F_OWNER varchar(8) 
		declare @F_CREDIT varchar(50) 
		declare @P_COSTCENT varchar(8) 
		declare @F_VAT_CODE int
		declare @P_NL_CODE varchar(50)
		  -- PLG 01/03/17 added
		DECLARE @FileExt Varchar(10)
		declare @MaxNameLength int
		DECLARE @RC int

/***************************************************************
	GET DEFAULT SETTINGS
***************************************************************/
		If @internal = 0 SET @NotInternal = 1		-- we will select not equal to 1 which will give us 0
		If @internal = 1 SET @NotInternal = 0		-- we will select not equal to 0 which will give us 1
		If @internal = 2 SET @NotInternal = 2		-- we will select not equal to 2 which will give us everything
-- NOTE it would be good (but not essential) to have default settings for these in case no inivars exist
		SET @Enabled = 0
--		SET @SQLServerName = ''
--		SET @SQLServerUser = ''
--		SET @SQLServerPW = ''
--		SET @SQLDatabaseName = ''
		SET @FileName = 'AgressoExport'
		SET @FileExt = 'txt'  -- this is the default added 1/3/17
		SET @Backslash = '\'
		SET @ExportPath = ''
		SET @TitlesEnabled = 1
		SET @HeaderEnabled = 1
		SET @ItemEnabled = 1
		SET @DescEnabled = 1
		SET @FooterEnabled = 1
		SET @ThisInvNo=''
        SET @LastInvNo=''
        SET @InitialValue=0
		SET @DateSelection = 'InvoiceDate'
		SET @MaxNameLength = 512 -- default
		
/***************************************************************
	GET SETTINGS
***************************************************************/
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled')
		BEGIN
			SET @Enabled = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled')
		END
		
/*		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerName') 
		BEGIN
			SET @SQLServerName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerName')
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerUser')
		BEGIN
			SET @SQLServerUser = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerUser')
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerPW') 
		BEGIN
			SET @SQLServerPW = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerPW')
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLDatabaseName') 
		BEGIN
			SET @SQLDatabaseName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLDatabaseName')
		END
*/
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileName') 
		BEGIN
			SET @FileName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileName')
		END
		-- added 01-03-2017
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileExt') 
		BEGIN
			SET @FileExt = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileExt')
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'MaxNameLength') 
		BEGIN
			SET @MaxNameLength = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'MaxNameLength')
		END
		-- end of add
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Backslash') 
		BEGIN
			SET @Backslash = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Backslash')
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ExportPath') 
		BEGIN
			SET @ExportPath = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ExportPath')
		END
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DateRangeSelection') 
		BEGIN
			SET @DateSelection = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DateRangeSelection')
		END

-- ============================================
-- SET WHETHER HEADERS< LINES, FOOTERS ENABLED
-- ============================================
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'TitlesEnabled')
		BEGIN
			SET @Decider = (SELECT TOP (1) [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'TitlesEnabled' ORDER BY ID)
			if @Decider = '0' set @TitlesEnabled = 0
		
		END
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'HeaderEnabled')
		BEGIN
		--PRINT 'Header MCB'
			SET @Decider = (SELECT TOP (1) [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'HeaderEnabled' ORDER BY ID)
			if @Decider = '0' set @HeaderEnabled = 0
		--PRINT '@Decider'
		--PRINT @Decider	
		
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ItemEnabled') 
		BEGIN
			SET @Decider = (SELECT TOP (1) [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ItemEnabled'  ORDER BY ID)
			if @Decider = '0' set @ItemEnabled = 0
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DescEnabled') 
		BEGIN
			SET @Decider = (SELECT TOP (1) [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DescEnabled'  ORDER BY ID)
			if @Decider = '0' set @DescEnabled = 0
		END

		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FooterEnabled')
		BEGIN
			SET @Decider = (SELECT TOP (1 [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FooterEnabled'  ORDER BY ID)
			if @Decider = '0' set @FooterEnabled = 0
		END
-- =============================================
-- START THE WORK
-- =============================================
		IF @Enabled = 0
		BEGIN --Not Enabled
			RETURN -1
		END --Not Enabled
		ELSE
		IF @Enabled = 1
		BEGIN --Enabled
		--PRINT 'I AM HERE 2'
			-- first get a new batch number
			SET @TableName = 'FI_Export_' +@Module +'_' + @MUMode
			-- MCB 24/07/2013 added new section to check for existence of FI_Export_GNT and if not to create it
			IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = @TableName))
				BEGIN
					exec @RC = usp_CreateFIExportTable @Module, @MuMode        -- 5th dec 2013 changed called sproc plg
				END 
				
			EXECUTE @RC = [dbo].[cabs_get_next_export_batch_num] @next_num = @Batchnumber OUTPUT
		--PRINT 'I AM HERE 4'
		--			PRINT '@Transferred'
		--		PRINT @Transferred
		--		PRINT '@NotInternal'
		--		PRINT @NotInternal
-- ============================================
-- DO TIDY UP
-- PLG 27/02/2017 added to prevent multiple headers and ill formed lines
-- ============================================				
	Set @SQLToDo = 'Update FI_Export_'+ @Module + '_' + @MuMode +'  set Exported = 99, ExportedDate =' + Char(39) +Cast(getdate() as Varchar(30)) + Char(39) + '   where isnull(Exported,0) < 1' 
	Exec(@SQLToDO)


-- =============================================
-- CREATE INVOICE TITLES
-- =============================================

					if @TitlesEnabled = 1 begin
					-- 22/2/17 PLG added check for existing Titles unexported
					
					--PRINT 'I AM HERE 5'
						-- put header creation code in here
						set @LineType   = 'TITLES' 
--						set @FIHeaderID = (Select MAX([ID]) from FI_Header where Module = @Module and SubModule = @Sub_Module and LineType = @Linetype and MUMOde = @MUMode and Direction = 'OUT')
						
					
						--  Insert into FI_Export_Finance_HALSUM (Exported, ExportedDate, F_Tranno,Batch_No) VALUES ('', '',@FoltranID,@BatchNumber )
						--  22/02/2017 PLG changed above line to the 2 parametised lines below
						Set @SQLToDo = 'Insert into FI_Export_' + @Module + '_' + @MuMode +' (Exported, ExportedDate, F_Tranno,Batch_No) VALUES ('+Char(39) + Char(39) +','+ Char(39) + Char(39) +',' + Char(39)+@FoltranID +Char(39)+',' + @BatchNumber +')'
						Exec(@SQLToDo)						--  the values don't really matter we just want a new line

						SET @FIExportLineNo = @@IDENTITY

						declare FIExportCursor cursor fast_forward for 
						select ID, MappedFields, LookUpTable, LookUpColumn, LookupField, DefaultValue, DecPointReq, Justification, FillCharacter,FieldLength, Name 
						from dbo.utf_ExportMappingInfo(@TableName,@Sub_Module, @LineType) 
						open FIExportCursor
						fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName

						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'Batch_No' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								 EXEC @RC = usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@mappingCount,@ResultTable,@ResultField,@selectionField,@DefaultValue,@Decplaces,@Justification,@PadCharacter,@FieldLength,@ItemValue OUTPUT
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update ' +@TABLENAme +  '   SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_' +@Module +'_' + 'HALSUM.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						end  -- end while loop
						close FIExportCursor
						Deallocate FIExportCursor

					end -- if titles enabled
				 -- end  
-- ======================================
-- END OF TITLES CODE
-- ======================================


		if @sub_module = 'IN' begin
			declare export_cursor	cursor FAST_FORWARD for
				
			Select F_TranNo, F_ONINV
				from vw_FOL_TRAN_INV_SUMMARY
				where isnull(F_ONINV,'') <> '' and F_TRANSFRD <>   --either we select untransferred ie 0 (not equal to 1) or we select ALL by setting to <> 2 which should catch everything
				(case @Transferred when 0 then 1 else 2 end ) And
				Substring(F_OWNER,1,1) <> 'D' AND
				-- PLG 10/5/16 changed date selection to match date range selected
				-- (F_INVDATE >= @LAST_DATE AND F_INVDATE <= @UP_UNTIL_DATE) 
				(F_INVDATE >= Case @DateSelection when 'InvoiceDate' then @Last_Date else '1900-01-01' end
				AND F_INVDATE <= Case @DateSelection when 'InvoiceDate' then @Up_Until_Date else '2500-01-01' end)
				AND
				(F_DATE >= Case @DateSelection when 'FunctionDate' then @Last_Date else '1900-01-01' end
				AND F_DATE <= Case @DateSelection when 'FunctionDate' then @Up_Until_Date else '2500-01-01' end)
				-- end of changes
				AND dbo.uf_IsInternal(F_TRANNO) <> @NotInternal
				--AND F_TRANNO IN('T026383', 'T026397')
				order by F_ONINV, F_TRANNO
				-- Order clause put in to group by invoice number
		end	
		else if @sub_module = 'CN' begin
			declare export_cursor	cursor FAST_FORWARD for
				
			Select F_TranNo, F_ONINV
				from vw_FOL_TRAN_CRED_SUMMARY
				where isnull(F_ONINV,'') <> '' and F_TRANSFRD <>   --either we select untransferred ie 0 (not equal to 1) or we select ALL by setting to <> 2 which should catch everything
				(case @Transferred when 0 then 1 else 2 end ) And
				Substring(F_OWNER,1,1) <> 'D' AND
				-- PLG 10/5/16 changed date selection to match date range selected
				-- (F_INVDATE >= @LAST_DATE AND F_INVDATE <= @UP_UNTIL_DATE) 
				(F_INVDATE >= Case @DateSelection when 'InvoiceDate' then @Last_Date else '1900-01-01' end
				AND F_INVDATE <= Case @DateSelection when 'InvoiceDate' then @Up_Until_Date else '2500-01-01' end)
				AND
				(F_DATE >= Case @DateSelection when 'FunctionDate' then @Last_Date else '1900-01-01' end
				AND F_DATE <= Case @DateSelection when 'FunctionDate' then @Up_Until_Date else '2500-01-01' end)
				-- end of changes
				AND dbo.uf_IsInternal(F_TRANNO) <> @NotInternal
				--AND F_TRANNO IN('T026383', 'T026397')
				order by F_ONINV, F_TRANNO
				-- Order clause put in to group by invoice number
		end
		else begin
			declare export_cursor	cursor FAST_FORWARD for
				
			Select F_TranNo, F_ONINV
				from vw_FOL_TRAN_SUMMARY
				where isnull(F_ONINV,'') <> '' and F_TRANSFRD <>   --either we select untransferred ie 0 (not equal to 1) or we select ALL by setting to <> 2 which should catch everything
				(case @Transferred when 0 then 1 else 2 end ) And
				Substring(F_OWNER,1,1) <> 'D' AND
				-- PLG 10/5/16 changed date selection to match date range selected
				-- (F_INVDATE >= @LAST_DATE AND F_INVDATE <= @UP_UNTIL_DATE) 
				(F_INVDATE >= Case @DateSelection when 'InvoiceDate' then @Last_Date else '1900-01-01' end
				AND F_INVDATE <= Case @DateSelection when 'InvoiceDate' then @Up_Until_Date else '2500-01-01' end)
				AND
				(F_DATE >= Case @DateSelection when 'FunctionDate' then @Last_Date else '1900-01-01' end
				AND F_DATE <= Case @DateSelection when 'FunctionDate' then @Up_Until_Date else '2500-01-01' end)
				-- end of changes
				AND dbo.uf_IsInternal(F_TRANNO) <> @NotInternal
				--AND F_TRANNO IN('T026383', 'T026397')
				order by F_ONINV, F_TRANNO
				-- Order clause put in to group by invoice number
		end
			open export_cursor
			fetch next from
				export_cursor
			into
				@FoltranID, @ThisInvNo
             -- to force the footer to be right
			while @@fetch_status = 0
			begin
-- =============================================
-- CURSOR WORK
-- =============================================
                 if @ThisInvNo <> @LastInvNo
			      set @NewInvoice = 1
			      set @LastInvNo = @ThisInvNo 
				if @NewInvoice=1 begin  

-- =============================================
-- CREATE INVOICE HEADER
-- =============================================
--PRINT '@HeaderEnabled'
--PRINT @HeaderEnabled
                    EXEC @RC = usp_linecount 1,@TableName, @ItemValue OUTPUT
					if @HeaderEnabled = 1 begin
					--PRINT 'I AM HERE 3'
						-- put header creation code in here
--						set @FIHeaderID = (Select MAX([ID]) from FI_Header where Module = @Module and SubModule = @Sub_Module and LineType = 'HEADER' and MUMOde = 'HALSUM' and Direction = 'OUT')
						set @LineType   = 'HEADER' 
						--PRINT '@FoltranID'
						--PRINT @FoltranID
						
						 Insert into FI_Export_Finance_HALSUM (Exported, ExportedDate, F_Tranno,Batch_No) VALUES ('', '',@FoltranID,@BatchNumber )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
						select ID, MappedFields, LookUpTable, LookUpColumn, LookupField, DefaultValue, DecPointReq, Justification, FillCharacter,FieldLength, Name 
						from dbo.utf_ExportMappingInfo(@TableName,@Sub_Module, @LineType) 
						open FIExportCursor
						fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName

						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								 EXEC @RC = usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@mappingCount,@ResultTable,@ResultField,@selectionField,@DefaultValue,@Decplaces,@Justification,@PadCharacter,@FieldLength,@ItemValue OUTPUT
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update ' +@TableName +'  SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_' +@Module +'_' + 'HALSUM.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								--PRINT '@SQLToDo'
								--PRINT @SQLToDo
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						end  -- end while loop
						close FIExportCursor
						Deallocate FIExportCursor

					end -- if header enabled
				 end  
-- ======================================
-- END OF HEADER CODE
-- ======================================
-- ======================================
-- ITEM CODE - THIS RUNS EVERY TIEM
-- ======================================
					--PRINT '@ItemEnabled'
					--PRINT @ItemEnabled
					if @ItemEnabled = 1 begin
						EXEC @RC = usp_linecount 0,@TableName, @ItemValue OUTPUT
						-- print 'Line number ' + Cast(@ItemValue as Varchar(5))
--						set @FIHeaderID = (Select MAX([ID]) from FI_Header where Module = @Module and SubModule = @Sub_Module and LineType = 'ITEM' and MUMOde = 'HALSUM' and Direction = 'OUT')
						-- changed 23/6/16 PLG was 'Item Line' 
						set @LineType   = 'ITEM' 
						Set @SQLToDo = 'Insert into ' +@TableName + ' (Exported, ExportedDate, F_Tranno,Batch_No) VALUES (' +CHAR(39)+Char(39)+CHAR(44) +CHAR(39)+Char(39)+CHAR(44)+ CHAR(39) + @FoltranID +CHAR(39) +CHAR(44)+Char(39)+@BatchNumber+Char(39)+')'
						Exec (@SQLToDo)
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
						select ID, MappedFields, LookUpTable, LookUpColumn, LookupField, DefaultValue, DecPointReq, Justification, FillCharacter,FieldLength, Name 
						from dbo.utf_ExportMappingInfo(@TableName,@Sub_Module, @LineType) 
						open FIExportCursor
						fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						--while (@@FETCH_STATUS <> -1) begin
						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'Batch_No' begin -- need to ignore the ID column
												
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
								 EXEC @RC = usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@mappingCount,@ResultTable,@ResultField,@selectionField,@DefaultValue,@Decplaces,@Justification,@PadCharacter,@FieldLength,@ItemValue OUTPUT
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update ' +@TableName + '   SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_' +@Module +'_' + 'HALSUM.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						end  -- end while loop
						close FIExportCursor
						Deallocate FIExportCursor

					end -- if item enabled

-- ======================================
-- END OF ITEM CODE
-- ======================================

-- ======================================
-- DESCRIPTION CODE
-- ======================================
					if @DescEnabled = 1 begin
						-- put header creation code in here
--						set @FIHeaderID = (Select MAX([ID]) from FI_Header where Module = @Module and SubModule = @Sub_Module and LineType = 'Text Line' and MUMOde = 'HALSUM' and Direction = 'OUT')
						set @LineType   = 'DESCRIPT' 
						--Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
						-- Insert into FI_Export_HALSUM (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						-- replaced with 
						Set @SQLToDo = 'Insert into ' +@tableName +' (Exported, ExportedDate, F_Tranno, Batch_No) VALUES (' +CHAR(39)+Char(39)+CHAR(44) +CHAR(39)+Char(39)+CHAR(44) +CHAR(39) + @FoltranID +CHAR(39) +CHAR(44)+Char(39)+@BatchNumber+Char(39)+')'
						Exec (@SQLToDo)


						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
						select ID, MappedFields, LookUpTable, LookUpColumn, LookupField, DefaultValue, DecPointReq, Justification, FillCharacter,FieldLength, Name 
						from dbo.utf_ExportMappingInfo(@TableName,@Sub_Module, @LineType) 
						open FIExportCursor
						fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName

						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								 EXEC @RC = usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@mappingCount,@ResultTable,@ResultField,@selectionField,@DefaultValue,@Decplaces,@Justification,@PadCharacter,@FieldLength,@ItemValue OUTPUT
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_' +@Module +'_' + 'HALSUM SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_' +@Module +'_' + 'HALSUM.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						end  -- end while loop
						close FIExportCursor
						Deallocate FIExportCursor

					end -- if Description enabled

-- ======================================
-- END OF DESCRIPTION CODE
-- ======================================


						--loop round
						-- SELECT @FIHeaderID as HeaderID, @Linetype as LineType
						-- create row in table
						if @Sub_Module = 'CN' begin
							SELECT @F_SOURCE = F_SOurce, @F_OWNER =F_OWNER, @F_CREDIT =F_CREDIT, @P_COSTCENT =P_COSTCENT, 
							@F_VAT_CODE =F_VAT_CODE, @P_NL_CODE =P_NL_CODE from vw_FOL_TRAN_CRED_SUMMARY where F_Tranno = @FoltranID AND F_ONINV = @ThisInvNo	--PLG 23/6/16 added where clause
							
							UPDATE FOL_TRAN set F_TRANSFRD = 1 Where @F_SOURCE = F_SOurce AND @F_OWNER =F_OWNER AND @F_CREDIT =F_CREDIT
							AND @F_VAT_CODE =F_VAT_CODE AND @P_NL_CODE =dbo.uf_GetNLCode(F_POSTCODE) AND dbo.uf_getCostCentre(F_POSTCODE) = @P_COSTCENT
							--F_TRANNO = @FoltranID

						end
						else begin
							SELECT @F_SOURCE = F_SOurce, @F_OWNER =F_OWNER, @F_CREDIT =F_CREDIT, @P_COSTCENT =P_COSTCENT, 
							@F_VAT_CODE =F_VAT_CODE, @P_NL_CODE =P_NL_CODE from vw_FOL_TRAN_INV_SUMMARY where F_Tranno = @FoltranID AND F_ONINV = @ThisInvNo	--PLG 23/6/16 added where clause

							UPDATE FOL_TRAN set F_TRANSFRD = 1 Where isnull(@F_SOURCE,'') = isnull(F_SOurce,'') AND isnull(@F_OWNER,'') =isnull(F_OWNER,'') AND isnull(@F_CREDIT,'') =isnull(F_CREDIT,'')
							AND isnull(@F_VAT_CODE,0) =isnull(F_VAT_CODE,0) AND isnull(@P_NL_CODE,'') =dbo.uf_GetNLCode(F_POSTCODE) AND dbo.uf_getCostCentre(F_POSTCODE) = isnull(@P_COSTCENT,'')

						--UPDATE FOL_TRAN set F_TRANSFRD = 1 Where F_TRANNO = @FoltranID
					end
-- needs to match this
--Fol_tran.F_SOURCE, F_OWNER, FOL_TRAN.F_ONINV, FOL_TRAN.F_CREDIT, P_COSTCENT, FOL_TRAN.F_VAT_CODE,SYS_ABBR.ST_DESC, P_NL_CODE, F_TRANSFRD				

-- =============================================
-- CURSOR WORK
-- =============================================
				fetch next from
					export_cursor
				into
					@FoltranID, @ThisInvNo
			
				if @ThisInvNo = @LastInvNo set @NewInvoice = 0
				else set @NewInvoice = 1
-- =============================================
-- FOOTER SECTION
-- =============================================
				if @NewInvoice = 1 begin
					-- create a footer (if required)
					if @FooterEnabled = 1 begin
						-- create footer row
						print 'in footer of ' + @LastInvNo
						--no code here at present as no definition
						--set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'FOOTER' and MUMOde = 'HALSUM' and Direction = 'OUT')
						--set @LineType   = 'FOOTER' 
						-- put code in here
						-- put header creation code in here
--						set @FIHeaderID = (Select MAX([ID]) from FI_Header where Module = @Module and SubModule = @Sub_Module and LineType = 'FOOTER' and MUMOde = 'HALSUM' and Direction = 'OUT')
						set @LineType   = 'FOOTER' 
						--Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
						 --Insert into FI_Export_HALSUM (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						 -- replaced with below
						 Set @SQLToDo = 'Insert into FI_Export_' +@Module + '_' +'HALSUM (Exported, ExportedDate, F_Tranno, Batch_No) VALUES (' +CHAR(39)+Char(39)+CHAR(44) +CHAR(39)+Char(39)+CHAR(44) +CHAR(39) + @FoltranID +CHAR(39) +CHAR(44)+Char(39)+@BatchNumber+Char(39)+')'
						 Exec (@SQLToDo)

						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
						select ID, MappedFields, LookUpTable, LookUpColumn, LookupField, DefaultValue, DecPointReq, Justification, FillCharacter,FieldLength, Name 
						from dbo.utf_ExportMappingInfo(@TableName,@Sub_Module, @LineType) 
						open FIExportCursor
						fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName

						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								 EXEC @RC = usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@mappingCount,@ResultTable,@ResultField,@selectionField,@DefaultValue,@Decplaces,@Justification,@PadCharacter,@FieldLength,@ItemValue OUTPUT
								
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_' +@Module +'_' + 'HALSUM SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_' +@Module +'_' + 'HALSUM.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
									
							fetch next from FIExportCursor into @itemid, @mappingCount, @ResultTable, @ResultField, @selectionField, @DefaultValue, @Decplaces, @Justification, @PadCharacter, @FieldSize, @ItemName
						end  -- end while loop
						close FIExportCursor
						Deallocate FIExportCursor

					end -- if footer enabled
				end -- if new invoice
-- =============================================
-- END OF FOOTER SECTION
-- =============================================
			end  -- export cursor loop
					
			close export_cursor
			deallocate export_cursor
/***************************************************************
UPDATE LAST TRANS DATE
***************************************************************/
        
		IF exists(SELECT VALUE FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate')
		BEGIN
			UPDATE xCABS_CONFIG_TABLE
			SET [VALUE] = ( (CONVERT(VARCHAR(11), (@UP_UNTIL_DATE), 103)) )
			WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate' 
		END	
		ELSE
		IF not exists(SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate') 
		BEGIN
			INSERT INTO xCABS_CONFIG_TABLE
			([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
			VALUES
			('G', '', 'Finance', 'LastTransDate', ( (CONVERT(VARCHAR(11), (@UP_UNTIL_DATE), 103)) ), 0, 'INS', GETUTCDATE()) 
		END
			
			--UPDATE xCABS_CONFIG_TABLE
			--SET [VALUE] = ( (CONVERT(VARCHAR(11), (@UP_UNTIL_DATE), 103)) )
			--WHERE [DELETED] = 0 AND [SECTION] = 'Agresso' AND [KEY] = 'LastTransDate'
/***************************************************************
EXPORT THE FILE
***************************************************************/	
			DECLARE @SQLVar nvarchar(4000)	
			DECLARE @Param  nVarchar(400)
			IF exists(SELECT Exported FROM FI_Export_Finance_HALSUM 
				WHERE (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '' OR ExportedDate IS NULL)) 
			BEGIN --Records To Export
				--New
--==============================================================================================================================================================				

-- PLG moved string write into main proc
declare -- @Path VARCHAR(255), 
		@objFileSystem int,
        @objTextStream int,
		@objErrorObject int,
		@strErrorMessage Varchar(1000),
	    -- @Command varchar(1000),
	    @hr int,
	    @fileAndPath varchar(400)
declare	@objFSys int
declare @i int

declare 
	write_cursor
cursor FAST_FORWARD for
	
	Select [ID]
	from FI_Export_Finance_HALSUM
	where (Exported = 0 OR Exported IS NULL)
	AND (ExportedDate = '' OR ExportedDate IS NULL)

open write_cursor

	SET @Date_Ext = (SELECT REPLACE((convert(varchar(11), (GETDATE()), 12)), '/', '_')) -- 01/03/2017 changed from 103 to 12
	SET @Time_Ext = (SELECT SUBSTRING(REPLACE((convert(varchar(11), (GETDATE()), 108)), ':', '_'),1,5)) -- 01/03/2017 changed to just take hh:mm
	
	IF RIGHT(@ExportPath, 1) <> @Backslash
		BEGIN
			SET @ExportPath = (@ExportPath + @Backslash)
		END

		SET @FileName = (@FileName + '_' + @Sub_Module + '_' + @Date_Ext + '_' + @Time_Ext + '.' +@FileExt) -- modified 01/03/2017 to shorten and add extension
		if Len(@Filename) > @MaxNameLength 	set @Filename = Replace(@filename, '_', '')
		while Len(@Filename) > @MaxNameLength begin
			set @filename = Replace(@Filename,Substring(@Filename,Len(@Filename)-6,2),'')
		end	
		----SET @File = @ExportPath + @FileName
		----SET @DBAccess = ' -S' + @SQLServerName + ' -U' + @SQLServerUser + ' -P' + @SQLServerPW + ' -c '  
		----SET @String = 'bcp ' + @SelectFromTempFile + ' queryout ' + @File + @DBAccess
			
	-- create text file
	
	select @strErrorMessage='opening the File System Object'
	EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT
	PRINT 'Create Text File '
	PRINT @HR
	PRINT @objFileSystem
	
	Set @FileAndPath=@Exportpath+@filename
	
	if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
	exec sp_OACreate 'Scripting.FileSystemObject', @objFSys out
	exec sp_OAMethod @objFSys, 'FileExists', @i out, @FileAndPath
	PRINT '@i = ' + cast(@i as VARCHAR(5))
	if @i = 1 OR  @initialValue>0
	BEGIN
		if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'OpenTextFile'
		, @objTextStream OUT, @FileAndPath,8,0
	END
	ELSE BEGIN
		if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
		, @objTextStream OUT, @FileAndPath,2,0
	END
	
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'
	
	PRINT '@HR after TextCreate'
	Print @HR
	Print @objTextStream 
	Print @FileAndPath
	
		
fetch next from
	write_cursor
into
	@FolTranid 

while @@fetch_status = 0
begin
	Set @SelectFromTempFile = ''
	--set @SQLVar = 'usp_getFIExportForOneTransaction  @F_Tranno, @ReturnValue OUTPUT'
	set @SQLVar = 'usp_getFIExportForOneTransaction2  ''Finance'',''HALSUM'', @ID, @ReturnValue OUTPUT' 
	--DECLARE @ReturnValue VARCHAR(100)
	--SET @ReturnValue = ''
	--set @SQLVar = 'usp_getFIExportForOneTransaction  ''HAL'', ''' + @FoltranID + ''', @ReturnValue OUTPUT' 
	set @Param = '@ID Varchar(20), @ReturnValue nVarchar(MAX) OUTPUT'  
	EXEC sp_executeSQL @SQLVar, @Param,
		@ID = @FoltranID,
		@ReturnValue = @SelectFromTempFile OUTPUT
	PRINT '@SelectFromTempFile '
	PRINT @SelectFromTempFile 	
	
--PRINT '@SQLVar'
--PRINT @SQLVar
--PRINT '@Param'
--PRINT @Param
--PRINT '@F_Tranno'
--PRINT @FoltranID
--PRINT '@SelectFromTempFile'
--PRINT @SelectFromTempFile
--==============================================================================================================================================================
			
--	EXEC Usp_WriteStringToFile @SelectFromTempFile, @ExportPath, @FileName, @InitialValue
	if @HR=0 Select @objErrorObject=@objTextStream, 
		@strErrorMessage='opening the file "'+@FileAndPath+'"' +'        ' +cast(@objFileSystem as Varchar(50))
	if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'OpenTextFile'
		, @objTextStream OUT, @FileAndPath,8,0,0
	if @HR=0 Select @objErrorObject=@objTextStream, 
		@strErrorMessage='writing to the file "'+@FileAndPath+'"'	
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'WriteLine', Null, @SelectFromTempFile
	
	if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'
	
	
	   SET @InitialValue=1
		UPDATE FI_Export_Finance_HALSUM
		SET Exported = 1,
		ExportedDate = GETDATE()
		WHERE (Exported = 0 OR Exported IS NULL)
		AND (ExportedDate = '' OR ExportedDate IS NULL)
		--AND F_Tranno = @FolTRanID			
		AND [ID] = @FolTRanID 
	
	if @hr<>0
		begin
		Declare 
			@Source varchar(255),
			@Description Varchar(255),
			@Helpfile Varchar(255),
			@HelpID int
		
		EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
			@source output,@Description output,@Helpfile output,@HelpID output
		Select @strErrorMessage='Error whilst '
				+coalesce(@strErrorMessage,'doing something')
				+', '+coalesce(@Description,'')
		raiserror (@strErrorMessage,16,1)
		set @strErrorMessage = ''
		set @hr = 0
		end

	fetch next from
		write_cursor
	into
		@FolTranid 
end

	EXECUTE  sp_OADestroy @objTextStream
	EXECUTE sp_OADestroy @objTextStream

	exec sp_OADestroy @objFSys 
close write_cursor
deallocate write_cursor


		END --Records To Export
		
		SET CONCAT_NULL_YIELDS_NULL ON
					
			
		END --Enabled 	
	END --Settings End	
--	end --debug			
END --SPROC ENDS
GO
