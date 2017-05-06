SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[cabs_get_next_session_num](@next_num varchar(7) OUTPUT) 
AS
BEGIN

	declare @cbcf_num integer
	declare @formatted_num varchar(20)

	select @cbcf_num = (select CF_SESSNO from CBCF)
	select @cbcf_num = @cbcf_num + 1

	begin transaction
	update CBCF set CF_SESSNO = @cbcf_num

	if @@error = 0
	begin
		commit transaction
		select @formatted_num  =  '000000' + ltrim(rtrim( convert(varchar(7), @cbcf_num) ))
		select @next_num  = 'S' + substring( @formatted_num, datalength( @formatted_num  ) - 5, 6 )
	end
	else
	rollback transaction
END