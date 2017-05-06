SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 1st September 2016
-- Description:	Gives the room size score for one room use
-- =============================================
CREATE FUNCTION uf_BestRoomFitUse
(
	-- Add the parameters for the function here
	@Covers int,
	@Room Varchar(10),
	@ReqUse Varchar(10)
)
RETURNS Varchar(20)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(20)
	Declare @RmUse Varchar(20)
	Declare @Min Decimal(10,4)
	Declare @Max Decimal(10,4)
	Declare @BestFit Decimal(10,2) = 0 
	-- Add the T-SQL statements to compute the return value here
	if exists (select us_Rm_use from Rm_use where us_rm_code = @room and us_rm_use = @Requse) begin
		set @result = @ReqUse
	end
	else begin
		declare usecur cursor fast_forward for select us_rm_use, us_min, us_max from rm_use where US_RM_CODE = @room
		open usecur
		fetch next from usecur into @RmUse, @Min, @Max
		while @@fetch_status = 0 begin
			if (@Covers <= @Max) or (@Max = 0) begin -- we do not exceed capacity
				if (@covers >= @min) begin -- we are above the minimum booking
					if @Max <> 0 begin
						if (Cast(@covers as decimal(10,4))/@max > @BestFit) begin
							set @BestFit = (Cast(@covers as decimal(10,4))/@max)
							set @Result = @RmUse
						end
						else begin --so max is 0
							if @BestFit = 0 set @Result = @RmUse
							-- so we have no better fit than one that is not constrained
						end
					end
				end
			end
			fetch next from usecur into @RmUse, @Min, @Max
		end
		close usecur
		deallocate usecur
	end
	-- Return the result of the function
	RETURN @Result
END