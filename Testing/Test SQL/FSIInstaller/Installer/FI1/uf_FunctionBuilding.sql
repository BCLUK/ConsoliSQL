
/****** Object:  UserDefinedFunction [dbo].[uf_FunctionServicePoint]    Script Date: 04/05/2016 12:25:02 ******/
if exists(select object_id from sys.objects where name = N'uf_FunctionBuilding')  begin
	DROP FUNCTION [dbo].[uf_FunctionBuilding]
end
GO

/****** Object:  UserDefinedFunction [dbo].[uf_FunctionBuilding]    Script Date: 04/05/2016 12:25:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 24th Mar 2016
-- Description:	Returns the service point for a function (based on room belonging to SP roomGroup)
-- =============================================
CREATE FUNCTION [dbo].[uf_FunctionBuilding] 
(
	-- Add the parameters for the function here
	@FunctionRef Varchar(10)
)
RETURNS Varchar(10)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(10)
	DECLARE @RoomCode VArchar(15)
	-- Add the T-SQL statements to compute the return value here
	set @Result = 'UNKNWN'
	
	set @RoomCode = isnull((Select F_Room from Func_fil where F_Ref = @FunctionRef),'NONE')
	if @RoomCode <> 'NONE' begin
		SET @Result = dbo.uf_RoomBuilding(@RoomCode)
	end
	
	-- Return the result of the function
	RETURN @Result

END


GO


