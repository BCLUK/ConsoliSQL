DECLARE @Result Varchar(50)
SET @Result = isnull((Select P_NL_CODE from Post_def where P_CODE = @LocCode and P_COSTCENT = 'CCHIRE'),'Unknown')