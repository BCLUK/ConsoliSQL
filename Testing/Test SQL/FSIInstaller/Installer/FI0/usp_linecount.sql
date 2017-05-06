/****** Object:  StoredProcedure [dbo].[usp_linecount]    Script Date: 26/09/2016 10:18:44 ******/
if exists(select object_id from sys.objects where name = 'usp_linecount') begin
	DROP PROCEDURE [dbo].[usp_linecount]
end
GO

/****** Object:  StoredProcedure [dbo].[usp_linecount]    Script Date: 26/09/2016 10:18:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_linecount]
-- Add the parameters for the stored procedure here
--@NewInvoice varchar(50)='',
--@TranNo varchar(50)='',
--@lineNo int  output
@InputPar varchar(50)='',  -- 1 means zero it any other no means increment
@InputPar1 varchar(50)='',	-- is the Finance Export Table table this relates to which become the Section in xCAbs_Config
@OutputVar varchar(50)='' output	-- is the line number now

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- expects InputPar to be 1 (new Invoice) or n  linenumber
-- expects the table name passed as InputPAr1 

    IF NOT EXISTS(SELECT * FROM xCABS_CONFIG_TABLE WHERE [section]= @InputPar1 AND [KEY]='CurrentInvLine')
    INSERT INTO  xCABS_CONFIG_TABLE ([type], [source], [section], [key], [value], [deleted], [change_by], [change_utc]) values('S', '', @InputPar1, 'CurrentInvLine', 0, 0, 'cabs', getdate())
    ELSE IF @InputPar<>'1'
    UPDATE xCABS_CONFIG_TABLE SET [VALUE]= CONVERT(VARCHAR, CONVERT(INT, [VALUE]) + 1) WHERE [SECTION]=@InputPar1  AND [key]='CurrentInvLine'
    ELSE IF @InputPar='1'
    UPDATE xCABS_CONFIG_TABLE SET [VALUE]= 0 WHERE [SECTION]=@InputPar1  AND [key]='CurrentInvLine'
    
    SELECT @OutputVar=[VALUE] FROM xCABS_CONFIG_TABLE  WHERE [SECTION]=@InputPar1 AND [key]='CurrentInvLine'    
END


GO
