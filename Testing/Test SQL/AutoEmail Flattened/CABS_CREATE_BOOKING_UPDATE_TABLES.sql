-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @SPROC_Name VARCHAR(100)
SET @FileName = 'CABS_CREATE_BOOKING_UPDATE_TABLES'
SET @SPROC_Name = 'CABS_CREATE_BOOKING_UPDATE_TABLES'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CABS_CREATE_BOOKING_UPDATE_TABLES]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[CABS_CREATE_BOOKING_UPDATE_TABLES]	
	PRINT @FileName + ': Dropped Procedure ' + @SPROC_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @SPROC_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Procedure ' + @SPROC_Name
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CABS_CREATE_BOOKING_UPDATE_TABLES]
AS
BEGIN
	-- =============================================
	-- Author:		MARK BIRCH
	-- Create date: 21-MAR-2014
	-- Description:	To Create a SPROC to create Status Update Table
	-- =============================================

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	if (select COUNT(*) from sysobjects where id = object_id(N'[AutoBookingUpdate]')) = 0
	BEGIN
		CREATE TABLE AutoBookingUpdate
		(
			F_REF VARCHAR(7) NULL,
			OLD_STATUS VARCHAR(6) NULL,
			NEW_STATUS VARCHAR(6) NULL,
			OLD_ROOM_GIVEN VARCHAR(3) NULL,
			NEW_ROOM_GIVEN VARCHAR(3) NULL,
			DATESTMP DATETIME NULL
		)	
	END
END
GO

PRINT '*****************************************************************************'

PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_CREATE_BOOKING_UPDATE_TABLES]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_CREATE_BOOKING_UPDATE_TABLES') AND [name] = 'Product')
BEGIN		
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_CREATE_BOOKING_UPDATE_TABLES]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_CREATE_BOOKING_UPDATE_TABLES') AND [name] = 'Module')
BEGIN		
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [CABS_CREATE_BOOKING_UPDATE_TABLES]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_CREATE_BOOKING_UPDATE_TABLES') AND [name] = 'Version')
BEGIN		
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_CREATE_BOOKING_UPDATE_TABLES: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO