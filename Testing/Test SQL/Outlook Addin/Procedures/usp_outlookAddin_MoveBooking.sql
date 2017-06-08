-- =============================================
-- Author:		Corey Bradford
-- Create date: 09 - 06 - 2016
-- Description:	<Description,,>
-- =============================================
create PROCEDURE usp_outlookAddin_MoveBooking
	-- Add the parameters for the stored procedure here
	@Impkey varchar( 35 ),
	@FuncRef varchar( 7 ),
	@Room varchar( 7 ),
	@BookDesc varchar( 50 ),
	@RoomUse varchar( 6 ),
	@Covers int,
	@UTCStart DateTime,
	@UTCEnd DateTime
AS
BEGIN
	if( [dbo].[uf_isRoomFree]( @Room, @UTCStart, @UTCEnd, '' ) = 1 )
	begin
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;
	
		declare @daysDiff int
		declare @hoursDiff int
		declare @minsDiff int
		declare @minsDiffToAdd int

		declare @roomLocation varchar(10)

		declare @currentStart datetime

		set @currentStart = ( select F_STARTDATETIME from FUNC_FIL where F_REF = @FuncRef );

		set @daysDiff = datediff( day, @currentStart, @UTCStart );
		set @hoursDiff = datediff( hour, @currentStart, @UTCStart );
		set @minsDiffToAdd = datediff( minute, @currentStart, @UTCStart );

		set @minsDiff = @minsDiffToAdd - ( @hoursDiff * 60 );
		set @hoursDiff = @hoursDiff - ( @daysDiff * 24 );

		set @roomLocation = ( select RM_LOC from ROOMS where RM_ABBR = @Room );

		BEGIN TRANSACTION
		update FUNC_FIL
			set F_CUT = 1
			where F_REF = @FuncRef;

		update FUNC_FIL
			set F_ROOM = @Room,
				F_COMMENT = @BookDesc,
				F_USE = @RoomUse,
				F_PAX_ACT = @Covers,
				F_PAX_MIN = @Covers,
				F_PAX_GTD = @Covers,
				F_START = [dbo].[fn_Format_CABS_Time]( [dbo].[uf_GetLocalDateTime]( @roomLocation, @UTCStart ) ),
				F_END = [dbo].[fn_Format_CABS_Time]( [dbo].[uf_GetLocalDateTime]( @roomLocation, @UTCEnd ) ),
				F_DAY = [dbo].[uf_DatetimefromParts]( datepart( year, @UTCStart ), datepart( month, @UTCStart ), datepart( day, @UTCStart ), 0 ),
				F_STARTDATETIME = @UTCStart,
				F_ENDDATETIME = @UTCEnd
			where F_REF = @FuncRef;

		--EXECUTE  [dbo].[usp_ChangeAllExtras] @FuncREF,@UTCStart,@MinsDiffToAdd,@HoursDiff,@MinsDiff,@covers

		update AI_FILE
			set AI_GEDATE = [dbo].[uf_DatetimefromParts]( datepart( year, @UTCStart ), datepart( month, @UTCStart ), datepart( day, @UTCStart ), 0 ),
				AI_STARTDATETIME = dateadd( minute, @minsDiffToAdd, AI_STARTDATETIME ),
				AI_ENDDATETIME = dateadd( minute, @minsDiffToAdd, AI_ENDDATETIME ),
				AI_TIME = [dbo].[uf_cabs_ModifyTime]( AI_TIME, @hoursDiff, @minsDiff ),
				AI_ENDTIME = [dbo].[uf_cabs_ModifyTime]( AI_ENDTIME, @hoursDiff, @minsDiff )
			where AI_FREF = @FuncRef;

		update AI_FILE
			set AI_COVERS = @Covers
			where AI_FREF = @FuncRef and AI_RES = 0

		update FUNC_FIL
			set F_CUT = 0
			where F_REF = @FuncRef;
		COMMIT TRANSACTION
	end
END
