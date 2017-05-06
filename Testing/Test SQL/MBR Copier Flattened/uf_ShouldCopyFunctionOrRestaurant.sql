SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_ShouldCopyFunctionOrRestaurant]')) 					
BEGIN
	DROP FUNCTION [dbo].[uf_ShouldCopyFunctionOrRestaurant]	
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Dropped Function uf_ShouldCopyFunctionOrRestaurant'
END
ELSE
BEGIN	
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: uf_ShouldCopyFunctionOrRestaurant -  Does Not Already Exist !'
END

PRINT 'uf_ShouldCopyFunctionOrRestaurant: Creating Function uf_ShouldCopyFunctionOrRestaurant'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	05/04/2017
-- Description:	Decides whether a function or restaurant should be copied.
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
CREATE FUNCTION uf_ShouldCopyFunctionOrRestaurant
(
	@RangeStart DATETIME,
	@RangeEnd DATETIME,
	@IncludeCancelled BIT,
	@IsFunction BIT,
	@StartDateTime DATETIME,
	@EndDateTime DATETIME,
	@IsRest VARCHAR(3),
	@Status VARCHAR(6)
)
RETURNS BIT
AS
BEGIN
	RETURN CASE WHEN @StartDateTime >= @RangeStart
		AND @EndDateTime <= @RangeEnd
		AND ISNULL(@IsRest, 'No') = CASE @IsFunction WHEN 1 THEN 'No' ELSE 'Yes' END
		AND (@IncludeCancelled = 1 OR (@IncludeCancelled = 0 AND @Status <> 'CANCEL'))
	THEN 1
	ELSE 0
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_ShouldCopyFunctionOrRestaurant]'))
BEGIN	
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: uf_ShouldCopyFunctionOrRestaurant Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: uf_ShouldCopyFunctionOrRestaurant Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'uf_ShouldCopyFunctionOrRestaurant: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyFunctionOrRestaurant]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyFunctionOrRestaurant') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyFunctionOrRestaurant]
							   ,@name = N'Module' 
							   ,@value = N'Enhanced MBR Copier'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyFunctionOrRestaurant') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_ShouldCopyFunctionOrRestaurant]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_ShouldCopyFunctionOrRestaurant') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_ShouldCopyFunctionOrRestaurant: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
-- End of Changes - TT - 14/03/2017