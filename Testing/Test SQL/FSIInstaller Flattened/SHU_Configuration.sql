-- User Specified Configuration
DECLARE @DBServerName VARCHAR(100) = '*** INSERT SQL SERVER NAME ***'  	
DECLARE @DBName VARCHAR(100) = '*** INSERT DATABASE NAME ***'  	
DECLARE @ExportPath VARCHAR(500) = '*** INSERT EXPORT PATH DIRECTORY ***'	
DECLARE @SQLServerUserName VARCHAR(500) = '*** INSERT SQL SERVER USERNAME ***'	
DECLARE @SQLServerUserPassword VARCHAR(500) = '*** INSERT SQL SERVER USER PASSWORD ***'	

exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','SQLServerName', @DBServerName,'S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','SQLServerUser', @SQLServerUserName,'S'		
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','SQLServerPW', @SQLServerUserPassword,'S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','SQLDatabaseName', @DBName,'S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','ExportPath', @ExportPath,'S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','Enabled','1','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','FileName','FSIExport','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','Backslash','\','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','DateSelection','InvoiceDate','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','TitlesEnabled','1','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','HeaderEnabled','0','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','ItemEnabled','1','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','FooterEnabled','0','S'
exec xCABS_CONFIG_WriteString '','usp_CreateExportFile_HALSUM','DescEnabled','0','S'
exec xCABS_CONFIG_WriteString '','Finance_HALSUM','Separator','44','S'

exec xCABS_CONFIG_WriteString '', 'Finance','ExportSprocName','usp_createExportFile_Halsum','G'
GO

TRUNCATE TABLE FI_HEADER
GO

-- TITLES for Invoices
Declare @ID Int
INSERT INTO [dbo].[FI_HEADER]
           ([FileType],[Module],[LineType],[SubModule],[Direction],[MUMode],[Active])
     VALUES
           ('CSV','Finance','TITLES','IN','OUT','HALSUM',1)
Set @ID = @@IDENTITY
INSERT INTO [dbo].[FI_TEMPLATE]	--1
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('CreditCode','Varchar(10)','Contains the Credit Code',1,10,0,44,NULL
           ,'CR_Code','LEFT',1,'Mapped from Invoice Credit',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]--2
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('AccountCode','Varchar(13)','Contains the Account Code for the client',11,23,0,44,NULL
           ,'ACT','LEFT',1,'Mapped from Clients Text1 ',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]--3
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingDate','Date','Date of Booking',24,34,0,44,NULL
           ,'Tran_Date','LEFT',1,'Taken from the event date',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]--4
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingRef','Varchar(7)','CABS Booking Reference',35,41,0,44,NULL
           ,'Tran_ref','LEFT',1,'Mapped from F_REF',@ID)
INSERT INTO [dbo].[FI_TEMPLATE] --5
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingName','Varchar(40)','Name of the booking',42,81,0,44,NULL
           ,'Booking_name','LEFT',1,'Mapped from MBR Name',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --6
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Nominal','Varchar(4)','Contains the Nominal Code',82,85,0,44,NULL
           ,'NOML','LEFT',1,'Mapped from ??',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --7
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Value','Numeric','Contains the Line value',86,102,0,44,2
           ,'VAL','LEFT',1,'Mapped from Fol_Tran Gross',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --8
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('HubCode','Varchar(10)','Contains the Hub Cost Code',103,112,0,44,NULL
           ,'Hub_Code','LEFT',1,'Mapped from PostDef (of hub) Credit',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --9
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BatchCode','Varchar(10)','Contains the BAtch Code',113,122,0,44,NULL
           ,'Batch','LEFT',1,'Generated',@ID)
GO

-- ITEMS for Invoices

GO
Declare @ID Int
INSERT INTO [dbo].[FI_HEADER]
           ([FileType],[Module],[LineType],[SubModule],[Direction],[MUMode],[Active])
     VALUES
           ('CSV','Finance','ITEM','IN','OUT','HALSUM',1)
Set @ID = @@IDENTITY
INSERT INTO [dbo].[FI_TEMPLATE]  --10
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('CreditCode','Varchar(10)','Contains the Credit Code',1,10,0,44,NULL
           ,'','LEFT',1,'Mapped from inv_summary Chargebk',@ID)
	INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('vw_FOL_TRAN_INV_SUMMARY.F_CHARGEBK',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --11
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('AccountCode','Varchar(13)','Contains the Account Code for the client',11,23,0,44,NULL
           ,'','LEFT',1,'Mapped from Clients Text1 ',@ID)
		   INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Clients.Text1',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --12
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingDate','Date','Date of Booking',24,34,0,44,NULL
           ,'','LEFT',1,'Taken from the event date',@ID)
		   INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Fol_Tran.F_DATE',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]   --13
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingRef','Varchar(7)','CABS Booking Reference',35,41,0,44,NULL
           ,'','LEFT',1,'Mapped from F_REF',@ID)
		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('FOL_TRAN.F_OWNER',@@IDENTITY)

INSERT INTO [dbo].[FI_TEMPLATE]  --14
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingName','Varchar(40)','Name of the bookingCode',42,81,0,NULL,NULL
           ,'RULE:usp_RULE_MBR_Name','LEFT',1,'Mapped from MBR Name',@ID)
		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('MBRFILE.MBR_CONTCT',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --15
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Nominal','Varchar(4)','Contains the Nominal Code',82,85,0,NULL,NULL
           ,'','LEFT',1,'Mapped from Post Def NL Code',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Post_def.P_NL_Code',@@IDENTITY)

INSERT INTO [dbo].[FI_TEMPLATE]  --16
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Value','Numeric','Contains the Line value',86,102,0,NULL,2
           ,'','LEFT',1,'Mapped from Fol_Tran Gross',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('vw_FOL_TRAN_INV_SUMMARY.VALUE',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --17
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('HubCode','Varchar(10)','Contains the Hub Cost Code',103,112,0,NULL,NULL
           ,'RULE:usp_LocationCostCode','LEFT',1,'Mapped from PostDef (of hub) Credit',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('ROOMS.RM_LOC',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --18
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BatchCode','Varchar(10)','Contains the BAtch Code',113,122,0,NULL,NULL
           ,'RULE:usp_RULE_Batch_No','LEFT',1,'Generated',@ID)

GO

-- HEADERS for Credits

Declare @ID Int
INSERT INTO [dbo].[FI_HEADER]
           ([FileType],[Module],[LineType],[SubModule],[Direction],[MUMode],[Active])
     VALUES
           ('CSV','Finance','TITLES','CN','OUT','HALSUM',1)
Set @ID = @@IDENTITY
INSERT INTO [dbo].[FI_TEMPLATE]   --19
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('CreditCode','Varchar(10)','Contains the Credit Code',1,10,0,NULL,NULL
           ,'CR_Code','LEFT',1,'Mapped from PostDef Credit',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]   --20
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('AccountCode','Varchar(13)','Contains the Account Code for the client',11,23,0,NULL,NULL
           ,'ACT','LEFT',1,'Mapped from Clients Text1 ',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]   --21
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingDate','Date','Date of Booking',24,34,0,NULL,NULL
           ,'Tran_Date','LEFT',1,'Taken from the event date',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]   --22
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingRef','Varchar(7)','CABS Booking Reference',35,41,0,NULL,NULL
           ,'Tran_ref','LEFT',1,'Mapped from F_REF',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --23
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingName','Varchar(40)','Name of the bookingCode',42,81,0,NULL,NULL
           ,'Booking_name','LEFT',1,'Mapped from MBR Name',@ID)
INSERT INTO [dbo].[FI_TEMPLATE] --24
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Nominal','Varchar(4)','Contains the Nominal Code',82,85,0,NULL,NULL
           ,'NOML','LEFT',1,'Mapped from ??',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --25
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Value','Numeric','Contains the Line value',86,102,0,NULL,2
           ,'VAL','LEFT',1,'Mapped from Fol_Tran Gross',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --26
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('HubCode','Varchar(10)','Contains the Hub Cost Code',103,112,0,NULL,NULL
           ,'Hub_Code','LEFT',1,'Mapped from PostDef (of hub) Credit',@ID)
INSERT INTO [dbo].[FI_TEMPLATE]  --27
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BatchCode','Varchar(10)','Contains the BAtch Code',113,122,0,NULL,NULL
           ,'Batch','LEFT',1,'Generated',@ID)
