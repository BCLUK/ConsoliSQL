-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_IsSendableSessBooking'
SET @Func_Name = 'uf_IsSendableSessBooking'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uf_IsSendableSessBooking]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
	DROP FUNCTION [dbo].[uf_IsSendableSessBooking]
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
-- =========================================================================================
-- Author:		Peter Green
-- Create date: 07/01/2015
-- Description:	checks whether this is the top unsent record for  a session
-- =========================================================================================
-- Version: 4
-- Date: 20/02/2017
-- =========================================================================================
-- Changes: 07/01/2015: PG: Original
--	(1)
-- Changes: 18/01/2017: TT: This function is has a circular refeerence with 
--	(2)						vw_AEFLINK which creates difficulties when running 
--							Autoemail installation and modify scripts. In query
--							replaced vw_AEFLINK with AEF_LINK
-- Changes: 07/02/2017: TT: Added a check of switch IgnoreSessionStatus set to 1
--	(3)						in the email template section of x cabs config. If it
--							is then the function returns 1 resulting in 
--							potentially each function being checked idiviaually
--							is sendable.
-- Changes: 20/02/2016: TT: Changed all of the return codes to enable better diagnostic
--  (4)						investigations of the automail process. A description of the
--							meaning of the return code can be found in a new table called 
--							DiagnosticMessages. A return code which is 0 means that an 
--							autoemail is not session sendable. A code that is +ve is 
--							session sendable
-- =========================================================================================
CREATE FUNCTION [dbo].[uf_IsSendableSessBooking] 
(
	-- Add the parameters for the function here
	@sessno varchar(7),
	@Fref varchar(7),
	@emailtype varchar(6),
	@Source varchar(20)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	Declare @Sendable int
	DECLARE @Result int
	Declare @SendableRef Varchar(7)

	-- Added Code to read new config setting - TT - 07/02/2017
	DECLARE @IgnoreSessionStatus VARCHAR(10) 
	SET @IgnoreSessionStatus = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'IgnoreSessionStatus')), '0')
	-- End of Changes - TT - 07/02/2017

	Set @Sendable = 0

	-- Adde new @IgnoreSessionStatus criteria to if statement - TT - 07/02/2017
	-- if isnull(@sessno,'') = '' begin
	if (isnull(@sessno,'') = '') -- Code moved OR (@IgnoreSessionStatus = '1') - TT - 20/02/2017
	begin
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 20/02/2017
		-- Set @sendable = 1
		Set @sendable = 1040		
	end
	-- Moved @IgnoreSessionStatus clause to enable discrete return code
	else if (@IgnoreSessionStatus = '1') 
	begin
		Set @sendable = 1041		
	end
	else begin
		--added sent flag
		-- Changed query to reference table aef_link instead of vw_AEFLINK - TT - 18/01/2017
		SET @SendableRef = (Select Top 1 AEFL_FREF from AEF_Link where AEFL_Sessno = @SessNo and AEFL_emailtype = @emailtype
		AND AEFL_Sent = 0
		--and AEFL_Source = @Source
		Order by AEFL_Fref)
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 20/02/2017
		if @Sendableref = @Fref 
		begin
			set @sendable = 1042
		end
	end

	SELECT @Result = @Sendable

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_IsSendableSessBooking: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsSendableSessBooking]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsSendableSessBooking') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_IsSendableSessBooking: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsSendableSessBooking: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsSendableSessBooking]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsSendableSessBooking') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_IsSendableSessBooking: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsSendableSessBooking: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_IsSendableSessBooking]
							   ,@name = N'Version' 
							   ,@value = N'4.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_IsSendableSessBooking') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_IsSendableSessBooking: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_IsSendableSessBooking: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO