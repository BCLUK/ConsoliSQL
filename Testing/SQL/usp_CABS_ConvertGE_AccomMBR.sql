
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
			WHERE  id = object_id(N'[dbo].[usp_CABS_ConvertGE_AccomMBR]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_CABS_ConvertGE_AccomMBR]	
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Dropped Procedure usp_CABS_ConvertGE_AccomMBR'
END
ELSE
BEGIN	
	PRINT 'usp_CABS_ConvertGE_AccomMBR: usp_CABS_ConvertGE_AccomMBR -  Does Not Already Exist !'
END

PRINT 'usp_CABS_ConvertGE_AccomMBR: Creating Procedure usp_CABS_ConvertGE_AccomMBR'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	21/04/2017
-- Description:	Execute procedures to convert global extras to accomodation
-- Product:		CABS
-- Module:		MBRCopier
-- Parameters:	MBRSysNo
-- Returns:		Insert Data Type
-- Switches:	Insert CABS Switches Used
-- Test:		Insert How to Test
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		21/04/2017
-- ====================================================================================================================
-- Changes (1.0): PLG: 21/04/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_CABS_ConvertGE_AccomMBR 
	-- Add the parameters for the stored procedure here
	@MBRSysNo Varchar(10) = '',
	@ClassCodes VARCHAR(MAX),
	@ConvertedAccommodationCount INT OUT
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	
	-- Insert statements for procedure here
	DECLARE @Continue INT
	SET @Continue = 0

	DECLARE @RunDate DATETIME = GETDATE(),
		@RunId INT

	--Gather Data
	if exists (select * from dbo.sysobjects where id = object_id(N'[usp_GEAccommData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	BEGIN
		EXEC usp_GEAccommDataForMBR @MBRSysNo, @RunDate, @RunId OUT
		SET @Continue = 1
	END
	ELSE
	if exists (select * from dbo.sysobjects where id = object_id(N'[usp_GEAccommData]') and OBJECTPROPERTY(id, N'IsProcedure') = 0)
	BEGIN
		PRINT 'Not all Stored Procedures are present'
		RETURN
	END

	IF @Continue = 1 BEGIN 
		SET @Continue = 0
		if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_ACCOM_BOOK_GE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) BEGIN	
			EXEC usp_CABS_ACCOM_BOOK_GE_ForMBR @MBRSysNo, @ClassCodes, @ConvertedAccommodationCount OUT, @RunDate, @RunId
			SET @Continue = 1
		END
		ELSE
		if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_ACCOM_BOOK_GE]') and OBJECTPROPERTY(id, N'IsProcedure') = 0) BEGIN	
			PRINT 'Not all Stored Procedures are present'
			RETURN
		END
	END
	
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_CABS_ConvertGE_AccomMBR]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_CABS_ConvertGE_AccomMBR: usp_CABS_ConvertGE_AccomMBR Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ConvertGE_AccomMBR: usp_CABS_ConvertGE_AccomMBR Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_CABS_ConvertGE_AccomMBR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ConvertGE_AccomMBR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ConvertGE_AccomMBR') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ConvertGE_AccomMBR]
							   ,@name = N'Module' 
							   ,@value = N'MBRCopier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ConvertGE_AccomMBR') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ConvertGE_AccomMBR]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ConvertGE_AccomMBR') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ConvertGE_AccomMBR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017