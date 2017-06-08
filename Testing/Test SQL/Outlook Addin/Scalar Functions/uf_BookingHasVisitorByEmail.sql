-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_BookingHasVisitorByEmail]')) 					
BEGIN
	DROP FUNCTION [dbo].[uf_BookingHasVisitorByEmail]	
	PRINT 'uf_BookingHasVisitorByEmail: Dropped Function uf_BookingHasVisitorByEmail'
END
ELSE
BEGIN	
	PRINT 'uf_BookingHasVisitorByEmail: uf_BookingHasVisitorByEmail -  Does Not Already Exist !'
END

PRINT 'uf_BookingHasVisitorByEmail: Creating Function uf_BookingHasVisitorByEmail'
GO

-- ====================================================================================================================
-- Author:		Corey Bradford				
-- Create Date:	23/05/2017
-- Description:	Returns whether a visitor has been assigned to a booking or not
-- Product:		CABS
-- Module:		Core
-- Parameters:	@fref, @emailAddress
-- Returns:		BIT
-- Switches:	N/A
-- Test:		N/A
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		23/05/2017
-- ====================================================================================================================
-- Changes:
-- 23/05/2017	1.0 - Corey Bradford
--					- Original Version
-- ====================================================================================================================
CREATE FUNCTION uf_BookingHasVisitorByEmail 
(
	-- Add the parameters for the function here
	@fref			VARCHAR( 10 ),
	@emailAddress	VARCHAR( 100 )
)
RETURNS BIT
AS
BEGIN
	RETURN CASE WHEN EXISTS
	(
		SELECT F_REF
		FROM FUNC_FIL
		LEFT JOIN INTVIS
			ON IV_FUNCREF = F_REF
		LEFT JOIN MBRFILE
			ON IV_HOSTMBR = MBR_SYSNO
		LEFT JOIN VISITORS
			ON V_FUNCNO = F_REF
		WHERE F_REF = @fref
		AND
		(
			MBR_EMAIL = @emailAddress
			OR V_EMAIL = @emailAddress
		)
	)
	THEN 1
	ELSE 0
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[uf_BookingHasVisitorByEmail]'))
BEGIN	
	PRINT 'uf_BookingHasVisitorByEmail: uf_BookingHasVisitorByEmail Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_BookingHasVisitorByEmail: uf_BookingHasVisitorByEmail Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'uf_BookingHasVisitorByEmail: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_BookingHasVisitorByEmail]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_BookingHasVisitorByEmail') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_BookingHasVisitorByEmail: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_BookingHasVisitorByEmail: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_BookingHasVisitorByEmail]
							   ,@name = N'Module' 
							   ,@value = N'Core'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_BookingHasVisitorByEmail') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_BookingHasVisitorByEmail: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_BookingHasVisitorByEmail: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_BookingHasVisitorByEmail]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_BookingHasVisitorByEmail') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_BookingHasVisitorByEmail: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_BookingHasVisitorByEmail: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
-- End of Changes - TT - 14/03/2017