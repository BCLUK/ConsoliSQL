-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'utf_PackageView'
SET @Func_Name = 'utf_PackageView'
if exists (select * from sys.objects where object_id = object_id(N'[dbo].[utf_PackageView]') and type in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[utf_PackageView]
	PRINT @FileName + ': Dropped Function ' + @Func_Name
END
ELSE
BEGIN
	PRINT @FileName + ': ' + @Func_Name + ' -  Does Not Already Exist !'
END
PRINT @FileName + ': Creating Function ' + @Func_Name
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 12th MArch 2015
-- Description:	Returns a Package List starting with the Header
-- =============================================
-- Version: 2
-- Date: 24/12/2015
-- =============================================
-- Changes: 24/12/2015: MCB: Added 'I' to Amended Statement
-- Changes: 24/12/2015: MCB: Added [] Around Headings
-- =============================================
CREATE FUNCTION [dbo].[utf_PackageView] 
(
	-- Add the parameters for the function here
	@PkHead Varchar(10) = '',
	@PHOwner Varchar(7) = ''
)
RETURNS 
@Table_Var TABLE 
(
	-- Add the column definitions for the TABLE variable here
	PH_SYSNO Varchar(7)
      ,PH_CODE Varchar(6)
      ,PK_POST Varchar(6)
      ,P_DESC Varchar(50)
      ,PK_COVERS int
      ,PH_OWNER Varchar(7)
      ,PK_SEQ int
)
AS
BEGIN

	   Declare @PH_SYSNO Varchar(7)
       Declare @PH_CODE Varchar(6)
       Declare @PK_POST Varchar(6)
       Declare @P_DESC Varchar(50)
       Declare @PK_COVERS int
       Declare @PH_OWNER Varchar(7)
       Declare @PK_SEQ int	
       Declare @OrderBy int
       Declare @AmndItems int       

	   -- Fill the table variable with the rows for your result set
	if isnull(@PkHead,'') = '' begin  --it is not for a specific package
		if isnull(@PHOwner,'') = '' begin --it is not for a specific function
			declare headcur cursor fast_forward for Select PH_SysNo, PH_Code, PH_Desc, PH_Owner from PkgHead where PH_Owner is not null
		end
		else begin -- it is for a specific function
			declare headcur cursor fast_forward for Select PH_SysNo, PH_Code, PH_Desc, PH_Owner from PkgHead where PH_Owner =@PHOwner
		end
	end
	else begin  -- it is for a specific package
		if isnull(@PHOwner,'') = '' begin --it is not for a specific function 
			declare headcur cursor fast_forward for Select PH_SysNo, PH_Code, REPLACE(PH_Desc, CHAR(39), CHAR(146)), PH_Owner from PkgHead where PH_Owner is not null and PH_SysNo = @PKHead
		end
		else begin -- it is for a specific function
			declare headcur cursor fast_forward for Select PH_SysNo, PH_Code, REPLACE(PH_Desc, CHAR(39), CHAR(146)), PH_Owner from PkgHead where PH_Owner =@PHOwner and PH_SysNo = @PKHead
		end
	end

	SET @AmndItems = 0
	
	open headcur
	fetch next from headcur into @PH_SysNo, @PH_Code, @P_Desc, @PH_Owner
	while @@FETCH_STATUS = 0 begin

		SET @AmndItems =(SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_ACTION IN('I', 'D', 'U') AND SUBSTRING(AEFA_PRIKEY, 1, NULLIF(PATINDEX ('%~%', AEFA_PRIKEY) - 1, -1)) = @PH_SYSNO)
					
		Insert into @Table_Var (PH_SYSNO,PH_CODE,PK_POST,P_DESC,PK_COVERS,PH_OWNER,PK_SEQ)
		VALUES (@PH_SYSNO, @PH_CODE,'', '[' + @P_Desc + ']', CASE @AmndItems WHEN 0 THEN 0 ELSE -1 END,@PH_OWNER,1)
		-- have inserted header row
		declare itemcur cursor fast_forward for Select PK_POST, PK_COVERS, PK_SEQ, 1 As OrderBy from PACKAGES where PK_SYSNO = @PH_SYSNO
		UNION
		 SELECT AEFA_CODE, AEFA_COVERS, 0, 2 FROM AEF_Amendments WHERE AEFA_ACTION = 'U' AND SUBSTRING(AEFA_PRIKEY, 1, NULLIF(PATINDEX ('%~%', AEFA_PRIKEY) - 1, -1)) = @PH_SYSNO
		 ORDER BY PK_POST, OrderBy, PK_SEQ
		open itemcur 
		fetch next from itemcur into @PK_Post, @PK_Covers, @PK_Seq, @OrderBy
		while @@Fetch_Status = 0 begin
			
			Insert into @Table_Var (PH_SYSNO,PH_CODE,PK_POST,P_DESC,PK_COVERS,PH_OWNER,PK_SEQ)
			VALUES (@PH_SYSNO,'',@PK_POST,dbo.uf_getExtraDescription(@PK_Post),@PK_Covers,@PH_OWNER,CASE @OrderBy WHEN 1 THEN @PK_Seq+1 ELSE -1 END)

			fetch next from itemcur into @PK_Post, @PK_Covers, @PK_Seq, @OrderBy
		end
		
		close itemcur
		deallocate itemcur
		fetch next from headcur into @PH_SysNo, @PH_Code, @P_Desc, @PH_Owner
	end
	close headcur
	deallocate headcur
	RETURN 
END
GO

PRINT '*****************************************************************************'								   
PRINT 'utf_PackageView: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_PackageView]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_PackageView') AND [name] = 'Product')
BEGIN		
	PRINT 'utf_PackageView: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_PackageView: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_PackageView]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_PackageView') AND [name] = 'Module')
BEGIN		
	PRINT 'utf_PackageView: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_PackageView: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_PackageView]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_PackageView') AND [name] = 'Version')
BEGIN		
	PRINT 'utf_PackageView: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_PackageView: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO