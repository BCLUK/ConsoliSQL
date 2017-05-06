IF exists(select OBJECT_ID from sys.objects where name = 'vw_FOL_TRAN_SUMMARY') begin
	DROP VIEW vw_FOL_TRAN_SUMMARY
END
GO
/****** Object:  View [dbo].[vw_FOL_TRAN_SUMMARY]    Script Date: 23/09/2016 22:33:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* SELECT * FROM [dbo].[FOL_TRAN];*/
CREATE VIEW [dbo].[vw_FOL_TRAN_SUMMARY]
AS
SELECT      F_OWNER, F_SOURCE, F_ONINV, F_CREDIT, Post_def.P_COSTCENT,F_POSTCODE, F_VAT_CODE,  ST_DESC,  
			F_TRANSFRD, ROUND(SUM(ROUND(CAST(Fol_tran.F_COST AS Money), 2)), 2) AS COST, 
			  ROUND(SUM(ROUND(CAST(Fol_tran.F_VALUE AS money), 2)), 2) AS VALUE, 
              ROUND(SUM(CAST(Fol_tran.F_VAT_AMT AS money)), 2) AS VATAMT, 
			  MAX(Fol_tran.F_TRANNO) AS F_TRANNO, 
              MAX(Fol_tran.F_DATE) AS F_DATE, 
			  MAX(Fol_tran.F_VAT_RATE) AS F_VAT_RATE, 
              MAX(Fol_tran.F_INVDATE) AS F_INVDATE, 
			  MAX(Fol_tran.F_CHARGEBK) AS F_CHARGEBK, MAX(ISNULL(F_CLIENT, '')) AS F_CLIENT, 
			  MAX(Fol_tran.F_MATTER) AS F_MATTER,
			  MAX(Fol_tran.F_ITEMTYPE) AS F_ITEMTYPE, MAX(Fol_tran.F_POSTDATE) AS F_POSTDATE, 
              ROUND(SUM(ROUND(CAST(Fol_tran.F_CALCAMT AS money), 2)), 2) AS F_CALC_AMT, 
			  dbo.uf_getExtClientRef(Fol_tran.F_SOURCE) AS ExtCliRef,
			  SUM(ItemCount) as ItemCount
FROM            dbo.vw_netted_Foltran AS Fol_tran
						INNER JOIN
                         dbo.POST_DEF ON F_POSTCODE = dbo.POST_DEF.P_CODE
                          INNER JOIN
                         dbo.SYS_ABBR ON dbo.POST_DEF.P_COSTCENT = dbo.SYS_ABBR.ST_CODE
GROUP BY Fol_tran.F_OWNER, Fol_tran.F_SOURCE, Fol_tran.F_ONINV, Fol_tran.F_CREDIT, Post_def.P_COSTCENT, Fol_tran.F_POSTCODE, Fol_tran.F_VAT_CODE, dbo.SYS_ABBR.ST_DESC, F_TRANSFRD
HAVING        (ROUND(SUM(ROUND(CAST(Fol_tran.F_CALCAMT AS money), 2)), 2) <> 0)



GO

