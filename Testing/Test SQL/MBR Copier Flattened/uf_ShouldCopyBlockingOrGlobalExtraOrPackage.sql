SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_ShouldCopyBlockingOrGlobalExtraOrPackage]')) 					
BEGIN
	DROP FUNCTION [dbo].[uf_ShouldCopyBlockingOrGlobalExtraOrPackage]	
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Dropped Function uf_ShouldCopyBlockingOrGlobalExtraOrPackage'
END
ELSE
BEGIN	
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: uf_ShouldCopyBlockingOrGlobalExtraOrPackage -  Does Not Already Exist !'
END

PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Creating Function uf_ShouldCopyBlockingOrGlobalExtraOrPackage'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	05/04/2017
-- Description:	Decides whether a blocking or global extra should be copied.
-- Product:		CABS
-- Module:		Enhanced MBR Copier
-- Parameters:	
-- Returns:		
-- Switches:	
-- Test:		
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		05/04/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 05/04/2017: Original Version
-- ====================================================================================================================
CREATE FUNCTION uf_ShouldCopyBlockingOrGlobalExtraOrPackage
(
	@RangeStart DATETIME,
	@RangeEnd DATETIME,
	@IncludeCancelled BIT,
	@StartDateTime DATETIME,
	@EndDateTime DATETIME,
	@Covers INT
)
RETURNS BIT
AS
BEGIN
	RETURN CASE WHEN @StartDateTime >= @RangeStart
		AND @EndDateTime <= @RangeEnd
		AND (@IncludeCancelled = 1 OR (@IncludeCancelled = 0 AND @Covers > 0))
	THEN 1
	ELSE 0
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_ShouldCopyBlockingOrGlobalExtraOrPackage]'))
BEGIN	
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: uf_ShouldCopyBlockingOrGlobalExtraOrPackage Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: uf_ShouldCopyBlockingOrGlobalExtraOrPackage Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyBlockingOrGlobalExtraOrPackage]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyBlockingOrGlobalExtraOrPackage') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyBlockingOrGlobalExtraOrPackage]
							   ,@name = N'Module' 
							   ,@value = N'Enhanced MBR Copier'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyBlockingOrGlobalExtraOrPackage') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyBlockingOrGlobalExtraOrPackage]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyBlockingOrGlobalExtraOrPackage') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyBlockingOrGlobalExtraOrPackage: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
-- End of Changes - TT - 14/03/2017