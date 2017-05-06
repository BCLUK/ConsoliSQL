--==============================================================================================================
if exists(select object_id from sys.objects where name = 'usp_RULE_Batch_No') begin
	Drop Procedure usp_RULE_Batch_No
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
-- Create date: 22/09/2016
-- Description:	Returns the BAtch code for use in exports
-- =============================================
CREATE PROCEDURE usp_RULE_Batch_No 
	-- Add the parameters for the stored procedure here
	@InputPar Varchar(100) = '', 
	@InputPar1 Varchar(10) = '',
	@OutputPAr Varchar(100) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Set @OutputPar =(SELECT dbo.uf_xcabs_config_readString('','FinanceExport','BatchNo'))
END
GO


