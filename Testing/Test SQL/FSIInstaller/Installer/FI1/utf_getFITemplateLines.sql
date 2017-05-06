
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[utf_getFITemplateLines]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[utf_getFITemplateLines]
GO

-- =============================================
-- Author:		Peter Green	
-- Create date: 19 Sept 2012
-- Description:	returns the elements for Finance Export as a Table
-- =============================================
CREATE FUNCTION [dbo].[utf_getFITemplateLines]
(	
	-- Add the parameters for the function here
	@FIHeaderID int
	
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT TOP 100 pERCENT * from FI_Template where FI_Header_ID = @FIHeaderID
	Order By StartPos 
)



GO
