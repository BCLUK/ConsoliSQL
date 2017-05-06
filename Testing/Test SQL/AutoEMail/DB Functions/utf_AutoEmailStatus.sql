-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Removed 07/03/2017 PRINT '*****************************************************************************' 

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[utf_AutoEmailStatus]'))
BEGIN
	DROP FUNCTION [dbo].[utf_AutoEmailStatus]	
	PRINT 'utf_AutoEmailStatus: Dropped Procedure utf_AutoEmailStatus'
END
ELSE
BEGIN	
	PRINT 'utf_AutoEmailStatus: utf_AutoEmailStatus -  Does Not Already Exist !'
END

PRINT 'utf_AutoEmailStatus: Creating Function utf_AutoEmailStatus'
GO

-- ====================================================================================================================
-- Author:		Tony Tasker				
-- Create Date:	16/02/2017
-- Description:	Returns a table displaying the current status of the AutoEmail Queue
-- Module:		AutoEmail
-- Parameters:	Function Reference
-- Returns:		TABLE
-- Switches:	None
-- Test:		SELECT * from [dbo].utf_AutoEmailStatus('F664690') or
--				SELECT * from [dbo].utf_AutoEmailStatus('')
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		2.0
-- Date:		16/02/2017
-- ====================================================================================================================
-- Changes (1.0): TT: 16/02/2017: Original Version
-- Changes (2.0): TT: 07/03/2017: Removed PRINT '****' statements at start/end of procedure as impacted install script
-- ====================================================================================================================
CREATE FUNCTION utf_AutoEmailStatus 
(	
	-- Add the parameters for the function here
	@FREF VARCHAR(7) = ''
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT	  AEFL_ID AS[ID]
			, AEFL_FREF AS FREF
			, AEFL_SessNo AS SESSNO
			, AEFL_FDay AS FDAY
			, AEFL_Sent AS [SENT]
			, AEFL_CanSend	AS CANSEND					
			, XCC.VALUE AS Frequency			
			,(CASE (Substring(dbo.fnGet_Config_Value('S', '', AEFL_EMailType, 'Frequency'), 
                    PATINDEX('%L%', dbo.fnGet_Config_Value('S', '', AEFL_EMailType, 'Frequency')) + 2, 2)) 
				WHEN 'NW'
					THEN AEFL_SendTime 
				ELSE 
					dbo.uf_GetemailSendTime(AEFL_EmailType, AEFL_FREF) 
				END) AS SendTime
			, AEFL_EMailType AS EMailType
			, DM3.DM_STATUS AS SessionSendStatus
			, DM1.DM_STATUS AS SendStatus
			, DM2.DM_STATUS AS MatchStatus																	
			, DM3.DM_Description AS SessionSendableDescription						
			, DM1.DM_Description AS SendableDescription			
			, DM2.DM_Description AS MatchDescription
			, dbo.uf_IsSendableSessBooking(AEFL_SessNo, AEFL_FREF, AEFL_EMailType, AEFL_Source) AS SessionSendable			
			, (CASE dbo.uf_IsSendableSessBooking(AEFL_SessNo, AEFL_FREF, AEFL_EMailType, AEFL_Source) 
				WHEN 0 
					THEN 0 
				ELSE dbo.uf_AEF_Link_Sendable(AEFL_FREF, 
                     AEFL_EMailType) 
				END) AS Sendable
			, dbo.ufAEF_MatchCriteria(AEFL_FREF, AEFL_EMailType) AS MatchCriteria			
			, AEFL_Department
			, AEFL_EmailSPROC
			, AEFL_MBRNo
			, AEFL_Source AS [SOURCE]
			, AEFL_LastUpdate
FROM dbo.AEF_LINK INNER JOIN DiagnosticMessages DM1
						ON dbo.uf_AEF_Link_Sendable(AEFL_FREF, AEFL_EMailType) = DM1.DM_CODE AND DM1.DM_USED_IN = 'uf_AEF_Link_Sendable'				  
				  INNER JOIN DiagnosticMessages DM2	
						ON dbo.ufAEF_MatchCriteria(AEFL_FREF, AEFL_EMailType) = DM2.DM_CODE AND DM2.DM_USED_IN = 'ufAEF_MatchCriteria'				  
				  INNER JOIN DiagnosticMessages DM3
						ON dbo.uf_IsSendableSessBooking(AEFL_SessNo, AEFL_FREF, AEFL_EMailType, AEFL_Source) = DM3.DM_CODE AND DM3.DM_USED_IN = 'uf_IsSendableSessBooking'
				  LEFT OUTER JOIN xCABS_CONFIG_TABLE XCC 
						ON [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = AEFL_EMailType AND [KEY] = 'Frequency'
WHERE AEFL_FREF LIKE 
	CASE @FREF 
	WHEN '' 
		THEN '%F%'
	ELSE 
		@FREF
	END	
)
GO

IF EXISTS ( SELECT * FROM   sys.objects 
			WHERE  object_id = object_id(N'[dbo].[utf_AutoEmailStatus]'))
BEGIN	
	PRINT 'utf_AutoEmailStatus: utf_AutoEmailStatus Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_AutoEmailStatus: utf_AutoEmailStatus Not Created Successfully !'	
END

-- Removed 07/03/2017 PRINT '*****************************************************************************' 

GO

PRINT '*****************************************************************************'								   
PRINT 'utf_AutoEmailStatus: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_AutoEmailStatus]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_AutoEmailStatus') AND [name] = 'Product')
BEGIN		
	PRINT 'utf_AutoEmailStatus: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_AutoEmailStatus: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_AutoEmailStatus]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_AutoEmailStatus') AND [name] = 'Module')
BEGIN		
	PRINT 'utf_AutoEmailStatus: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_AutoEmailStatus: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_AutoEmailStatus]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_AutoEmailStatus') AND [name] = 'Version')
BEGIN		
	PRINT 'utf_AutoEmailStatus: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_AutoEmailStatus: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO