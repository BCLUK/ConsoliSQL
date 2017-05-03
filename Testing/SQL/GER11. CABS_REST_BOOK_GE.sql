if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_REST_BOOK_GE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [CABS_REST_BOOK_GE] 
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Mark Birch
-- Script Name: CABS_REST_BOOK_GE.sql
-- Create date: 11-MAY-2016
-- Description:	Create Restaurant Bookings from Global Extras
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 3
-- Date: 16/08/2016
-- =============================================
-- Changes: 22/06/2016: MCB: Added EXEC CABS_MOVE_MBR_GE @AI_FREF, 'A' to move MBR To new Client.  
-- Changes: 16/08/2016: MCB: Added RUN_ID and RUN_DATE  
-- =============================================
CREATE PROCEDURE CABS_REST_BOOK_GE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@ID INT,
		@AI_PRIKEY VARCHAR(10),
		@AI_FREF VARCHAR(7),
		@AI_CODE VARCHAR(6), 
		@AI_COVERS DECIMAL (10, 4),
		@AI_GEDATE DATETIME,
		@AI_TIME VARCHAR(5), 
		@AI_ENDTIME VARCHAR(5),
		@AI_STARTDATETIME DATETIME,
		@AI_ENDDATETIME DATETIME,
		@AI_CODE_SELECTION VARCHAR(1000)

	DECLARE
		@RestCode VARCHAR(6),
		@SessCode VARCHAR(6),
		@BOOKING_REF VARCHAR(7),
		@BOOKING_MADE INT,
		@AV_OK INT

	DECLARE
		@RUN_ID INT,
		@RUN_DATE DATETIME

	DECLARE
		CreateRest_Cur
	CURSOR FAST_FORWARD for
	
		SELECT ID, AI_PRIKEY, AI_FREF, AI_CODE, AI_COVERS, AI_GEDATE, AI_TIME, AI_ENDTIME, (AI_GEDATE + AI_TIME), (AI_GEDATE + AI_ENDTIME), AI_CODE_SELECTION, RUN_ID, RUN_DATE 
		FROM GERestData_Full
		WHERE AI_COVERS <> 0
		AND Processed = 0
	
	OPEN CreateRest_Cur

	FETCH NEXT FROM
		CreateRest_Cur
	INTO
		@ID,
		@AI_PRIKEY,
		@AI_FREF,
		@AI_CODE,
		@AI_COVERS,
		@AI_GEDATE,
		@AI_TIME, 
		@AI_ENDTIME,
		@AI_STARTDATETIME,
		@AI_ENDDATETIME,
		@AI_CODE_SELECTION,
		@RUN_ID,
		@RUN_DATE

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @BOOKING_REF = ''
		SET @BOOKING_MADE = 0

		SET @RestCode = LTRIM(RTRIM((SELECT SUBSTRING(@AI_CODE_SELECTION, 1, PATINDEX ('%~%', @AI_CODE_SELECTION) -1))))
		SET @SessCode = LTRIM(RTRIM((SELECT SUBSTRING(@AI_CODE_SELECTION, PATINDEX ('%~%', @AI_CODE_SELECTION) +1, LEN(@AI_CODE_SELECTION)))))

		PRINT 'Processing: ' + (CONVERT(VARCHAR, @ID)) + ': ' + @AI_PRIKEY + ': ' + @RestCode + '|' + @SessCode + ' for ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers'
		
		IF COALESCE(@RestCode, '') = '' BEGIN
			PRINT '! No Restaurant Code - This record (' + @AI_PRIKEY + ') will be skipped' 
		END

		IF COALESCE(@SessCode, '') = '' BEGIN
			PRINT '! No Restaurant Session Code - This record (' + @AI_PRIKEY + ') will be skipped' 
		END

		IF (COALESCE(@RestCode, '') <> '' AND COALESCE(@SessCode, '') <> '') BEGIN --Only continue if there is a Restaurant Code and a Session Code.
			EXEC @AV_OK = cabs_check_av_rest @AI_STARTDATETIME, @AI_ENDDATETIME, @RestCode, @SessCode, @AI_COVERS

			IF @AV_OK = 1 BEGIN
				PRINT '* Availability in ' + @RestCode + '|' + @SessCode + ' for ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers' 
				PRINT '> Creating Booking For ' + @AI_PRIKEY + ' in ' + @RestCode + '|' + @SessCode + ' for ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers'
				EXEC cabs_book_room_rest @AI_GEDATE, @AI_STARTDATETIME, @AI_ENDDATETIME, @RestCode, @SessCode, @AI_FREF, @AI_COVERS, @AI_TIME, @AI_ENDTIME, @AI_PRIKEY, @BOOKING_REF OUTPUT, @BOOKING_MADE OUTPUT
				EXEC CABS_MOVE_MBR_GE @AI_FREF, 'R'
			END
			ELSE
			IF @AV_OK = 0 BEGIN
				PRINT '! No availability in ' + @RestCode + '|' + @SessCode + ' for ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers'
			END
		END

		UPDATE GERestData_Full
		SET FUNC_NO = @BOOKING_REF,
		Processed = 1,
		Success = @BOOKING_MADE
		WHERE ID = @ID

	PRINT 'Processing COMPLETE for ' + (CONVERT(VARCHAR, @ID)) + ': ' + @AI_PRIKEY + ': ' + @RestCode + '|' + @SessCode + ' for ' + CONVERT(VARCHAR, @AI_COVERS) + ' covers' + CHAR(10)

	FETCH NEXT FROM 
		CreateRest_Cur
	INTO
		@ID,
		@AI_PRIKEY,
		@AI_FREF,
		@AI_CODE,
		@AI_COVERS,
		@AI_GEDATE,
		@AI_TIME, 
		@AI_ENDTIME,
		@AI_STARTDATETIME,
		@AI_ENDDATETIME,
		@AI_CODE_SELECTION,
		@RUN_ID,
		@RUN_DATE
	END

	CLOSE CreateRest_Cur
	DEALLOCATE CreateRest_Cur

	PRINT '-- Processing COMPLETE --'
END
GO


