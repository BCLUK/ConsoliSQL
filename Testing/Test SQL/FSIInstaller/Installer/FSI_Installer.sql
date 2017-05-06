-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 01/02/2017
-- Description:	This stored procedure wrtten to run FSI installation or update sql scripts.
--
--				The script uses xp_cmdshell which must be enabled before this script can be run.				
--
--				The following commands can be run to enable and disable xp_cmdshell
--
--					EXEC sp_configure 'show advanced options', 1
--					GO
--					RECONFIGURE
--					GO
--
--				Enable xp_cmdshell:
--
--					EXEC sp_configure 'xp_cmdshell', 1
--					GO
--					RECONFIGURE
--					GO
--
--				Disable xp_cmdshell:
--
--					EXEC sp_configure 'xp_cmdshell', 0
--					GO
--					RECONFIGURE
--					GO
--
--				Hide advanced options:
--
--					EXEC sp_configure 'show advanced options', 0
--					GO
--					RECONFIGURE
--					GO
--
--				Before running this script insert the database server name, database name and the 
--				directory where the sql scripts are. 
--
-- =====================================================================================================
-- Version:		3
-- Date:		03/02/2017
-- =====================================================================================================
-- Changes:	TT: 01/02/2017: Original Version
--  (1)			
-- Changes:	TT: 02/02/2017: Removed configuration scripts
--  (2)		
-- Changes: PLG: 03/02/2017:  Added usp_RULE_DateOnly to script
--  (3)
-- =====================================================================================================
SET NOCOUNT ON  

-- Create temporary table to hold an error message
CREATE TABLE #aetemp (StatusMessage VARCHAR(500))

-- Added Code to enable a script to be used for either a new install or an upgrade - TT - 18/01/2017
DECLARE @INSTALL VARCHAR = '1'
DECLARE @UPDATE VARCHAR = '2'
DECLARE @PURPOSE VARCHAR 

-- ****** This should be either either SET @PURPOSE = @INSTALL or SET @PURPOSE = @UPDATE before delivered to the client ********
SET @PURPOSE = '*** INSERT SCRIPT PURPOSE VALUE @INSTALL OR @UPDATE ***' 

IF @PURPOSE = @UPDATE
BEGIN
	PRINT '*** This script will perform a clean install of the FSI Module ***'
END
ELSE IF @PURPOSE = @UPDATE
BEGIN
	PRINT '*** This script will perform an update to the FSI Module ***'
END
ELSE	
BEGIN
	PRINT '*** @PURPOSE VARIABLE NOT SET CORRECTLY ***'
	PRINT '*** Script Terminated ***'
	GOTO PROC_END
END
-- End of Change - TT - 18/01/2017

