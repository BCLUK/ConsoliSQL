if exists (select * from dbo.sysobjects where id = object_id(N'[CABS_MOVE_MBR_GE]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [CABS_MOVE_MBR_GE] 
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Mark Birch
-- Script Name: CABS_MOVE_MBR_GE.sql
-- Create date: 22-JUN-2016
-- Description:	Move MBR for Global Extras Global Extras
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 1
-- Date: 22/06/2016
-- =============================================
-- Changes: dd/mm/yyyy: XXX: 
-- =============================================
CREATE PROCEDURE CABS_MOVE_MBR_GE @MBR_NO VARCHAR(7), @Type VARCHAR(5)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SettingsType VARCHAR(10), @SP_TRG VARCHAR(100), @NEW_CLIENT VARCHAR(7)
	SET @SettingsType = 'S'

	IF @Type = 'A' BEGIN
		SET @SP_TRG = 'GlobalExtras_AccomCodes'
	END
	
	IF @Type = 'R' BEGIN
		SET @SP_TRG = 'GlobalExtras_RestCodes'
	END

	SET @NEW_CLIENT = (SELECT COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @SP_TRG, 'ClientNo')), 'N/A'))
	
	IF @NEW_CLIENT = 'N/A' BEGIN
		RETURN
	END
	ELSE
	IF @NEW_CLIENT <> 'N/A' BEGIN
		
		IF (LEN(@NEW_CLIENT) <> 7 OR LEFT(@NEW_CLIENT, 1) <> 'C') BEGIN
			SET @NEW_CLIENT = 'C000000'
		END  

		DECLARE
			@MBR_SYSNO VARCHAR(7),
			@MBR_CLIENT VARCHAR(7)

		DECLARE
			MoveMBR_Cur
		CURSOR FAST_FORWARD for
	
			SELECT MBR_SYSNO, MBR_CLIENT
			FROM MBRFILE
			WHERE MBR_SYSNO = @MBR_NO
			AND MBR_CLIENT <> @NEW_CLIENT
			ORDER BY MBR_SYSNO
	
		OPEN MoveMBR_Cur

		FETCH NEXT FROM
			MoveMBR_Cur
		INTO
			@MBR_SYSNO,
			@MBR_CLIENT

		WHILE @@FETCH_STATUS = 0
		BEGIN
	
			IF @MBR_CLIENT <> @NEW_CLIENT BEGIN
				UPDATE MBRFILE
				SET MBR_CLIENT = @NEW_CLIENT,
				MBR_ADINFO = COALESCE(CONVERT(VARCHAR, MBR_ADINFO), '') + CHAR(10) + 'Client Number Updated from ' + @MBR_CLIENT + ' to ' + @NEW_CLIENT + ' on ' + (CONVERT(VARCHAR(11), (GETDATE()), 103)) + ' ' + (CONVERT(VARCHAR(8), (GETDATE()), 108)) + ' via the Global Extras Conversion Process.' + CHAR(10) 
				WHERE MBR_CLIENT = @MBR_CLIENT 
				AND MBR_SYSNO =  @MBR_SYSNO
			END
	
			FETCH NEXT FROM 
				MoveMBR_Cur
			INTO
				@MBR_SYSNO,
				@MBR_CLIENT
		END

		CLOSE MoveMBR_Cur
		DEALLOCATE MoveMBR_Cur
	END
END
GO