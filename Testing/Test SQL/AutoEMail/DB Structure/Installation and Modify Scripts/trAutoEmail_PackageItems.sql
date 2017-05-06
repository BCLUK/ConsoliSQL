-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH 
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

if exists (select * from sys.objects where object_id = object_id(N'[trAutoEmail_PackageItems]') and OBJECTPROPERTY(object_id, N'IsTrigger') = 1)
BEGIN
	DROP TRIGGER [trAutoEmail_PackageItems]
	PRINT 'trAutoEmail_PackageItems: Dropped Trigger trAutoEmail_PackageItems on PACKAGES'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_PackageItems: Trigger trAutoEmail_PackageItems on PACKAGES Does Not Exist !'
END
PRINT 'trAutoEmail_PackageItems: Creating Trigger trAutoEmail_PackageItems on PACKAGES'
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
-- Version: 16
-- Date: 23/03/2017
-- =============================================
-- Changes: 13/02/2015: MCB: Added Department Handling
-- Changes: 05/03/2015: MCB: Changed @DeptDecideCode to VARCHAR(10) 
-- Changes: 11/03/2015: MCB: Fixed Link Between Package 
-- Changes: 11/03/2015: MCB: Added IsNull around SELECT TOP 1 Status 
-- Changes: 13/03/2015: MCB: Changed @Source VARCHAR(20); @Department VARCHAR(MAX)
-- Changes: 20/03/2015: MCB: Added Delete/Update handling Via Cursor
-- Changes: 27/03/2015: MCB: Added Delete Handling for duplictae items
-- Changes: 30/03/2015: MCB: Added Second ELSE for Cursor to handle -1 Error
-- Changes: 08/04/2015: MCB: Added UPDATE:NOCHNG
-- Changes: 08/04/2015: MCB: Amended ae_DEL_AEF_Amendments call to latest version
-- Changes: 17/04/2015: MCB: Added ID
-- Changes: 17/04/2015: MCB: Removed EXEC ae_DEL_AEF_Amendments @PrikeyDel, 0, 0
-- Changes: 17/04/2015: MCB: Inserted EXEC ae_DEL_AEF_Amendments @PrikeyDel, 0, 0
-- Changes: 17/04/2015: MCB: Changed 'INSERT:NOCHNG' Logic
-- Changes: 17/12/2015: MCB: Added Extra check for IU
-- Changes: 23/03/2017: TT:  Removed call to stored procedure 
--	(16)					 CABS_CREATE_AUTOEMAILER_TABLES as it should not be needed
--							 if the build processs is robust
-- =============================================
CREATE TRIGGER [dbo].[trAutoEmail_PackageItems] 
   ON  [dbo].[PACKAGES] 
   AFTER INSERT, UPDATE, DELETE
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
		@Action VARCHAR(1),
		@Prikey VARCHAR(100),
		@ItemCode VARCHAR(6),
		@PrikeyDel VARCHAR(100)
		
	DECLARE	
		@Source VARCHAR(50),
		@SentStatus bit,		-- added plg 19th Jan 2015	
		@SectionBooking INT,
		@OLDCovers INT,
		@NEWCovers INT,
		@OLDDate DATETIME,
		@NEWDate DATETIME,
		@OLDCharge DECIMAL (10, 2),
		@NEWCharge DECIMAL (10, 2),
		@OLDNotes VARCHAR(MAX),
		@NEWNotes VARCHAR(MAX),
		@OLDStart VARCHAR(5),
		@NEWStart VARCHAR(5),
		@OLDEnd VARCHAR(5),
		@NEWEnd VARCHAR(5),	
		@CanSend INT,
		@DeptDecideCode VARCHAR(10),
		@LocDecideCode VARCHAR(6),		
		@Department VARCHAR(MAX)	
	
	DECLARE
		@ID INT			
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
			SET @CanSend = 1
		END

		--TODO Cursor
		IF @Action IN('D') BEGIN DECLARE myCURSOR3 CURSOR FAST_FORWARD for 	
			SELECT
				PH_OWNER, 
				'',
				(PK_SYSNO + '~' + PK_POST + '~' + CONVERT(VARCHAR, PK_SEQ)),
				PK_POST,
				PK_COVERS,
				PK_SELL,
				'',
				'00:00',
				'00:00'
			FROM DELETED
			INNER JOIN PKGHEAD ON PH_SYSNO = PK_SYSNO
		END	
		ELSE 
		IF @Action IN('I', 'U') BEGIN DECLARE myCURSOR3 CURSOR FAST_FORWARD for	
			SELECT
				PH_OWNER, 
				'',
				(PK_SYSNO + '~' + PK_POST + '~' + CONVERT(VARCHAR, PK_SEQ)),
				PK_POST,
				PK_COVERS,
				PK_SELL,
				'',
				'00:00',
				'00:00'
			FROM INSERTED
			INNER JOIN PKGHEAD ON PH_SYSNO = PK_SYSNO
		END
		ELSE RETURN

		OPEN myCURSOR3

		FETCH NEXT FROM
			myCURSOR3
		INTO
			@BookingNumber,
			@Department,
			@Prikey,
			@ItemCode,
			@NEWCovers,
			@NEWCharge,
			@NEWNotes,
			@NEWStart,
			@NEWEnd

		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @ID = (SELECT MAX(AEFA_ID) FROM AEF_Amendments WHERE AEFA_PRIKEY = @Prikey)
	
			SET @BookingDateTime = (SELECT (F_STARTDATETIME) FROM FUNC_FIL WHERE F_REF = @BookingNumber)
			SET @SessionNumber = (SELECT COALESCE(F_SESSNO, '') FROM FUNC_FIL WHERE F_REF = @BookingNumber)

			SET @DeptDecideCode = @ItemCode
			SET @LocDecideCode = (SELECT COALESCE(RM_LOC, '') FROM FUNC_FIL INNER JOIN ROOMS ON F_ROOM = RM_ABBR WHERE F_REF = @BookingNumber)
			SET @Department = (SELECT [dbo].[uf_getDeptCodes] (@DeptDecideCode, @LocDecideCode))			

			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_PRIKEY = @Prikey) > 0 BEGIN
				IF @Action IN('D') BEGIN
					SET @OLDCovers = (SELECT PK_COVERS FROM DELETED WHERE (PK_SYSNO + '~' + PK_POST + '~' + CONVERT(VARCHAR, PK_SEQ)) = @Prikey)
					SET @OLDDate = (SELECT (F_DAY + F_START) FROM DELETED INNER JOIN PKGHEAD ON PH_SYSNO = PK_SYSNO INNER JOIN FUNC_FIL ON F_REF = PH_OWNER WHERE F_REF = @BookingNumber AND (PK_SYSNO + '~' + PK_POST + '~' + CONVERT(VARCHAR, PK_SEQ)) = @Prikey)
					SET @OLDCharge = (SELECT PK_SELL FROM DELETED WHERE (PK_SYSNO + '~' + PK_POST + '~' + CONVERT(VARCHAR, PK_SEQ)) = @Prikey)
					SET @OLDNotes = ''
					SET @OLDStart = '00:00'
					SET @OLDEnd = '00:00'
				END
				ELSE
				IF @Action IN('I', 'U') BEGIN
					SET @OLDCovers = (SELECT AEFA_COVERS FROM AEF_Amendments WHERE AEFA_PRIKEY = @Prikey AND AEFA_ID = @ID)
					SET @OLDCharge = (SELECT AEFA_CHARGE FROM AEF_Amendments WHERE AEFA_PRIKEY = @Prikey AND AEFA_ID = @ID)
					SET @OLDDate = @BookingDateTime
					SET @NEWDate = @BookingDateTime 
					SET @OLDNotes = ''
					SET @OLDStart = '00:00'
					SET @OLDEnd = '00:00'
				END
			END		
			ELSE
			IF (SELECT COUNT(*) FROM AEF_Amendments WHERE AEFA_PRIKEY = @Prikey AND AEFA_ID = @ID) = 0 BEGIN
				SET @OLDCovers = @NEWCovers
				SET @OLDCharge = @NEWCharge
				SET @OLDDate = @BookingDateTime
				SET @NEWDate = @BookingDateTime 
				SET @OLDNotes = @NEWNotes
				SET @OLDStart = @NEWStart
				SET @OLDEnd = @NEWEnd
			END	

	
			IF (@OLDCovers <> @NEWCovers) OR (@OLDDate <> @NEWDate) OR (@OLDCharge <> @NEWCharge) OR (@OLDNotes <> @NEWNotes) OR (@OLDStart <> @NEWStart) OR (@OLDEnd <> @NEWEnd) BEGIN 
				SET @Action = 'U'
				SET @Source = 'UPDATE:PackageItem'
			END

			IF (@OLDCovers = @NEWCovers) AND (@OLDDate = @NEWDate) AND (@OLDCharge = @NEWCharge) AND (@OLDNotes = @NEWNotes) AND (@OLDStart = @NEWStart) AND (@OLDEnd = @NEWEnd) BEGIN
				IF @Action IN('I', 'U') BEGIN
					SET @Action = 'I'
					SET @Source = 'NOCHNG:IU'
			
					SET @PrikeyDel = SUBSTRING(@Prikey, 1, CHARINDEX('~',@Prikey,(charindex('~',@Prikey)+1))-1)
					EXEC ae_DEL_AEF_Amendments @PrikeyDel, 0, 0		
				END
			END
	
			IF @Action = 'D' BEGIN
				SET @Source = 'DELETE:PackageItem'
				SET @PrikeyDel = SUBSTRING(@Prikey, 1, CHARINDEX('~',@Prikey,(charindex('~',@Prikey)+1))-1)
				EXEC ae_DEL_AEF_Amendments @PrikeyDel, 0, 0		
			END
	
			-- Removed call to CABS_CREATE_AUTOEMAILER_TABLES - TT - 23/03/2017
			-- EXECUTE CABS_CREATE_AUTOEMAILER_TABLES
			EXECUTE ae_INS_AEF_Amendments @BookingNumber, @Prikey, @ItemCode, @OLDStart, @OLDEnd, @OLDCovers, @OLDCharge, @OLDNotes, @Action
			EXECUTE ae_INS_EmailTypes_AEF_Link @BookingNumber, @SessionNumber, @BookingDateTime, @CanSend, @Source, @Action, @Department
		
			FETCH NEXT FROM 
				myCURSOR3
			INTO
				@BookingNumber,
				@Department,
				@Prikey,
				@ItemCode,
				@NEWCovers,
				@NEWCharge,
				@NEWNotes,
				@NEWStart,
				@NEWEnd
		END

		CLOSE myCURSOR3
		DEALLOCATE myCURSOR3

	END --Enabled
