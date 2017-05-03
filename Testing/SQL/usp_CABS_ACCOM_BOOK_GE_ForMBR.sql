
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
			WHERE  id = object_id(N'[dbo].[usp_CABS_ACCOM_BOOK_GE_ForMBR]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_CABS_ACCOM_BOOK_GE_ForMBR]	
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Dropped Procedure usp_CABS_ACCOM_BOOK_GE_ForMBR'
END
ELSE
BEGIN	
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: usp_CABS_ACCOM_BOOK_GE_ForMBR -  Does Not Already Exist !'
END

PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Creating Procedure usp_CABS_ACCOM_BOOK_GE_ForMBR'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	21/04/2017
-- Description:	Books accomodation from the selected global extras table
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
CREATE PROCEDURE usp_CABS_ACCOM_BOOK_GE_ForMBR 
	-- Add the parameters for the stored procedure here
	@MBRSysNo Varchar(10) = '',
	@ClassCodes VARCHAR(MAX),
	@ConvertedAccommodationCount INT OUT,
	@RunDate DATETIME,
	@RunId INT
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	
	-- Insert statements for procedure here

	DECLARE
		@ID INT,
		@AI_PRIKEY VARCHAR(10),
		@AI_FREF VARCHAR(7),
		@AI_CODE VARCHAR(6), 
		@AI_COVERS DECIMAL (10, 4),
		@AI_GEDATE DATETIME,
		@AI_GEDATE2 DATETIME,
		@AI_CODE_SELECTION VARCHAR(1000),
		@AI_COVERS_START DECIMAL (10, 4),
		@ID_START INT

	DECLARE
		@Len INT,
		@CodeToUse VARCHAR(6),
		@CodeRemain VARCHAR(1000),
		@AV_OK INT,
		@BLOCK_ID VARCHAR(7),
		@BLOCKING_MADE INT
	
	DECLARE
		@NewID INT,
		@NewCovers DECIMAL (12, 4),
		@RemaniningCovers DECIMAL (12, 4) 	

	DECLARE @BlockingIds TABLE (BL_SYSNO VARCHAR(70))

	DECLARE
		CreateBlocking_Cur
	CURSOR FAST_FORWARD for
	
		SELECT ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_GEDATE2, AI_CODE_SELECTION, AI_COVERS_START, ID_START
		FROM GEAccommData_Full where AI_FREF = @MBRSysNo
			AND Processed = 0
	
	OPEN CreateBlocking_Cur

	FETCH NEXT FROM
		CreateBlocking_Cur
	INTO
		@ID,
		@AI_PRIKEY,
		@AI_FREF,
		@AI_CODE,
		@AI_COVERS,
		@AI_GEDATE,
		@AI_GEDATE2,
		@AI_CODE_SELECTION,
		@AI_COVERS_START,
		@ID_START

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @BLOCK_ID = ''
		SET @BLOCKING_MADE = 0

		PRINT 'Processing: ' + (CONVERT(VARCHAR, @ID)) + ': ' + @AI_PRIKEY + ': ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers' 

		IF RIGHT(@AI_CODE_SELECTION, 1) <> ';' BEGIN
			SET @AI_CODE_SELECTION = @AI_CODE_SELECTION + ';'
		END
		
		SET @CodeRemain = @AI_CODE_SELECTION
		SET @CodeToUse = LTRIM(RTRIM((SELECT SUBSTRING(@AI_CODE_SELECTION, 1, PATINDEX ('%;%', @AI_CODE_SELECTION) -1))))
		SET @CodeRemain = LTRIM(RTRIM(REPLACE ( @CodeRemain, @CodeToUse + ';' , '' )))

		EXEC @AV_OK = cabs_check_accom_av_ge @AI_GEDATE, @AI_GEDATE2, @CodeToUse, @AI_COVERS, 0
		IF @AV_OK = 1 BEGIN
			PRINT '* Availability in ' + @CodeToUse
			PRINT '> Creating Blocking For ' + @AI_PRIKEY + ' in Room Type ' + @CodeToUse
			EXEC cabs_create_blocking_ge @AI_GEDATE, @AI_GEDATE2, @CodeToUse, @AI_FREF, @AI_COVERS, 0, 0, @BLOCK_ID OUTPUT, @BLOCKING_MADE OUTPUT

			INSERT INTO @BlockingIds VALUES (@BLOCK_ID)
			SET @ConvertedAccommodationCount += 1

			-- PLG not required for use in MBR     EXEC CABS_MOVE_MBR_GE @AI_FREF, 'A'
			PRINT '? Are there any more to process...'
			IF (@AI_COVERS < @AI_COVERS_START) AND @AI_COVERS <> 0 BEGIN
				PRINT CHAR(9) + '...Yes'
				SET @RemaniningCovers = (@AI_COVERS_START - @AI_COVERS)
				PRINT '> Generate New Record for ' + CONVERT(VARCHAR, @RemaniningCovers) + ' covers'

				EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'A', @NewID OUTPUT

 				INSERT INTO GEAccommData_Full
				(ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_GEDATE2, AI_CODE_SELECTION, AI_CODE_BOOKED, BLOCK_NO, FOLIO_NO, AI_COVERS_START, ID_START, Processed, Success, RUN_ID, RUN_DATE)
				VALUES
				(@NewID, @AI_PRIKEY, @AI_FREF, @AI_CODE, (@RemaniningCovers), @AI_GEDATE, @AI_GEDATE2, @AI_CODE_SELECTION, '', '', '', @RemaniningCovers, @ID_START, 0, 0, @RunId, @RunDate)
			END
			ELSE
				PRINT CHAR(9) + '...No'

		END

		IF @AV_OK = 0 BEGIN
			PRINT '- No availability in ' + @CodeToUse
		END

		WHILE @AV_OK = 0 AND LEN(@CodeRemain) > 0 BEGIN
			SET @CodeToUse = LTRIM(RTRIM((SELECT SUBSTRING(@CodeRemain, 1, PATINDEX ('%;%', @CodeRemain) -1))))
			SET @CodeRemain = LTRIM(RTRIM(REPLACE ( @CodeRemain, @CodeToUse + ';' , '' )))	
			EXEC @AV_OK = cabs_check_accom_av_ge @AI_GEDATE, @AI_GEDATE2, @CodeToUse, @AI_COVERS, 0
	
			IF @AV_OK = 0 BEGIN
				PRINT '- No availability in ' + @CodeToUse
			END

			IF @AV_OK = 1 BEGIN
				PRINT '* Availability in ' + @CodeToUse
				PRINT '> Creating Blocking For ' + @AI_PRIKEY + ' in Room Type ' + @CodeToUse
				EXEC cabs_create_blocking_ge @AI_GEDATE, @AI_GEDATE2, @CodeToUse, @AI_FREF, @AI_COVERS, 0, 0, @BLOCK_ID OUTPUT, @BLOCKING_MADE OUTPUT

				INSERT INTO @BlockingIds VALUES (@BLOCK_ID)
				SET @ConvertedAccommodationCount += 1

				-- plg not required     EXEC CABS_MOVE_MBR_GE @AI_FREF, 'A'
				PRINT '? Are there any more to process...'
				IF (@AI_COVERS < @AI_COVERS_START) AND @AI_COVERS <> 0 BEGIN
					PRINT CHAR(9) + '...Yes'
					SET @RemaniningCovers = (@AI_COVERS_START - @AI_COVERS)
					
					IF @RemaniningCovers > 0 BEGIN
						PRINT '> Generate New Record for ' + CONVERT(VARCHAR, @RemaniningCovers) + ' covers'

						EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'A', @NewID OUTPUT

 						INSERT INTO GEAccommData_Full
						(ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_GEDATE2, AI_CODE_SELECTION, AI_CODE_BOOKED, BLOCK_NO, FOLIO_NO, AI_COVERS_START, ID_START, Processed, Success, RUN_ID, RUN_DATE)
						VALUES
						(@NewID, @AI_PRIKEY, @AI_FREF, @AI_CODE, (@RemaniningCovers), @AI_GEDATE, @AI_GEDATE2, @AI_CODE_SELECTION, '', '', '', @RemaniningCovers, @ID_START, 0, 0, @RunId, @RunDate)
					END
				END
				ELSE
					PRINT CHAR(9) + '...No'
			END
		END

		IF @AV_OK = 0 BEGIN
			PRINT '! No availability for ' + @AI_PRIKEY + ': ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers'
			SET @CodeToUse = LTRIM(RTRIM((SELECT SUBSTRING(@AI_CODE_SELECTION, 1, PATINDEX ('%;%', @AI_CODE_SELECTION) -1))))
			SET @NewCovers = (@AI_COVERS - 1)
			
			IF @NewCovers > 0 BEGIN
				PRINT '> Generate New Record for ' + CONVERT(VARCHAR, @NewCovers) + ' covers'
		
				EXEC CABS_GET_NEXT_GE_CONVERT_NUM 'A', @NewID OUTPUT
				
				INSERT INTO GEAccommData_Full
				(ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_GEDATE2, AI_CODE_SELECTION, AI_CODE_BOOKED, BLOCK_NO, FOLIO_NO, AI_COVERS_START, ID_START, Processed, Success, RUN_ID, RUN_DATE)
				VALUES
				(@NewID, @AI_PRIKEY, @AI_FREF, @AI_CODE, (@NewCovers), @AI_GEDATE, @AI_GEDATE2, @AI_CODE_SELECTION, '', '', '', @AI_COVERS_START, @ID_START, 0, 0, @RunId, @RunDate)
			END
		END

		UPDATE GEAccommData_Full
		SET AI_CODE_BOOKED = CASE @BLOCKING_MADE WHEN 1 THEN @CodeToUse ELSE '' END,
		BLOCK_NO = @BLOCK_ID,
		Processed = 1,
		Success = @BLOCKING_MADE
		WHERE ID = @ID
	-- PLG 24/04/2107   now- delete the global extra if all OK
		if @AV_OK = 1 begin
			delete AI_FILE where AI_PRIKEY = @ID
			print 'AI_FILE global extra deleted '
		end
		PRINT 'Processing COMPLETE for ' + (CONVERT(VARCHAR, @ID)) + ': ' + @AI_PRIKEY + ': ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers' + CHAR(10)

		FETCH NEXT FROM CreateBlocking_Cur
		INTO @ID, @AI_PRIKEY, @AI_FREF, @AI_CODE, @AI_COVERS, @AI_GEDATE, @AI_GEDATE2, @AI_CODE_SELECTION, @AI_COVERS_START, @ID_START
	END

	CLOSE CreateBlocking_Cur
	DEALLOCATE CreateBlocking_Cur

	/*INSERT INTO #MBR_COPIER_OUTPUT
	SELECT BL_MBR,
		MBR_CLIENT,
		MBR_CONTCT,
		@ClassCodes,
		MBR_EVENT,
		BLOCKING.BL_SYSNO,
		CONVERT(VARCHAR(10), BL_DATE, 103),
		P_DESC,
		CONVERT(VARCHAR(10), BL_DATE, 103),
		CONVERT(VARCHAR(10), BL_TO, 103),
		BL_SOFT,
		'',
		''
	FROM @BlockingIds AS BL_IDS
	LEFT JOIN BLOCKING
	ON BLOCKING.BL_SYSNO = BL_IDS.BL_SYSNO
	LEFT JOIN MBRFILE
	ON MBR_SYSNO = BL_MBR
	LEFT JOIN POST_DEF
	ON P_CODE = BL_RTYPE*/

	/*SELECT *
	FROM GEAccommData_Full
	WHERE RUN_ID = @RunId*/

	;with cte
	as
	(
		SELECT *
		FROM GEAccommData_Full
		where RUN_ID = @RunId
	),
	cte2
	as
	(
		select *
		from cte as a
		where success = 1
			or
			(
				success = 0
				and
				(
					select sum(success)
					from cte as b
					where b.ai_prikey = a.ai_prikey
				) = 0
				and ai_covers = ai_covers_start
			)
	)
	INSERT INTO #MBR_COPIER_OUTPUT
	select MBR_SYSNO,
		MBR_CLIENT,
		MBR_CONTCT,
		@ClassCodes,
		MBR_EVENT,
		bl_sysno,
		CONVERT(VARCHAR(10), CASE Success WHEN 1 THEN BL_DATE ELSE cte2.AI_GEDATE END, 103),
		P_DESC,
		CONVERT(VARCHAR(10), CASE Success WHEN 1 THEN BL_DATE ELSE cte2.AI_GEDATE END, 103),
		CONVERT(VARCHAR(10), CASE Success WHEN 1 THEN BL_TO ELSE cte2.AI_GEDATE2 END, 103),
		CASE Success WHEN 1 THEN BL_SOFT ELSE cte2.AI_COVERS END,
		cte2.ai_prikey,
		case when Success = 0 then 'Failed' /*when ai_covers_start = cte2.ai_covers then 'Complete'*/ else convert(varchar, ai_covers_start - cte2.ai_covers) + ' Remain' end
	from cte2
	left join mbrfile
	on mbr_sysno = ai_fref
	left join ai_file
	on ai_file.ai_prikey = cte2.ai_prikey
	left join post_def
	on p_code = cte2.ai_code
	left join blocking
	on bl_sysno = block_no

	/*
	SELECT BL_MBR,
		MBR_CLIENT,
		MBR_CONTCT,
		@ClassCodes,
		MBR_EVENT,
		BLOCKING.BL_SYSNO,
		CONVERT(VARCHAR(10), BL_DATE, 103),
		P_DESC,
		CONVERT(VARCHAR(10), BL_DATE, 103),
		CONVERT(VARCHAR(10), BL_TO, 103),
		BL_SOFT,
		'',
		''
	*/

	PRINT '-- Processing COMPLETE --'
	
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_CABS_ACCOM_BOOK_GE_ForMBR]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: usp_CABS_ACCOM_BOOK_GE_ForMBR Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: usp_CABS_ACCOM_BOOK_GE_ForMBR Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ACCOM_BOOK_GE_ForMBR]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ACCOM_BOOK_GE_ForMBR') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ACCOM_BOOK_GE_ForMBR]
							   ,@name = N'Module' 
							   ,@value = N'MBRCopier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ACCOM_BOOK_GE_ForMBR') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CABS_ACCOM_BOOK_GE_ForMBR]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CABS_ACCOM_BOOK_GE_ForMBR') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CABS_ACCOM_BOOK_GE_ForMBR: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017