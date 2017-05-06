
-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_CopyMBRClassCodes]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_CopyMBRClassCodes]	
	PRINT 'usp_CopyMBRClassCodes: Dropped Procedure usp_CopyMBRClassCodes'
END
ELSE
BEGIN	
	PRINT 'usp_CopyMBRClassCodes: usp_CopyMBRClassCodes -  Does Not Already Exist !'
END

PRINT 'usp_CopyMBRClassCodes: Creating Procedure usp_CopyMBRClassCodes'
GO

-- ====================================================================================================================
-- Author:		peter green				
-- Create Date:	21/03/2017
-- Description:	Copies classification codes from one MBR to Anotherr
-- Product:		CABS
-- Module:		MBRCopier
-- Parameters:	OldMBR, NewMBR
-- Returns:		int
-- Switches:	Insert CABS Switches Used
-- Test:		Insert How to Test
-- Called By:	CABS_Copy_MBR
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		21/03/2017
-- ====================================================================================================================
-- Changes (1.0): plg: 21/03/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_CopyMBRClassCodes 
	-- Add the parameters for the stored procedure here
	@OldMBR Varchar(10),
	@NewMBR Varchar(10)
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	Declare @ClassTable Varchar(20)
	Declare @SQL Varchar(max)
	Declare @SQL1 NVarchar(max)
	Declare @Counter2 int
	Declare @Params NVArchar(2000)
	-- Insert statements for procedure here

	Declare ClassTableCur Cursor fast_forward for Select name from sys.tables where name like 'AC[0-9][0-9]'
	open ClassTableCur
	Fetch next from ClassTableCur into @ClassTable
	while @@FETCH_STATUS = 0 begin
		set @SQL1 = N'SELECT @Counter1 = Count(AC_CODE) from ' + @ClassTable + '  Where AC_OWner = ' + Char(39) + @NewMBR  +Char(39) +'   '
		set @Params = N'@Counter1 int OUTPUT' 
		-- Print @SQL1
 		EXEC sp_Executesql @SQL1, @params, @Counter1 = @Counter2 OUTPUT
--		Print @Counter2 
--		Print @ClassTAble 
		if @Counter2 = 0 begin
			Set @SQL = 'INSERT INTO '  + @ClassTable + '   SELECT ' + Char(39)+ @NewMBR + Char(39)+ '  AS AC_OWNER, b.AC_CODE, b.AC_COND '+ ' From ' + @ClassTable + '  b where AC_OWNER = ' +  Char(39)+ @OldMBR + Char(39)
			--print @SQL
			EXEC(@SQL)
		end

	--	EXEC('SELECT ' + @NewMBR +', AC_CODE, AC_COND INTO ' + @ClassTable + ' From ' + @ClassTable + ' where AC_OWNER = ' +@OldMBR)
		Fetch next from ClassTableCur into @ClassTable
	end
	Close ClassTableCur	
	Deallocate ClassTableCur
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_CopyMBRClassCodes]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_CopyMBRClassCodes: usp_CopyMBRClassCodes Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CopyMBRClassCodes: usp_CopyMBRClassCodes Not Created Successfully !'	
END

PRINT '*****************************************************************************'

-- Set Extended Properties - Added - TT - 14/03/2017

PRINT 'usp_CopyMBRClassCodes: Creating Extended Properties'


EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CopyMBRClassCodes]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CopyMBRClassCodes') AND [name] = 'Product')
BEGIN		
	PRINT 'usp_CopyMBRClassCodes: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CopyMBRClassCodes: Product Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CopyMBRClassCodes]
							   ,@name = N'Module' 
							   ,@value = N'MBRCopier'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CopyMBRClassCodes') AND [name] = 'Module')
BEGIN		
	PRINT 'usp_CopyMBRClassCodes: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CopyMBRClassCodes: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'PROCEDURE' 
							   ,@level1name = [usp_CopyMBRClassCodes]
							   ,@name = N'Version' 
							   ,@value = N'1.0'
							   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('usp_CopyMBRClassCodes') AND [name] = 'Version')
BEGIN		
	PRINT 'usp_CopyMBRClassCodes: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_CopyMBRClassCodes: Version Extended Propety Not Created Successfully !'
END
	
PRINT '*****************************************************************************'								   
	
GO
-- End of Changes - TT - 14/03/2017