SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create view [dbo].[Vw_OutlookMBRSelect]
as 
select TOP 100 percent MBR_SYSNO, MBR_CMPNAM + ', ' + MBR_ADDR1 as NAME, MBR_IMPKEY from MBRFILE 
where ISNULL( MBR_CMPNAM, '' ) <> ''
	and ISNULL( MBR_ADDR1, '' ) <> ''
	and MBR_INTERN = 1 and MBR_sysno <> MBR_IMPKEY
order by MBR_CMPNAM