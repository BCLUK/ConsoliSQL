

/****** Object:  UserDefinedFunction [dbo].[uf_RoomBuilding]    Script Date: 09/05/2016 12:17:32 ******/
if exists (select object_id from sys.objects where name = N'uf_RoomBuilding') begin
	DROP FUNCTION [dbo].[uf_RoomBuilding]
end
GO

/****** Object:  UserDefinedFunction [dbo].[uf_RoomBuilding]    Script Date: 09/05/2016 12:17:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 24th Mar 2016
-- Description:	Returns the Building for a room  (assumes building room groups that have BC as first two characters)
-- =============================================
CREATE FUNCTION [dbo].[uf_RoomBuilding] 
(
	-- Add the parameters for the function here
	@RoomCode Varchar(15)
)
RETURNS Varchar(10)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ServicePoint Varchar(10)

	-- Add the T-SQL statements to compute the return value here
	SET @ServicePoint = isnull((Select Top 1 RG_GRPCODE from RMGROUPS where RG_RMABBR = @RoomCode and Substring(RG_GRPCODE,1,2) = 'BC'),'UNKNWN') 

	-- Return the result of the function
	RETURN @ServicePoint

END


GO


