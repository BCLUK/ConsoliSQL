SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_ExtrasTree]
AS
SELECT DISTINCT 
                         dbo.POST_DEF.P_CODE AS ExtraCode, dbo.POST_DEF.P_COSTCENT AS CostCentreCode, dbo.POST_DEF.P_RPTCENT, dbo.POST_DEF.P_DESC AS ExtraDescription,
                          dbo.POST_DEF.P_ST_CHRGE, dbo.POST_DEF.P_NL_CODE, dbo.POST_DEF.P_EVENT, dbo.POST_DEF.P_MAXPOOL, dbo.POST_DEF.P_IN_CHRGE, 
                         dbo.POST_DEF.P_CHARGEBK, dbo.POST_DEF.P_COST, dbo.POST_DEF.P_HOURLY, dbo.POST_DEF.P_OPGROUP, dbo.POST_DEF.P_TIME, 
                         dbo.POST_DEF.P_ALTCODE, dbo.POST_DEF.P_LATEST_TIME, dbo.POST_DEF.P_ONLINE, dbo.POST_DEF.P_WEEKENDS, dbo.POST_DEF.P_EARLIEST_TIME, 
                         dbo.POST_DEF.P_EMAIL, cc.ST_DESC + ' - ' + sc.SC_LOC AS CostCentreDesc, sc.SC_LOC, loc.ST_DESC AS Location
FROM            dbo.POST_DEF INNER JOIN
                         dbo.SYS_ABBR AS cc ON dbo.POST_DEF.P_COSTCENT = cc.ST_CODE INNER JOIN
                         dbo.SERVCENT AS sc INNER JOIN
                         dbo.SYS_ABBR AS loc ON loc.ST_CODE = sc.SC_LOC ON sc.SC_EXTRA = dbo.POST_DEF.P_CODE
WHERE        (cc.ST_TYPE = 'CRC') AND (dbo.POST_DEF.P_COSTCENT <> 'CCHIRE')