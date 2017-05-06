-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'uf_AEF_Link_Sendable'
SET @Func_Name = 'uf_AEF_Link_Sendable'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'uf_AEF_Link_Sendable')
BEGIN
	DROP FUNCTION [dbo].[uf_AEF_Link_Sendable]
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

-- ============================================================================================
-- Author:		Peter Green
-- Create date: 22 Dec 2014
-- Description:	Decides whether a row in the AEF Link table is in a sendable state
-- ============================================================================================
-- Version: 6
-- Date: 16/02/2017
-- ============================================================================================
-- Changes: 22/12/2014: PLG: Original
-- Changes:	16/06/2016: TT:  Added functionality for recurring emails	
-- Changes:	28/07/2016: TT:  Added functionality for autoemails from MBR changes
-- Changes:	02/08/2016: TT:  Added functionality for autoemails from MBR changes
-- Changes: 12/09/2016: TT:  Added call to function [uf_AEF_Is_Within_Send_Window]
-- Changes: 01/11/2016: TT:	 Added functionality to only allow emails to be sent 
--	(4)						 when outside the WIP window i.e. a configured amount
--							 of time has passed without further changes
--			02/11/2016: TT:  Added fixes to SendWindow Functionality
-- Changes: 15/11/2015: TT:	 Added condition to not check if date is in past for 
--  (5)						 emailtypes of AE After Event)
-- Changes: 16/02/2016: TT:	 Changed all of the return codes to enable better diagnostic
--  (6)						 investigations of the automail process. A description of the
--							 meaning of the return code can be found in a new table called 
--							 DiagnosticMessages. A return code which is -ve means that an 
--							 autoemail is not sendable. A code that is +ve is sendable
-- ============================================================================================
CREATE FUNCTION [dbo].[uf_AEF_Link_Sendable] 
(
	-- Add the parameters for the function here
	@FREF Varchar(7),
	@emailType Varchar(6) = 'AEFDEF'
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result int
	Declare @functiondate DateTime
	Declare @Datediff int
	Declare @SendableState int
	Declare @SentStatus INT
	Declare @SendTime Datetime
	Declare @Frequency VARCHAR(100)
	DECLARE @MinsB4 INT

	-- Add the T-SQL statements to compute the return value here
	-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
	-- Set @SendableState = 0
	Set @SendableState = -1001

	-- Added code to only allow emails to be sent when outside the WIP window i.e. a 
	-- configured amount of time has passed without further changes
	-- TT - 01/11/2016
	DECLARE @WIPWindow AS INT
	DECLARE @LastUpdate AS DATETIME
	
	-- Read the config setting from X CABS Config
	SET @WIPWindow = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', 'CABS_AUTO_EMAIL_FUNCS', 'WIPWindow')), '0')
	
	-- If for some reason the setting is < 0 set it to 0
	IF @WIPWindow < 0 SET @WIPWindow = 0
	
	-- Get the date and time of the last record update
	SELECT @LastUpdate = AEFL_LastUpdate FROM AEF_LINK WHERE AEFL_FREF = @FREF and AEFL_EMailType = @emailType
	SET @LastUpdate = COALESCE(@LastUpdate, '2000-JAN-01')

	-- If the last record change is still within the Work In Progress Window 
	-- i.e. have not waited enough time since last record update - do not send email
	IF DATEDIFF(MINUTE, GETDATE(), DATEADD(MINUTE, @WIPWindow,  @LastUpdate)) > 0
	BEGIN
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
		-- Set @SendableState = 0
		Set @SendableState = -1002
		RETURN @SendableState
	END
	-- End of Additions - TT - 01/11/2016

	-- Added specific functionality for MBR Related AutoEmails
	-- Will only send if the evnt is current - TT - 02/08/2016
	IF @emailType = 'AEFECC'
	BEGIN
		DECLARE @EVENT_END_DATE AS DATETIME
		SET @EVENT_END_DATE = (SELECT MBR_TO FROM MBRFILE INNER JOIN FUNC_FIL ON F_MBR_NO = MBR_SYSNO WHERE F_REF = @FREF)
		IF DATEDIFF(MINUTE, GETDATE(), @EVENT_END_DATE) > 0
			-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
			-- Set @SendableState = 1
			SET @SendableState = 1001
		ELSE 
			-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
			-- Set @SendableState = 0
			SET @SendableState = -1003
		
		RETURN @SendableState
	END

	Set @SentStatus = isnull((SELECT AEFL_Sent from AEF_Link where AEFL_FREF = @FREF and AEFL_EMailType = @emailType),0)
	If @SentStatus = 0 set @SendableState = 1	-- IT HAS NOT BEEN SENT
	If @SendableState = 1 Begin
		Set @SendableState = isnull((SELECT AEFL_CanSend from AEF_Link where AEFL_FREF = @FREF and AEFL_EMailType = @emailType),0)

		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
		-- Set @SendableState = 1
		Set @SendableState = 1002
		If @SendableState = 1002 Begin  -- IT IS SENDABLE

			-- Section added to implement sending emails during a send window - TT - 12/09/2016
			Declare @Within_Window int
			SET @Within_Window = (SELECT [dbo].[uf_AEF_Is_Within_Send_Window](@FREF, @emailType))
			IF (@Within_Window = 1)
			BEGIN

				Set @SendTime = isnull((SELECT AEFL_SendTime from AEF_Link where AEFL_FREF = @FREF and AEFL_EMailType = @emailType),'20100101')
				set @Datediff = DATEDIFF(MINUTE,@SendTime,getdate())  -- Send time is only filled from a trigger
				if @Datediff >= 0 begin  -- the send time is in the past so we can send it
					if @SendTime = '20100101' begin
					-- only interested in this if it did not come from a trigger
						Set @Frequency = 'D:2;H:0;M:0' -- default
						IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @emailType AND [KEY] = 'Frequency') > 0
							BEGIN
								SET @Frequency = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @emailType AND [KEY] = 'Frequency')
							END
						SET @MinsB4 = (SELECT [dbo].[fn_GetMinsValue]( @Frequency) ) --using previous sproc
						-- now find the function date
						Set @functiondate = isnull((SELECT AEFL_FDAY from AEF_Link where AEFL_FREF = @FREF and AEFL_EMailType = @emailType),'20991231')
						Set @Datediff = DATEDIFF(minute,getdate(),@functiondate)  -- How long until function start
						-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
						-- Set @SendableState = 0
						if @Datediff >=@MinsB4 Set @SendableState = -1004
					end
				end
				else begin
					-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
					-- Set @SendableState = 0
					Set @SendableState = -1005
				end
			-- Added to reset return value if @WithinWindow is not 1 - TT - 02/11/2016
			END
			ELSE
			BEGIN
				-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
				-- Set @SendableState = 0
				Set @SendableState = -1006			
			-- End of changes - TT - 02/11/2016
			END -- End of Send Window Code - TT - 12/09/2016			
		End
	End
	-- Changed TT 16/06/2016
	-- Added extra condition for MBR Autoemail - TT - 28/07/2016
	--if @SendableState = 1 AND dbo.uf_GetEmailSendType(@emailType) <> 'RE' begin
	-- Added condition to not check if date is in past for emailtypes of AE After Event) - TT - 15/11/2016
	-- Changed return value to enable better diagnostic investigations of autoemail process @SendableState = 1 now 1002 - TT - 16/02/2017
	if @SendableState = 1002 AND dbo.uf_GetEmailSendType(@emailType) <> 'RE' 
							 AND dbo.uf_GetEmailSendType(@emailType) <> 'AE' AND @emailType <> 'AEFECC' 
	begin
		
		Set @functiondate = isnull((SELECT AEFL_FDAY from AEF_Link where AEFL_FREF = @FREF and AEFL_EMailType = @emailType),'20991231')
		
		Set @Datediff = DATEDIFF(minute,getdate(),@functiondate)  -- How long until function start
		
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
		-- Set @SendableState = 0
		if @datediff < 0 set 
			@SendableState = -1007
	end

	SET @Result = @SendableState

	-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'uf_AEF_Link_Sendable: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Link_Sendable]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Link_Sendable') AND [name] = 'Product')
BEGIN		
	PRINT 'uf_AEF_Link_Sendable: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Link_Sendable: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Link_Sendable]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Link_Sendable') AND [name] = 'Module')
BEGIN		
	PRINT 'uf_AEF_Link_Sendable: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Link_Sendable: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [uf_AEF_Link_Sendable]
							   ,@name = N'Version' 
							   ,@value = N'6.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('uf_AEF_Link_Sendable') AND [name] = 'Version')
BEGIN		
	PRINT 'uf_AEF_Link_Sendable: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'uf_AEF_Link_Sendable: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO