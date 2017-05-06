
IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'usp_CreateExportFile_GNT') begin
	Drop Procedure usp_CreateExportFile_GNT
END
Go

/****** Object:  StoredProcedure [dbo].[usp_CreateExportFile_GNT]    Script Date: 20/09/2016 09:15:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Mark Birch
-- Create date: 27-SEP-2012
-- Description:	<Description,,>
-- Amended 8th Oct Peter Green
--  Added Batch number control, Archiving of FI_Export_GNT and Creation of clean FI_Export_GNT Table
--  Added filter on records selected 
--  18 Jul 2013 PLG changed name to usp_CreateExportFile_GNT to work in parallel with HAL
--                  new sproc usp_CreateExportFile created to select between them
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateExportFile_GNT]
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
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'usp_CreateExportFile_GNT' --The Object Name

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
		DECLARE  @InitialValue tinyint
		-- @Internal is 0 for External, 1 for Internal, 2 for Both
/***************************************************************
	GET DEFAULT SETTINGS
***************************************************************/
		If @internal = 0 SET @NotInternal = 1		-- we will select not equal to 1 which will give us 0
		If @internal = 1 SET @NotInternal = 0		-- we will select not equal to 0 which will give us 1
		If @internal = 2 SET @NotInternal = 2		-- we will select not equal to 2 which will give us everything

		SET @Enabled = 0
		SET @SQLServerName = ''
		SET @SQLServerUser = ''
		SET @SQLServerPW = ''
		SET @SQLDatabaseName = ''
		SET @FileName = 'AgressoExport'
		SET @Backslash = '\'
		SET @ExportPath = ''
		SET  @InitialValue=0
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
			-- plg 18.7.2013 added new section to check for existence of FI_Export_GNT and if not to create it
			IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'FI_Export_GNT'))
				BEGIN
					exec sp_CreateFIExportTable 'GNT'
				END 
			-- first get a new batch number
			EXECUTE [dbo].[cabs_get_next_export_batch_num] @next_num = @Batchnumber OUTPUT
			declare 
				export_cursor
			cursor FAST_FORWARD for

				Select F_TranNo
				from FOL_TRAN
				where isnull(F_ONINV,'') <> '' and F_TRANSFRD <>   --either we select untransferred ie 0 (not equal to 1) or we select ALL by setting to <> 2 which should catch everything
				(case @Transferred when 0 then 1 else 2 end ) And
				Substring(F_OWNER,1,1) <>'D' AND
				(F_INVDATE > @LAST_DATE AND F_INVDATE <= @UP_UNTIL_DATE) 
				AND dbo.uf_IsInternal(F_TRANNO) <> @NotInternal  
				--AND F_TRANNO IN('T026383', 'T026397')

			open export_cursor

			fetch next from
				export_cursor
			into
				@FoltranID

			while @@fetch_status = 0
			begin
