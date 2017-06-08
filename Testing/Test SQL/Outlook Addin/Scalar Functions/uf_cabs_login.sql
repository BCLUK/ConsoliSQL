SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		Corey Bradford
-- Create date: 15/09/2016
-- Description:	Verifies login details and returns 0x00 if verified
-- Version:		3
-- Updates:	
-- 15/02/2017	2 Corey Bradford
--				+ Added Error code returns
--				~ Changed @security from VARCHAR(26) to VARCHAR(5)
--
-- 17/03/2017	3 Corey Bradford
--				+ Added nullcheck to passed parameters
--				~ Fixed CHARINDEX check by removing % symbol
--				~ Fixed MAJOR SECURITY FLAW where if retrived variables were null it would return Success
--
-- Error Codes:
-- 0x00			Success
-- 0x01			Could not find user
-- 0x02			Incorrect password
-- 0x03			User doesnt have security
-- ==========================================================================================
CREATE FUNCTION [dbo].[uf_cabs_login]
(
	@Username VARCHAR( 31 ),
	@Password VARCHAR( 31 ),
	@Security VARCHAR( 5 )
)
RETURNS INT
AS
BEGIN
	DECLARE @RetrivedUsername VARCHAR( 31 ),
			@RetrivedPassword VARCHAR( 31 ),
			@RetrivedSecurity VARCHAR( 26 )

	SELECT @RetrivedUsername = O_USER,
		   @RetrivedPassword = O_PWORD,
		   @RetrivedSecurity = O_SECURITY
	FROM [dbo].[OP_FILE]
	WHERE O_USER = @Username

	IF @Username IS NULL
	OR @RetrivedUsername IS NULL
	OR @Username <> @RetrivedUsername
		RETURN 0x01

	IF @Password IS NULL
	OR @RetrivedPassword IS NULL
	OR @Password <> @RetrivedPassword
		RETURN 0x02

	IF @Security IS NULL
	OR @RetrivedSecurity IS NULL
	OR CHARINDEX( @Security, @RetrivedSecurity ) = 0
		RETURN 0x03

	RETURN 0x00
END