GO
-- ITEMS for Credits

Declare @ID Int
INSERT INTO [dbo].[FI_HEADER]
           ([FileType],[Module],[LineType],[SubModule],[Direction],[MUMode],[Active])
     VALUES
           ('CSV','Finance','ITEM','CN','OUT','HALSUM',1)
Set @ID = @@IDENTITY
INSERT INTO [dbo].[FI_TEMPLATE]  --28
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('CreditCode','Varchar(10)','Contains the Credit Code',1,10,0,NULL,NULL
           ,'','LEFT',1,'Mapped from Credit Note Chargebk',@ID)
	INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('vw_FOL_TRAN_CRED_SUMMARY.P_CHARGEBK',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --29
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('AccountCode','Varchar(13)','Contains the Account Code for the client',11,23,0,NULL,NULL
           ,'','LEFT',1,'Mapped from Clients Text1 ',@ID)
		   INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Clients.Text1',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --30
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingDate','Date','Date of Booking',24,34,0,NULL,NULL
           ,'','LEFT',1,'Taken from the event date',@ID)
		   INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Fol_Tran.F_DATE',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --31
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingRef','Varchar(7)','CABS Booking Reference',35,41,0,NULL,NULL
           ,'','LEFT',1,'Mapped from F_REF',@ID)
		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('FOL_TRAN.F_OWNER',@@IDENTITY)

INSERT INTO [dbo].[FI_TEMPLATE]  --32
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BookingName','Varchar(40)','Name of the bookingCode',42,81,0,NULL,NULL
           ,'','LEFT',1,'Mapped from MBR Contact Name',@ID)
		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('MBRFILE.MBR_CONTCT',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --33
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Nominal','Varchar(4)','Contains the Nominal Code',82,85,0,NULL,NULL
           ,'RULE:usp_RULE_get_IntorExt_CodeSplit','LEFT',1,'Mapped from POST DEF NL CODE',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('Post_def.P_NL_CODE',@@IDENTITY)

INSERT INTO [dbo].[FI_TEMPLATE]  --34
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('Value','Numeric','Contains the Line value',86,102,0,NULL,2
           ,'','LEFT',1,'Mapped from Fol_Tran Gross',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('vw_FOL_TRAN_CRED_SUMMARY.VALUE',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --35
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('HubCode','Varchar(10)','Contains the Hub Cost Code',103,112,0,NULL,NULL
           ,'RULE:usp_LocationCostCode','LEFT',1,'Mapped from PostDef (of hub) Credit',@ID)
		   		INSERT INTO [dbo].[FI_MAPPED_FIELDS]
           ([FI_CABS_FIELD],[FI_FINANCE_FIELD])
     VALUES
           ('ROOMS.RM_LOC',@@IDENTITY)
INSERT INTO [dbo].[FI_TEMPLATE]  --36
           ([Name],[Type],[Description],[StartPos],[EndPos],[FillCharacter],[Delimiter],[DecPointReq],
		   [DefaultValue],[Justification],[Visible],[Notes],[FI_Header_ID])
     VALUES
           ('BatchCode','Varchar(10)','Contains the BAtch Code',113,122,0,NULL,NULL
           ,'RULE:usp_RULE_Batch_No','LEFT',1,'Generated',@ID)

GO

