IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'uf_GetCostCentre') begin
	Drop Function uf_GetCostCentre
END
Go

/****** Object:  UserDefinedFunction [dbo].[uf_GetCostCentre]    Script Date: 27/09/2016 00:32:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 11/5/16
-- Description:	Returns the costcentre for an extra code
-- =============================================
CREATE FUNCTION [dbo].[uf_GetCostCentre] 
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
	SET @Result = (SELECT Top 1 P_COSTCENT from POST_DEF where P_CODE =@ExtraCode)

	-- Return the result of the function
	RETURN @Result

END

GO

