-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_AEF_Is_Within_Send_Window'
SET @Func_Name = 'uf_AEF_Is_Within_Send_Window'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_AEF_Is_Within_Send_Window')
BEGIN
	DROP FUNCTION [dbo].[uf_AEF_Is_Within_Send_Window]
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

-- ================================================================================
-- Author:		Tony Tasker
-- Create date: 12/09/2016
-- Description:	This function will determine what the autoemail send window is 
--				based on X CABS Config settings.
--				If the start of an event falls within the send window then the
--				function will return 1. If it does not the function returns 0.
--				The default value is 1 - which means that missing or incorrect
--				config settings will not stop emails from being sent.
--
--				The function takes two parameters - the function reference and
--				the email type as defined in Descriptions and Codes (AET section)
-- ================================================================================
-- Version: 2
-- Date: 03/11/2016
-- ==============================================================================
-- Changes: 12/09/2016: TT: Original
-- Changes: 03/11/2016: TT: Changes required to fix autoemail send window implementation
-- (2)
-- ==============================================================================
CREATE FUNCTION [dbo].[uf_AEF_Is_Within_Send_Window] 
(
	-- Add the parameters for the function here
	@FREF Varchar(7),
	@emailType Varchar(6) = 'AEFDEF'	
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result Int
	DECLARE @Is_Within_Send_Window Int

	DECLARE @StartWindow DateTime
	DECLARE @EndWindow DateTime
	DECLARE @WindowDuration Int

	DECLARE @FDAY DateTime
	
	-- Will set the default return value to 1 so that if not imnplemeneted emails are still sent	
	SET @Is_Within_Send_Window = 1

	-- Get the relevant config setting from X_CABS_CONFIG (System Defaults)
	-- String not converted to datetime intrinsically - added convert - TT - 02/11/2016
	--SET @StartWindow = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'STARTWINDOW')), '2000-01-01')  
	SET @StartWindow = CONVERT(datetime, COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'STARTWINDOW')), '2000-01-01'), 103) 			
	
	-- Changed WNDOWDURATION to WINDOWDURATION - TT - 02/11/2016
	SET @WindowDuration = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailType, 'WINDOWDURATION')), '0')  

	-- Ensure Config settings are present i.e. they are not set to their default values
	IF (@StartWindow <> '2000-01-01') AND (@WindowDuration > 0)
	BEGIN
		-- Determine the end of the Send Window
		SET @EndWindow = DATEADD(day, @WindowDuration, @StartWindow)

		-- Get the start day of the function
		-- Get the Function Day from AEF_LINK instead of FUNC_FIL - TT - 03/11/2016
		-- SET @FDAY = (SELECT F_DAY FROM FUNC_FIL WHERE F_REF =  @FREF)
		SET @FDAY = (SELECT AEFL_FDAY FROM AEF_LINK WHERE AEFL_FREF =  @FREF AND AEFL_EMailType = @emailType)

		-- Autoemails should only be sent if the function start date lies
		-- within the send window
		
		-- Added oouter brackets to correct logic - TT - 02/11/2016
		--IF NOT (@FDAY >= @StartWindow) AND (@FDAY <= @EndWindow)
		IF NOT ((@FDAY >= @StartWindow) AND (@FDAY <= @EndWindow))
			SET @Is_Within_Send_Window = 0		
	END
	
	-- Set the return value
	SET @Result = @Is_Within_Send_Window

	-- Return function value
	RETURN @Result

END

GO

PRINT '*****************************************************************************'								   
PRINT 'uf_AEF_Is_Within_Send_Window: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Is_Within_Send_Window]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Is_Within_Send_Window') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_AEF_Is_Within_Send_Window: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Is_Within_Send_Window: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Is_Within_Send_Window]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Is_Within_Send_Window') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_AEF_Is_Within_Send_Window: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Is_Within_Send_Window: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Is_Within_Send_Window]
							   ,@name = N'Version' 
							   ,@value = N'2.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Is_Within_Send_Window') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_AEF_Is_Within_Send_Window: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Is_Within_Send_Window: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO