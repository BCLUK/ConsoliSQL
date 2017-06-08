
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
			WHERE  id = object_id(N'[dbo].[utf_FuzzySearchHost]'))
BEGIN
	DROP FUNCTION [dbo].[utf_FuzzySearchHost]	
	PRINT 'utf_FuzzySearchHost: Dropped Procedure utf_FuzzySearchHost'
END
ELSE
BEGIN	
	PRINT 'utf_FuzzySearchHost: utf_FuzzySearchHost -  Does Not Already Exist !'
END

PRINT 'utf_FuzzySearchHost: Creating Function utf_FuzzySearchHost'
GO

-- ====================================================================================================================
-- Author:		Corey James Bradford			
-- Create Date:	12/05/2017
-- Description:	This will perform a fuzzy metaphone search for a host based off of the search text
-- Product:		CABS
-- Module:		Outlook Addin
-- Parameters:	@SearchText
-- Returns:		TABLE
-- Switches:	N/A
-- Test:		N/A
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		12/05/2017
-- ====================================================================================================================
-- Changes (1.0): Corey Bradford: 12/05/2017: Original Version
-- ====================================================================================================================
CREATE FUNCTION utf_FuzzySearchHost 
(	
	@firstName	VARCHAR(100),
	@lastName	VARCHAR(100)
)
RETURNS @FoundHosts TABLE
(
	MBR_SYSNO		VARCHAR( 7 ),
	MBR_CMPNAM		VARCHAR( 100 ),
	MBR_ADDR1		VARCHAR( 40 ),
	[NAME]			VARCHAR( 142 ),
	MBR_IMPKEY		VARCHAR( 50 ),
	FirstNameScore	DECIMAL( 4, 2 ),
	LastNameScore	DECIMAL( 4, 2 )
)
AS
BEGIN
	DECLARE @firstNameMet VARCHAR( 5 ) = dbo.Metaphone( @firstName )
	DECLARE @lastNameMet VARCHAR( 5 ) = dbo.Metaphone( @lastName )

	INSERT INTO @FoundHosts SELECT TOP 100
		MBR_SYSNO,
		MBR_CMPNAM,
		MBR_ADDR1,
		MBR_CMPNAM + ', ' + MBR_ADDR1 AS [NAME],
		MBR_IMPKEY,
		CASE WHEN ISNULL( @firstName, '' ) <> ''
		THEN dbo.GetFuzzyMatchDistance( MBR_ADDR1, FirstDoubleMetaphone, @firstName, @firstNameMet  )
		ELSE 0
		END
		AS FirstNameScore,
		CASE WHEN ISNULL( @lastName, '' ) <> ''
		THEN dbo.GetFuzzyMatchDistance( MBR_CMPNAM, LastDoubleMetaphone, @lastName, @lastNameMet )
		ELSE 0
		END
		AS LastNameScore
	FROM dbo.vw_MBRFileDoubleMetaphone
	WHERE 
		MBR_SYSNO <> MBR_IMPKEY
		AND MBR_STATUS <> 'CANCEL'
	ORDER BY FirstNameScore, LastNameScore, MBR_CMPNAM, MBR_ADDR1
	

	--;WITH CTE AS
	--(
	--	SELECT 
	--		MBR_SYSNO,
	--		MBR_CMPNAM,
	--		MBR_ADDR1,
	--		MBR_CMPNAM + ', ' + MBR_ADDR1 AS [NAME],
	--		MBR_IMPKEY,
	--		CASE WHEN ISNULL( @firstName, '' ) <> ''
	--		THEN dbo.GetFuzzyMatchDistance( MBR_ADDR1, FirstDoubleMetaphone, @firstName, dbo.Metaphone( @firstName )  )
	--		ELSE 0
	--		END
	--		AS FirstNameScore,
	--		CASE WHEN ISNULL( @lastName, '' ) <> ''
	--		THEN dbo.GetFuzzyMatchDistance( MBR_CMPNAM, LastDoubleMetaphone, @lastName, dbo.Metaphone( @lastName ) )
	--		ELSE 0
	--		END
	--		AS LastNameScore
	--	FROM dbo.vw_MBRFileDoubleMetaphone
	--	WHERE 
	--		MBR_SYSNO <> MBR_IMPKEY
	--		AND MBR_STATUS <> 'CANCEL'
	--)
	--INSERT INTO @FoundHosts SELECT TOP 100 * 
	--FROM CTE
	--ORDER BY FirstNameScore + LastNameScore, MBR_CMPNAM, MBR_ADDR1
	
	RETURN
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[utf_FuzzySearchHost]'))
BEGIN	
	PRINT 'utf_FuzzySearchHost: utf_FuzzySearchHost Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_FuzzySearchHost: utf_FuzzySearchHost Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO

PRINT 'utf_FuzzySearchHost: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_FuzzySearchHost]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_FuzzySearchHost') AND [name] = 'Product')
BEGIN		
	PRINT 'utf_FuzzySearchHost: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_FuzzySearchHost: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_FuzzySearchHost]
							   ,@name = N'Module' 
							   ,@value = N'Outlook Addin'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_FuzzySearchHost') AND [name] = 'Module')
BEGIN		
	PRINT 'utf_FuzzySearchHost: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_FuzzySearchHost: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_FuzzySearchHost]
							   ,@name = N'Version' 
							   ,@value = N'1.0'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_FuzzySearchHost') AND [name] = 'Version')
BEGIN		
	PRINT 'utf_FuzzySearchHost: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_FuzzySearchHost: Version Extended Propety Not Created Successfully !'
END

PRINT '*****************************************************************************'								   
GO