-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_PackCodeDept.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_PackCodeDept]'))
BEGIN
DROP VIEW [dbo].[vw_PackCodeDept]
PRINT 'vw_PackCodeDept: Dropped View vw_PackCodeDept'
END
ELSE
BEGIN
	PRINT 'vw_PackCodeDept: View vw_PackCodeDept Does Not Exist !'
END
PRINT 'vw_PackCodeDept: Creating View vw_PackCodeDept'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_PackCodeDept]
AS
	SELECT PKGHEAD.PH_SYSNO AS 'PACK', PACKAGES.PK_POST AS 'CODE', SERVCENT.SC_DEPT AS 'DEPT', SERVCENT.SC_LOC AS 'LOC'
	FROM PKGHEAD
	INNER JOIN PACKAGES ON PH_SYSNO = PK_SYSNO
	INNER JOIN SERVCENT ON PK_POST = SC_EXTRA
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_PackCodeDept: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_PackCodeDept]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_PackCodeDept') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_PackCodeDept: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_PackCodeDept: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_PackCodeDept]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_PackCodeDept') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_PackCodeDept: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_PackCodeDept: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_PackCodeDept]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_PackCodeDept') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_PackCodeDept: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_PackCodeDept: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
