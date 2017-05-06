-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_AEFLink.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================

IF EXISTS (SELECT name FROM sys.objects WHERE name = 'vw_AEFLink')
BEGIN	
	DROP VIEW [dbo].vw_AEFLink
	PRINT 'vw_AEFLink: Dropped View vw_AEFLink'
END
ELSE
BEGIN
	PRINT 'vw_AEFLink: View vw_AEFLink Does Not Exist !'
END
PRINT 'vw_AEFLink: Creating View vw_AEFLink'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Added column AEFL_LastUpdate to the view from AEF_LINK - TT - 02/11/2016
CREATE VIEW [dbo].[vw_AEFLink]
AS
SELECT        AEFL_ID, AEFL_FREF, AEFL_EMailType, AEFL_CanSend, AEFL_FDay, AEFL_Sent, (CASE (Substring(dbo.fnGet_Config_Value('S', '', AEFL_EMailType, 'Frequency'), 
                         PATINDEX('%L%', dbo.fnGet_Config_Value('S', '', AEFL_EMailType, 'Frequency')) + 2, 2)) 
                         WHEN 'NW' THEN AEFL_SendTime ELSE dbo.uf_GetemailSendTime(AEFL_EmailType, AEFL_FREF) END) AS AEFL_SendTime, AEFL_Source, 
                         dbo.uf_IsSendableSessBooking(AEFL_SessNo, AEFL_FREF, AEFL_EMailType, AEFL_Source) AS SessionSendable, 
                         (CASE dbo.uf_IsSendableSessBooking(AEFL_SessNo, AEFL_FREF, AEFL_EMailType, AEFL_Source) WHEN 0 THEN 0 ELSE dbo.uf_AEF_Link_Sendable(AEFL_FREF, 
                         AEFL_EMailType) END) AS Sendable, dbo.ufAEF_MatchCriteria(AEFL_FREF, AEFL_EMailType) AS MatchCriteria, AEFL_SessNo, AEFL_Department, 
                         AEFL_EmailSPROC, AEFL_MBRNo, AEFL_LastUpdate
FROM            dbo.AEF_Link
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_AEFLink: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_AEFLink]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_AEFLink') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_AEFLink: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_AEFLink: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_AEFLink]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_AEFLink') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_AEFLink: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_AEFLink: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_AEFLink]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_AEFLink') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_AEFLink: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_AEFLink: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
