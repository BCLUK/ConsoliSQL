-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 18/10/2016
-- Description:	This stored procedure wrtten to run autoemail installation or update sql scripts.
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
-- Version:		15
-- Date:		27/03/2017
-- =====================================================================================================
-- Changes:	TT: 09/11/2016: Original Version
--  (1)
-- Changes:	TT: 09/11/2016: Added lines for complete AutoEMail install
--				09/11/2016: Changed code to allow for success/failure messages to be displayed
--  (2)
-- Changes:	TT: 21/11/2016: Added line for CABS_AEF_SEND_PRK.sql
--  (3)
-- Changes:	TT: 30/11/2016: Updated for recent AutoEmail code changes
--  (4)
-- Changes:	TT: 18/01/2017: Updated to facilitate either an update or an installation
--  (5)
-- Changes:	TT: 19/01/2017: Updated ensure no variables are preset
--  (6)
-- Changes:	TT: 24/01/2017: Added function FuncValue to install script
--  (7)
-- Changes:	TT: 30/01/2017: Added code to remove '\\' fro mstart of DBName if exists and also
--  (8)						to add a '\' to @Path of it does not exist
-- Changes:	TT: 20/02/2017: Added code to the install the autoemail diagnostic script files
--  (9)						(tab_DiagnosticMessages_CREATE and utf_AutoEmailStatus)
-- Changes:	TT: 08/03/2017: Removed 09. CABS_AEF_SEND_CHN.sql, 11. CABS_AEF_SEND_PRQ.sql, 14a. 
--  (10)					CABS_AEF_SEND_SFD.sql and 16a. CABS_AEF_SEND_ECC.sql from the installation
--							as they are not used by any clients
-- Changes:	TT: 16/03/2017: Changed the filenames of the stored procedures to reflect the actual
--  (11)					stored procedure names
-- Changes:	TT: 21/03/2017: Changed the filenames of the functions to reflect the actual
--  (12)					function names
-- Changes:	TT: 21/03/2017: Changed the filenames of the views to reflect the actual
--  (13)					function names
-- Changes:	TT: 21/03/2017: Removed 00. CABS_CREATE_AUTOEMAILER_TABLES.sql from script as no longer 
--  (14)					required
-- Changes:	TT: 27/03/2017: Added script to rationalise build - ensure extended properties are added
--  (15)					to objects that cant be dropped (tables) and drop any deprecated objects
--							Changed SQL Job filenames to reflect actual name of scheduled jobs
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

IF @PURPOSE = @INSTALL
BEGIN
	PRINT '*** This script will perform a clean install of the AutoEmail Module ***'
