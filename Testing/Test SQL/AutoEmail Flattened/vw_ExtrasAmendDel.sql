-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_ExtrasAmendDel.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ExtrasAmendDel]'))
BEGIN
DROP VIEW [dbo].[vw_ExtrasAmendDel]
PRINT 'vw_ExtrasAmendDel: Dropped View vw_ExtrasAmendDel'
END
ELSE
BEGIN
	PRINT 'vw_ExtrasAmendDel: View vw_ExtrasAmendDel Does Not Exist !'
END
PRINT 'vw_ExtrasAmendDel: Creating View vw_ExtrasAmendDel'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_ExtrasAmendDel]
AS
SELECT        dbo.AEF_Amendments.AEFA_FREF AS AI_FREF, dbo.AEF_Amendments.AEFA_PRIKEY AS AI_PRIKEY, dbo.AEF_Amendments.AEFA_START AS AI_TIME, 
                         dbo.AEF_Amendments.AEFA_END AS AI_ENDTIME, dbo.AEF_Amendments.AEFA_COVERS AS AI_COVERS, dbo.AEF_Amendments.AEFA_CHARGE AS AI_CHARGE, 
                         CONVERT(VARCHAR, dbo.AEF_Amendments.AEFA_NOTES) AS AI_TEXT, dbo.AEF_Amendments.AEFA_CODE AS AI_CODE, REPLACE(dbo.POST_DEF.P_DESC, CHAR(39), CHAR(146)) AS P_DESC, 
                         2 AS OrderBy
FROM            dbo.AEF_Amendments INNER JOIN
                         dbo.POST_DEF ON dbo.AEF_Amendments.AEFA_CODE = dbo.POST_DEF.P_CODE
WHERE        (dbo.AEF_Amendments.AEFA_ACTION IN('D'))
AND LEFT(AEFA_PRIKEY, 1) = '0'
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_ExtrasAmendDel: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtrasAmendDel]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtrasAmendDel') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_ExtrasAmendDel: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtrasAmendDel: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtrasAmendDel]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtrasAmendDel') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_ExtrasAmendDel: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtrasAmendDel: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtrasAmendDel]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtrasAmendDel') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_ExtrasAmendDel: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtrasAmendDel: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
