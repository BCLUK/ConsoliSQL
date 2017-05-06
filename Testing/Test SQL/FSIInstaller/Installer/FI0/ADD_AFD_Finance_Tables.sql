/********************************************************************************************************
 (c) Business Careware Ltd 2012
 
       Script Name : 3. ADD_AFD_Finance_Tables
      
            Author : Mark Birch
 
      Date Created : 14-NOV-2012
 
  Expected outcome : CREATE All Tables For the AFD Finance Project
 
             Usage : Run through SQL Query Analyser
             
    Error Handling : None Expected
                  
    Changes : Date : 14-NOV-2012: MCB: 	ADDED FI_Export
					ADDED FI_FIELD_DESCR
					ADDED FI_HEADER
					ADDED FI_MAPPED_FIELDS
					ADDED FI_TEMPLATE
					ADDED FOL_TRAN_INSERT_F_CALCAMT Trigger
					ADDED FOL_TRAN.F_CALCAMT Field
      

*********************************************************************************************************/
if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[FI_Export]')) = 0
BEGIN
CREATE TABLE [dbo].[FI_Export](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Interface] [varchar](2) NULL,
	[Trans_Type] [varchar](2) NULL,
	[Voucher_Type] [varchar](2) NULL,
	[Voucher_No] [varchar](9) NULL,
	[Account] [varchar](8) NULL,
	[apar_ID] [varchar](8) NULL,
	[dim_4] [varchar](8) NULL,
	[dim_5] [varchar](8) NULL,
	[Cur_amount] [varchar](20) NULL,
	[Amount] [varchar](20) NULL,
	[Voucher_date] [varchar](8) NULL,
	[Description] [varchar](50) NULL,
	[ext_inv_ref] [varchar](15) NULL,
	[tax_code] [varchar](2) NULL,
	[apar_type] [varchar](1) NULL,
	[account2] [varchar](4) NULL,
	[base_amount] [varchar](20) NULL,
	[base_curr] [varchar](20) NULL,
	[Currency] [varchar](3) NULL,
	[Client] [varchar](2) NULL,
	[Exported] [int] NULL,
	[ExportedDate] [datetime] NULL,
	[F_Tranno] [varchar](10) NULL
) ON [PRIMARY]
END

if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[FI_FIELD_DESCR]')) = 0
BEGIN
CREATE TABLE [dbo].[FI_FIELD_DESCR](
	[IDCol] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](50) NOT NULL,
	[Fieldname] [varchar](50) NOT NULL,
	[AliasName] [varchar](1000) NULL,
	[TableAlias] [varchar](50) NULL,
	[FieldType] [varchar](50) NULL
) ON [PRIMARY]
END

if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[FI_HEADER]')) = 0
BEGIN
CREATE TABLE [dbo].[FI_HEADER](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FileType] [char](5) NULL,
	[Module] [varchar](50) NULL,
	[LineType] [varchar](10) NULL,
	[SubModule] [varchar](20) NULL,
	[Direction] [char](3) NULL,
	[MUMODE] [Varchar](10) NULL,
	[Active] [bit] NULL,
 CONSTRAINT [PK_FI_Header] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
END

if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[FI_MAPPED_FIELDS]')) = 0
BEGIN
CREATE TABLE [dbo].[FI_MAPPED_FIELDS](
	[FI_CABS_FIELD] [varchar](255) NULL,
	[FI_FINANCE_FIELD] [int] NULL
) ON [PRIMARY]
END

if (select COUNT(*) from dbo.sysobjects where id = object_id(N'[FI_TEMPLATE]')) = 0
BEGIN
CREATE TABLE [dbo].[FI_TEMPLATE](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](20) NOT NULL,
	[Type] [varchar](20) NULL,
	[Description] [varchar](150) NULL,
	[StartPos] [int] NULL,
	[EndPos] [int] NULL,
	[FillCharacter] [smallint] NULL,
	[Delimiter] [smallint] NULL,
	[DecPointReq] [bit] NULL,
	[DefaultValue] [varchar](100) NULL,
	[Justification] [varchar](6) NULL,
	[Visible] [bit] NULL,
	[Notes] [varchar](250) NULL,
	[FI_Header_ID] [int] NULL
) ON [PRIMARY]
END