-- =============================================
-- THE END
-- =============================================
END
GO

PRINT '*****************************************************************************'								   
PRINT 'trAutoEmail_PackageItems: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [PACKAGES]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_PackageItems]
							   ,@name = N'Product' 
							   ,@value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_PackageItems') AND [name] = 'Product')
BEGIN		
	PRINT 'trAutoEmail_PackageItems: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_PackageItems: Product Extended Property Not Created Successfully !'
END	

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [PACKAGES]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_PackageItems]
							   ,@name = N'Module' 
							   ,@value = N'AutoEmail'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_PackageItems') AND [name] = 'Module')
BEGIN		
	PRINT 'trAutoEmail_PackageItems: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_PackageItems: Module Extended Property Not Created Successfully !'
END			

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA' 
							   ,@level0name = [dbo] 
							   ,@level1type = N'TABLE' 
							   ,@level1name = [PACKAGES]
							   ,@level2type = N'TRIGGER' 
							   ,@level2name = [trAutoEmail_PackageItems]
							   ,@name = N'Version' 
							   ,@value = N'16.0'
								   
IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('trAutoEmail_PackageItems') AND [name] = 'Version')
BEGIN		
	PRINT 'trAutoEmail_PackageItems: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'trAutoEmail_PackageItems: Version Extended Propety Not Created Successfully !'
END
							   
PRINT '*****************************************************************************'								   
GO
