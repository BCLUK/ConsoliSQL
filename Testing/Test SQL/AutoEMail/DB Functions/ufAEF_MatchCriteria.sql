-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

DECLARE @FileName VARCHAR(100)
DECLARE @Func_Name VARCHAR(100)
SET @FileName = 'ufAEF_MatchCriteria'
SET @Func_Name = 'ufAEF_MatchCriteria'
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'ufAEF_MatchCriteria')
BEGIN
	DROP FUNCTION [dbo].ufAEF_MatchCriteria
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

-- ===========================================================================================
-- Author:		Peter Green
-- Create date: 23 12 2014
-- Description:	Checks whether entry in link table meets criteria to run
-- ===========================================================================================
-- Version: 12
-- Date: 13/03/2017
-- ===========================================================================================
-- Changes: 19/01/2015: MCB: Added better checking
-- Changes: 04/02/2015: MCB: Added @CreateDateDiff, @CreateDayCutOff handling
-- Changes: 09/02/2015: MCB: Amended @CreateDateDiff, @CreateDayCutOff handling
-- Changes: 11/02/2015: MCB: Converted @Enabled to handle String
-- Changes: 12/02/2015: MCB: Added handling for Booking Items
-- Changes: 16/02/2015: MCB: Changed Setting to use new Function to retrieve values.
-- Changes: 16/02/2015: MCB: Added External/Internal handling
-- Changes: 05/03/2015: MCB: Added DrinkTrolleyItem handling
-- Changes: 05/03/2015: MCB: Added PackageItem handling
-- Changes: 05/03/2015: MCB: Added MenuItem handling
-- Changes: 26/03/2015: MCB: Added NoChange handling
-- Changes: 30/06/2016: TT : Added Code to deal with Recurring Bookings
--							 (FREFS: FFFFFFF, FFFFFFE)
-- Changes: 28/07/2016: TT : Added Code to deal with autoemails from MBR
-- (8)
-- Changes: 16/11/2016: TT: Changed default value of @OnlySendBookerUpdate from 1 to 0
-- (9)						Added code to read config setting for OnlySendBookerUpdate
-- Changes: 24/11/2016: TT: Replaced Enabled check with new function call
--	(10)					Added code to check for Booking Source but it is possibly
--							not required so have commented it out
--			28/11/2016:	TT:	Added new function reference (FFFFFFD) for Summary Weekly 
--							Reminder Email
-- Changes: 16/02/2017: TT: Changed all of the return codes to enable better diagnostic
--  (11)    				investigations of the automail process. A description of the
--							meaning of the return code can be found in a new table called 
--							DiagnosticMessages. A return code which is -ve means that the  
--							criteria to send the autoemail is not mactched. A code that is
--							+ve  means that the criteria to send the autoemail is matched.
-- Changes: 13/03/2017: TT: Moved the code that checks whether or not the autoemail is  
--  (12)    				enabled to the top of the function - this ensures that recurring
--							autoemails are no checked to see if they are enabled where as 
--							previously they were not. 
-- ===========================================================================================
CREATE FUNCTION [dbo].[ufAEF_MatchCriteria] 
(
	-- Add the parameters for the function here
	@FREF varchar(7) = 'FFFFFFF',
	@emailtype varchar(6)
)
RETURNS int
AS
BEGIN	

	-- Declare the return variable here
	DECLARE @Result int					-- the final result 1 or 0

	-- Added - TT - 13/03/2017
	DECLARE @Enabled VARCHAR(1000)
	DECLARE @EnabledINT int

	SET @Enabled = (SELECT [dbo].[uf_Get_AEF_EnabledSwitch](@EmailType, ''))
	
	SET @EnabledINT = Cast(@Enabled as int)
	IF @enabledINT > 0
	BEGIN

		-- TT - 13/06/2016 - Added
		--IF (@FREF = 'FFFFFFE') OR (@FREF = 'FFFFFFF')
		-- Added new function reference (FFFFFFD) for Summary Weekly Reminder Email - TT - 28/11/2016
		IF (@FREF = 'FFFFFFF') OR (@FREF = 'FFFFFFE') OR (@FREF = 'FFFFFFD')
		BEGIN --Send for all updates		
			-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
			-- SET @Result = 1
			SET @Result = 1020
			RETURN @result
		END --Send for all updates		
		-- End of Changes - TT - 13/03/2017

		-- Added code to ensure email AEFACK can only be sent when booking is made anywhere except the Console - TT - 24/11/2016
		-- commented out as not needed - may delete if confirmed no longer required - TT - 24/11/2016
		--IF @emailtype = 'AEFACK'
		--BEGIN
		--	DECLARE @AppSource VARCHAR(1)
		--	SET @AppSource = (SELECT TOP 1 COALESCE(FS_SOURCE,'') FROM FUNC_SOURCE WHERE FS_REF = @FREF)
		--	IF @AppSource = 'C' 
		--	BEGIN
		--		SET @Result = 0
		--		RETURN @Result
		--	END
		--END
		-- End of changes - TT - 24/11/2016

		DECLARE @DelayedBooking int			-- whether it is a delayed booking (1) or not (0)
		DECLARE @room varchar(7),			-- CABS room code 
				@functionstatus varchar(7), -- Booking status (as SysAbbr)
				@roomgiven varchar(3),		-- Room given yet 'Yes' or 'No'
				@SessionNo Varchar(7),		-- Session number (empty string if not a session)
				@Source Varchar(20)			-- Sent as String ('CREATE', 'UPDATE' + ':' + qualifier)
											-- qualifier determined by circumstances e.g. 'ROOM' 'BOOKER' or 'EXTRA' if this is what has been updated
		DECLARE @IsASession int,			-- if a session = 1 else = 0
				@RoomChangedINT int,
				@ExtraChangedINT int,			
				@RoomGivenINT int,
				@BookerChangedINT int,
				@MenuChangedINT int,
				@PackageChangedINT int,
				@DrinkTrolleyChangedINT int,
				@Internal int, 
				@InternalINT int
			
		DECLARE
				-- @Enabled VARCHAR(1000), - Moved code higher up the function - TT - 13/03/2017
				@StatusCode VARCHAR(1000),
				@OnlySendRoomUpdate VARCHAR(1000),
				@OnlySendRoomGiven VARCHAR(1000),
				@OnlySendBookerUpdate VARCHAR(1000)

		DECLARE
				-- @EnabledINT int, - Moved code higher up the function - TT - 13/03/2017			
				@StatusCodeINT int,
				@OnlySendRoomUpdateINT int,
				@OnlySendRoomGivenINT int,
				@OnlySendBookerUpdateINT int
		DECLARE 
				@NewBooking INT,
				@AutoUpdate INT

		DECLARE
				@CreateDayCutOff INT,
				@CreateDateDiff INT,
				@WithinCutOff INT

		DECLARE
				@SendInternal VARCHAR(1000),		 			
				@SendInternalINT INT,
				@SendExternal VARCHAR(1000),		 			
				@SendExternalINT INT
	
		DECLARE
				@NoChange INT

		-- Added - TT - 28/07/2016			
		DECLARE @MBR_No VARCHAR(7)			
									
		-- Add the T-SQL statements to compute the return value here
		--====================================
		--  Set the defaults
		--====================================
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017
		-- SET @Result = 0
		SET @Result = -1020	
		SET @DelayedBooking = 0	

		--SET @Enabled = '0'
		--SET @StatusCode = ''
		--SET @OnlySendRoomUpdate = 0
		--SET @OnlySendRoomGiven = 0
		-- Changed default value of @OnlySendBookerUpdate from 1 to 0 - TT - 16/11/2015
		SET @OnlySendBookerUpdate = 0 -- Was 1

		--SET @CanRun = 0
		--SET @IncOtherSession = 0
		set @roomchangedINT = 0
		Set @BookerChangedINT = 0
		SET @ExtraChangedINT = 0
	
		SET @MenuChangedINT = 0
		SET @PackageChangedINT = 0
		SET @DrinkTrolleyChangedINT = 0
					
		SET @NewBooking = 0
		SET @AutoUpdate = 0
		SET @CreateDayCutOff = 2
		SET @CreateDateDiff = 0
		SET @WithinCutOff = 0
		SET @NoChange = 0
		-- =========================================
		-- Get Values
		-- =========================================
		SET @Room = (SELECT F_ROOM FROM Func_Fil where F_REF = @FREF)
		SET @FunctionStatus = (SELECT F_STATUS FROM Func_Fil where F_REF = @FREF)
		SET @RoomGiven = (SELECT F_RMGIVEN FROM Func_Fil where F_REF = @FREF) 
		SET @SessionNo = (SELECT F_SESSNO FROM Func_Fil where F_REF = @FREF)
		SET @IsASession = 0
		SET @Internal = (SELECT F_INTERN FROM FUNC_FIL WHERE F_REF = @FREF)
		--SET @Booker = (SELECT F_BOOKER FROM Func_Fil where F_REF = @FREF)

		SET @Source = (SELECT AEFL_Source from AEF_Link where AEFL_FREF = @FREF and AEFL_EmailType = @emailtype)

		-- Get MBR_NO - There should be only 1 record - Added - TT - 28/07/2016			
		SET @MBR_No = (SELECT COALESCE(AEFL_MBRNo, '') FROM AEF_Link where AEFL_FREF = @FREF and AEFL_EmailType = @emailtype)

		--MCB Added 110215
		-- Replaced Enabled check with new function call - TT - 24/11/2016
		--SET @Enabled = (SELECT [dbo].[fn_GetEnabledValue](COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'Enabled')), '0'), ''))
	
		-- SET @Enabled = (SELECT [dbo].[uf_Get_AEF_EnabledSwitch](@EmailType, '')) - Moved code higher up the function - TT - 13/03/2017
		-- End of Changes - TT - 24/11/2016

		--MCB Added 160215
		SET @StatusCode = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'StatusCode')), 'CONFRM')
		SET @OnlySendRoomUpdate = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'OnlySendRoomUpdate')), '0')		
		SET @OnlySendRoomGiven = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'OnlySendRoomGiven')), '0')		
		SET @CreateDayCutOff = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'CreateDayCutOff')), '2')		

		SET @SendInternal = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'SendInternal')), '1')		
		SET @SendExternal = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'SendExternal')), '1')
	
		-- Added code to read config setting - TT - 16/11/2016
		SET @OnlySendBookerUpdate = COALESCE((SELECT [dbo].[fnGet_Config_Value] ('S', '', @emailtype, 'OnlySendBookerUpdate')), '0')		

		IF @SendInternal = 1 BEGIN
			SET @SendInternalINT = 1
		END
		ELSE
		IF @SendInternal = 0 BEGIN
			SET @SendInternalINT = 9
		END

		IF @SendExternal = 1 BEGIN
			SET @SendExternalINT = 0
		END
		ELSE
		IF @SendExternal = 0 BEGIN
			SET @SendExternalINT = 9
		END

		-- Moved code higher up the function - TT - 13/03/2017			
		-- SET @EnabledINT = Cast(@Enabled as int)
		-- @enabledINT > 0 BEGIN		-- actually could probably put this higher up
		-- End of Changes - TT - 13/03/2017
		SET @OnlySendRoomUpdateINT = Cast(@OnlySendRoomUpdate as int)
		SET @OnlySendRoomGivenINT = Cast(@OnlySendRoomGiven as int)
		SET @OnlySendBookerUpdateINT = Cast(@OnlySendBookerUpdate as int)
		SET @CreateDateDiff = (SELECT [dbo].[uf_CreateDateDiff] (@FREF))
		--=========================
		-- Check if status is right.  If it set we must use it.  If it is not set it doesn't matter
		--=========================
		if isnull(@Statuscode,'') = '' begin
			set @StatusCodeINT = 1 
		end
		else if (patindex('%'+ @FunctionStatus +'%', @statuscode) >0)  begin
			SET @StatusCodeINT = 1  -- the function status is in the list on which we send the email
		end
		

		-- Set Status Code to 1 for records with an MBR_No set and Email Type - AEFECC - Added - TT - 28/07/2016
		IF @emailtype = 'AEFECC'
		BEGIN
			IF @MBR_No = ''
				SET @StatusCodeINT = 0
			ELSE
				SET @StatusCodeINT = 1
		END
			

		IF (@Internal = @SendInternalINT) OR (@Internal = @SendExternalINT) BEGIN
			SET @InternalINT = 1
		END	
		--=========================
		-- Check if is room update.  If it set we must use it.  If it is not set it doesn't matter
		--=========================
		if @StatusCodeINT = 1 and @InternalINT = 1 begin
			if (substring(@Source,1,6) = 'UPDATE') begin
				if (substring(@Source,8,6) = 'NOCHNG') begin
					set @NoChange = 1  -- no change
				end
				if (substring(@Source,8,4) = 'ROOM') begin
					set @RoomChangedINT = 1  -- room has changed
				end
				if (substring(@Source,8,6) = 'BOOKER') begin
					set @BookerChangedINT = 1  -- booker has changed
				end
				if (substring(@Source,8,5) = 'EXTRA') begin
					set @ExtraChangedINT = 1  -- Extra has changed										
				end

				if (substring(@Source,8,9) = 'NewExtras') begin
					set @ExtraChangedINT = 1  -- Extra has changed										
				end

				if (substring(@Source,8,4) = 'MENU') begin
					set @MenuChangedINT = 1  -- Menu has changed
				end

				if (substring(@Source,8,8) = 'MenuItem') begin
					set @MenuChangedINT = 1  -- Menu has changed
				end
				
				if (substring(@Source,8,7) = 'PACKAGE') begin
					set @PackageChangedINT = 1  -- Package has changed
				end

				if (substring(@Source,8,11) = 'PackageItem') begin
					set @PackageChangedINT = 1  -- Drink Trolley has changed
				end
				
				if (substring(@Source,8,12) = 'DrinkTrolley') begin
					set @DrinkTrolleyChangedINT = 1  -- Drink Trolley has changed
				end
				
				if (substring(@Source,8,16) = 'DrinkTrolleyItem') begin
					set @DrinkTrolleyChangedINT = 1  -- Drink Trolley has changed
				end

				if (substring(@Source,8,10) = 'NewBooking') begin
					set @NewBooking = 1  -- new booking 
				end
				if (substring(@Source,8,4) = 'MISC') begin
					set @AutoUpdate = 1  -- Update 
				end			
				if (substring(@Source,8,6) = 'STATUS') begin
					set @AutoUpdate = 1  -- Update 
					
					--IF @CreateDateDiff >= @CreateDayCutOff
					IF @CreateDateDiff <= @CreateDayCutOff
					BEGIN
						SET @WithinCutOff = 1
					END
				end	
			end
			else
			if (substring(@Source,1,6) = 'INSERT') begin
				if (substring(@Source,8,10) = 'NewBooking') begin
					set @NewBooking = 1  -- new booking 
				end	
				if (substring(@Source,8,6) = 'NOCHNG') begin
					set @NewBooking = 1  -- new booking 
				end					
			end

			IF (@NewBooking = 1 AND @AutoUpdate = 0 AND @NoChange = 0)
			BEGIN
				-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
				-- Set @Result = 1
				SET @Result = 1021				
				Return @result
			END
			ELSE
			IF (@NewBooking = 0 AND @AutoUpdate = 1 AND @WithinCutOff = 1 AND @NoChange = 1) --Swap Around?? Was 0 
			BEGIN
				-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
				-- Set @Result = 0
				Set @Result = -1023
				Return @result
			END
			--Commented Out: MCB: 12/02/15
			--ELSE
			--IF (@NewBooking = 0 AND @AutoUpdate = 1 AND @WithinCutOff = 0) --Swap Around?? Was 1
			--BEGIN
			--	Set @Result = 1
			--	Return @result
			--END
						
				--IF (@NewBooking = 0 AND @AutoUpdate = 1 AND @WithinCutOff = 0)
				--BEGIN
				--	Set @Result = 0
				--	Return @result
				--END
				--ELSE
				--IF (@NewBooking = 0 AND @AutoUpdate = 1 AND @WithinCutOff = 1)
				--BEGIN
				--	Set @Result = 1
				--	Return @result
				--END
			ELSE			
			IF (@OnlySendRoomUpdateINT = 1 AND @OnlySendRoomGivenINT = 1)
			BEGIN --Only send for Room Update and Room Given
				IF @RoomGiven = 'Yes'
				BEGIN --Room Given is Yes
					IF @RoomChangedINT = 1
					BEGIN  --Room has changed
						-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
						-- set @result = 1						
						SET @result = 1022						
					END  --Room has changed
					ELSE
					IF @RoomChangedInt = 0
					BEGIN  --Room has not changed
						IF @OnlySendBookerUpdate = 0
						BEGIN --Don't need to send booker Update
							-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
							SET @result = -1024						
							RETURN @result
						END
						ELSE
						IF @OnlySendBookerUpdate = 1
						BEGIN -- Send Booker Update
							IF @BookerChangedINT = 0
							BEGIN --Booker Hasn't Changed
								-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
								SET @result = -1025						
								RETURN @result
							END--Booker Hasn't Chaged
							ELSE
							BEGIN --Booker has changed
								-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
								-- Set @Result = 1
								Set @Result = 1023
								Return @result
							END
						END								
					END --Room has not changed					
				END --Room Given is Yes
				ELSE
				IF @RoomGiven = 'No'
				BEGIN --Room Given is No
					IF @OnlySendBookerUpdate = 0
					BEGIN --Don't need to send booker Update
						-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
						Set @Result = -1026
						RETURN @Result
					END
					ELSE
					IF @OnlySendBookerUpdate = 1
					BEGIN -- Send Booker Update
						IF @BookerChangedINT = 0	
						BEGIN --Booker Hasn't Changed
						-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
							Set @Result = -1027
							RETURN @result
						END
						ELSE
						IF @BookerChangedINT = 1
						BEGIN --Booker has changed
							-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
							-- Set @Result = 1
							Set @Result = 1024
							Return @result
						END
					END -- Send Booker Update
				END --Room Given is No
			END --Only send for Room Update and Room Given
			ELSE
			IF (@OnlySendRoomUpdateINT = 1 AND @OnlySendRoomGivenINT = 0)
			BEGIN --Only send for Room Update NOT Room Given
				IF @RoomChangedINT = 1
				BEGIN --Room has changed
					-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
					-- Set @Result = 1	
					Set @Result = 1025
					Return @Result						
				END	--Room has changed
				ELSE
				IF @RoomChangedINT = 1
				BEGIn--Room has not changed
					IF @OnlySendBookerUpdateINT = 0
					BEGIN --Don't need to send booker Update
						-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017								
						Set @Result = -1028
						RETURN @result
					END
					ELSE
					IF @OnlySendBookerUpdateINT = 1
					BEGIN -- Send Booker Update
						IF @BookerChangedINT = 0
						BEGIN --Booker Hasn't Changed
							-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017								
							Set @Result = -1029
							RETURN @result
						END --Booker Hasn't Changed
						ELSE
						IF @BookerChangedINT = 1
						BEGIN --Booker has changed
							-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017								
							-- Set @Result = 1									
							Set @Result = 1026
							RETURN @result
						END --Booker has changed
					END -- Send Booker Update
				END --Room has not changed									
			END --Only send for Room Update NOT Room Given
			ELSE
			IF (@OnlySendRoomUpdateINT = 0 AND (@OnlySendRoomGivenINT = 0 OR @OnlySendRoomGivenINT = 1) AND (@OnlySendBookerUpdateINT = 0 OR @OnlySendBookerUpdateINT = 1)
				OR @ExtraChangedINT = 1 OR @MenuChangedINT = 1 OR @PackageChangedINT = 1 OR @DrinkTrolleyChangedINT = 1) 
			BEGIN --Send for all updates	
				-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017									
				-- SET @Result = 1
				SET @Result = 1027
				RETURN @result
			END --Send for all updates
		END --Correct Status Code
		-- Added ELSE block to enable better diagnostic information - TT - 16/02/2017
		ELSE
		BEGIN
			-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017			
			SET @Result = -1022
		END --Incorrect Status Code
	END -- Enabled
	-- Added ELSE block to enable better diagnostic information - TT - 16/02/2017
	ELSE
	BEGIN
		-- Changed return value to enable better diagnostic investigations of autoemail process - TT - 16/02/2017		
		SET @Result = -1021
	END -- Not Enabled

		-- Return the result of the function
	RETURN @Result

END
GO

PRINT '*****************************************************************************'								   
PRINT 'ufAEF_MatchCriteria: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [ufAEF_MatchCriteria]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ufAEF_MatchCriteria') AND [name] = 'Product')
BEGIN		
	PRINT 'ufAEF_MatchCriteria: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ufAEF_MatchCriteria: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [ufAEF_MatchCriteria]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ufAEF_MatchCriteria') AND [name] = 'Module')
BEGIN		
	PRINT 'ufAEF_MatchCriteria: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ufAEF_MatchCriteria: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'FUNCTION' 
							   ,@level1name = [ufAEF_MatchCriteria]
							   ,@name = N'Version' 
							   ,@value = N'12.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('ufAEF_MatchCriteria') AND [name] = 'Version')
BEGIN		
	PRINT 'ufAEF_MatchCriteria: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'ufAEF_MatchCriteria: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO

