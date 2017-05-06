if exists(select OBJECT_ID from sys.objects where name = 'vw_netted_Foltran') begin
	DROP VIEW vw_netted_Foltran
end
GO

/****** Object:  View [dbo].[vw_netted_Foltran]    Script Date: 30/01/2017 15:53:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[vw_netted_Foltran]
AS
-- Description: nets off pluses and minuses to provide a single figure for adjusted records
-- Amended 11/5/16 PLG to add more fields from PostDef and count

SELECT   TOP (100) PERCENT F_TRANNO, F_SOURCE, F_DATE, F_TREF, F_POSTCODE, F_VALUE, F_VAT_RATE, F_VAT_AMT, F_ONINV, 
		F_INVDATE, F_ADJNO, F_TRANSFRD, F_CHARGEBK, F_CLIENT, F_CREDIT, F_VAT_CODE, F_COST, F_MATTER, F_OWNER, 
		F_ITEMTYPE, F_POSTDATE, F_CALCAMT, F_PaidBy, F_NowShow, F_PaidOn, F_Docket, F_Transfrd_Paid, F_Transfrd_XML, 
		P_COSTCENT, P_NL_CODE, ItemCount
FROM            (SELECT        TOP (100) PERCENT MAX(F_TRANNO) AS F_TRANNO, 
							MAX(ISNULL(F_SOURCE, '')) AS F_SOURCE, 
							MAX(ISNULL(F_DATE, '01/01/1900')) AS F_DATE, 
							MAX(ISNULL(F_TREF, '')) AS F_TREF, 
							MAX(ISNULL(F_POSTCODE, '')) AS F_POSTCODE, 
							ROUND(SUM(isnull(F_VALUE,0)), 2) AS F_VALUE, 
							MAX(ISNULL(F_VAT_RATE, 0)) AS F_VAT_RATE, 
							ROUND(SUM(ISNULL(F_VAT_AMT, 0)), 2) AS F_VAT_AMT, 
							MAX(ISNULL(F_ONINV, '')) AS F_ONINV, 
                            MAX(ISNULL(F_INVDATE, '01/01/1900')) AS F_INVDATE, 
                            F_ADJNO, 
                            MAX(isnull(F_TRANSFRD,0)) AS F_TRANSFRD, 
                            MAX(ISNULL(F_CHARGEBK, '')) AS F_CHARGEBK, 
                            MAX(ISNULL(F_CLIENT, '')) AS F_CLIENT, 
                            MAX(ISNULL(F_CREDIT, '')) AS F_CREDIT, 
                            MAX(ISNULL(F_VAT_CODE, 0)) AS F_VAT_CODE, 
                            SUM(isnull(F_COST,0)) AS F_COST, 
                            MAX(ISNULL(F_MATTER, '')) AS F_MATTER, 
                            MAX(ISNULL(F_OWNER, '')) AS F_OWNER, 
                            MAX(ISNULL(F_ITEMTYPE, '')) AS F_ITEMTYPE, 
                            MAX(ISNULL(F_POSTDATE, '01/01/1900')) AS F_POSTDATE, 
                            ROUND(SUM(ISNULL(F_CALCAMT, 0)), 2) AS F_CALCAMT, 
                            Max(isnull(F_PAidby, '')) as F_PaidBy,
							Max(isnull(F_NowShow,0)) as F_NowShow, 
							Max(isnull(F_PaidOn,'01/01/1900')) as F_PaidOn, 
							Max(isnull(F_Docket,'')) as F_Docket, 
							Max(isnull(F_Transfrd_Paid,0)) as F_Transfrd_Paid, 
							Max(isnull(F_Transfrd_XML,0)) as F_Transfrd_XML,
							COUNT(F_Tranno) as ItemCount
                          FROM            dbo.FOL_TRAN
                          WHERE        (F_ADJNO IS NOT NULL) AND (F_POSTCODE <> 'DEPREC') AND (F_POSTCODE <> 'DEP') AND (F_POSTCODE <> 'PRE PA') AND F_ONINV = 'I005386'
                          GROUP BY F_ADJNO
                          UNION
                          SELECT        TOP (100) PERCENT F_Tranno, 
                          ISNULL(F_SOURCE, '') AS F_SOURCE, 
                          ISNULL(F_DATE, '01/01/1900') AS F_DATE, 
                          ISNULL(F_TREF, '') AS F_TREF, 
                          ISNULL(F_POSTCODE, '') AS F_POSTCODE, 
                          ROUND(isnull(F_VALUE,0), 2) AS F_Value, 
                          isnull(F_VAT_RATE,0.00) as F_VAT_RATE, 
                          ROUND(isnull(F_VAT_AMT,0.00), 2) AS F_VAT_AMT, 
                          ISNULL(F_ONINV, '') AS F_ONINV, 
                          ISNULL(F_INVDATE, '01/01/1900') AS F_INVDATE, 
                          '' AS F_ADJNO, 
                          isnull(F_TRANSFRD,0) as F_TRANSFRD, 
                          ISNULL(F_CHARGEBK, '') AS F_CHARGEBK, 
                          ISNULL(F_CLIENT, '') AS F_CLIENT, 
                          ISNULL(F_CREDIT, '') AS F_CREDIT, 
                          ISNULL(F_VAT_CODE,0) as F_VAT_CODE, 
                          ISNULL(F_COST,0.00) as F_COST, 
                          ISNULL(F_MATTER, '') AS F_MATTER, 
                          ISNULL(F_OWNER, '') AS F_OWNER, 
                          ISNULL(F_ITEMTYPE, '') AS F_ITEMTYPE, 
                          isnull(F_POSTDATE,'01/01/1900') as F_POSTDATE, 
                          ROUND(isnull(F_CALCAMT,(F_VALUE-F_VAT_AMT)), 2) AS F_CALCAMT, 
                          isnull(F_PaidBy,'') as F_PaidBy, 
						  isnull(F_NowShow,0) as F_NowShow, 
						  isnull(F_PaidOn,'01/01/1900') as F_PaidOn, 
						  isnull(F_Docket,'') as F_Docket, 
						  isnull(F_Transfrd_Paid,0) as F_Transfrd_Paid, 
						  isnull(F_Transfrd_XML,0) as F_Transfrd_XML,
						  1 as ItemCount
                          FROM            dbo.FOL_TRAN AS FOL_TRAN_1
                          WHERE        (F_ADJNO IS NULL) AND (F_POSTCODE <> 'DEPREC') AND (F_POSTCODE <> 'DEP') AND (F_POSTCODE <> 'PRE PA') 
						  ) AS derivedtbl_1  LEFT OUTER join POST_DEF on P_CODE = F_POSTCODE
ORDER BY F_ONINV, F_TRANNO




GO


