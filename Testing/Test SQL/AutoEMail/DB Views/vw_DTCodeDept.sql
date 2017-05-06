-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_DTCodeDept.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_DTCodeDept]'))
BEGIN
DROP VIEW [dbo].[vw_DTCodeDept]
PRINT 'vw_DTCodeDept: Dropped View vw_DTCodeDept'
END
ELSE
BEGIN
	PRINT 'vw_DTCodeDept: View vw_DTCodeDept Does Not Exist !'
END
PRINT 'vw_DTCodeDept: Creating View vw_DTCodeDept'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_DTCodeDept]
AS
	SELECT DrinkTrolleyHead.DTH_SYSNO AS 'DT', DrinkTrolleyItems.DTI_POST AS 'CODE', SERVCENT.SC_DEPT AS 'DEPT', SERVCENT.SC_LOC AS 'LOC'
	FROM DrinkTrolleyHead
	INNER JOIN DrinkTrolleyItems ON DTH_SYSNO = DTI_SYSNO
	INNER JOIN SERVCENT ON DTI_POST = SC_EXTRA
GO
PRINT '*****************************************************************************'								   
PRINT 'vw_DTCodeDept: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DTCodeDept]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DTCodeDept') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_DTCodeDept: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DTCodeDept: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DTCodeDept]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DTCodeDept') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_DTCodeDept: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DTCodeDept: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DTCodeDept]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DTCodeDept') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_DTCodeDept: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DTCodeDept: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
