SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_ConvertAccommGEToBlockings]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_ConvertAccommGEToBlockings]	
	PRINT 'usp_ConvertAccommGEToBlockings: Dropped Procedure usp_ConvertAccommGEToBlockings'
END
ELSE
BEGIN	
	PRINT 'usp_ConvertAccommGEToBlockings: usp_ConvertAccommGEToBlockings -  Does Not Already Exist !'
END

PRINT 'usp_ConvertAccommGEToBlockings: Creating Procedure usp_ConvertAccommGEToBlockings'
GO

-- ====================================================================================================================
-- Author:		Mike Edwards				
-- Create Date:	06/06/2017
-- Description:	Converts accommodation global extras to blockings.
-- Product:		CABS
-- Module:		Enhanced MBR Copier
-- Parameters:	@MBR_SYSNO VARCHAR(7)
-- Returns:		N/A
-- Switches:	N/A
-- Test:		EXEC usp_ConvertAccommGEToBlockings @MBR_SYSNO
-- Called By:	N/A
-- Calls:		N/A
-- ====================================================================================================================
-- Version:		1.0
-- Date:		06/06/2017
-- ====================================================================================================================
-- Changes (1.0): M.E.: 06/06/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_ConvertAccommGEToBlockings
	@MBR_SYSNO VARCHAR(7),
	@ClassCodes VARCHAR(MAX),
	@CompleteConversions INT OUT,
	@FailedConversions INT OUT
AS
BEGIN
	SET NOCOUNT ON

	SET @CompleteConversions = 0
	SET @FailedConversions = 0
	
	DECLARE @c CURSOR,
		@DATE_FROM DATETIME,
		@DATE_TO DATETIME,
		@AI_CODE VARCHAR(6)

	-- Get extras grouped by their AI_CODE and then grouped by consecutive days
	SET @c = CURSOR FAST_FORWARD FOR	WITH ExtraCodes AS
										(
											SELECT Column1
											FROM dbo.BreakStringIntoRows(dbo.uf_xCABS_CONFIG_ReadString('', 'GlobalExtras_AccomCodes', 'Include'))
										),
										GroupDates AS
										(
											SELECT AI_CODE, ROW_NUMBER() OVER (ORDER BY AI_CODE, AI_GEDATE) AS Id, AI_GEDATE
											FROM AI_FILE
											INNER JOIN ExtraCodes
											ON ExtraCodes.Column1 = AI_CODE
											WHERE AI_FREF = @MBR_SYSNO
											GROUP BY AI_CODE, AI_GEDATE
										)
										SELECT MIN(AI_GEDATE) AS DATE_FROM, MAX(AI_GEDATE) AS DATE_TO, AI_CODE
										FROM GroupDates
										GROUP BY DATEDIFF(DAY, Id, AI_GEDATE), AI_CODE
	OPEN @c

	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM @c INTO @DATE_FROM, @DATE_TO, @AI_CODE
		IF @@FETCH_STATUS <> 0 BREAK

		DECLARE @ExtrasData TABLE (AI_PRIKEY VARCHAR(10), AI_CODE VARCHAR(6), AI_GEDATE DATETIME, AI_COVERS INT)

		-- Get all extras between grouped start and end date
		INSERT @ExtrasData
		SELECT AI_PRIKEY, AI_CODE, AI_GEDATE, AI_COVERS
		FROM AI_FILE
		WHERE AI_FREF = @MBR_SYSNO
			AND AI_CODE = @AI_CODE
			AND AI_GEDATE BETWEEN @DATE_FROM AND @DATE_TO
			
		-- Get potential room types from extra code
		DECLARE @RawCodes VARCHAR(1000) = dbo.uf_xCABS_CONFIG_ReadString('', 'GlobalExtras_AccomCodes', @AI_CODE)
		DECLARE @Codes TABLE (BL_RTYPE VARCHAR(6))

		INSERT @Codes
		SELECT Column1
		FROM dbo.BreakStringIntoRows(REPLACE(@RawCodes, ';', ','))
		
		-- While an extra still exists with cover more than 1
		WHILE EXISTS(SELECT AI_PRIKEY FROM @ExtrasData)
		BEGIN
			DECLARE @Covers INT,
					@StartDate DATETIME,
					@EndDate DATETIME,
					@AvResult INT

			SELECT @Covers = MIN(AI_COVERS),
				@StartDate = MIN(AI_GEDATE),
				@EndDate = DATEADD(DAY, 1, MAX(AI_GEDATE))
			FROM @ExtrasData
		
			DECLARE @CodeCur CURSOR,
				@RoomCode VARCHAR(6)
			SET @CodeCur = CURSOR FAST_FORWARD FOR	SELECT BL_RTYPE
													FROM @Codes

			OPEN @CodeCur

			PRINT @AI_CODE + ' - ' + CONVERT(varchar(10), @StartDate, 126) + ' to ' + CONVERT(varchar(10), @EndDate, 126) + ' for ' + CONVERT(varchar, @Covers) + ' cover(s)'

			-- Sift through all potential room types and try to book
			DECLARE @Booked BIT = 0

			WHILE @Booked = 0
			BEGIN
				FETCH NEXT FROM @CodeCur INTO @RoomCode
				IF @@FETCH_STATUS <> 0 BREAK

				PRINT '  Checking resources in ' + @RoomCode
				
				-- Check resources
				EXEC cabs_check_accom_av_ge @StartDate, @EndDate, @RoomCode, @Covers, @AvResult OUT

				IF @AvResult = 1
				BEGIN
					-- Available... book it
					DECLARE @BlockingId VARCHAR(7),
						@BookResult INT

					PRINT '  Trying to book for ' + CONVERT(varchar, @Covers) + ' covers...'

					EXEC cabs_create_blocking_ge @StartDate, @EndDate, @RoomCode, @MBR_SYSNO, @Covers, 0, 0, @BlockingId OUTPUT, @BookResult OUTPUT

					IF @BookResult = 1
					BEGIN
						SET @Booked = 1
					
						-- Reduce the covers if the booking was successful
						UPDATE AI_FILE
						SET AI_COVERS -= @Covers
						WHERE AI_FREF = @MBR_SYSNO
							AND AI_CODE = @AI_CODE
							AND AI_GEDATE BETWEEN @StartDate AND @EndDate
							
						INSERT INTO #MBR_COPIER_OUTPUT
						SELECT MBR_SYSNO,
							MBR_CLIENT,
							MBR_CONTCT,
							@ClassCodes,
							MBR_EVENT,
							BL_SYSNO,
							CONVERT(VARCHAR(10), BL_DATE, 103),
							ISNULL(ST_DESC, 'Undefined'),
							CONVERT(VARCHAR(10), BL_DATE, 103),
							CONVERT(VARCHAR(10), BL_TO, 103),
							BL_SOFT,
							@AI_CODE,
							'Success'
						FROM BLOCKING
						LEFT JOIN MBRFILE
						ON MBR_SYSNO = BL_MBR
						LEFT JOIN SYS_ABBR
						ON ST_TYPE = 'RMT'
							AND ST_CODE = BL_RTYPE
						WHERE BL_SYSNO = @BlockingId

						SET @CompleteConversions += 1

						PRINT '    Success'
					END
				END
			END

			IF @Booked = 0
			BEGIN
				INSERT INTO #MBR_COPIER_OUTPUT
				SELECT MBR_SYSNO,
					MBR_CLIENT,
					MBR_CONTCT,
					@ClassCodes,
					MBR_EVENT,
					'',
					CONVERT(VARCHAR(10), @StartDate, 103),
					ISNULL(P_DESC, 'Undefined'),
					CONVERT(VARCHAR(10), @StartDate, 103),
					CONVERT(VARCHAR(10), @EndDate, 103),
					@Covers,
					@AI_CODE,
					'Failed'
				FROM MBRFILE
				LEFT JOIN POST_DEF
				ON P_CODE = @AI_CODE
				WHERE MBR_SYSNO = @MBR_SYSNO

				SET @FailedConversions += 1

				PRINT '  ! Failed to book'
			END

			UPDATE @ExtrasData
			SET AI_COVERS -= @Covers
			WHERE AI_CODE = @AI_CODE
				AND AI_GEDATE BETWEEN @StartDate AND @EndDate

			DELETE @ExtrasData
			WHERE AI_CODE = @AI_CODE
				AND AI_GEDATE BETWEEN @StartDate AND @EndDate
				AND AI_COVERS <= 0

			-- Clean up extras
			DELETE AI_FILE
			WHERE AI_FREF = @MBR_SYSNO
				AND AI_CODE = @AI_CODE
				AND AI_GEDATE BETWEEN @StartDate AND @EndDate
				AND AI_COVERS <= 0
		END
	END
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_ConvertAccommGEToBlockings]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_ConvertAccommGEToBlockings: usp_ConvertAccommGEToBlockings Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccommGEToBlockings: usp_ConvertAccommGEToBlockings Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_ConvertAccommGEToBlockings: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccommGEToBlockings]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccommGEToBlockings') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_ConvertAccommGEToBlockings: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccommGEToBlockings: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccommGEToBlockings]
							   ,@name = N'Module' 
							   ,@value = N'Enhanced MBR Copier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccommGEToBlockings') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_ConvertAccommGEToBlockings: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccommGEToBlockings: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_ConvertAccommGEToBlockings]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_ConvertAccommGEToBlockings') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_ConvertAccommGEToBlockings: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_ConvertAccommGEToBlockings: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017