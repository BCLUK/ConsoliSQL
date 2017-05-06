SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Liam Toohey
-- Create date: 19/06/2014
-- Description:	Get recurrence pattern from Outlook Add-In and call seperate functions to return dates list
-- =============================================
CREATE PROCEDURE [dbo].[usp_outlookAddin_CheckBookForPattern]
	
	@StartDate varchar(20),
	@EndDate varchar(20), 
	@StartTime varchar(6), 
	@EndTime varchar(6), 
	@ReccurenceType int, 
	@Instance int, 
	@Occurence int, 
	@DayOfWeek int, 
	@DayOfMonth int, 
	@MonthOfYear int, 
	@Interval int, 
	@Room varchar(50),
	@Username varchar(50)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 declare @DropTable nvarchar(400)
 set @DropTable = 'Drop Table ' + @Username + '_BookingResults'

if (Select count(*) from sys.objects where name =  @username + '_BookingResults') > 0 exec sp_executesql @DropTable

 declare @TableString nvarchar(4000) 
 set @TableString ='create table ' + @Username + '_BookingResults ' + 

'(
    ID int, 
	BookingDate Datetime,
	Availabilty Smallint
)'

exec sp_executesql @TableString


declare @functiontoCall Varchar(50)
	set @functiontocall = (SELECT CASE @ReccurenceType
           WHEN 0 then 'utf_test_for_daily'
		   WHEN 1 then 'utf_test_for_weekly'
		   WHEN 2 then 'utf_test_for_monthly'
		   WHEN 3 then 'utf_test_for_nth_monthly'
		   WHEN 5 then 'utf_test_for_yearly'
		   WHEN 6 then 'utf_test_for_nth_yearly'
		else ''    
       END )

	declare @SQLString nvarchar(4000)
	set @SQLString = 'INSERT INTO ' + @Username + '_BookingResults SELECT * from dbo.' + @functiontocall + 

	'(''' +
	@StartDate +''',''' +
	@EndDate + ''',''' +
	@StartTime + ''',''' + 
	@EndTime + ''',' +  
	Cast(@ReccurenceType as Varchar(5)) + ',' + 
	Cast(@Instance as Varchar(5)) + ',' + 
	Cast(@Occurence as Varchar(5)) + ',' +  
	Cast(@DayOfWeek as Varchar(5)) + ',' +  
	Cast(@DayOfMonth as Varchar(5)) + ',' + 
	Cast(@MonthOfYear as Varchar(5)) + ',' + 
	Cast(@Interval as Varchar(5)) + ',''' + 
	@Room +
	''')'

	exec (@SQLString)
END
