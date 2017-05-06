-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 08/11/2016
-- Description:	Script to create view vw_Extras.
--
-- =====================================================================================================
-- Version:		1
-- Date:		08/11/2016
-- =====================================================================================================
-- Changes:		TT: 08/11/2016: Original Version
--	 (1)
-- =====================================================================================================
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'vw_Extras')
BEGIN	
	DROP VIEW [dbo].[vw_Extras]
	PRINT 'vw_Extras: Dropped View vw_Extras'
END
ELSE
BEGIN
	PRINT 'vw_Extras: View vw_Extras Does Not Exist !'
END
PRINT 'vw_Extras: Creating View vw_Extras'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_Extras]
AS
SELECT        AI_FREF AS AI_FREF, AI_PRIKEY AS AI_PRIKEY, AI_TIME AS AI_TIME, AI_ENDTIME AS AI_ENDTIME, AI_COVERS AS AI_COVERS, AI_CHARGE AS AI_CHARGE, 
                         CONVERT(VARCHAR(1000), AI_TEXT) AS AI_TEXT, AI_CODE AS AI_CODE, REPLACE(P_DESC, CHAR(39), CHAR(146)) AS P_DESC, P_OPGROUP AS AI_OPSHEET, 1 AS OrderBy
FROM            AI_FILE, POST_DEF
WHERE        AI_CODE = P_CODE
AND NOT AI_PRIKEY IN(SELECT AEFA_PRIKEY FROM AEF_Amendments WHERE AEFA_ACTION IN('I'))--, 'U'))
UNION
SELECT        AEFA_FREF AS AI_FREF, AEFA_PRIKEY AS AI_PRIKEY, AEFA_START AS AI_TIME, AEFA_END AS AI_ENDTIME, AEFA_COVERS AS AI_COVERS, AEFA_CHARGE AS AI_CHARGE, CONVERT(VARCHAR(1000), AEFA_NOTES) AS AI_TEXT, AEFA_CODE AS AI_CODE, REPLACE(P_DESC, CHAR(39), CHAR(146)) AS P_DESC, P_OPGROUP AS AI_OPSHEET,
                         -1 AS OrderBy
FROM            AEF_Amendments, POST_DEF
WHERE        AEFA_CODE = P_CODE AND AEFA_ACTION IN('I')
AND			 LEFT(AEFA_PRIKEY, 1) = '0'
UNION
SELECT        AEFA_FREF, AEFA_PRIKEY, AEFA_START, AEFA_END, AEFA_COVERS, AEFA_CHARGE, CONVERT(VARCHAR(1000), AEFA_NOTES), AEFA_CODE, REPLACE(P_DESC, CHAR(39), CHAR(146)), P_OPGROUP AS AI_OPSHEET,
                         2 AS OrderBy
FROM            AEF_Amendments, POST_DEF
WHERE        AEFA_CODE = P_CODE AND AEFA_ACTION = 'U'
AND			 LEFT(AEFA_PRIKEY, 1) = '0'

GO

PRINT '*****************************************************************************'								   
PRINT 'vw_Extras: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Extras]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Extras') AND [name] = 'Product')
BEGIN		
	PRINT 'vw_Extras: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Extras: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Extras]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Extras') AND [name] = 'Module')
BEGIN		
	PRINT 'vw_Extras: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Extras: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'VIEW' 
							   ,@level1name = [vw_Extras]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('vw_Extras') AND [name] = 'Version')
BEGIN		
	PRINT 'vw_Extras: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'vw_Extras: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
