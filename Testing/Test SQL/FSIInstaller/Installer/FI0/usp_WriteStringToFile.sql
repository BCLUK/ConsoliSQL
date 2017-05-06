
/****** Object:  StoredProcedure [dbo].[usp_WriteStringToFile]    Script Date: 26/09/2016 10:20:45 ******/
if exists(select object_id from sys.objects where name = 'usp_WriteStringToFile') begin
	DROP PROCEDURE [dbo].[usp_WriteStringToFile]
end
GO

/****** Object:  StoredProcedure [dbo].[usp_WriteStringToFile]    Script Date: 26/09/2016 10:20:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_WriteStringToFile]
 (
@String Varchar(max), --8000 in SQL Server 2000
@Path VARCHAR(255),
@Filename VARCHAR(100),
@initialValue int
--
)
AS
DECLARE  @objFileSystem int
        ,@objTextStream int,
		@objErrorObject int,
		@strErrorMessage Varchar(1000),
	    @Command varchar(1000),
	    @hr int,
		@fileAndPath varchar(400)

set nocount on

SET CONCAT_NULL_YIELDS_NULL OFF

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT

--Select @FileAndPath=@path+'\'+@filename
Select @FileAndPath=@path+@filename
/*
<%
 dim fs
 set fs=Server.CreateObject("Scripting.FileSystemObject")
 if fs.FileExists("c:\asp\introduction.asp")=true then
   response.write("File c:\asp\introduction.asp exists!")
 else
   response.write("File c:\asp\introduction.asp does not exist!")
 end if
 set fs=nothing
 %>
*/
if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
--
--FileSystemObject.FileExists(filename)
declare	@objFSys int
declare @i int
exec sp_OACreate 'Scripting.FileSystemObject', @objFSys out
exec sp_OAMethod @objFSys, 'FileExists', @i out, @FileAndPath
PRINT '@i'
PRINT @i

if @i = 1 OR  @initialValue>0
BEGIN
	if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'OpenTextFile'
		, @objTextStream OUT, @FileAndPath,8,0
END
ELSE
	if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
		, @objTextStream OUT, @FileAndPath,2,0

if @HR=0 Select @objErrorObject=@objTextStream, 
	@strErrorMessage='writing to the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Write', Null, @String

if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'

if @hr<>0
	begin
	Declare 
		@Source varchar(255),
		@Description Varchar(255),
		@Helpfile Varchar(255),
		@HelpID int
	
	EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
		@source output,@Description output,@Helpfile output,@HelpID output
	Select @strErrorMessage='Error whilst '
			+coalesce(@strErrorMessage,'doing something')
			+', '+coalesce(@Description,'')
	raiserror (@strErrorMessage,16,1)
	end
EXECUTE  sp_OADestroy @objTextStream
EXECUTE sp_OADestroy @objTextStream

exec sp_OADestroy @objFSys 

SET CONCAT_NULL_YIELDS_NULL ON

GO

