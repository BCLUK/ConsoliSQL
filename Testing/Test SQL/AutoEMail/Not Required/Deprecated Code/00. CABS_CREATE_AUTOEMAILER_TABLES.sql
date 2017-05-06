IF EXISTS ( SELECT * FROM   sysobjects 
            WHERE  id = object_id(N'[dbo].[CABS_CREATE_AUTOEMAILER_TABLES]') 
                   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [dbo].[CABS_CREATE_AUTOEMAILER_TABLES]
	PRINT '00. CABS_CREATE_AUTOEMAILER_TABLES: Dropped Procedure CABS_CREATE_AUTOEMAILER_TABLES'
END
ELSE
BEGIN
	PRINT '00. CABS_CREATE_AUTOEMAILER_TABLES: CABS_CREATE_AUTOEMAILER_TABLES - Does Not Already Exist !'
END
PRINT '00. CABS_CREATE_AUTOEMAILER_TABLES: Creating Procedure CABS_CREATE_AUTOEMAILER_TABLES'
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CABS_CREATE_AUTOEMAILER_TABLES]
AS
BEGIN
	-- =============================================
	-- Author:		MARK BIRCH
	-- Create date: 08-APR-2013
	-- Description:	To Create a SPROC to create Auto-Emailer Tables
	-- =============================================
	-- Version: 3
	-- Date: 01/11/2016
	-- =============================================
	-- Changes: MCB: 26-NOV-2013: Added Two New Fields (AEF_INSERTED_DATE; AEF_UPDATED_DATE)
	-- Changes: MCB: 15-JAN-2014: Added One New Field (AEF_KEY)
	-- Changes: MCB: 15-JAN-2014: Added New Table AutoEmailFunction_SEND_PARAMS
	-- Changes: MCB: 17-JAN-2014: Added One New Field (AEF_FROM_TRIGGER)
	-- Changes: MCB: 17-JAN-2014: Added New Table AutoEmailFunction_FromTrigger
	-- Changes: MCB: 29-JUL-2014: Added RoomGiven Field
	-- Changes: MCB: 15-AUG-2014: Added Session Field
	-- Changes: MCB: 31-AUG-2014: Added AEF_ROUTE Field
	-- Changes: MCB: 13-FEB-2015: Added AEF_Link Table
	-- Changes: MCB: 12-MAR-2015: Added AEF_Amendments Table
	-- Changes: MCB: 16-MAR-2015: Changed AEFA_PRIKEY TO VARCHAR(100)
	-- Changes: MCB: 11-SEP-2015: Added MenuActivityCount Table
	-- Changes: MCB: 29-OCT-2015: Added Booking Ref to PARAMS Table	
	-- Changes: TT:  01-JUN-2016: Added AEFL_EmailSPROC to AEF_Link
	-- Changes: TT:  02-AUG-2016: Added AEFL_MBRNo to AEF_Link
	-- Changes: TT:  02-AUG-2016: Increased column width from 10 to 100 to 
	--							  store email stored proc name and template
	-- Changes: TT:	 18-OCT-2016: Added column to store mail item id from system email tables
	-- Changes: TT:	 01-NOV-2016: Added colummn AEFL_LastUpdate to table AEF_LINK to 
	--	(3)						  store date and time of last record change	
	-- =============================================

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction]')) = 0
	BEGIN
		CREATE TABLE AutoEmailFunction
		(
			AEF_KEY int IDENTITY(1,1) NOT NULL,
			AEF_FUNC_REF varchar(7) NULL,
			AEF_STATUS varchar(6) NULL,
			AEF_STATUS_TEXT VARCHAR(100) NULL,
			AEF_ROOM varchar(6) NULL,
			AEF_ROOM_TEXT varchar(100) NULL,
			AEF_USE varchar(6) NULL,
			AEF_USE_TEXT varchar(100) NULL,
			AEF_PURPOSE varchar(100) NULL,
			AEF_BOOKER varchar(50) NULL,
			AEF_BOOKER_TEXT varchar(200) NULL,
			AEF_BOOKER_EMAIL varchar(100) NULL,
			AEF_DATE datetime NULL,
			AEF_START varchar(5) NULL,
			AEF_END varchar(5) NULL,
			AEF_SETUP varchar(5) NULL, 
			AEF_BDOWN varchar(5) NULL,
			AEF_COVERS int NULL,
			AEF_MBR_NO varchar(7) NULL,
			AEF_MBR_NAME varchar(100) NULL,
			AEF_CONTCT varchar(40) NULL,
			AEF_EMAIL varchar(100) NULL,
			AEF_CEMAIL varchar(100) NULL,
			AEF_INTERN int NULL,
			AEF_EXTRAYN int NULL,
			AEF_PACKYN int NULL,
			AEF_MENUYN int NULL,
			AEF_RMGIVEN VARCHAR(3) NULL,
			AEF_SESSNO VARCHAR(7) NULL,
			AEF_STARTDATETIME datetime NULL,
			AEF_CANSEND varchar(3) NULL,
			AEF_SENT int NULL,
			AEF_SENT_DATE datetime NULL,
			AEF_INSERTED_DATE datetime NULL,
			AEF_UPDATED_DATE datetime NULL,
			AEF_FROM_TRIGGER INT NULL,
			AEF_DTYN int NULL
		)
	END

	if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_FromTrigger]')) = 0
	BEGIN
		CREATE TABLE AutoEmailFunction_FromTrigger
		(
			AEF_T_KEY int IDENTITY(1,1) NOT NULL,
			AEF_KEY int NULL,
			AEF_FUNC_REF varchar(7) NULL,
			AEF_STATUS varchar(6) NULL,
			AEF_STATUS_TEXT VARCHAR(100) NULL,
			AEF_ROOM varchar(6) NULL,
			AEF_ROOM_TEXT varchar(100) NULL,
			AEF_USE varchar(6) NULL,
			AEF_USE_TEXT varchar(100) NULL,
			AEF_PURPOSE varchar(100) NULL,
			AEF_BOOKER varchar(50) NULL,
			AEF_BOOKER_TEXT varchar(200) NULL,
			AEF_BOOKER_EMAIL varchar(100) NULL,
			AEF_DATE datetime NULL,
			AEF_START varchar(5) NULL,
			AEF_END varchar(5) NULL,
			AEF_SETUP varchar(5) NULL, 
			AEF_BDOWN varchar(5) NULL,
			AEF_COVERS int NULL,
			AEF_MBR_NO varchar(7) NULL,
			AEF_MBR_NAME varchar(100) NULL,
			AEF_CONTCT varchar(40) NULL,
			AEF_EMAIL varchar(100) NULL,
			AEF_CEMAIL varchar(100) NULL,
			AEF_INTERN int NULL,
			AEF_EXTRAYN int NULL,
			AEF_PACKYN int NULL,
			AEF_MENUYN int NULL,
			AEF_RMGIVEN VARCHAR(3) NULL,
			AEF_SESSNO VARCHAR(7) NULL,
			AEF_STARTDATETIME datetime NULL,
			AEF_CANSEND varchar(3) NULL,
			AEF_SENT int NULL,
			AEF_SENT_DATE datetime NULL,
			AEF_SENT_SESSION int NULL,
			AEF_INSERTED_DATE datetime NULL,
			AEF_UPDATED_DATE datetime NULL,
			AEF_FROM_TRIGGER INT NULL,
			-- Increased column width from 10 to 100 to store email stored proc name and template - TT - 02/08/2016
			AEF_ROUTE VARCHAR(100) NULL,			
			AEF_DTYN int NULL,
			-- Added column to store mail item id from system email tables - TT - 18/10/2016
			AEF_MAILITEM_ID int NULL
		)
	END

	if (select COUNT(*) from sysobjects where id = object_id(N'[AutoEmailFunction_SEND_PARAMS]')) = 0
	BEGIN
		CREATE TABLE AutoEmailFunction_SEND_PARAMS
		(
			AEF_SP_KEY int IDENTITY(1,1) NOT NULL,
			AEF_KEY int NULL,
			AEF_EmailProfile VARCHAR(200) NULL,
			AEF_EMailAddr VARCHAR(200) NULL,
			AEF_EmailFormat VARCHAR(200) NULL,
			AEF_Importance VARCHAR(200) NULL,
			AEF_Sensitivity VARCHAR(200) NULL,
			AEF_FROM_TRIGGER INT NULL,
			AEF_BookingRef VARCHAR(7) NULL,
			AEF_DateStamp DATETIME NULL
		)	
	END		

	if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Link]')) = 0
	BEGIN
		CREATE TABLE [AEF_Link]
		(
			[AEFL_ID] [int] IDENTITY(1,1) NOT NULL,
			[AEFL_FREF] [varchar](7) NULL,
			[AEFL_SessNo] [varchar](7) NULL,
			[AEFL_EMailType] [varchar](6) NULL,
			[AEFL_CanSend] [int] NULL,
			[AEFL_FDay] [datetime] NULL,
			[AEFL_Sent] [int] NULL,
			[AEFL_SendTime] [datetime] NULL,
			[AEFL_Source] [varchar](50) NULL,
			[AEFL_Department] [varchar](MAX) NULL,
			--Added column [AEFL_EmailSPROC] to be used for storing template specific stored proc - MB/TT - 01/06/2016
			[AEFL_EmailSPROC] [varchar](200) NULL, 
			-- Added Column to store MBR_No - TT - 02/08/2016
			[AEFL_MBRNo] [varchar](7) NULL,
			-- Added colummn to store date and time of last record change - TT - 01/11/2016
			[AEFL_LastUpdate] [DateTime] NULL
		) ON [PRIMARY]
	END


	if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[AEF_Amendments]')) = 0
	BEGIN
		CREATE TABLE [AEF_Amendments]
		(
			[AEFA_ID] [int] IDENTITY(1,1) NOT NULL,
			[AEFA_FREF] [varchar](7) NULL,
			[AEFA_PRIKEY] [varchar](100) NULL,
 			[AEFA_CODE] [varchar](100) NULL,
 			[AEFA_START] [varchar](5) NULL,
 			[AEFA_END] [varchar](5) NULL,
 			[AEFA_COVERS] [varchar](5) NULL,
 			[AEFA_CHARGE] DECIMAL (10, 2) NULL,
 			[AEFA_NOTES] [TEXT] NULL,
 			[AEFA_ACTION] [varchar](1) NULL 
		) ON [PRIMARY]
	END

	IF (SELECT COUNT(*) FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[MenuActivityCount]')) = 0
	BEGIN
		CREATE TABLE MenuActivityCount
		(
			MEN_MENU_CODE VARCHAR(10) NULL,
			MEN_DEL_COUNT INT NULL,
			MEN_REC_TYPE VARCHAR(1),
			MEN_DATE DATETIME 
		)	
	END

END
GO

-- Run the stored procedure just created - TT - 18/10/2016

PRINT '00. CABS_CREATE_AUTOEMAILER_TABLES: Executing Procedure CABS_CREATE_AUTOEMAILER_TABLES'
EXEC CABS_CREATE_AUTOEMAILER_TABLES
GO