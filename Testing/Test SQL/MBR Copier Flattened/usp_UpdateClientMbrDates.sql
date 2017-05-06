IF OBJECT_ID('usp_UpdateClientMbrDates', 'P') IS NOT NULL
DROP PROCEDURE usp_UpdateClientMbrDates
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Edwards
-- Create date: 17/03/2016
-- Description:	Updates
-- =============================================
CREATE PROCEDURE usp_UpdateClientMbrDates
	@Client VARCHAR(7)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Mbr VARCHAR(7)

	DECLARE ClientMbrCur CURSOR LOCAL FAST_FORWARD FOR
	SELECT MBR_SYSNO
	FROM MBRFILE
	WHERE MBR_CLIENT = @Client

	OPEN ClientMbrCur

	WHILE 1 = 1
	BEGIN
		FETCH NEXT FROM ClientMbrCur INTO @Mbr
		IF @@FETCH_STATUS <> 0 BREAK

		EXEC usp_UpdateMBRDates @Mbr
	END

	CLOSE ClientMbrCur
	DEALLOCATE ClientMbrCur
END
GO