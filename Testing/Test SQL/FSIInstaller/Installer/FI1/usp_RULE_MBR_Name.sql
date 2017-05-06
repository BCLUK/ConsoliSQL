IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'usp_RULE_MBR_Name') begin
	Drop Procedure usp_RULE_MBR_Name
END
Go
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
-- Create date: 22/09/2016
-- Description:	Return the MBR Name (corporate or person) for use as a rule in FSI
-- =============================================
CREATE PROCEDURE usp_RULE_MBR_Name 
	-- Add the parameters for the stored procedure here
	@inputPAr Varchar(10) = '', 
	@InputPar1 Varchar(10) = '',
	@OutputPar Varchar(100) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @Internal bit
    -- Insert statements for procedure here
	set @Internal = (SELECT MBR_INTERN from MBRFILE where MBR_SYSNO = @inputPAr)
	Set @OutputPAr = (SELECT dbo.uf_GetMBRNAme(@inputPAr,@Internal))
END
GO


