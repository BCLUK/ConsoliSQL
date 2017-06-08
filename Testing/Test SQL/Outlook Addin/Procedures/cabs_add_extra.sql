SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE  PROCEDURE [dbo].[cabs_add_extra]
( 	
	@AiPrikey varchar(10),
	@func_ref varchar(7),
	@extra_time varchar(5),
	@extra_covers money,
	@extra_notes varchar(255), 
	@booked_id varchar(31),			/* CABS operator that made the booking */	 
	@extra_code varchar(6),
	@extra_endtime varchar(5),
	@extra_charge numeric( 9, 2),
	@extra_cback varchar(50),
	@extra_credit varchar(50),
	@extra_canpost varchar(3),
	@ExtraStartDateTime datetime,
	@ExtraEndDateTime datetime
)



/*
	BCL
		SAK 28Feb2007 - Update parameter @booked_id from varchar(8) to varchar(31)

		SAK 01Mar2007 - Added function endtime check to avoid extras times over-running 
						their booking times

		SAK 28Aug2007 - When this procedure was changed to no longer handle MBR/Global extras
						the location check for a booking's room was no longer in place.  I have 
						added this back in to ensure that the correct location code is set for
						extras in the extras monitor

		SAK 28Jan2008 - Ignore provisional status bookings in resource count.

*/
AS



	declare @extra_num integer  /* Extra prikey key value, stored in CBCF */
	declare @formatted_ai_no varchar(10)
	declare @func_day datetime /* Function date */
	declare @func_start varchar(5) /* Function end time */
	declare @func_end varchar(5) /* Function end time */
	declare @func_internal int
	declare @func_loc varchar(6) 
	declare @func_status varchar(6) 
	 
	declare
	@RetVal int

begin
	set @extra_num = 0

	set @func_day = (select F_DAY from FUNC_FIL where F_REF = @func_ref)
	set @func_status = (select F_STATUS from FUNC_FIL where F_REF = @func_ref)

	if not @func_day is null
	begin
-- SAK: 18Sep2007 - Now passed through as params due to timezone problems
--	  set @ExtraStartDateTime = convert( datetime, convert( varchar(10), @func_day, 103 ) + ' ' + @extra_time, 103 )
--	  set @ExtraEndDateTime = convert( datetime, convert( varchar(10), @func_day, 103 ) + ' ' + @extra_endtime, 103 )

		-- Check Resources if not a provisional booking
	if @func_status = 'PROVNL'
		set @RetVal = 0
	else
		exec @RetVal = cabs_check_resources 	@AiPrikey,
											@extra_code, 
											@ExtraStartDateTime,
											@ExtraEndDateTime,
											@extra_covers
	end -- found function date


if @RetVal >= 0
	begin
		If (@extra_code = '') or (@extra_code is null)
    	select @extra_code = 'ATT'

		-- Check function exisits
		If (@func_ref like 'M%') or (select count(*) from FUNC_FIL where F_REF = @func_ref) > 0
		begin
		-- Get owner function values
		set @func_start = (select F_START from FUNC_FIL where F_REF = @func_ref)
		set @func_end = (select F_END from FUNC_FIL where F_REF = @func_ref)
    	set @func_internal = (select F_INTERN from FUNC_FIL where F_REF = @func_ref)

		-- Get room location
		set @func_loc = (select RM_LOC from ROOMS, FUNC_FIL where RM_ABBR = F_ROOM and F_REF = @func_ref)
		-- Pad room loc out to 6 chars
		set @func_loc = substring( @func_loc + '      ', 1, 6 )

		-- can't book an extra before the booking starts
		if @extra_time < @func_start 
			set @extra_time = @func_start

		if @extra_endtime > @func_end
			set @extra_endtime = @func_end

		If @extra_charge = 0 
		Begin
    		If @func_internal = 1
			begin
				-- check for a value in POST_DEF_CONFIG
		       	set @extra_charge = (select PC_INT_CHARGE from POST_DEF_CONFIG where PC_LOC = @func_loc and PC_CODE = @extra_code)
				if @extra_charge is null
			       	set @extra_charge = (select P_IN_CHRGE from POST_DEF where P_CODE = @extra_code)
			end
			Else
			begin
		       	set @extra_charge = (select PC_CHARGE from POST_DEF_CONFIG where PC_LOC = @func_loc and PC_CODE = @extra_code)
				if @extra_charge is null    	   
					set @extra_charge = (select P_ST_CHRGE from POST_DEF where P_CODE = @extra_code)
			end
		End

		set @extra_num = @AiPrikey
