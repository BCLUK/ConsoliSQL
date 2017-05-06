
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
			WHERE  id = object_id(N'[dbo].[usp_CABS_copyPackage]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_CABS_copyPackage]	
	PRINT 'usp_CABS_copyPackage: Dropped Procedure usp_CABS_copyPackage'
END
ELSE
BEGIN	
	PRINT 'usp_CABS_copyPackage: usp_CABS_copyPackage -  Does Not Already Exist !'
END

PRINT 'usp_CABS_copyPackage: Creating Procedure usp_CABS_copyPackage'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	31/03/2017
-- Description:	Copies packages from one MBR to another.  Part of Enhanced MBR Copier
-- Product:		CABS
-- Module:		CORE
-- Parameters:	Insert Parameter List
-- Returns:		Insert Data Type
-- Switches:	Insert CABS Switches Used
-- Test:		Insert How to Test
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		31/03/2017
-- ====================================================================================================================
-- Changes (1.0): plg: 31/03/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_CABS_copyPackage 
	-- Add the parameters for the stored procedure here
	@PHSysNo Varchar(10),
	@NewOwner Varchar(10) = '',
	@NewDate DateTime ,
	@NewPrikey varchar(10) OUTPUT,
	@OperatorId VARCHAR(31)
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	
	-- Insert statements for procedure here
	--Declare @NewPriKey varchar(10)
	Declare @NewSysNo Varchar(10)
	Declare @RC Varchar(500)
	Declare @Result Varchar(20)
	Declare @next_Num Varchar(10)
	Declare @PackageLength int
	Declare @OldStart datetime
	Declare @OldTO datetime

	Declare @PK_POST varchar(6),
           @PK_DATE datetime,
           @PK_SEQ int,
           @PK_SELL decimal(12,4),
           @PK_VATCODE int,
           @PK_SECT varchar(1),
           @PK_COVERS decimal(10,2),
           @PK_CREDIT varchar(50),
           @PK_CHARGEBK varchar(50)


    -- Insert statements for procedure here
	EXECUTE @RC = [dbo].[cabs_get_next_pkg_num]  @Next_Num OUTPUT
	SET @NewPRIKEY = @next_Num

	BEGIN TRANSACTION
		SELECT @OldStart = [PH_FROM], @OldTo = [PH_TO] from PKGHEAD where PH_SYSNO = @PHSysNo 

		Set @Packagelength = Datediff(hh,@Oldstart, @OldTo)  

		INSERT INTO [dbo].[PKGHEAD]
           ([PH_SYSNO],[PH_CODE],[PH_DESC],[PH_FROM],[PH_TO],
		   [PH_COVERS],[PH_OWNER],[PH_POSTED],[PH_PRICE],[PH_CREDIT],
		   [PH_CHARGEBK],[PH_OPGROUP],[PH_ACCOM],[PH_CANPOST])
		SELECT @newPriKey,[PH_CODE],[PH_DESC],@newDate,Dateadd(hh,@Packagelength,@newdate),
			[PH_COVERS],@NewOwner,NULL,[PH_PRICE],[PH_CREDIT],
			[PH_CHARGEBK],[PH_OPGROUP],[PH_ACCOM],0 
			from PKGHEAD where PH_SYSNO = @PHSysNo

		--now do all the items
		Declare Packages_CTE cursor fast_forward for (Select [PK_POST],[PK_DATE],[PK_SEQ],[PK_SELL],
		[PK_VATCODE],[PK_SECT],[PK_COVERS],[PK_CREDIT],[PK_CHARGEBK] 
		from Packages where PK_SYSNO = @PHSysNo) 

		open Packages_CTE 

		fetch next from Packages_CTE into @PK_POST,@PK_DATE,@PK_SEQ,@PK_SELL,
		@PK_VATCODE,@PK_SECT,@PK_COVERS,@PK_CREDIT,@PK_CHARGEBK

		While @@FETCH_STATUS = 0 begin
			INSERT INTO [dbo].[PACKAGES]([PK_SYSNO],[PK_POST],[PK_DATE],[PK_SEQ]
           ,[PK_SELL],[PK_VATCODE],[PK_SECT],[PK_COVERS],[PK_POSTED],[PK_CREDIT]
           ,[PK_CHARGEBK])
			VALUES(@NewPrikey,@PK_POST, @PK_DATE, @PK_SEQ, 
           @PK_SELL, @PK_VATCODE, @PK_SECT, @PK_COVERS, 0,@PK_CREDIT, 
           @PK_CHARGEBK)
			fetch next from Packages_CTE into @PK_POST,@PK_DATE,@PK_SEQ,@PK_SELL,
			@PK_VATCODE,@PK_SECT,@PK_COVERS,@PK_CREDIT,@PK_CHARGEBK
		end

		close Packages_CTE
		deallocate Packages_CTE

		if @@ERROR = 0
			COMMIT TRANSACTION
		else
			ROLLBACK TRANSACTION
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_CABS_copyPackage]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_CABS_copyPackage: usp_CABS_copyPackage Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_copyPackage: usp_CABS_copyPackage Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_CABS_copyPackage: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_copyPackage]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_copyPackage') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_CABS_copyPackage: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_copyPackage: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_copyPackage]
							   ,@name = N'Module' 
							   ,@value = N'CORE'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_copyPackage') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_CABS_copyPackage: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_copyPackage: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_copyPackage]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_copyPackage') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_CABS_copyPackage: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_copyPackage: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017