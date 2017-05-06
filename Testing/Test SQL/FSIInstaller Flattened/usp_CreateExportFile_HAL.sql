IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'usp_CreateExportFile_HAL') begin
	Drop Procedure usp_CreateExportFile_HAL
END
Go
/****** Object:  StoredProcedure [dbo].[usp_CreateExportFile_HAL]    Script Date: 20/09/2016 09:18:24 ******/
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
--				Deleted = 0, Type = 'S', Section = 'usp_CreateExportFile_HAL', Key =<line type>, VALUE='Disabled'
-- Requires:	a Row in xCAbsConfig where Type = 'S' and Section = 'usp_CreateExportFile_HAL'
--				
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateExportFile_HAL]
	-- Add the parameters for the stored procedure here
	@LAST_DATE DATETIME, @UP_UNTIL_DATE DATETIME, @Module VARCHAR(50), @Sub_Module VARCHAR(50), @Internal int, @Transferred int
AS
BEGIN --SPROC BEGINS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--PRINT 'I AM HERE 1'
/****************************************************************************************************************************
CABS CONFIGURATION - GENERIC
****************************************************************************************************************************/
--OBJECT HEADER
--Checks that this sproc should run
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'usp_CreateExportFile_HAL' --The Object Name

	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) = 0 -- Object Doesn't Exist; Run As Normal
	BEGIN -- No Settings Begin
		RETURN
	END -- No Settings End
	ELSE
	IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG) > 0 -- Object Exists; Settings to Consider
	BEGIN --Settings Begin
-- =============================================
-- DECLARATIONS
-- =============================================
		DECLARE @Enabled VARCHAR(1000)

		DECLARE @SQLServerName VARCHAR(1000)
		DECLARE @SQLServerUser VARCHAR(1000)
		DECLARE @SQLServerPW VARCHAR(1000)
		DECLARE @SQLDatabaseName VARCHAR(1000)
		DECLARE @FileName VARCHAR(1000)
		DECLARE @Backslash VARCHAR(1)
		DECLARE @ExportPath VARCHAR(1000)

		Declare @FoltranID Varchar(10)
		Declare @FIHeaderID Int
		Declare @Linetype Varchar(10)
		Declare @ItemNAme Varchar(50)
		Declare @ItemID int
		Declare @FIExportLineNo int
		Declare @SQLToDo Varchar(4000)
		Declare @ItemValue Varchar(500)
		Declare @FieldSize Int
		DECLARE @DATE_EXT VARCHAR(10)
		DECLARE @TIME_EXT VARCHAR(8)
		DECLARE @File VARCHAR(1000)
		DECLARE @SelectFromTempFile VARCHAR(MAX)
		DECLARE @DBAccess VARCHAR(255)
		DECLARE @String VARCHAR(8000)
		DECLARE @BatchNumber Varchar(20)	-- added plg 8 Oct 2012
		DECLARE @NotInternal Int -- added plg to use a perverse piece of logic on Internal Selection
		-- @Internal is 0 for External, 1 for Internal, 2 for Both
		DECLARE @ThisInvNo VArchar(10) -- used for holding current invoice number to decide whether this is a new invoice
		DECLARE @LastInvNo VArchar(10) -- used for holding last invoice number to decide whether this is a new invoice
		Declare @NewInvoice Bit 
		Declare @HeaderEnabled Bit
		Declare @ItemEnabled Bit
		Declare @DescEnabled Bit
		Declare @FooterEnabled Bit
		Declare @Decider Varchar(50)  -- used for bringing text fields and then using them temporarily fo switching
		Declare @InitialValue tinyint
/***************************************************************
	GET DEFAULT SETTINGS
***************************************************************/
		If @internal = 0 SET @NotInternal = 1		-- we will select not equal to 1 which will give us 0
		If @internal = 1 SET @NotInternal = 0		-- we will select not equal to 0 which will give us 1
		If @internal = 2 SET @NotInternal = 2		-- we will select not equal to 2 which will give us everything
