SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_cabs_copy_packages]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_cabs_copy_packages]	
	PRINT 'usp_cabs_copy_packages: Dropped Procedure usp_cabs_copy_packages'
END
ELSE
BEGIN	
	PRINT 'usp_cabs_copy_packages: usp_cabs_copy_packages -  Does Not Already Exist !'
END

PRINT 'usp_cabs_copy_packages: Creating Procedure usp_cabs_copy_packages'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	04/04/2017
-- Description:	Copies all packages attached to an MBR or a function.
-- Product:		CABS
-- Module:		Enhanced MBR Copier
-- Parameters:	N/A
-- Returns:		N/A
-- Switches:	N/A
-- Test:		N/A
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		04/04/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 04/04/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_cabs_copy_packages 
	@Ref VARCHAR(7),
	@NewRef VARCHAR(7),
	@StartDate DATETIME,
	@EndDate DATETIME,
	@DayDiff INT,
	@DOWFixed BIT,
	@OperatorId VARCHAR(31),
	@IncludeCancelled BIT,
	@ClassCodes VARCHAR(MAX),
	@PackagesCopied INT OUT,
	@Merging BIT
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Merging = 1
	BEGIN
		IF @Ref LIKE 'M%'
		BEGIN
			INSERT INTO #MBR_COPIER_MERGE_OUTPUT
			SELECT MBR_SYSNO,
				MBR_CLIENT,
				MBR_CONTCT,
				@ClassCodes,
				MBR_EVENT,
				PH_SYSNO,
				'',
				'',
				CONVERT(VARCHAR(10), PH_FROM, 103),
				CONVERT(VARCHAR(10), PH_TO, 103),
				PH_COVERS,
				'',
				PH_DESC
			FROM PKGHEAD
			LEFT JOIN MBRFILE
			ON MBR_SYSNO = PH_OWNER
			WHERE PH_OWNER = @NewRef
				AND dbo.uf_ShouldCopyBlockingOrGlobalExtraOrPackage(PH_FROM, PH_TO, @IncludeCancelled, PH_FROM, PH_TO, PH_COVERS) = 1
		END
		ELSE IF @Ref LIKE 'F%'
		BEGIN
			INSERT INTO #MBR_COPIER_MERGE_OUTPUT
			SELECT MBR_SYSNO,
				MBR_CLIENT,
				MBR_CONTCT,
				@ClassCodes,
				MBR_EVENT,
				PH_SYSNO,
				'',
				RM_NAME,
				CONVERT(VARCHAR(10), PH_FROM, 103),
				CONVERT(VARCHAR(10), PH_TO, 103),
				PH_COVERS,
				'',
				PH_DESC
			FROM PKGHEAD
			LEFT JOIN FUNC_FIL
			ON F_REF = PH_OWNER
			LEFT JOIN MBRFILE
			ON MBR_SYSNO = F_MBR_NO
			LEFT JOIN ROOMS
			ON RM_ABBR = F_ROOM
			WHERE PH_OWNER = @NewRef
				AND dbo.uf_ShouldCopyBlockingOrGlobalExtraOrPackage(PH_FROM, PH_TO, @IncludeCancelled, PH_FROM, PH_TO, PH_COVERS) = 1
		END
	END

	DECLARE @C CURSOR,
		@PackageSysNo VARCHAR(7),
		@PackageStart DATETIME,
		@NewPackageSysNo VARCHAR(7),
		@NewPackageStart DATETIME

	SET @C = CURSOR FAST_FORWARD FOR
		SELECT PH_SYSNO, PH_FROM
		FROM PKGHEAD
		WHERE PH_OWNER = @Ref
			AND dbo.uf_ShouldCopyBlockingOrGlobalExtraOrPackage(@StartDate, @EndDate, @IncludeCancelled, PH_FROM, PH_TO, PH_COVERS) = 1

	OPEN @C

	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM @C INTO @PackageSysNo, @PackageStart
		IF @@FETCH_STATUS <> 0 BREAK

		SET @NewPackageStart = DATEADD(DAY, @DayDiff, @PackageStart)
		IF @DOWFixed = 1
		BEGIN
			DECLARE @OldDay INT = DATEPART(WEEKDAY, @PackageStart)
			SET @NewPackageStart = dbo.uf_GetNextMatchingDate(@NewPackageStart, @OldDay)
		END

		EXEC usp_CABS_copyPackage @PackageSysNo, @NewRef, @NewPackageStart, @NewPackageSysNo OUT, @OperatorId

		IF @Ref LIKE 'M%'
		BEGIN
			INSERT INTO #MBR_COPIER_OUTPUT
			SELECT MBR_SYSNO,
				MBR_CLIENT,
				MBR_CONTCT,
				@ClassCodes,
				MBR_EVENT,
				PH_SYSNO,
				'',
				'',
				CONVERT(VARCHAR(10), PH_FROM, 103),
				CONVERT(VARCHAR(10), PH_TO, 103),
				PH_COVERS,
				'',
				PH_DESC
			FROM PKGHEAD
			LEFT JOIN MBRFILE
			ON MBR_SYSNO = PH_OWNER
			WHERE PH_SYSNO = @NewPackageSysNo
		END
		ELSE IF @Ref LIKE 'F%'
		BEGIN
			INSERT INTO #MBR_COPIER_OUTPUT
			SELECT MBR_SYSNO,
				MBR_CLIENT,
				MBR_CONTCT,
				@ClassCodes,
				MBR_EVENT,
				PH_SYSNO,
				'',
				RM_NAME,
				CONVERT(VARCHAR(10), PH_FROM, 103),
				CONVERT(VARCHAR(10), PH_TO, 103),
				PH_COVERS,
				'',
				PH_DESC
			FROM PKGHEAD
			LEFT JOIN FUNC_FIL
			ON F_REF = PH_OWNER
			LEFT JOIN MBRFILE
			ON MBR_SYSNO = F_MBR_NO
			LEFT JOIN ROOMS
			ON RM_ABBR = F_ROOM
			WHERE PH_SYSNO = @NewPackageSysNo
		END

		SET @PackagesCopied += 1
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_cabs_copy_packages]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_cabs_copy_packages: usp_cabs_copy_packages Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_cabs_copy_packages: usp_cabs_copy_packages Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_cabs_copy_packages: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_cabs_copy_packages]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_cabs_copy_packages') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_cabs_copy_packages: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_cabs_copy_packages: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_cabs_copy_packages]
							   ,@name = N'Module' 
							   ,@value = N'Enhanced MBR Copier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_cabs_copy_packages') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_cabs_copy_packages: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_cabs_copy_packages: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_cabs_copy_packages]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_cabs_copy_packages') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_cabs_copy_packages: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_cabs_copy_packages: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017