SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 17th Sep 2014
-- Description:	Returns extras codes for tree view
-- =============================================
CREATE FUNCTION [dbo].[utf_ExtraTreeByLoc1] 
(
	-- Add the parameters for the function here
	@LocCode Varchar(10) = 'ALL'
)
RETURNS 
@Table_Var TABLE 
(
	-- Add the column definitions for the TABLE variable here
	 ExtraCode varchar(10), CostCentreCode Varchar(10), P_RPTCENT Varchar(10), ExtraDescription Varchar(100), 
	 P_ST_CHRGE money, P_NL_CODE varchar(50), P_EVENT varchar(100), P_MAXPOOL int, P_IN_CHRGE money, 
	 P_CHARGEBK varchar(30), P_COST money, P_HOURLY int, P_OPGROUP varchar(10), P_TIME varchar(5), P_ALTCODE varchar(10), 
	 P_LATEST_TIME varchar(5), P_ONLINE int, P_WEEKENDS int, P_EARLIEST_TIME varchar(5), P_EMAIL varchar(255), CostCentreDesc varchar(100), 
	 SC_LOC varchar(10), Location Varchar(50)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if @Loccode = 'ALL' begin
		insert into @Table_Var SELECT Top 100 Percent ExtraCode, CostCentreCode, P_RPTCENT, ExtraDescription,
                          P_ST_CHRGE, P_NL_CODE, P_EVENT, P_MAXPOOL, P_IN_CHRGE, 
                         P_CHARGEBK, P_COST, P_HOURLY, P_OPGROUP, P_TIME, P_ALTCODE, 
						 P_LATEST_TIME, P_ONLINE, P_WEEKENDS, P_EARLIEST_TIME, P_EMAIL, CostCentreDesc, 
						 SC_LOC, Location from vw_ExtrasTree order by CostCentreCode,ExtraCode  
	end
	else begin
		insert into @Table_Var SELECT Top 100 Percent e.ExtraCode,e.CostCentreCode, e.P_RPTCENT, e.ExtraDescription,
                          e.P_ST_CHRGE, e.P_NL_CODE, e.P_EVENT, e.P_MAXPOOL, e.P_IN_CHRGE, 
                         e.P_CHARGEBK, e.P_COST, e.P_HOURLY, e.P_OPGROUP, e.P_TIME, e.P_ALTCODE, 
						 e.P_LATEST_TIME, e.P_ONLINE, e.P_WEEKENDS, e.P_EARLIEST_TIME, e.P_EMAIL, e.CostCentreDesc, 
						 e.SC_LOC, e.Location  from vw_ExtrasTree e
		where SC_LOC = @LocCode or SC_LOC= case (select count(Sc_extra) from Servcent where SC_LOc= @loccode and SC_extra = e.Extracode) when 0 then 'ALL' else 'x9x9x9' end
		order by SC_LOC, CostCentreCode,ExtraCode -- 
	end

	RETURN 
END