-- NOTE it would be good (but not essential) to have default settings for these in case no inivars exist
		SET @Enabled = 0
		SET @SQLServerName = ''
		SET @SQLServerUser = ''
		SET @SQLServerPW = ''
		SET @SQLDatabaseName = ''
		SET @FileName = 'AgressoExport'
		SET @Backslash = '\'
		SET @ExportPath = ''
		SET @HeaderEnabled = 1
		SET @ItemEnabled = 1
		SET @DescEnabled = 1
		SET @FooterEnabled = 1
		SET @ThisInvNo=''
        SET @LastInvNo=''
        SET @InitialValue=0
/***************************************************************
	GET SETTINGS
***************************************************************/
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled') > 0
		BEGIN
			SET @Enabled = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Enabled')
		END
		
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerName') > 0
		BEGIN
			SET @SQLServerName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerName')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerUser') > 0
		BEGIN
			SET @SQLServerUser = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerUser')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerPW') > 0
		BEGIN
			SET @SQLServerPW = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLServerPW')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLDatabaseName') > 0
		BEGIN
			SET @SQLDatabaseName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'SQLDatabaseName')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileName') > 0
		BEGIN
			SET @FileName = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'FileName')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Backslash') > 0
		BEGIN
			SET @Backslash = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Backslash')
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ExportPath') > 0
		BEGIN
			SET @ExportPath = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'ExportPath')
		END
-- ============================================
-- SET WHETHER HEADERS< LINES, FOOTERS ENABLED
-- ============================================
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Header') > 0
		BEGIN
		--PRINT 'Header MCB'
			SET @Decider = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Header')
			if @Decider = 'Disabled' set @HeaderEnabled = 0
		--PRINT '@Decider'
		--PRINT @Decider	
		
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Item') > 0
		BEGIN
			SET @Decider = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Item')
			if @Decider = 'Disabled' set @ItemEnabled = 0
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Description') > 0
		BEGIN
			SET @Decider = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Description')
			if @Decider = 'Disabled' set @DescEnabled = 0
		END

		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Footer') > 0
		BEGIN
			SET @Decider = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'Footer')
			if @Decider = 'Disabled' set @FooterEnabled = 0
		END
