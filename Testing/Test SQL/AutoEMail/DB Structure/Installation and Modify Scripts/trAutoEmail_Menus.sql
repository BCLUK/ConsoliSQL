-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

if exists (select * from sys.objects where object_id = object_id(N'[trAutoEmail_Menus]') and OBJECTPROPERTY(object_id, N'IsTrigger') = 1)
BEGIN
	DROP TRIGGER [trAutoEmail_Menus]
	PRINT 'trAutoEmail_Menus: Dropped Trigger trAutoEmail_Menus on MASTMENU'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Menus: Trigger trAutoEmail_Menus on MASTMENU Does Not Exist !'
END
PRINT 'trAutoEmail_Menus: Creating Trigger trAutoEmail_Menus on MASTMENU'
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Mark Birch
-- Create date: 23-DEC-2014
-- Description:	Trigger to handle Auto Email Requests for Bookings
-- =============================================
-- Version: 5
-- Date: 13/03/2015
-- =============================================
-- Changes: 13/02/2015: MCB: Added Department handling
-- Changes: 05/03/2015: MCB: Changed @DeptDecideCode to VARCHAR(10) 
-- Changes: 05/03/2015: MCB: Amended Department handling
-- Changes: 11/03/2015: MCB: Added IsNull around SELECT TOP 1 Status 
-- Changes: 13/03/2015: MCB: Changed @Source VARCHAR(20); @Department VARCHAR(MAX)
-- =============================================
CREATE TRIGGER [dbo].[trAutoEmail_Menus] 
   ON  [dbo].[MASTMENU] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
-- =============================================
-- LOCAL DECLARATIONS 
-- =============================================
	DECLARE
		@Enabled INT,
		@SettingsType VARCHAR(1000),
		@Section VARCHAR(1000),
		@InsertCount INT, 
		@DeleteCount INT,
		@ThisIsAnInsert INT,
		@ThisIsAnUpdate INT,
		@ThisIsADelete INT
-- =============================================
-- LOCAL DEFAULT SETTINGS
-- =============================================
	SET @Enabled = 0
	SET @SettingsType = 'S' 
	SET @Section = 'CABS_AUTO_EMAIL_FUNCS_Trigger'
	SET @ThisIsAnInsert = 0
	SET @ThisIsAnUpdate = 0
	SET @ThisIsADelete = 0
-- =============================================
-- DECLARATIONS 
-- =============================================
	DECLARE 
		@BookingNumber VARCHAR(7),
		@BookingDateTime DATETIME,
		@EmailType VARCHAR(6),
		@Frequency VARCHAR(1000),
		@SendFrequency VARCHAR(1000),
		@SendMinutes INT,
		@SendDateTime DATETIME,
		@SessionNumber VARCHAR(7),
		@Action VARCHAR(1)
		
	DECLARE	
		@Source VARCHAR(50),
		@SentStatus bit,		-- added plg 19th Jan 2015	
		@SectionBooking INT,
		@OLDCovers INT,
		@NEWCovers INT,
		@OLDDate DATETIME,
		@NEWDate DATETIME,
		@CanSend INT,
		@DeptDecideCode VARCHAR(10),
		@LocDecideCode VARCHAR(6),		
		@Department VARCHAR(MAX)	
-- =============================================
-- GET SETTINGS 
-- =============================================
	SET @Enabled = COALESCE((SELECT [dbo].[fnGet_Config_Value] (@SettingsType, '', @Section, 'Enabled')), '0')
