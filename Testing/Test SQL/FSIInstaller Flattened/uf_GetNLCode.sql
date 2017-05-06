
IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'uf_GetNLCode') begin
	Drop Function uf_GetNLCode
END
Go

/****** Object:  UserDefinedFunction [dbo].[uf_GetNLCode]    Script Date: 27/09/2016 00:33:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 11/5/16
-- Description:	Returns the NL Code for an extra code
-- =============================================
CREATE FUNCTION [dbo].[uf_GetNLCode] 
(
	-- Add the parameters for the function here
	@ExtraCode Varchar(10)
)
RETURNS Varchar(10)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(10)

	-- Add the T-SQL statements to compute the return value here
	SET @Result = isnull((SELECT Top 1 P_NL_CODE from POST_DEF where P_CODE =@ExtraCode),'')

	-- Return the result of the function
	RETURN @Result

END


GO