-- =============================================
-- START THE WORK
-- =============================================
		IF @Enabled = 0
		BEGIN --Not Enabled
			RETURN
		END --Not Enabled
		ELSE
		IF @Enabled = 1
		BEGIN --Enabled
		--PRINT 'I AM HERE 2'
			-- first get a new batch number
			
			-- MCB 24/07/2013 added new section to check for existence of FI_Export_GNT and if not to create it
			IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'FI_Export_HAL'))
				BEGIN
					exec sp_CreateFIExportTable 'HAL'
				END 
				
			EXECUTE [dbo].[cabs_get_next_export_batch_num] @next_num = @Batchnumber OUTPUT
		--PRINT 'I AM HERE 4'
		--			PRINT '@Transferred'
		--		PRINT @Transferred
		--		PRINT '@NotInternal'
		--		PRINT @NotInternal
				
			declare export_cursor	cursor FAST_FORWARD for
				
			Select F_TranNo, F_ONINV
				from FOL_TRAN
				where isnull(F_ONINV,'') <> '' and F_TRANSFRD <>   --either we select untransferred ie 0 (not equal to 1) or we select ALL by setting to <> 2 which should catch everything
				(case @Transferred when 0 then 1 else 2 end ) And
				Substring(F_OWNER,1,1) <>'D' AND
				(F_INVDATE >= @LAST_DATE AND F_INVDATE <= @UP_UNTIL_DATE) 
				AND dbo.uf_IsInternal(F_TRANNO) <> @NotInternal
				--AND F_TRANNO IN('T026383', 'T026397')
				order by F_ONINV, F_TRANNO
				-- Order clause put in to group by invoice number
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
                    EXEC usp_linecount 1, 0, @ItemValue OUTPUT
					if @HeaderEnabled = 1 begin
					--PRINT 'I AM HERE 3'
						-- put header creation code in here
						set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'HEADER' and MUMOde = 'HAL' and Direction = 'OUT')
						set @LineType   = 'HEADER' 
						--PRINT '@FoltranID'
						--PRINT @FoltranID
						
						--Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
						 Insert into FI_Export_HAL (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
							select column_name,CHARACTER_MAXIMUM_LENGTH 
							from information_schema.columns  
							where table_name = 'FI_Export_HAL' order by ordinal_position
						-- select * from FI_Export_HAL where ID = @FIExportLineNo  --debug only
						open FIExportCursor
						fetch next from FIExportCursor into @ItemName, @FieldSize
						--while (@@FETCH_STATUS <> -1) begin
						while (@@FETCH_STATUS = 0) begin
						if @ItemName='dim_1' and @FIHeaderID=14
						  print 'd'
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
								--if @itemname='apar_id' or  @itemname='batch_id' --reji added if condition
								if @itemname='accountable'
								print 'apar_d'
								set @ItemID = dbo.uf_getTemplateID_nameType(@ItemNAme,@FIHeaderID)
								 EXEC usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@ItemValue OUTPUT
								--next line just for debugging
								--SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value ', @ItemNAme as '@ItemNAme', @FIHeaderID as '@FIHeaderID'
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_HAL SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_HAL.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								--PRINT '@SQLToDo'
								--PRINT @SQLToDo
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @ItemName, @FieldSize
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
					PRINT '@ItemEnabled'
					PRINT @ItemEnabled
					if @ItemEnabled = 1 begin
						-- put header creation code in here
						set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'Item Line' and MUMOde = 'HAL' and Direction = 'OUT')
						set @LineType   = 'ITEM' 
					--	Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
					 Insert into FI_Export_HAL (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
							select column_name,CHARACTER_MAXIMUM_LENGTH 
							from information_schema.columns  
							where table_name = 'FI_Export_HAL' order by ordinal_position
						-- select * from FI_Export_HAL where ID = @FIExportLineNo  --debug only
						open FIExportCursor
						fetch next from FIExportCursor into @ItemName, @FieldSize
						--while (@@FETCH_STATUS <> -1) begin
						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
													
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
									if @itemname='apar_id' --reji added if condition
								print 'apar_d'
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
								set @ItemID = dbo.uf_getTemplateID_nameType(@ItemNAme,@FIHeaderID)
								 EXEC usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@ItemValue OUTPUT
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_HAL SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_HAL.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @ItemName, @FieldSize
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
						set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'Text Line' and MUMOde = 'HAL' and Direction = 'OUT')
						set @LineType   = 'DESCRIPT' 
						--Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
						 Insert into FI_Export_HAL (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
							select column_name,CHARACTER_MAXIMUM_LENGTH 
							from information_schema.columns  
							where table_name = 'FI_Export_HAL' order by ordinal_position
						-- select * from FI_Export_HAL where ID = @FIExportLineNo  --debug only
						open FIExportCursor
						fetch next from FIExportCursor into @ItemName, @FieldSize
						--while (@@FETCH_STATUS <> -1) begin
						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
									if @itemname='apar_id' --reji added if condition
								print 'apar_d'
								set @ItemID = dbo.uf_getTemplateID_nameType(@ItemNAme,@FIHeaderID)
								 EXEC usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@ItemValue OUTPUT
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_HAL SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_HAL.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
										
							fetch next from FIExportCursor into @ItemName, @FieldSize
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
					UPDATE FOL_TRAN set F_TRANSFRD = 1 Where F_TRANNO = @FoltranID
				
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
						set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'FOOTER' and MUMOde = 'HAL' and Direction = 'OUT')
						set @LineType   = 'FOOTER' 
						-- put code in here
						-- put header creation code in here
						set @FIHeaderID = (Select [ID] from FI_Header where Module = @Module and LineType = 'FOOTER' and MUMOde = 'HAL' and Direction = 'OUT')
						set @LineType   = 'FOOTER' 
						--Insert into FI_Export_HAL (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'XX',@FoltranID )
						 Insert into FI_Export_HAL (Exported, ExportedDate, F_Tranno) VALUES ('', '',@FoltranID )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY

						declare FIEXportCursor cursor fast_forward for 
							select column_name,CHARACTER_MAXIMUM_LENGTH 
							from information_schema.columns  
							where table_name = 'FI_Export_HAL' order by ordinal_position
							-- select * from FI_Export_HAL where ID = @FIExportLineNo  --debug only
						open FIExportCursor
						fetch next from FIExportCursor into @ItemName, @FieldSize
						--while (@@FETCH_STATUS <> -1) begin
						while (@@FETCH_STATUS = 0) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
									
								set @ItemID = dbo.uf_getTemplateID_nameType(@ItemNAme,@FIHeaderID)
								
								EXEC usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@ItemValue OUTPUT
								
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_HAL SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_HAL.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end --end if item name
									
							fetch next from FIExportCursor into @ItemName, @FieldSize
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
        
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate') = 1
		BEGIN
			UPDATE xCABS_CONFIG_TABLE
			SET [VALUE] = ( (CONVERT(VARCHAR(11), (@UP_UNTIL_DATE), 103)) )
			WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate' 
		END	
		ELSE
		IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'G' AND [SECTION] = 'Finance' AND [KEY] = 'LastTransDate') = 0
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
			IF (SELECT COUNT(*) FROM FI_Export_HAL WHERE (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '' OR ExportedDate IS NULL)) > 0
			BEGIN --Records To Export
				--New
