SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[usp_outlookAddin_BookRoom]
@Book_sessno varchar(7),
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

SET NOCOUNT ON; 

DECLARE @RC int
DECLARE @func_ref varchar(7) = ''
DECLARE @book_max int = 100
DECLARE @book_min int = 0
DECLARE @book_forecast int = 0
DECLARE @book_cback varchar(50) = ''
DECLARE @book_credit varchar(50)= ''
DECLARE @book_matter varchar(50)= ''
DECLARE @booked_id varchar(31)= ''
DECLARE @book_internal int = 0 

if isnull(@book_status,'') = '' begin
	EXECUTE @book_status = [dbo].[xCABS_CONFIG_ReadString] 
   'G'
  ,'Outlook'
  ,'DefaultRoomStatus'
end
-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[cabs_book_room_fromMBR] 
   @func_ref
  ,@MBR_No
  ,@book_day
  ,@book_start
  ,@book_end
  ,@book_room
  ,@book_status
  ,@book_use
  ,@book_covers
  ,@book_max
  ,@book_min
  ,@book_forecast
  ,@book_cback
  ,@book_credit
  ,@book_matter
  ,@sender_hr_id
  ,@booked_id
  ,@book_purpose
  ,@book_internal
  ,@book_sessno
  ,@f_startdatetime
  ,@f_enddatetime
  ,@book_room_result OUTPUT

Select @book_room_result


END