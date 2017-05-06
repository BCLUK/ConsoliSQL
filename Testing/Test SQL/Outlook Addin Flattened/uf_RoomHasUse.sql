SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 28th Mar 2014
-- Description:	From the rm_use table decides whether a particular room has a particular layout
-- =============================================
CREATE FUNCTION [dbo].[uf_RoomHasUse] 
(
	-- Add the parameters for the function here
	@Room varchar(10),
	@use varchar(10)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int
	Set @Result = 0
	-- Add the T-SQL statements to compute the return value here
	if (@use = 'ANY' or @use = '') begin
		if (@room = 'ANY' or @room = '') begin 
			Set @result = 1
		end
		else begin
			set @result = (Select Count(RM_ABBR) from rooms where RM_ABBR = @Room)
		end
	end
	else begin
		if (@room = 'ANY' or @room = '') begin 
			Set @Result = (select count(ST_CODE) from SYS_ABBR where ST_Type = 'RUS' and ST_CODE = @use)
		end
		else begin
			SET @Result = (Select Count(US_RM_USE) from RM_USE where US_RM_CODE = @Room and US_RM_USE = @use)
		end
	end
	-- Return the result of the function
	RETURN @Result

END