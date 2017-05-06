IF OBJECT_ID('[dbo].[uf_MbrCopierLogin]', 'FN') IS NOT NULL
BEGIN
	DROP FUNCTION [dbo].[uf_MbrCopierLogin]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Edwards
-- Create date: 14/02/2017
-- Description:	Login for the MBR Copier, checks user exists in OP_FILE and password is correct.
-- Version:		1
-- Updates:
-- Error Codes:
-- 0x00:		Success
-- 0x01:		User does not exist
-- 0x02:		Password is incorrect
-- =============================================
CREATE FUNCTION [dbo].[uf_MbrCopierLogin]
(
	@Username VARCHAR(31),
	@Password VARCHAR(31)
)
RETURNS INT
AS
BEGIN
	IF NOT EXISTS(SELECT 0 FROM OP_FILE WHERE O_USER = @Username)
	RETURN 1
	
	DECLARE @PasswordCheck VARCHAR(31) = (SELECT O_PWORD FROM OP_FILE WHERE O_USER = @Username)
	IF @Password != @PasswordCheck
	RETURN 2

	RETURN 0
END
GO