if exists (select * from sysobjects where id = object_id(N'[FOL_TRAN_INSERT_F_CALCAMT]') and OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [FOL_TRAN_INSERT_F_CALCAMT]
GO

CREATE  TRIGGER [dbo].[FOL_TRAN_INSERT_F_CALCAMT] ON [dbo].[FOL_TRAN]
AFTER INSERT
AS

-- (c) Business Careware Ltd 2012
-- 
--       Script Name : FOL_TRAN_INSERT_F_CALCAMT
--      
--            Author : Martin Baud 
-- 
--      Date Created : 20th September 2012
-- 
--  Expected outcome : Calculates new field value [FOL_TRAN].[F_CALCAMT]
--                     from [FOL_TRAN].[F_VALUE] & [FOL_TRAN].[F_VAT_AMT]
--                     depending on [CBCF].[CF_VAT_INC]
--  

DECLARE
  @VAT_INC INT,
  @TRAN_NO varchar(7), 
  @VALUE FLOAT,
  @VAT_AMT FLOAT,
  @CAL_CAMT FLOAT
  
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    Select @VAT_INC   = (SELECT CF_VAT_INC from CBCF )
    Select @TRAN_NO   = (SELECT F_TRANNO   from inserted )
    Select @VALUE     = (SELECT F_VALUE    from inserted )
    Select @VAT_AMT   = (SELECT F_VAT_AMT  from inserted )
    
    
    IF @VAT_INC = 1 
        SET @CAL_CAMT = @VALUE - @VAT_AMT  /* GROSS amount held in F_VALUE so write NET value to F_CALCAMT */
    ELSE
		SET @CAL_CAMT = @VALUE + @VAT_AMT  /* NET amount held in F_VALUE so write GROSS value to F_CALCAMT */

		
    /* Set value */
    UPDATE FOL_TRAN SET F_CALCAMT = @CAL_CAMT
     WHERE F_TRANNO = @TRAN_NO

END

GO

IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'F_CALCAMT'
     and sysobjects.id = syscolumns.id
     and sysobjects.name = 'FOL_TRAN') = 0
BEGIN

ALTER TABLE FOL_TRAN ADD F_CALCAMT FLOAT NULL

END
GO


/****** Object:  Table [dbo].[RM_LINK]    Script Date: 16/09/2016 13:34:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If exists(select * from sys.tables where name = 'RM_LINK') begin
	print 'Table RM_Link already exists'
	print 'Dropping properties'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_VALUE'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_LINKTYPE'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_RMABBR'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_TYPE'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_ID'
end
else begin
	CREATE TABLE [dbo].[RM_LINK](
		[RLK_ID] [int] IDENTITY(1,1) NOT NULL,
		[RLK_TYPE] [char](1) NOT NULL,
		[RLK_RMABBR] [varchar](10) NOT NULL,
		[RLK_LINKTYPE] [varchar](10) NOT NULL,
		[RLK_VALUE] [varchar](50) NULL
	) ON [PRIMARY]
end
Go
	SET ANSI_PADDING OFF
	GO
	print 'Creating properties for RM_LINK'
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A system generated unique ID (integer)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_ID'
	GO
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'R for Conference rooms A for Accomodation' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_TYPE'
	GO
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The room abbreviation maps to RM_ABBR in Rooms or RM_NUM in Arooms' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_RMABBR'
	GO
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The Link Type from a code in Sys_abbr with the Type RLU' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_LINKTYPE'
	GO
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Whatever Value we want to store ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RM_LINK', @level2type=N'COLUMN',@level2name=N'RLK_VALUE'
	GO