-- =============================================
-- CURSOR WORK
-- =============================================
				declare FIHeaderCursor Cursor Fast_forward for Select [ID],Linetype  from FI_Header where Module = @Module and Direction = 'OUT' and MUMode = 'GNT'
				-- plg 18.7.13 added test for GNT mode to ensure we are in the right section
				declare FIEXportCursor cursor fast_forward for select column_name,CHARACTER_MAXIMUM_LENGTH from information_schema.columns  where table_name = 'FI_Export_GNT' order by ordinal_position
			--use cursor to move through fol_tran GT F_INVDATE F_ONINV not null
			--select foltran record
				--temp code to test
				-- SELECT @FoltranID
				open FIHeaderCursor
					Fetch next from FIHeaderCursor into @FIHeaderID, @Linetype
					While (@@FETCH_STATUS <> -1) begin 
						--loop round
						-- SELECT @FIHeaderID as HeaderID, @Linetype as LineType
						-- create row in table
						Insert into FI_Export_GNT (Interface, Trans_Type, F_Tranno) VALUES ('BI', 'TX',@FoltranID )
						--the values don't really matter we just want a new line
						SET @FIExportLineNo = @@IDENTITY
						-- select * from FI_Export_GNT where ID = @FIExportLineNo  --debug only
						open FIExportCursor
						fetch next from FIExportCursor into @ItemName, @FieldSize
						while (@@FETCH_STATUS <> -1) begin
							if @ItemName <> 'ID' AND @ItemName <> 'Exported' AND @ItemName <> 'ExportedDate'  and @ItemName <> 'F_TranNo' and @ItemName <> 'BatchNo' begin -- need to ignore the ID column
								Set @FieldSize = isnull(@FieldSize,0)  -- to get rid of null values
								--next line just for debugging
								-- SELECT @ItemNAme as ItemNameInCursorLoop
								set @ItemID = dbo.uf_getTemplateID_nameType(@ItemNAme,@FIHeaderID)
								 EXEC usp_CABS_get_FI_Value_for_Invoice @ItemID,@FoltranID,@ItemValue OUTPUT
								--next line just for debugging
								-- SELECT  @ItemID as 'ItemID ', @ItemValue as 'Item Value '
								set @ItemValue = SUBSTRING(@ItemValue,1,@fieldSize)				
								Set @SQLToDo = 'Update FI_Export_GNT SET ' 
								Set @SQLToDo = @SQLToDo + @ItemNAme + ' = ' +CHAR(39) + @ItemValue + CHAR(39) + '  Where FI_Export_GNT.ID = ' + Convert(Varchar(10),@FIExportLineNo)
								-- SELECT @SQLToDo
								Execute (@SQLToDo)
							end
										
							fetch next from FIExportCursor into @ItemName, @FieldSize
						end
						close FIExportCursor
						fetch next from FIHeaderCursor into @FIHeaderID, @Linetype
					end
					close FIHeaderCursor
					Deallocate FIExportCursor
					Deallocate FIHeaderCursor

					UPDATE FOL_TRAN set F_TRANSFRD = 1 Where F_TRANNO = @FoltranID
-- =============================================
-- CURSOR WORK
-- =============================================
				fetch next from
					export_cursor
				into
					@FoltranID
			end

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
			IF (SELECT COUNT(*) FROM FI_Export_GNT WHERE (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '' OR ExportedDate IS NULL)) > 0
			BEGIN --Records To Export
				--New
--==============================================================================================================================================================				
declare 
	write_cursor
cursor FAST_FORWARD for
	
	Select F_Tranno
	from FI_Export_GNT
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
	set @SQLVar = 'usp_getFIExportForOneTransaction  ''GNT'', @F_Tranno, @ReturnValue OUTPUT' 	
	set @Param = '@F_Tranno Varchar(20), @ReturnValue nVarchar(MAX) OUTPUT'  
	EXEC sp_executeSQL @SQLVar, @Param, @F_Tranno = @FoltranID, @ReturnValue = @SelectFromTempFile OUTPUT


--==============================================================================================================================================================
/* --PETER'S
				Set @FolTranid = (Select top 1 F_Tranno from FI_Export where (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '' OR ExportedDate IS NULL))
				set @SQLVar = 'usp_getFIExportForOneTransaction  @F_Tranno, @ReturnValue OUTPUT' 
				set @Param = '@F_Tranno Varchar(20), @ReturnValue nVarchar(4000) OUTPUT'  
				EXEC sp_executeSQL @SQLVar, @Param, @F_Tranno = @FoltranID, @ReturnValue = @SelectFromTempFile OUTPUT
*/				
				--usp_getFIExportForOneTransaction 'T026372', ''
				--SET @SelectFromTempFile = '"SELECT * FROM ' + @SQLDatabaseName + '.dbo.FI_Export WHERE (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '''' OR ExportedDate IS NULL)"'		

			----ELSE		
			----IF (SELECT COUNT(*) FROM FI_Export WHERE (Exported = 0 OR Exported IS NULL) AND (ExportedDate = '' OR ExportedDate IS NULL)) = 0
			----BEGIN --No Records To Export	
			----	SET @SelectFromTempFile = '"SELECT '''', ''No Records for this period (' + (CONVERT(VARCHAR(11), (@LAST_DATE), 103)) + ' - ' + (CONVERT(VARCHAR(11), (@UP_UNTIL_DATE), 103)) + ')''"'		
			----END --No Records To Export	


			
	EXEC Usp_WriteStringToFile @SelectFromTempFile, @ExportPath, @FileName,  @InitialValue
	SET  @InitialValue=1
		UPDATE FI_Export_GNT
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