-- =============================================
-- THE WORK
-- =============================================
	IF @Enabled = 0 BEGIN
		RETURN
	END
	ELSE
	IF @Enabled = 1 BEGIN--Enabled
		SET @InsertCount = (SELECT COUNT(*) FROM INSERTED)
		SET @DeleteCount = (SELECT COUNT(*) FROM DELETED) 
		
		IF (@InsertCount > 0 and @DeleteCount > 0) BEGIN --Update Check
			SET @Action = 'U'
			SET @Source = 'Update'
			SET @CanSend = 1
		END --Update Check
		
		IF (@InsertCount > 0 and @DeleteCount = 0) BEGIN
			SET @Action = 'U'
			SET @Source = 'Insert'
			SET @CanSend = 1
		END
		
		IF (@InsertCount = 0 and @DeleteCount > 0) BEGIN
			SET @Action = 'D'
			SET @Source = 'Delete'
			SET @CanSend = 0
		END

		IF @InsertCount = 1  BEGIN
			SET @BookingNumber = (SELECT MNM_OWNER FROM INSERTED)
			SET @BookingDateTime = (SELECT F_STARTDATETIME FROM INSERTED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
			SET @SessionNumber = (SELECT COALESCE(F_SESSNO, '') FROM INSERTED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
			--SET @DeptDecideCode = (SELECT AI_CODE FROM INSERTED)
			--SET @LocDecideCode = (SELECT COALESCE(RM_LOC, '') FROM INSERTED INNER JOIN FUNC_FIL ON AI_FREF = F_REF INNER JOIN ROOMS ON F_ROOM = RM_ABBR)
			SET @Department = (SELECT MNM_OPGROUP FROM INSERTED) --(SELECT [dbo].[uf_getDeptCodes] (@DeptDecideCode, @LocDecideCode))				
		END
		ELSE
		IF @InsertCount = 0 BEGIN
			SET @BookingNumber = (SELECT MNM_OWNER FROM DELETED)
			SET @BookingDateTime = (SELECT F_STARTDATETIME FROM DELETED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
			SET @SessionNumber = (SELECT COALESCE(F_SESSNO, '') FROM DELETED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
		END
		-- =============================================
		-- INSERT RECORDS
		-- =============================================	
		IF @Action = 'D' BEGIN
			SET @CanSend = 0
			SET @Source = 'DELETED'
		END
	
		--IF @Action = 'I' BEGIN
		--	SET @CanSend = 1
		--	SET @Source = 'UPDATE:NewExtras'
		--END

		IF @Action = 'U' BEGIN
			SET @Source = 'UPDATE:MENU'
			SET @CanSend = 1
			SET @OLDCovers = (SELECT MNM_COVERS FROM DELETED)
			SET @NEWCovers = (SELECT MNM_COVERS FROM INSERTED)
			SET @OLDDate = (SELECT (F_DAY + MNM_TIME) FROM DELETED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
			SET @NEWDate = (SELECT (F_DAY + MNM_TIME) FROM INSERTED INNER JOIN FUNC_FIL ON MNM_OWNER = F_REF)
		
			--  new code inserted by plg 19 Jan 2015 to check if this is quick change
			SET @SentStatus = isnull((SELECT TOP 1 AEFL_Sent FROM AEF_Link WHERE AEFL_FREF = @BookingNumber),0)
			IF @SentStatus = 0 BEGIN --i.e. it hasn't been sent yet
				-- we just deal with it as though this were the insert
				SET @Action = 'I'
				SET	@Source = 'UPDATE:MENU'
			end
			else begin --i.e. it has been sent already
		
				IF @OLDCovers <> @NEWCovers
				BEGIN 
					SET @Source = 'UPDATE:MENU'
				END
			
				IF @OLDDate <> @NEWDate
				BEGIN 
					SET @Source = 'UPDATE:MENU'
				END
			end		
		END

		EXECUTE ae_INS_EmailTypes_AEF_Link @BookingNumber, @SessionNumber, @BookingDateTime, @CanSend, @Source, @Action, ''

	END --Enabled
-- =============================================
-- THE END
-- =============================================
END
GO

PRINT '*****************************************************************************'								   
PRINT 'trAutoEmail_Menus: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MASTMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Menus]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Menus') AND [name] = 'Product')
BEGIN		
	PRINT 'trAutoEmail_Menus: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Menus: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MASTMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Menus]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Menus') AND [name] = 'Module')
BEGIN		
	PRINT 'trAutoEmail_Menus: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Menus: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [MASTMENU]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_Menus]
							   ,@name = N'Version' 
							   ,@value = N'5.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_Menus') AND [name] = 'Version')
BEGIN		
	PRINT 'trAutoEmail_Menus: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_Menus: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