BEGIN TRY
	
	-- User Specified Configuration
	DECLARE @DBServerName VARCHAR(100) = '*** INSERT SQL SERVER NAME ***'  	
	DECLARE @DBName VARCHAR(100) = '*** INSERT DATABASE NAME ***'  	
	-- Ensure @Path has a \ at the end of the string
	DECLARE @Path VARCHAR(500) = '*** INSERT SQL SCRIPT DIRECTORY ***'	

	DECLARE @FileName VARCHAR(500) 
	DECLARE @Command  VARCHAR(500)
	DECLARE @FileList TABLE(Files VARCHAR(500))
	DECLARE @ReturnCode INT
	DECLARE @ErrorMessage VARCHAR(2000)

	-- Added code to ensure @Path variable has a\ char at the end - TT - 30/01/2017
	IF SUBSTRING(@Path, LEN(@Path), 1) <> '\' SET @Path = @Path + '\'

	-- Added code to ensure @DBName does not start with '\\'
	IF SUBSTRING(@DBName, 1, 2) = '\\' SET @DBName = SUBSTRING(@DBName, 3, LEN(@DBName)) -- TT - 30/01/2017

	-- The following are all scripts that must be run. Each row of the table contains
	-- the full path and filename of a SQL script to be executed (including single and 
	-- quotes)	

	-- AutoEMail DB Structure Scripts
	-- Added code to differentiate between an install and an update - TT - 18/01/2017
	IF @PURPOSE = @INSTALL
	BEGIN		
		INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\Add_AFD_Finance_Tables.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\SetupFinanceLookupTable.sql' + '"')
	END
	ELSE IF @PURPOSE = @UPDATE
	BEGIN
		PRINT ''
	END
	-- End of Changes - TT - 18/01/2017

	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_CreateFIExportTable.sql' + '"')

	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_GetNLCode.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_getTemplateID_nameType.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_IsInternal.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_LocationCostCode.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_linecount.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_getFIDim1.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_getFIDim7.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'Fi0\usp_FI_Code_from_Tilda.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_FI_Code_to_Tilda.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\ActivateExtendedLocationsSwitch.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\Usp_WriteStringToFile.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\utf_ExportMappingInfo.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\vw_netted_Foltran.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_getFunc_or_AccomDecider.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_getExtClientRef.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_getCostCentre.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\uf_roomBuilding.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI0\usp_RULE_DateOnly.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\utf_getFITemplateLines.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\ufGetSelectionParameter.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\usp_RULE_Batch_No.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\Usp_RULE_LocationCostCode.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\usp_RULE_MBR_Name.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\vw_FOL_TRAN_CRED_SUMMARY.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\vw_FOL_TRAN_INV_SUMMARY.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\vw_FOL_TRAN_SUMMARY.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI1\uf_functionbuilding.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI2\usp_CABS_get_FI_Value_for_Invoice.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI3\usp_CreateExportFile_GNT.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI3\usp_CreateExportFile_HAL.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI3\usp_CreateExportFile_HALSUM.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI3\usp_CreateExportFile_GNTSUM.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'FI3\usp_CreateExportFile.sql' + '"')
	
	-- Loop through all the records in the files table ...
	WHILE (SELECT COUNT(Files) FROM @FileList) > 0  
	BEGIN 
		-- Initailise the error message variable
		SET @ErrorMessage = ''

		-- Get a formatted path and filename
		SET @FileName = (SELECT TOP(1) Files FROM @FileList)  

		-- Build the SQL command to run the SQL script
		SET @Command = 'sqlcmd -S ' + @DBServerName + ' -d  ' + @DBName + ' -i ' + @FileName
		PRINT 'EXECUTE: ' + @Command

		-- Execute the SQL command and store any status messages in the temporary table								
		INSERT #aetemp 
		EXEC @ReturnCode = master.dbo.xp_cmdshell @Command
		
		-- Check the return code. If it is non zero an error has occurred
		IF @ReturnCode <> 0
		BEGIN

			-- Get and store the error message
			SELECT @ErrorMessage = @ErrorMessage + StatusMessage   
			FROM #aetemp
			WHERE StatusMessage IS NOT NULL
 
			-- If required display the error message, return code amd SQL Command just executed
			-- SELECT @ErrorMessage as ErrorMessage, @ReturnCode as ReturnCode, @Command as Script
			
			-- Raise an error to halt execution of the script
			RAISERROR(@ErrorMessage, 11, 1)

		END

		-- Only here if last script ran without any errors.
		-- Delete any status messages and delete the SQL script pathname and filename from the tables variable 	
		-- Removed DELETE as will use table to report on failure/success - TT - 09/11/2016	
		--DELETE FROM #aetemp
		DELETE FROM @FileList WHERE Files = @FileName  

	END  
	-- Added SELECT to return failure/success messages - TT - 09/11/2016	
	SELECT * FROM #aetemp WHERE StatusMessage IS NOT NULL
	DELETE FROM #aetemp	
	PRINT 'FSI Installation/Update Completed Successfully'
	GOTO PROC_END
END TRY
BEGIN CATCH	
	PRINT 'FSI Installation/Update was Unsuccessful: ' + @ErrorMessage
	GOTO PROC_END
END CATCH  

PROC_END:
-- Tidy Up - Drop the Temp Table
DROP TABLE #aetemp

GO