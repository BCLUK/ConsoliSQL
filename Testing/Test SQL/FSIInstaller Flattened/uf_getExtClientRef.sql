
IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'uf_getExtClientRef') begin
	Drop Function uf_getExtClientRef
END
Go
/****** Object:  UserDefinedFunction [dbo].[uf_getExtClientRef]    Script Date: 26/09/2016 10:26:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 15th Dec 2013
-- Description:	Gets external client ref from CL_Text1 from MBRNO
-- =============================================
CREATE FUNCTION [dbo].[uf_getExtClientRef] 
(
	-- Add the parameters for the function here
	@MBR_SYSNO Varchar(10)
)
RETURNS Varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(50)
	DECLARE @CL_SYSNO Varchar(10)

	-- Add the T-SQL statements to compute the return value here
	if isnull(@MBR_SYSNO,'') = '' begin
		set @Result = 'Invalid MBR NO'
	end
	else begin
		SET @CL_SYSNO = (select MBR_CLIENT from MBRFILE where MBR_SYSNO = @MBR_SYSNO)
		if isnull(@CL_Sysno,'') = '' begin
			SET @Result = 'Missing Client'
		end
		else begin
			SET @Result = (select CL_Text1 from CLIENTS where CL_SysNo = @CL_SYSNO)
			if isnull(@Result,'') = '' begin
				SET @Result = 'No Ext Client Ref'
			end
		end 
	end
	-- Return the result of the function
	RETURN @Result

END

GO

