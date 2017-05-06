SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Peter Green
-- Create date: 14th July 2014
-- Description:	Books a room for multiple dates provided in a table
-- =============================================
CREATE PROCEDURE [dbo].[usp_outlookAddin_BookMultipleDates] 
	-- Add the parameters for the stored procedure here
	@TableName Varchar(50) = '', 
	@book_sessno varchar(7),
	@MBR_No varchar(10),
	@book_day datetime,
	@book_start varchar(5),
	@book_end varchar(5),
	@book_room varchar(6),
	@book_status varchar(6),
	@book_use varchar(6),
	@book_covers int,
	@f_startdatetime datetime,
	@f_enddatetime datetime,
	@book_purpose varchar(50),
	@sender_hr_id varchar(31),
	@book_room_result varchar(7) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @temptable TABLE (ID int, Bookingdate datetime, [Availability] smallint)
	declare @sql1 varchar(4000)
	declare @bookingdate datetime
	declare @RC varchar(200)

	SET @Sql1 = 'Insert into  @Temptable Select * from ' + @TableNAme + ' where [Availability] = 1'
	Exec(@SQl1)

	declare mycur cursor fast_forward for select Bookingdate from @temptable
	open mycur
	fetch next from mycur into  @BookingDAte
	While @@Fetch_status = 0 begin

		EXECUTE @RC = [dbo].[usp_outlookAddin_BookRoom] @book_sessno, @MBR_No,@Bookingdate,@book_start,@book_end,@book_room,@book_status,@book_use,@book_covers,@f_startdatetime,@f_enddatetime,@book_purpose,@sender_hr_id,@book_room_result OUTPUT
		fetch next from mycur into  @BookingDAte

	End
	close mycur
	deallocate mycur
--	SELECT @TableName, @p2
END