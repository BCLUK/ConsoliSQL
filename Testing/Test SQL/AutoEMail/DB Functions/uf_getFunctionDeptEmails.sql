-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_getFunctionDeptEmails'
SET @Func_Name = 'uf_getFunctionDeptEmails'
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[uf_getFunctionDeptEmails]') and xtype in (N'FN', N'IF', N'TF'))
BEGIN
	DROP FUNCTION [dbo].[uf_getFunctionDeptEmails]
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
-- Create date: 6th Feb 2015
-- Description:	gets a string of email recipients for each department affected by a function
-- =============================================
-- Version: 3
-- Date: 18/02/2015
-- =============================================
-- Changes: 13/02/2015: MCB: Added Include and Exclude strings
-- Changes: 18/02/2015: MCB: Passed Department String to check againstInclude and Exclude strings
-- =============================================
CREATE FUNCTION [dbo].[uf_getFunctionDeptEmails] 
(
	-- Add the parameters for the function here
	@FREF Varchar(10),
	@CCString VARCHAR(1000),
	@IncludeString VARCHAR(1000),
	@ExcludeString VARCHAR(1000)
)
RETURNS varchar(4000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(4000)
	DECLARE @COstCent Varchar(10)
	DECLARE @Email Varchar(4000)
	DECLARE @Exists Smallint
	DECLARE @CCAct Smallint
	DECLARE @CCInclude Smallint
	DECLARE @CCExclude Smallint
	
	-- Add the T-SQL statements to compute the return value here
	sET @Result = ';'
	IF Substring(@FREF,1,1) = 'S' begin
		declare SessionCursor Cursor Fast_Forward FOR Select P_COstCENT from vw_SessionCostCentres where f_SessNo = @FREF
		Open SessionCursor
		Fetch Next From SessionCursor into @CostCent
		While @@Fetch_Status = 0 begin

			IF COALESCE(@CCString, '') <> '' BEGIN
				SET @CCAct = PATINDEX('%' + @CostCent + '%', @CCString) 
			END
			ELSE	
				SET @CCAct = 1

			IF @CCAct >=1 BEGIN				
				IF COALESCE(@IncludeString, '') <> '' BEGIN
					SET @CCInclude = PATINDEX('%' + @CostCent + '%', @IncludeString)
				END
				ELSE
					SET @CCInclude = 1

				IF COALESCE(@ExcludeString, '') <> '' BEGIN
					SET @CCExclude = PATINDEX('%' + @CostCent + '%', @ExcludeString)
				END
				ELSE
					SET @CCExclude = 0

				IF @CCInclude >= 1 AND @CCExclude = 0 BEGIN
					set @email = (SELECT dbo.uf_getDepteMail(@CostCent))
					set @exists = ISNULL(patindex('%'+@email+'%',@rESULT),0)
					IF @EXISTS = 0 BEGIN
						set @Result = @Result + '; ' + @Email
						if SUBSTRING(@Result,1,1) = ';' set @Result = SUBSTRING(@Result,2,Len(@Result)-1)
					end
				END
			END	
				
			Fetch Next From SessionCursor into @CostCent
		end
		Close SessionCursor
		Deallocate SessionCursor
	end
	else IF Substring(@FREF,1,1) = 'F' begin
		declare SessionCursor Cursor Fast_Forward FOR Select P_COstCENT from vw_FunctionCostCentres where AI_FREF = @FREF
		Open SessionCursor
		Fetch Next From SessionCursor into @CostCent
		While @@Fetch_Status = 0 begin

			IF COALESCE(@CCString, '') <> '' BEGIN
				SET @CCAct = PATINDEX('%' + @CostCent + '%', @CCString) 
			END
			ELSE	
				SET @CCAct = 1

			IF @CCAct >=1 BEGIN
				IF COALESCE(@IncludeString, '') <> '' BEGIN
					SET @CCInclude = PATINDEX('%' + @CostCent + '%', @IncludeString)
				END
				ELSE
					SET @CCInclude = 1

				IF COALESCE(@ExcludeString, '') <> '' BEGIN
					SET @CCExclude = PATINDEX('%' + @CostCent + '%', @ExcludeString)
				END
				ELSE
					SET @CCExclude = 0
							
				IF @CCInclude >= 1 AND @CCExclude = 0 BEGIN
					set @email = ISNULL((SELECT dbo.uf_getDepteMail(@CostCent)), '')
					set @exists = patindex('%'+@email+'%',ISNULL(@rESULT, ''))
					IF @EXISTS = 0 BEGIN
						set @Result = COALESCE(@Result, '') + '; ' + COALESCE(@Email, '')
						if SUBSTRING(@Result,1,1) = ';' set @Result = SUBSTRING(@Result,2,Len(@Result)-1)
					end	
				END
			END		
			
			Fetch Next From SessionCursor into @CostCent
		end
		Close SessionCursor
		Deallocate SessionCursor
	end
	--SELECT @Result = @FREF

	-- Return the result of the function
	if SUBSTRING(@Result,1,1) = ';' set @Result = SUBSTRING(@Result,2,Len(@Result)-1)
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_getFunctionDeptEmails: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getFunctionDeptEmails]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getFunctionDeptEmails') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_getFunctionDeptEmails: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getFunctionDeptEmails: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getFunctionDeptEmails]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getFunctionDeptEmails') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_getFunctionDeptEmails: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getFunctionDeptEmails: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_getFunctionDeptEmails]
							   ,@name = N'Version' 
							   ,@value = N'3.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_getFunctionDeptEmails') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_getFunctionDeptEmails: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_getFunctionDeptEmails: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO