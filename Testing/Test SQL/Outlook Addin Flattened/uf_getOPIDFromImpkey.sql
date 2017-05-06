SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		Corey Bradford
-- Create date: 25/07/2016
-- Description:	Returns the OPID based on the passed @Impkey, @CallerID is used to determine
--				which default to return if no OPID is associated with the passed @Impkey
-- Version:		3
-- ------------------------------------------------------------------------------------------
-- Updates:
-- 17-03-2017	3 - Corey Bradford
--					~ Replace spaces in @Impkey with nothing
--
-- 25-01-2017	2 - Corey Bradford
--					+ @callerID which determines which default OPID to return
--
-- 25-07-2016	1 - Corey Bradford
--					+ Initial Version
-- ------------------------------------------------------------------------------------------
-- Caller ID's:
-- 'O'			Outlook addin
-- 'W'			CABS web
-- 'C'			CABS console
-- ==========================================================================================
CREATE FUNCTION uf_GetOPIDFromImpkey 
(
	@Impkey			VARCHAR( 31 ),
	@callerID		CHAR( 1 ) 
)
RETURNS VARCHAR( 31 )
AS
BEGIN
	DECLARE @MBRADDR VARCHAR( 31 )
	
	SET @Impkey = REPLACE( @Impkey, ' ', '' )

	IF EXISTS( SELECT * FROM OP_FILE WHERE O_USER = @Impkey )
		RETURN @Impkey;
	
	SET @MBRADDR  = ( SELECT MBR_ADDR5 FROM MBRFILE WHERE MBR_IMPKEY = @Impkey );
	IF EXISTS( SELECT * FROM OP_FILE WHERE O_USER = @MBRADDR )
		RETURN @MBRADDR;

	IF @callerID = 'O' AND EXISTS( SELECT * FROM OP_FILE WHERE O_USER = 'Outlook' )
		RETURN 'Outlook';

	-- If cabsweb or outlook if no outlook record exists
	IF EXISTS( SELECT * FROM OP_FILE WHERE O_USER = 'cabsweb' )
		RETURN 'cabsweb';

	RETURN 'Not Found';
END