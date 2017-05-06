SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Corey Bradford
-- Create date: 13 - 06 - 2016
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION uf_cabs_ModifyTime
(
	-- Add the parameters for the function here
	@Time varchar( 5 ),
	@Hours int,
	@Minutes int
)
RETURNS varchar( 5 )
AS
BEGIN
	-- Declare the return variable here
	declare @newTime varchar( 5 ) = ''
	declare @newHours int
	declare @newMinutes int

	set @newHours = cast( substring( @Time, 1, 2 ) as int ) + @Hours;
	set @newMinutes = cast( substring( @Time, 4, 2 ) as int ) + @Minutes;
	
	if( @newHours < 10 )
		set @newTime = '0'
		
	set @newTime += cast( @newHours as varchar( 2 ) )
	set @newTime += ':'

	if( @newMinutes < 10 )
		set @newTime += '0'

	set @newTime += cast( @newMinutes as varchar( 2 ) )

	-- Return the result of the function
	return @newTime;
END