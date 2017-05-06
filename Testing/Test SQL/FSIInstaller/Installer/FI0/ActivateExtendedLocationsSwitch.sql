exec xCABS_CONFIG_WriteString '','System','UseLocationExtendedData',1,'G'

if (select Count(P_Code) from post_def where P_Code in (select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC')) <> (select count(ST_CODE) FROM sys_ABBR where ST_TYPE = 'LOC' AND ST_CODE <> 'ALL') begin
	if (select Count(P_Code) from post_def where P_Code in (select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC')) > 0 begin
		declare @DupCode Varchar(10)
		declare @CodeTest Varchar(6)
		declare @Counter int
		declare LocCur cursor fast_forward for select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC' and ST_CODE in (Select P_Code from Post_Def)
		open LocCur
		fetch next from LocCur into @DupCode
		while @@Fetch_status = 0 begin
			set @Counter = 1
			set @CodeTest = SUBSTRING(CHAR(64+@Counter) + @DUPCODE,1,6)
			while (select Count(P_Code) from POST_DEF where P_Code =@CodeTest) > 0 begin
				set @Counter = @Counter + 1
				set @CodeTest = SUBSTRING(CHAR(64+@Counter) + @CodeTest,2,5)
			end
			if (select Count(P_Code) from POST_DEF where P_Code =@CodeTest) = 0 begin
				update Post_def set P_Code = @CodeTest where P_CODE =@DupCode
				update AI_FILE set AI_COde = @CodeTest where AI_CODE =@DupCode
				update FOL_TRAN set F_POSTCODE= @CodeTest where F_POSTCODE =@DupCode
			end

			fetch next from LocCur into @DupCode
		end
		close LocCur
		deallocate Loccur
	end

	INSERT INTO [dbo].[POST_DEF]  ([P_CODE],[P_COSTCENT],[P_RPTCENT],[P_DESC],[P_ST_CHRGE],[P_NL_CODE]
			   ,[P_EVENT],[P_MAXPOOL],[P_IN_CHRGE],[P_CHARGEBK],[P_COST],[P_HOURLY],[P_OPGROUP]
			   ,[P_TIME],[P_ALTCODE],[P_LATEST_TIME],[P_EARLIEST_TIME],[P_ONLINE],[P_WEEKENDS],[P_EMAIL])
		 SELECT ST_CODE,'CCHIRE','','Additional Info - ' + ST_DESC,0.00, ''
				,1,1,0.00,0,0.00,0,'CCHIRE'
			   ,'00:00','','23:59','00:01',0,1,'helpdesk@bcluk.com' from SYS_ABBR where ST_TYPE = 'LOC' and ST_CODE <>'ALL'
end

	IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'uf_LocationCostCode') begin
	Drop Function uf_LocationCostCode
END
Go


-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 15th Sept 2016
-- Description:	Returns the cost centre for a Location.  This assumes that there is a Post_Def record with the same code as the location
-- Purpose:		Created for FSI
-- Version:		1
-- Date:		15th Sept 2016
-- Changes:		
-- =============================================
CREATE FUNCTION uf_LocationCostCode 
(
	-- Add the parameters for the function here
	@LocCode varchar(10)
)
RETURNS Varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Varchar(50)

	-- Add the T-SQL statements to compute the return value here
	SET @Result = isnull((Select P_NL_CODE from Post_def where P_CODE = @LocCode and P_COSTCENT = 'CCHIRE'),'Unknown')

	-- Return the result of the function
	RETURN @Result

END
GO

IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'Usp_RULE_LocationCostCode') begin
	Drop Procedure Usp_RULE_LocationCostCode
END
Go
-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 22/9/16
-- Description:	FSI Stored Procedure to return the location cost code for a function
-- =============================================
CREATE PROCEDURE Usp_RULE_LocationCostCode 
	-- Add the parameters for the stored procedure here
	@InputPar Varchar(10) = '',		--this will be the location code
	@InputPar1 Varchar(10) = '',	-- this will be the F_Tranno
	@OutputPar Varchar(100) OUTPUT  -- we are returning the location cost code (if it exists)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @OutputPar = dbo.uf_LocationCostCode(@InputPar)
	SELECT @OutputPar
END
GO
