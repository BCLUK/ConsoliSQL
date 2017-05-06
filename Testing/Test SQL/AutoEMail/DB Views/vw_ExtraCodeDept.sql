-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_ExtraCodeDept.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_ExtraCodeDept]'))
BEGIN
DROP VIEW [dbo].[vw_ExtraCodeDept]
PRINT 'vw_ExtraCodeDept: Dropped View vw_ExtraCodeDept'
END
ELSE
BEGIN
	PRINT 'vw_ExtraCodeDept: View vw_ExtraCodeDept Does Not Exist !'
END
PRINT 'vw_ExtraCodeDept: Creating View vw_ExtraCodeDept'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_ExtraCodeDept]
AS
	SELECT     POST_DEF.P_CODE AS 'CODE', POST_DEF.P_COSTCENT AS 'DEPT', CASE POST_DEF.P_COSTCENT WHEN 'CCHIRE' THEN (SELECT RM_LOC FROM ROOMS WHERE RM_ABBR = POST_DEF.P_CODE) ELSE 'EC' END AS 'LOC'
	FROM         POST_DEF
	UNION
	SELECT SERVCENT.SC_EXTRA, SERVCENT.SC_DEPT, SERVCENT.SC_LOC
	FROM SERVCENT
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_ExtraCodeDept: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtraCodeDept]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtraCodeDept') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_ExtraCodeDept: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtraCodeDept: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtraCodeDept]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtraCodeDept') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_ExtraCodeDept: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtraCodeDept: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_ExtraCodeDept]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_ExtraCodeDept') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_ExtraCodeDept: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_ExtraCodeDept: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
