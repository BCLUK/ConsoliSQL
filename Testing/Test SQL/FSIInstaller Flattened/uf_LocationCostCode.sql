IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'uf_LocationCostCode') begin
	Drop Function uf_LocationCostCode
END
Go
-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 15th Sept 2016
-- Description:	Returns the cost centre for a Location.  This assumes that there is a Post_Def record with the same code as the location
-- Purpose:		Created for FSI
-- Version:		1
-- Date:		15th Sept 2016
-- Changes:		
-- =============================================
CREATE FUNCTION uf_LocationCostCode 
(
	-- Add the parameters for the function here
	@LocCode varchar(10)
)
RETURNS Varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(50)

	-- Add the T-SQL statements to compute the return value here
	SET @Result = isnull((Select P_NL_CODE from Post_def where P_CODE = @LocCode and P_COSTCENT = 'CCHIRE'),'Unknown')

	-- Return the result of the function
	RETURN @Result

END
GO

