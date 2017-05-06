-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_Menus.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_Menus]'))
BEGIN
DROP VIEW [dbo].[vw_Menus]
PRINT 'vw_Menus: Dropped View vw_Menus'
END
ELSE
BEGIN
	PRINT 'vw_Menus: View vw_Menus Does Not Exist !'
END
PRINT 'vw_Menus: Creating View vw_Menus'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_Menus]
AS
SELECT        dbo.MASTMENU.MNM_NAME, dbo.MASTMENU.MNM_PRICE, dbo.MADEMENU.MEN_POSITION, dbo.MADEMENU.MEN_COVERS, dbo.MADEMENU.MEN_ITEM_CODE,
                          REPLACE(dbo.MENUITEM.MNI_DESCRIPTION, CHAR(39), CHAR(146)) AS MNI_DESCRIPTION, dbo.MASTMENU.MNM_OWNER
FROM            dbo.MENUITEM INNER JOIN
                         dbo.MADEMENU ON dbo.MENUITEM.MNI_CODE = dbo.MADEMENU.MEN_ITEM_CODE LEFT OUTER JOIN
                         dbo.MASTMENU ON dbo.MADEMENU.MEN_MENU_CODE = dbo.MASTMENU.MNM_CODE
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_Menus: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Menus]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Menus') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_Menus: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Menus: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Menus]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Menus') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_Menus: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Menus: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Menus]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Menus') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_Menus: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Menus: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
