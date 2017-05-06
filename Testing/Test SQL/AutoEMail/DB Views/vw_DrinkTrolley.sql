-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_DrinkTrolley.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_DrinkTrolley]'))
BEGIN
DROP VIEW [dbo].[vw_DrinkTrolley]
PRINT 'vw_DrinkTrolley: Dropped View vw_DrinkTrolley'
END
ELSE
BEGIN
	PRINT 'vw_DrinkTrolley: View vw_DrinkTrolley Does Not Exist !'
END
PRINT 'vw_DrinkTrolley: Creating View vw_DrinkTrolley'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_DrinkTrolley]
AS
SELECT        dbo.DrinkTrolleyHead.DTH_SYSNO, dbo.DrinkTrolleyHead.DTH_CODE, dbo.DrinkTrolleyHead.DTH_DESC, dbo.DrinkTrolleyHead.DTH_OWNER, 
                         dbo.DrinkTrolleyItems.DTI_POST, dbo.POST_DEF.P_DESC, dbo.DrinkTrolleyItems.DTI_SEQ, dbo.DrinkTrolleyItems.DTI_QTYSUPPLIED
FROM            dbo.POST_DEF INNER JOIN
                         dbo.DrinkTrolleyItems ON dbo.POST_DEF.P_CODE = dbo.DrinkTrolleyItems.DTI_POST LEFT OUTER JOIN
                         dbo.DrinkTrolleyHead ON dbo.DrinkTrolleyItems.DTI_SYSNO = dbo.DrinkTrolleyHead.DTH_SYSNO
GO

PRINT '*****************************************************************************'								   
PRINT 'vw_DrinkTrolley: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DrinkTrolley]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DrinkTrolley') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_DrinkTrolley: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DrinkTrolley: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DrinkTrolley]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DrinkTrolley') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_DrinkTrolley: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DrinkTrolley: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_DrinkTrolley]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_DrinkTrolley') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_DrinkTrolley: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_DrinkTrolley: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