--==============================================================================================================================================================				
declare 
	write_cursor
cursor FAST_FORWARD for
	
	Select F_Tranno
	from FI_Export_HAL
	where (Exported = 0 OR Exported IS NULL)
	AND (ExportedDate = '' OR ExportedDate IS NULL) GROUP BY f_tranno

open write_cursor

	SET @Date_Ext = (SELECT REPLACE((convert(varchar(11), (GETDATE()), 103)), '/', '_'))
	SET @Time_Ext = (SELECT REPLACE((convert(varchar(11), (GETDATE()), 108)), ':', '_'))
	
	IF RIGHT(@ExportPath, 1) <> @Backslash
		BEGIN
			SET @ExportPath = (@ExportPath + @Backslash)
		END

		SET @FileName = (@FileName + '_' + '['+ @Date_Ext + ']_[' + @Time_Ext + ']' + '.txt')
			
		----SET @File = @ExportPath + @FileName
		----SET @DBAccess = ' -S' + @SQLServerName + ' -U' + @SQLServerUser + ' -P' + @SQLServerPW + ' -c '  
		----SET @String = 'bcp ' + @SelectFromTempFile + ' queryout ' + @File + @DBAccess
			
		
fetch next from
	write_cursor
into
	@FolTranid 

while @@fetch_status = 0
begin
	Set @SelectFromTempFile = ''
	--set @SQLVar = 'usp_getFIExportForOneTransaction  @F_Tranno, @ReturnValue OUTPUT'
	set @SQLVar = 'usp_getFIExportForOneTransaction  ''HAL'', @F_Tranno, @ReturnValue OUTPUT' 
	--DECLARE @ReturnValue VARCHAR(100)
	--SET @ReturnValue = ''
	--set @SQLVar = 'usp_getFIExportForOneTransaction  ''HAL'', ''' + @FoltranID + ''', @ReturnValue OUTPUT' 
	set @Param = '@F_Tranno Varchar(20), @ReturnValue nVarchar(MAX) OUTPUT'  
	EXEC sp_executeSQL @SQLVar, @Param,
		@F_Tranno = @FoltranID,
		@ReturnValue = @SelectFromTempFile OUTPUT
	
PRINT '@SQLVar'
PRINT @SQLVar
PRINT '@Param'
PRINT @Param
PRINT '@F_Tranno'
PRINT @FoltranID
PRINT '@SelectFromTempFile'
PRINT @SelectFromTempFile
--==============================================================================================================================================================
			
	EXEC Usp_WriteStringToFile @SelectFromTempFile, @ExportPath, @FileName, @InitialValue
	   SET @InitialValue=1
		UPDATE FI_Export_HAL
		SET Exported = 1,
		ExportedDate = GETDATE()
		WHERE (Exported = 0 OR Exported IS NULL)
		AND (ExportedDate = '' OR ExportedDate IS NULL)	AND F_Tranno = @FolTRanID			

	fetch next from
		write_cursor
	into
		@FolTranid 
end

close write_cursor
deallocate write_cursor

		END --Records To Export
		
					
			
		END --Enabled 	
	END --Settings End				
END --SPROC ENDS

GO