--      set @extra_num = (select AI_PRIKEY from AI_FILE where AI_FREF = @func_ref and AI_CODE = @extra_code) -- See if the extra already exists

		if @extra_num is null or @extra_num = ''
			begin
				-- adding an extra
				exec @extra_num = cabs_get_next_num 0

				if @extra_num > 0 -- Check we got a valid extra number
				begin
					exec cabs_format_system_no 'A', @extra_num, @formatted_ai_no OUTPUT

					insert into AI_FILE
						(AI_PRIKEY, AI_FREF, AI_CODE, AI_TIME, AI_TEXT, AI_EDATE, AI_COVERS, AI_CHARGE,
						AI_OPID, AI_GEDATE, AI_VATCODE, AI_POSTED, AI_LCS, AI_ROOM, AI_MONDATE,
						AI_MONOP, AI_RES, AI_REQD, AI_CHARGEBK, AI_CREDIT, AI_LOCCODE, AI_OPSHEET,
						AI_ENDTIME, AI_CANPOST, AI_STARTDATETIME, AI_ENDDATETIME)
					values 
						( @formatted_ai_no, @func_ref,  @extra_code, @extra_time, @extra_notes, getdate(), @extra_covers, @extra_charge,
						@booked_id, @func_day, 2, 0, 0, '', NULL,
						NULL, 0, 1, @extra_cback, @extra_credit, @func_loc + @extra_code, '',
						@extra_endtime, @extra_canpost, @ExtraStartDateTime, @ExtraEndDateTime
						)

				insert into MONITOR
					(MON_PRIKEY, MON_FREF, MON_CODE, MON_TIME, MON_TEXT, MON_EDATE, MON_COVERS, MON_CHARGE, MON_OPID, MON_GEDATE,
					MON_VATCODE, MON_POSTED, MON_LCS, MON_ROOM, MON_MONDATE, MON_MONOP, MON_RES, MON_REQD, MON_DATE, MON_DELETED,
					MON_LOCCODE, MON_ENDTIME)
				select
					AI_PRIKEY, AI_FREF, AI_CODE, AI_TIME, AI_TEXT, AI_EDATE, AI_COVERS, AI_CHARGE, AI_OPID, AI_GEDATE,
					AI_VATCODE, AI_POSTED, AI_LCS, AI_ROOM, null, '', AI_RES, AI_REQD, AI_GEDATE, 0,
					AI_LOCCODE, AI_ENDTIME
				from
					AI_FILE
				where
					AI_PRIKEY = @formatted_ai_no
				
			end /* Valid Extra number */
       		end /* New extra ? */
		else
			begin -- we're updating the extra
				update 
					AI_FILE
				set 
					AI_TIME = @extra_time,
					AI_TEXT = @extra_notes,
					AI_EDATE = getdate(),
					AI_COVERS = @extra_covers,
					AI_OPID = @booked_id,
					AI_GEDATE = @func_day,
					AI_ENDTIME = @extra_endtime,
					AI_CHARGEBK = @extra_cback,
					AI_CREDIT = @extra_credit,
					AI_CANPOST = @extra_canpost,
					AI_STARTDATETIME = @ExtraStartDateTime,
					AI_ENDDATETIME = @ExtraEndDateTime
				where
					AI_PRIKEY = @extra_num

				update 
					MONITOR
				set 
					MON_TIME = AI_TIME,
					MON_TEXT = AI_TEXT,
					MON_EDATE = AI_EDATE,
					MON_COVERS = AI_COVERS,
					MON_CHARGE = AI_CHARGE,
					MON_OPID = AI_OPID,
					MON_GEDATE = AI_GEDATE,
					MON_VATCODE = AI_VATCODE,
					MON_POSTED = AI_POSTED,
					MON_MONDATE = NULL,
					MON_MONOP = '',
					MON_RES = AI_RES,
					MON_REQD = AI_REQD,
					MON_DATE = AI_GEDATE,
					MON_DELETED = 0,
					MON_LOCCODE = AI_LOCCODE,
					MON_ENDTIME = AI_ENDTIME
				from
					AI_FILE
				where
					MON_PRIKEY = @extra_num and
					AI_PRIKEY = MON_PRIKEY
			end -- adding the extra
		end
	else
    	set @extra_num = -2 -- the booking doesn't exist

	If @extra_num is null
    	set @extra_num = -1
	end
else
	set @extra_num = -3

return @extra_num /* returns negative if errors (standard SQL error codes apply),
						or positive AI_FILE.AI_PRIKEY value if sucessfull. */

end