IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'utf_ExportMappingInfo') begin
	Drop Function utf_ExportMappingInfo
END
Go

/****** Object:  UserDefinedFunction [dbo].[utf_ExportMappingInfo]    Script Date: 27/09/2016 00:28:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Green
-- Create date: 21st Nov 2015
-- Description:	Returns all info on export template and mappings as a single table for export calcs
-- Updates:	1 May 2016 amended to add INV Summary
-- =============================================
CREATE FUNCTION [dbo].[utf_ExportMappingInfo] 
(
	-- Add the parameters for the function here
	@TableName varchar(100),
	@sub_module Varchar(100),
	@LineType varchar(20)
)
RETURNS 
@Table_Var TABLE 
(
	-- Add the column definitions for the TABLE variable here
	[ID] int ,
	[Name] varchar(20) ,
	[Type] varchar(20) ,
	[Description] varchar(150) ,
	[StartPos] int ,
	[EndPos] int ,
	[FieldLength] int,
	[FillCharacter] smallint ,
	[Delimiter] smallint ,
	[DecPointReq] bit ,
	[DefaultValue] varchar(100) ,
	[Justification] varchar(6) ,
	[FI_Header_ID] int,
	Module Varchar(50),
	SubModule Varchar(50),
	LineType Varchar(50),
	Column_Name Varchar(100), 
	ORDINAL_POSITION Int,
	Data_Type Varchar(20),
	CHARACTER_MAXIMUM_LENGTH int,
	FI_CABS_FIELD varchar(50), 
	MappedFields bit, 
	LookUpTable Varchar(50), 
	LookUpColumn Varchar(50),
	LookupField Varchar(50) 
	)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
Insert into @TAble_Var select ID,Name,[Type],[Description],StartPos,EndPos,(endpos-startpos+1) as FieldLength, 
FillCharacter,isnull(Delimiter,'') as Delimiter,DecPointReq,Isnull(DefaultValue,'') as defaultvalue,Justification,
FI_Header_ID, Module, SubModule, LineType, Column_Name, ORDINAL_POSITION,Data_Type,CHARACTER_MAXIMUM_LENGTH, FI_CABS_FIELD, MappedFields, LookUpTable, LookUpColumn,
Case LookUpTable when 'FOL_TRAN' then 'F_TRANNO'
							when 'MBRFILE' then 'MBR_SYSNO'
							when 'AI_FILE' Then 'AI_PRIKEY'
							when 'CLIENTS' then 'CL_SYSNO'
							when 'CONTACTS' then 'CT_SYSNO'
							when 'POST_DEF' then 'P_CODE'
							when 'ROOMS' then 'RM_ABBR'
							when 'AROOMS' then 'RM_NUM'
							when 'RM_LINK' then 'RLK_ID'
							when 'POST_DEF' then 'P_CODE'
							when 'vw_FOL_TRAN_SUMMARY' then 'F_TRANNO'
							when 'vw_FOL_TRAN_INV_SUMMARY' then 'F_TRANNO'
							when 'vw_FOL_TRAN_CRED_SUMMARY' then 'F_TRANNO'
							when 'vw_INVOICE_HEADER' then 'F_ONINV'
							when 'vw_CREDIT_HEADER' then 'F_ONINV'
							else 'XXXXX'
							end as LookupField 
from (select FIT.ID,Name,[Type],[Description],StartPos,EndPos,(endpos-startpos+1) as FieldLength, FillCharacter,isnull(Delimiter,'') as Delimiter,
DecPointReq,Isnull(DefaultValue,'') as defaultvalue,Justification,FI_Header_ID,FIH.Module,SubModule,LineType,
ISC.*, 
FMF.FI_CABS_FIELD, case isnull(FI_CABS_FIELD,'') when '' then 0 else 1 end as MappedFields, substring(FI_CABS_FIELD,1,charindex('.',FI_CABS_FIELD)-1) as LookUpTable,  substring(FI_CABS_FIELD,charindex('.',FI_CABS_FIELD)+1,99) as LookUpColumn
from INFORMATION_SCHEMA.columns ISC
inner join FI_Template FIT on FIT.Name = ISC.COLUMN_NAME
inner join FI_Header FIH on FIH.ID  = FIT.FI_Header_ID and SubModule = @Sub_Module and LineType = @LineType
left outer join FI_MAPPED_FIELDS FMF on FI_FINANCE_FIELD = FIT.ID
where TABLE_NAME = @TableName 
) as tempStruc order by FI_Header_ID, StartPos
	
	RETURN 
END

GO


