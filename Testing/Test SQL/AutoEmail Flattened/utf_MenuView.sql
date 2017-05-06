-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'utf_MenuView'
SET @Func_Name = 'utf_MenuView'
if exists (select * from sys.objects where object_id = object_id(N'[dbo].[utf_MenuView]') and type in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[utf_MenuView]
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
-- Author:		Mark Birch
-- Create date: 13th March 2015
-- Description:	Returns a Menu List starting with the Header
-- =============================================
-- Version: 3
-- Date: 24/12/2015
-- =============================================
-- Changes: 13/11/2015: MCB: Added Notes in correct place.
-- Changes: 24/12/2015: MCB: Added [] Around Headings
-- =============================================
CREATE FUNCTION [dbo].[utf_MenuView] 
(
	-- Add the parameters for the function here
	@PkHead Varchar(10) = '',
	@PHOwner Varchar(7) = ''
)
RETURNS 
@Table_Var TABLE 
(
	-- Add the column definitions for the TABLE variable here
	PH_SYSNO Varchar(10)
      ,PH_CODE Varchar(10)
      ,PK_POST Varchar(100)
      ,P_DESC Varchar(1000)
      ,PK_COVERS int
      ,PH_OWNER Varchar(7)
      ,PK_SEQ int
)
AS
BEGIN

	   Declare @PH_SYSNO Varchar(10)
       Declare @PH_CODE Varchar(10)
       Declare @PK_POST Varchar(100)
       Declare @P_DESC Varchar(1000)
       Declare @PK_COVERS int
       Declare @PH_OWNER Varchar(7)
       Declare @PK_SEQ int	
       Declare @OrderBy int
       Declare @AmndItems int
       
	   -- Fill the table variable with the rows for your result set
	if isnull(@PkHead,'') = '' begin  --it is not for a specific package
		if isnull(@PHOwner,'') = '' begin --it is not for a specific function 
			declare headcur cursor fast_forward for Select MNM_CODE, '', REPLACE(MNM_NAME, CHAR(39), CHAR(146)), MNM_Owner from MASTMENU where MNM_Owner is not null
		end
		else begin -- it is for a specific function
			declare headcur cursor fast_forward for Select MNM_CODE, '', REPLACE(MNM_NAME, CHAR(39), CHAR(146)), MNM_Owner from MASTMENU where MNM_Owner =@PHOwner
		end
	end
	else begin  -- it is for a specific package
		if isnull(@PHOwner,'') = '' begin --it is not for a specific function
			declare headcur cursor fast_forward for Select MNM_CODE, '', REPLACE(MNM_NAME, CHAR(39), CHAR(146)), MNM_Owner from MASTMENU where MNM_Owner is not null and MNM_CODE = @PKHead
		end
		else begin -- it is for a specific function
			declare headcur cursor fast_forward for Select MNM_CODE, '', REPLACE(MNM_NAME, CHAR(39), CHAR(146)), MNM_Owner from MASTMENU where MNM_Owner =@PHOwner and MNM_CODE = @PKHead
		end
	end

	SET @AmndItems = 0

	open headcur
	fetch next from headcur into @PH_SYSNO, @PH_Code, @P_Desc, @PH_Owner
	while @@FETCH_STATUS = 0 begin
		
		SET @AmndItems =(SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_ACTION IN('I', 'D', 'U') AND SUBSTRING(AEFA_PRIKEY, 1, NULLIF(PATINDEX ('%~%', AEFA_PRIKEY) - 1, -1)) = @PH_SYSNO)
		
		Insert into @Table_Var (PH_SYSNO,PH_CODE,PK_POST,P_DESC,PK_COVERS,PH_OWNER,PK_SEQ)
		VALUES (@PH_SYSNO,@PH_CODE,'', '[' + @P_Desc + ']', CASE @AmndItems WHEN 0 THEN 0 ELSE -1 END,@PH_OWNER,1)
		-- have inserted header row
		declare itemcur cursor fast_forward for Select MEN_ITEM_CODE, MEN_COVERS, MEN_POSITION, 1 As OrderBy from MADEMENU where MEN_MENU_CODE = @PH_SYSNO
		UNION SELECT AEFA_CODE, AEFA_COVERS, 0, 2 FROM AEF_Amendments WHERE AEFA_ACTION = 'U' AND SUBSTRING(AEFA_PRIKEY, 1, NULLIF(PATINDEX ('%~%', AEFA_PRIKEY) - 1, -1)) = @PH_SYSNO
		ORDER BY MEN_ITEM_CODE, OrderBy, MEN_POSITION
		open itemcur 
		fetch next from itemcur into @PK_Post, @PK_Covers, @PK_Seq, @OrderBy
		while @@Fetch_Status = 0 begin
			
			Insert into @Table_Var (PH_SYSNO,PH_CODE,PK_POST,P_DESC,PK_COVERS,PH_OWNER,PK_SEQ)
			VALUES (@PH_SYSNO,'',@PK_POST,dbo.uf_getMenuItemDescription(@PK_Post),@PK_Covers,@PH_OWNER, CASE @OrderBy WHEN 1 THEN @PK_Seq+1 ELSE -1 END)

			fetch next from itemcur into @PK_Post, @PK_Covers, @PK_Seq, @OrderBy
		end
		close itemcur
		deallocate itemcur
	
		if isnull(@PkHead,'') = '' AND (SELECT CONVERT(VARCHAR(1000), COALESCE(MNM_NOTES, '')) FROM MASTMENU WHERE MNM_CODE = @PH_SYSNO) <> '' begin 
		Insert into @Table_Var (PH_SYSNO,PH_CODE,PK_POST,P_DESC,PK_COVERS,PH_OWNER,PK_SEQ)
		VALUES (@PH_SYSNO, 'NOTES', 'NOTES', (SELECT CONVERT(VARCHAR(1000), COALESCE(MNM_NOTES, '')) FROM MASTMENU WHERE MNM_CODE = @PH_SYSNO), 0, @PH_Owner, -2)
		end

		fetch next from headcur into @PH_SYSNO, @PH_Code, @P_Desc, @PH_Owner
	end
	close headcur
	deallocate headcur
	RETURN 
END
GO

PRINT '*****************************************************************************'								   
PRINT 'utf_MenuView: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_MenuView]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_MenuView') AND [name] = 'Product')
BEGIN		
	PRINT 'utf_MenuView: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_MenuView: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_MenuView]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_MenuView') AND [name] = 'Module')
BEGIN		
	PRINT 'utf_MenuView: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_MenuView: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [utf_MenuView]
							   ,@name = N'Version' 
							   ,@value = N'3.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('utf_MenuView') AND [name] = 'Version')
BEGIN		
	PRINT 'utf_MenuView: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'utf_MenuView: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO