SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 28th Mar 2014
-- Description:	Decides whether room is the right size
-- =============================================
CREATE FUNCTION [dbo].[uf_OutlookRoomFit] 
(
	-- Add the parameters for the function here
	@Covers int,
	@Room Varchar(10),
	@Use Varchar(10)
)
RETURNS Varchar (50)
AS
BEGIN
	-- Declare the return variable here
	Declare @Outstring Varchar(50)
	DECLARE @Result int
	Declare @Min int
	Declare @Max int
	-- Add the T-SQL statements to compute the return value here
	if (@Use = 'ANY' or @USE = '') Begin
		Set @Min = (Select MIN(US_MIN) from RM_USE where US_RM_CODE = @Room)
		set @Max = (Select MAX(US_MAX) from RM_USE where US_RM_CODE = @Room)
	end
	else begin
		Set @Min = (Select US_MIN from RM_USE where US_RM_CODE = @Room and US_RM_USE = @Use)
		Set @Max = (Select US_MAX from RM_USE where US_RM_CODE = @Room and US_RM_USE = @Use)
	end

	if @max = 0 begin
		Set @Result = 1
	end
	else begin
		if @Covers > @Max begin
			set @Result = 0 
		end
		else begin
			set @result = 1
		end
	end
	if @min = 0 begin
		set @result = @result + 2
	end
	else begin 
		if @Covers > @Min begin
			set @Result = @result + 2 
		end
	end
	-- now catch is room is under occupied
	if @result = 3 begin
		if @max <> 0 begin
			if (Cast(@Covers as decimal)/@Max ) < 0.5 set @result = 1
		end
	end


	if @Result = 3 begin 
		set @Outstring = '100 Room Fit'
	end
	else begin	
		if @result = 2 begin
			set @Outstring = '000 Room too small - max cap ' + Cast(@max as Varchar(4))
		end
		else begin
			if @result = 1 begin
				set @Outstring = '050 Room too Large - min book ' + Cast(@min as Varchar(4)) + ' Max cap - ' +Cast(@max as Varchar(4))
			end
			else set @Outstring = '000 Some problem in calcs has occurred '
		end
	end
	-- Return the result of the function
	RETURN @Outstring

END