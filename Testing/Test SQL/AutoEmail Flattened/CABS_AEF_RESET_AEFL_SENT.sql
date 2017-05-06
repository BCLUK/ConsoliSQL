-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_AEF_RESET_AEFL_SENT'
SET @SPROC_Name = 'CABS_AEF_RESET_AEFL_SENT'
IF EXISTS ( SELECT * FROM sys.objects 
            WHERE  object_id = object_id(N'[dbo].[CABS_AEF_RESET_AEFL_SENT]') 
                   and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].CABS_AEF_RESET_AEFL_SENT
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

-- ==========================================================================
-- Author:		Tony Tasker
-- Create date: 16/06/2016
-- Description:	Resets AEFL_Sent to 0 in table AEF_LINK
--				This code will run just after midnight (or when scheduled to 
--				in Job "SHU] Auto-Emailer Recurring Emails Check") 
--				This will enable the AEFL_SendTime to be updated to the time 
--				and date of the next scheduled sending of the email based on
--				X CABS Config settings			
-- =========================================================================
-- Version: 3
-- Date: 28/11/2016
-- =========================================================================
-- Changes: 16/06/2016: TT:  Original Version
--  (1)
-- Changes: 28/11/2016: TT:  Added new function reference (FFFFFFD) for 
--	(2)						 Summary Weekly Reminder Email
-- Changes: 13/03/2017: TT:  Changed code to only reset sent flag for a 
--	(3)						 specific autoemail when that autoemail is 
--							 enabled 
-- ==========================================================================

CREATE PROCEDURE [dbo].[CABS_AEF_RESET_AEFL_SENT] 
	
AS
BEGIN	
	SET NOCOUNT ON;

	-- Added new function reference (FFFFFFD) for Summary Weekly Reminder Email - TT - 28/11/2016
	--UPDATE AEF_Link SET AEFL_Sent = 0 WHERE AEFL_Sent = 1 AND (AEFL_FREF = 'FFFFFFE' OR AEFL_FREF = 'FFFFFFF')
	-- Removed generic reset code - TT - 13/03/2017
	--UPDATE AEF_Link SET AEFL_Sent = 0 WHERE AEFL_Sent = 1 
	--									AND (AEFL_FREF = 'FFFFFFD' OR 
	--										 AEFL_FREF = 'FFFFFFE' OR 
	--										 AEFL_FREF = 'FFFFFFF')

	-- Added in code to individually reset recurring autoemails (tend to be used for report emails) 
	-- only if the individual autoemail is enabled - TT - 13/03/2017
	IF dbo.uf_Get_AEF_EnabledSwitch('AEFUIE','') > 0
		UPDATE AEF_Link SET AEFL_Sent = 0 WHERE AEFL_Sent = 1 AND AEFL_FREF = 'FFFFFFF'
	
	IF dbo.uf_Get_AEF_EnabledSwitch('AEFUPE','') > 0
		UPDATE AEF_Link SET AEFL_Sent = 0 WHERE AEFL_Sent = 1 AND AEFL_FREF = 'FFFFFFE'

	IF dbo.uf_Get_AEF_EnabledSwitch('AEFSWR','') > 0
		UPDATE AEF_Link SET AEFL_Sent = 0 WHERE AEFL_Sent = 1 AND AEFL_FREF = 'FFFFFFD'
	--End of changes - 13/03/2017
    
END
GO

PRINT '*****************************************************************************'

PRINT 'CABS_AEF_RESET_AEFL_SENT: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_RESET_AEFL_SENT]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_RESET_AEFL_SENT') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_RESET_AEFL_SENT]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_RESET_AEFL_SENT') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_AEF_RESET_AEFL_SENT]
							   ,@name = N'Version' 
							   ,@value = N'3.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_AEF_RESET_AEFL_SENT') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_AEF_RESET_AEFL_SENT: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO