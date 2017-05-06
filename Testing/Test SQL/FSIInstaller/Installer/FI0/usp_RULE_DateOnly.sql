if exists (select object_ID from sys.objects where name = N'usp_RULE_Batch_No') begin
	DROP PROCEDURE usp_RULE_Batch_No
end
GO
/****** Object:  StoredProcedure [dbo].[usp_RULE_Batch_No]    Script Date: 23/01/2017 10:38:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 23/01/2017
-- Description:	Strips the time off a date time field to return only a date
-- =============================================
CREATE PROCEDURE [dbo].[usp_RULE_DateOnly] 
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
	Set @OutputPar = DATEADD(dd, DATEDIFF(dd, 0, @inputPar), 0)

END

GO


