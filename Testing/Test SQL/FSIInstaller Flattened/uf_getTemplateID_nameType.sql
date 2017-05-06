
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[uf_getTemplateID_nameType]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[uf_getTemplateID_nameType]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 19th Sept 2012
-- Description:	Gets the Template Line ID for the field and line type for easier refencing
-- =============================================
CREATE FUNCTION [dbo].[uf_getTemplateID_nameType] 
(
	-- Add the parameters for the function here
	@RowName Varchar(50),
	@HeaderID Int
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar int

	-- Add the T-SQL statements to compute the return value here
	SET @ResultVar = (Select TOP 1 [ID] from FI_Template where [NAme] = @RowName and FI_Header_ID = @HeaderID)

	-- Return the result of the function
	RETURN @ResultVar

END


GO
