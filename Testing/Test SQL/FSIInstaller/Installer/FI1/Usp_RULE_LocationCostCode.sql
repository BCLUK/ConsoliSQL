If exists(select OBJECT_ID from sys.objects where name = N'Usp_RULE_LocationCostCode') begin
	DROP PROCEDURE Usp_RULE_LocationCostCode
end
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 22/9/16
-- Description:	FSI Stored Procedure to return the location cost code for a function
-- =============================================
CREATE PROCEDURE Usp_RULE_LocationCostCode 
	-- Add the parameters for the stored procedure here
	@InputPar Varchar(10) = '',		--this will be the location code
	@InputPar1 Varchar(10) = '',	-- this will be the F_Tranno
	@OutputPar Varchar(100) OUTPUT  -- we are returning the location cost code (if it exists)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @OutputPar = dbo.uf_LocationCostCode(@InputPar)
	SELECT @OutputPar
END
GO