END
ELSE IF @PURPOSE = @UPDATE
BEGIN
	PRINT '*** This script will perform an update to the AutoEmail Module ***'
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

	-- Added - TT - 30/11/2016
	-- Miscellaneous Scripts Required by AutoEmail (19. CABS_AEF_SEND_SWR.sql) - 
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_GetMBRName.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getMBR_Internal.sql' + '"')
	-- End of Changes 
	-- Added - TT - 24/01/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'FuncValue.sql' + '"')
	--End of CHanges - TT - 24/01/2017

	-- AutoEMail DB Structure Scripts
	-- Added code to differentiate between an install and an update - TT - 18/01/2017
	IF @PURPOSE = @INSTALL
	BEGIN
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_AEF_Amendments_CREATE.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_AEF_LINK_CREATE.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_AutoEmailFunction_CREATE.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_AutoEmailFunction_FromTrigger_CREATE.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_AutoEmailFunction_SEND_PARAMS_CREATE.sql' + '"')
		INSERT INTO @FileList VALUES('"' + @PATH + 'tab_MenuActivityCount_CREATE.sql' + '"')
	END
	ELSE IF @PURPOSE = @UPDATE
	BEGIN
		-- Changed the name of table filename - TT - 22/03/2017
		INSERT INTO @FileList VALUES('"' + @PATH + 'AutoEmailFunction_FromTrigger_ALTER.sql' + '"')
		-- Split code out to separate files ix_Config_SessNo_EmailType_Sent.sql and ix_Config_FREF_EmailType.sql- TT - 23/03/2017
		-- INSERT INTO @FileList VALUES('"' + @PATH + '01d.AEFLINK_Table_Index.sql' + '"')
		-- Changed the name of table filename - TT - 22/03/2017
		INSERT INTO @FileList VALUES('"' + @PATH + 'AEF_LINK_ALTER.sql' + '"')
	END
	-- End of Changes - TT - 18/01/2017
	
	-- Added new files which have split out from 01d.AEFLINK_Table_Index.sql - TT - 23/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'ix_Config_SessNo_EmailType_Sent.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ix_Config_FREF_EmailType.sql' + '"')
	
	-- Added - TT - 20/02/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'tab_DiagnosticMessages_CREATE.sql' + '"')

	-- Removed as code no longer required - TT - 23/03/2017
	-- INSERT INTO @FileList VALUES('"' + @PATH + '00. CABS_CREATE_AUTOEMAILER_TABLES.sql' + '"')	

	-- Split codedout into separate files ix_Config_Type_Section_Key_Deleted.sql and ix_Config_Type_Section_Deleted.sql - TT - 23/03/2017
	-- INSERT INTO @FileList VALUES('"' + @PATH + '01c.xCABS_Config_Table_Index.sql' + '"')

	-- Added new files which have split out from 01c.xCABS_Config_Table_Index.sql - TT - 23/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'ix_Config_Type_Section_Key_Deleted.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ix_Config_Type_Section_Deleted.sql' + '"')
	
	-- AutoEMail DB Functions Scripts
	
	-- Added - TT - 20/02/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'utf_AutoEmailStatus.sql' + '"')
	-- Changed the names of the function filenames - TT - 21/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_IsDateABankHoliday.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getDepteMail.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_HasRoomBeenGiven.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_CreateDateDiff.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getDeptCodes.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getFunctionDeptEmails.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'fn_GetEnabledValue.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'fn_GetHiddenRoomText.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'fn_GetMinsValue.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'fn_GetTimeValue.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'fnGet_Config_Value.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_IsSendableSessBooking.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_GetEmailEarlyCutOff.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getExtraDescription.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_getMenuItemDescription.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'utf_DrinkTrolleyView.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'utf_MenuView.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'utf_PackageView.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_GetMenuItemCount.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_AEF_Link_Sendable.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_GetEmailSendTime.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_GetEmailSendType.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_FirstName_From_CT_DESC.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_LastName_From_CT_DESC.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_TelNo_From_CT_DESC.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_EC_Email.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_Acc_Man_Email.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_Acc_Man_FirstName.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_Acc_Man_LastName.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_Acc_Man_Telephone.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_EC_LastName.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_EC_Telephone.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_EC_FirstName.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ufAEF_MatchCriteria.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_AEF_Is_Within_Send_Window.sql' + '"')
	-- Added - TT - 30/11/2016
	INSERT INTO @FileList VALUES('"' + @PATH + 'uf_Get_AEF_EnabledSwitch.sql' + '"')
	-- End of Changes - TT - 21/03/2017

	-- AutoEMail DB Views Scripts
	-- Changed the names of the function filenames - TT - 22/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_AEFLink.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_Extras.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_PackCodeDept.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_Packages.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_Menus.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_DTCodeDept.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_DrinkTrolley.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_ExtraCodeDept.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_FunctionCostCentres.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'vw_ExtrasAmendDel.sql' + '"')
	-- End of Changes - TT - 22/03/2017

	-- AutoEMail DB Stored Procedures Scripts
	-- Changed the names of the stored procedure filenames - TT - 16/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'ae_DEL_AEF_Amendments.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_CREATE_BOOKING_UPDATE_TABLES.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AUTO_BOOKING_UPDATE.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ae_UPD_AEF_Amendments.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ae_INS_AEF_Amendments.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'ae_INS_EmailTypes_AEF_Link.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'spAutoEmail_MenuItems.sql' + '"')	
	INSERT INTO @FileList VALUES('"' + @PATH + 'ae_INS_EmailTypes_AEF_Link_MBR.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_RESET_AEFL_SENT.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_DELETE_RECORDS.sql' + '"')
	-- Removed - No longer required - TT - 08/03/2017
	-- INSERT INTO @FileList VALUES('"' + @PATH + '09. CABS_AEF_SEND_CHN.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_CXL.sql' + '"')
	-- Removed - No longer required - TT - 08/03/2017
	--INSERT INTO @FileList VALUES('"' + @PATH + '11. CABS_AEF_SEND_PRQ.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_DOB.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_UIE.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_UPE.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AUTO_EMAIL_FUNCS_SEND.sql' + '"')
	-- Removed - No longer required - TT - 08/03/2017
	-- INSERT INTO @FileList VALUES('"' + @PATH + '14a. CABS_AEF_SEND_SFD.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AUTO_EMAIL_FUNCS.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AUTO_EMAIL_FUNCS_SESS_CHECK.sql' + '"')
	-- Removed - No longer required - TT - 08/03/2017
	--INSERT INTO @FileList VALUES('"' + @PATH + '16a. CABS_AEF_SEND_ECC.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_FFC.sql' + '"')
	-- Added line for CABS_AEF_SEND_PRK.sql - TT - 21/11/2016
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_PBK.sql' + '"')
	-- Added - TT - 30/11/2016
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_DRM.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'CABS_AEF_SEND_SWR.sql' + '"')
	-- End of Changes - TT - 16/03/2017

	-- AutoEMail Triggers
	-- Changed the names of the trigger filenames - TT - 23/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_Class.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_Booking.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_Extras.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAE_MenuActivityCountDEL.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_MenuItems.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_PackageItems.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_DrinkTrolleyItems.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_DrinkTrolley.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_Menus.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'trAutoEmail_Packages.sql' + '"')
	-- End of Changes - TT - 23/03/2017

	-- Rationalise version - TT - 27/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'Rationalise_Build.sql' + '"')

	-- AutoEMail Scheduled Job Scripts
	-- Changed the names of the scheduled job filename - TT - 27/03/2017
	INSERT INTO @FileList VALUES('"' + @PATH + 'Auto-Emailer Session Check.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'Auto-Emailer Recurring Emails Check.sql' + '"')
	INSERT INTO @FileList VALUES('"' + @PATH + 'Auto-Emailer AEF_LINK Delete.sql' + '"')
	-- End of Changes
	
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
	PRINT 'AutoEmail Installation/Update Completed Successfully'
	GOTO PROC_END
END TRY
BEGIN CATCH	
	PRINT 'AutoEmail Installation/Update was Unsuccessful: ' + @ErrorMessage
	GOTO PROC_END
END CATCH  

PROC_END:
-- Tidy Up - Drop the Temp Table
DROP TABLE #aetemp

GO