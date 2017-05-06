-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_FunctionCostCentres.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_FunctionCostCentres]'))
BEGIN
DROP VIEW [dbo].[vw_FunctionCostCentres]
PRINT 'vw_FunctionCostCentres: Dropped View vw_FunctionCostCentres'
END
ELSE
BEGIN
	PRINT 'vw_FunctionCostCentres: View vw_FunctionCostCentres Does Not Exist !'
END
PRINT 'vw_FunctionCostCentres: Creating View vw_FunctionCostCentres'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_FunctionCostCentres]
AS
SELECT DISTINCT TOP (100) PERCENT dbo.AI_FILE.AI_FREF, dbo.POST_DEF.P_COSTCENT
FROM            dbo.AI_FILE INNER JOIN
                         dbo.POST_DEF ON dbo.AI_FILE.AI_CODE = dbo.POST_DEF.P_CODE
UNION
SELECT DISTINCT TOP (100) PERCENT dbo.FUNC_FIL.F_REF, dbo.POST_DEF.P_COSTCENT
FROM            dbo.FUNC_FIL INNER JOIN
                         dbo.POST_DEF ON dbo.FUNC_FIL.F_ROOM = dbo.POST_DEF.P_CODE
UNION
SELECT DISTINCT TOP (100) PERCENT dbo.AI_FILE.AI_FREF, dbo.SERVCENT.SC_DEPT
FROM            dbo.AI_FILE INNER JOIN
                         dbo.SERVCENT ON dbo.AI_FILE.AI_CODE = dbo.SERVCENT.SC_EXTRA
UNION
SELECT DISTINCT TOP (100) PERCENT dbo.FUNC_FIL.F_REF, dbo.MASTMENU.MNM_OPGROUP
FROM            dbo.FUNC_FIL INNER JOIN
                         dbo.MASTMENU ON dbo.FUNC_FIL.F_REF = dbo.MASTMENU.MNM_OWNER
UNION
SELECT DISTINCT TOP (100) PERCENT dbo.DrinkTrolleyHead.DTH_OWNER, dbo.SERVCENT.SC_DEPT
FROM DrinkTrolleyHead
	INNER JOIN DrinkTrolleyItems ON dbo.DrinkTrolleyHead.DTH_SYSNO = dbo.DrinkTrolleyItems.DTI_SYSNO
	INNER JOIN SERVCENT ON dbo.DrinkTrolleyItems.DTI_POST = dbo.SERVCENT.SC_EXTRA                         
UNION
SELECT DISTINCT TOP (100) PERCENT dbo.PKGHEAD.PH_OWNER, dbo.POST_DEF.P_COSTCENT
FROM            dbo.PKGHEAD INNER JOIN
                         dbo.PACKAGES ON PH_SYSNO = PK_SYSNO
                         INNER JOIN
                         dbo.POST_DEF ON dbo.PACKAGES.PK_POST = dbo.POST_DEF.P_CODE
AND COALESCE(dbo.PKGHEAD.PH_OWNER, '') <> '' 
UNION
--ADDED 24/11/2015
SELECT DISTINCT TOP (100) PERCENT dbo.AEF_Amendments.AEFA_FREF, dbo.SERVCENT.SC_DEPT
FROM            dbo.AEF_Amendments INNER JOIN
                         dbo.SERVCENT ON dbo.AEF_Amendments.AEFA_CODE = dbo.SERVCENT.SC_EXTRA
WHERE dbo.AEF_Amendments.AEFA_ACTION = 'D'     
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_FunctionCostCentres: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_FunctionCostCentres]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_FunctionCostCentres') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_FunctionCostCentres: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_FunctionCostCentres: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_FunctionCostCentres]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_FunctionCostCentres') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_FunctionCostCentres: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_FunctionCostCentres: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_FunctionCostCentres]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_FunctionCostCentres') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_FunctionCostCentres: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_FunctionCostCentres: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
