-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_Packages.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_Packages]'))
BEGIN
DROP VIEW [dbo].[vw_Packages]
PRINT 'vw_Packages: Dropped View vw_Packages'
END
ELSE
BEGIN
	PRINT 'vw_Packages: View vw_Packages Does Not Exist !'
END
PRINT 'vw_Packages: Creating View vw_Packages'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_Packages]
AS
SELECT        dbo.PKGHEAD.PH_SYSNO, dbo.PKGHEAD.PH_CODE, dbo.PKGHEAD.PH_DESC, dbo.PACKAGES.PK_POST, REPLACE(dbo.POST_DEF.P_DESC, CHAR(39), CHAR(146)) AS P_DESC, dbo.PACKAGES.PK_COVERS, 
                         dbo.PKGHEAD.PH_OWNER, dbo.PACKAGES.PK_SEQ
FROM            dbo.POST_DEF RIGHT OUTER JOIN
                         dbo.PACKAGES ON dbo.POST_DEF.P_CODE = dbo.PACKAGES.PK_POST FULL OUTER JOIN
                         dbo.PKGHEAD ON dbo.PACKAGES.PK_SYSNO = dbo.PKGHEAD.PH_SYSNO
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_Packages: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Packages]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Packages') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_Packages: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Packages: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Packages]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Packages') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_Packages: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Packages: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Packages]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Packages') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_Packages: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Packages: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
