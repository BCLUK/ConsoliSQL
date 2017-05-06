-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'ae_INS_EmailTypes_AEF_Link_MBR'
SET @SPROC_Name = 'ae_INS_EmailTypes_AEF_Link_MBR'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE object_id = object_id(N'[dbo].[ae_INS_EmailTypes_AEF_Link_MBR]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[ae_INS_EmailTypes_AEF_Link_MBR]
	PRINT @FileName + ': Dropped Procedure ' + @SPROC_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @SPROC_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Procedure ' + @SPROC_Name
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================ 
-- Author:		Tony Tasker
-- Create date: 28/07/2016
-- Description:	To Insert Email Types into AEF_Link per booking
--				Based on ae_INS_EmailTypes_AEF_Link but for 
--				driven from MBR as opposed to a Function
-- =============================================================
-- Version: 4
-- Date: 23/03/2017
-- =================================================================
-- Changes: 28/07/2016: TT: Original
-- Changes: 01/11/2016: TT: Added GETDATE() to INSERT INTO 
--	(2)						AEF_LINK .... to account for new column 
--							AEFL_LastUpdate
-- Changes: 24/11/2016: TT: Added code to allow email templates to 
--	(3)						be enabled specifically for changes to
--							tables Func_Fil or AI_FILE or ACxx 
-- Changes: 23/03/2017: TT: Removed call to stored procedure 
--	(4)						CABS_CREATE_AUTOEMAILER_TABLES as it 
--							should not be needed if the build processs is robust
--							Removed check for table AEF_LINK 	 
-- =================================================================
CREATE PROCEDURE [dbo].[ae_INS_EmailTypes_AEF_Link_MBR] 
	@BookingDateTime DATETIME, @CanSend INT, @Source VARCHAR(50), @Action VARCHAR(1), @MBR_NO VARCHAR(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Removed check for table existing - it does - TT - 23/03/2017
	--DECLARE @TableExists INT
	--SET @TableExists = 0

	-- Removed check for table exisiting - it does - TT - 23/03/2017
	--if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Link]')) = 1
	--BEGIN
	-- Removed call to CABS_CREATE_AUTOEMAILER_TABLES - TT - 23/03/2017
	-- EXEC CABS_CREATE_AUTOEMAILER_TABLES

	-- Removed check for table existing - it does - TT - 23/03/2017
	--if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Link]')) = 1
	--BEGIN
	--	SET @TableExists = 1
	--END			

	-- Removed check for table existing - it does - TT - 23/03/2017
	--IF @TableExists = 1
	--BEGIN			
	DECLARE
		@EmailType VARCHAR(6),
		@Enabled INT,
		@Frequency VARCHAR(1000),
		@SendFrequency VARCHAR(1000),
		@SendMinutes INT,
		@SendDateTime DATETIME,
		@EarliestSendTest Varchar(100),
		@EarliestSendDate DAteTime,  
		@EmailSPROC VARCHAR(200),
		@FREF VARCHAR(7),
		@SessionNumber VARCHAR(10) = '',
		@Department VARCHAR(MAX) = ''
	
	DECLARE
		AEF_EMAIL_TEMPLATES
	CURSOR FAST_FORWARD for
		
		-- This may be expanded in the future but for at present only autoemail
		-- that can be sent this way is AEFCEC
		SELECT ST_CODE  
		FROM SYS_ABBR
		WHERE ST_TYPE = 'AET' AND ST_CODE = 'AEFECC'
		
	OPEN AEF_EMAIL_TEMPLATES

	FETCH NEXT FROM
		AEF_EMAIL_TEMPLATES
	INTO
		@EmailType

	WHILE @@FETCH_STATUS = 0
	BEGIN			
		-- @EmailSPROC will get a template specific stored procedure from X Cabs Config if one exists - the default value will be CABS_AUTO_EMAIL_FUNCS_SEND
		SET @EmailSPROC = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'EmailSPROC')), 'CABS_AUTO_EMAIL_FUNCS_SEND')

		-- Check to see if template is enabled for specific action (action will be I for insert or U for update)
		-- Added code to allow email templates to be enabled specifically for changes to tables Func_Fil or AI_FILE or ACxx - TT - 24/11/2016
		--SET @Enabled = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'Enabled')), '0'), @Action))
		SET @Enabled = (SELECT [dbo].[uf_Get_AEF_EnabledSwitch](@EmailType, @Action))
		-- End of changes - TT - 24/11/2016		

		SET @Frequency = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'Frequency')), 'D:1;H:0;M:0')
		SET @SendFrequency = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @EmailType, 'SendFrequency')), 'N')
			
		-- ========================================================================
		-- GET OLDEST F_REF
		-- Because this relates to an MBR Change assumes
		-- that an MBR exists for each event
		-- The first function can be used to get other data required for autoemail
		-- ========================================================================
		SET @FREF = (SELECT TOP 1 F_REF FROM FUNC_FIL where F_MBR_NO = @MBR_NO ORDER BY F_STARTDATETIME)

		-- added plg 6-3-15  to test for cutoff dates
		Set @EarliestSendDate = dbo.uf_GetEmailEarlyCutOff(@EmailType, @FREF)
			
		-- =============================================
		-- GET SEND DATE/TIME
		-- =============================================	
		SET @SendMinutes = (SELECT [dbo].[fn_GetMinsValue]( @Frequency) )		
			
		-- Get SendDateTime
		SET @SendDateTime = (SELECT dbo.uf_GetEmailSendTime( @EmailType, @FREF))
			
		-- Either Insert or Update record in AEF_LINK	
		IF (@Enabled > 0) and (DATEDIFF(minute,@earliestSendDate,@Senddatetime) > 0) BEGIN
			IF (SELECT COUNT(*) FROM AEF_Link WHERE AEFL_EMailType = @EmailType AND AEFL_MBRNo = @MBR_NO) = 0 BEGIN
				INSERT INTO AEF_Link
					
				-- 01/11/2016 - TT - Added GETDATE() to INSERT INTO AEF_LINK .... to account for new column AEFL_LastUpdate	
				SELECT @FREF, @SessionNumber, @EmailType, @CanSend, @BookingDateTime, 0, @SendDateTime, @Source, @Department, @EmailSPROC, @MBR_NO, GETDATE()			
			END	
			ELSE
			IF (SELECT COUNT(*) FROM AEF_Link WHERE AEFL_EMailType = @EmailType AND AEFL_MBRNo = @MBR_NO) > 0 BEGIN
				UPDATE AEF_Link
					SET AEFL_CanSend = @CanSend,
					AEFL_SendTime = @SendDateTime,
					AEFL_Sent = 0,
					AEFL_SessNo = @SessionNumber,
					AEFL_SOURCE = @Source,					
					AEFL_Department =	CASE AEFL_Sent 
											WHEN 0 THEN 
												CASE (patindex('%'+ @Department +'%', AEFL_Department)) 
													WHEN 0 THEN AEFL_Department + @Department
													ELSE AEFL_Department
												END
											WHEN 1 THEN @Department 
										END,				
					AEFL_EmailSPROC = @EmailSPROC,
					AEFL_MBRNo = @MBR_NO,						
					-- 01/11/2016 - TT - Added GETDATE() to INSERT INTO AEF_LINK .... to account for new column AEFL_LastUpdate	
					AEFL_LastUpdate = GETDATE()					
				WHERE AEFL_MBRNo = @MBR_NO AND
						AEFL_EMailType = @EmailType
			END					
		END
	
		FETCH NEXT FROM 
			AEF_EMAIL_TEMPLATES
		INTO
			@EmailType
	END

	CLOSE AEF_EMAIL_TEMPLATES
	DEALLOCATE AEF_EMAIL_TEMPLATES
	-- Removed check for table existing - it does - TT - 23/03/2017				
	--END --Table Exists
END
GO

PRINT '*****************************************************************************'

PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link_MBR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link_MBR') AND [name] = 'Product')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link_MBR]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link_MBR') AND [name] = 'Module')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [ae_INS_EmailTypes_AEF_Link_MBR]
							   ,@name = N'Version' 
							   ,@value = N'4.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ae_INS_EmailTypes_AEF_Link_MBR') AND [name] = 'Version')
BEGIN		
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ae_INS_EmailTypes_AEF_Link_MBR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO