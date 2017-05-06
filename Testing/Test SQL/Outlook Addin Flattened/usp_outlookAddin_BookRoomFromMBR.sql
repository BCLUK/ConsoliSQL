SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE  PROCEDURE [dbo].[usp_outlookAddin_BookRoomFromMBR]( 
				@func_ref varchar(7),
				@MBR_No varchar(10), 		/* Meeting Host */
				@book_day datetime,
				@book_start varchar(5),		/* 24Hr Clock */
				@book_end varchar(5),		/* 24Hr Clock */
				@book_room varchar(6),
				@book_status varchar(6),
				@book_use varchar(6),		/* Currently only 'MEET' will be passed through here */
				@book_covers integer,			/* Must be > 0 */
				@book_max integer,			/* max, min and forecast used for PwC split billing */
				@book_min integer,			
				@book_forecast integer,			
				@book_cback varchar(50),
				@book_credit varchar(50),
				@book_matter varchar(50),
				@sender_hr_id varchar(31),		/* Booker of the room, assistant etc. of host */
				@booked_id varchar(31),		/* CABS operator that made the booking */
				@book_purpose varchar(50),
				@book_internal int,
				@book_sessno varchar(7),
				@f_startdatetime datetime,
				@f_enddatetime datetime,
				@book_room_result varchar(7) OUTPUT	/* -1 = Availability conflict, -2 = Host not found */
					)
AS
	/*
		BCL
			01Mar2007 - SAK: Added check to clear a visitors carpark ref when a carpark booking is deleted
			13Sep2007 - SAK: 
							@book_day, @book_start and @book_end are all local room times
							@F_StartDatetime and @F_EndDatetime are UTC booking date and times
			14June2013 - MCB: Added OP_ID Updates to Existing Bookings.							
	*/
	declare
		@was_multi int,
		@is_multi int,
		@old_room varchar(6)

	declare @section_room varchar(6)
	declare @func_num integer
	declare @formatted_func_no varchar(20)
--	 declare @mbr_no varchar(7)
	declare @func_owner varchar(7)
	declare @mbr_plcode varchar(20)
	declare @mbr_name varchar(100)
	declare @mbr_no_result integer
	declare @av_ok integer
	declare @room_charge float
	declare @dummy_room int
	declare @f_booker varchar(31)

	set @f_booker = @sender_hr_id

	/* Auto extras */
	declare 
		@auto_extra_code varchar(6), 
		@auto_extra_in_charge float,
		@auto_extra_charge float, 
		@auto_extra_fixed int, 
		@auto_extra_reqd float,
		@auto_extra_text varchar(255),
		@auto_extra_use_charge float

	declare
		@func_setup varchar(5),
		@func_bdown varchar(5)

	declare
		@old_day datetime,
		@old_start varchar(5),
		@old_end varchar(5),
		@old_covers int,
		@old_loc varchar(6),
		@new_loc varchar(6)
			
begin

if @func_ref is null
	set @func_ref = ''

If @book_status = '' or @book_status is null
	set @book_status = 'PROVNL'

set @func_setup = (select US_SETUP from RM_USE where US_RM_CODE = @book_room and US_RM_USE = @book_use)
set @func_bdown = (select US_BDOWN from RM_USE where US_RM_CODE = @book_room and US_RM_USE = @book_use)

if @func_setup is null or @func_setup = '' or datalength( ltrim(rtrim(@func_setup)) ) <> 5
	set @func_setup = '00:00'


if @func_bdown is null or @func_bdown = '' or datalength( ltrim(rtrim(@func_bdown)) ) <> 5
	set @func_bdown = '00:00'

if @func_ref <> ''
	begin
		-- get old room value
		set @old_room = (select RM_ABBR from ROOMS, FUNC_FIL where F_REF = @FUNC_REF and F_ROOM = RM_ABBR )
		set @was_multi = (select RM_MULTI from ROOMS where RM_ABBR = @old_room )
	end
else
	begin
		set @was_multi = 0
		set @old_room = ''
	end

-- Check for Multi-Rooms
set @is_multi = (select  RM_MULTI from ROOMS where RM_ABBR = @book_room)
if @is_multi = 1
	begin
		set @av_ok = -1

		declare 
			multi_room_cursor 
		cursor for
			select 
				M_SECT 
			from 
				MULTIRMS, ROOMS
			where 
				M_ROOM = RM_ABBR AND M_ROOM = @book_room

		open multi_room_cursor

		fetch next from 
			multi_room_cursor 
		into 
			@section_room

		while @@FETCH_STATUS = 0
		begin
			/* pass UTC date time values through to check_av
			exec @av_ok = cabs_check_av @func_ref, @book_day, @section_room, @book_start, @book_end, @func_setup, @func_bdown
			*/
			exec @av_ok = cabs_check_av @func_ref, @f_startdatetime, @f_enddatetime, @section_room, @func_setup, @func_bdown
			if @av_ok = -1
				BREAK

			fetch next from 
				multi_room_cursor 
			into 
				@section_room
		end

		close multi_room_cursor
		deallocate multi_room_cursor

	end /* Multi room av check */
else
	set @av_ok = 1

/* Section rooms OK - Check main room */
if @av_ok = 1
begin
	set @av_ok = -1

	-- no av checking for dummy rooms
	set @dummy_room = (select count(*) from ROOMS where RM_ABBR = @book_room and RM_COMMENT = 'DUMMY')

	exec @av_ok = cabs_check_av @func_ref, @f_startdatetime, @f_enddatetime, @book_room, @func_setup, @func_bdown

	if @dummy_room = 1
		set @av_ok = 1

	If @av_ok > 0
	begin
--		exec @mbr_no_result = cabs_get_mbr_no @host_hr_id, @mbr_no OUTPUT

		select 
			@mbr_name = (select isnull(MBR_CMPNAM, "") + ',' + isnull(MBR_ADDR1, "") + ',' + isnull(MBR_ADDR2, "")
		from 
			MBRFILE where MBR_SYSNO = @mbr_no)

		if not @mbr_no is Null
			begin

				if @func_ref = ''
				begin

					if @book_cback = '<default>'
						set @book_cback = (select MBR_CBACK from MBRFILE where MBR_SYSNO = @mbr_no)
		
					if @book_credit = '<default>'
						set @book_credit = (select MBR_CREDIT from MBRFILE where MBR_SYSNO = @mbr_no)

					exec @func_num = cabs_get_next_num 1
					/* select @func_num */
		
					exec cabs_format_system_no 'F', @func_num, @formatted_func_no OUTPUT
					/* select @formatted_func_no */

					/* Calculate room charge - Lehman do not use hourly charges */
					If (select count(*) from RM_USE where US_RM_CODE = @book_room and US_RM_USE = @book_use) > 0 
        				Begin
							If @book_internal = 1
								set @room_charge = (select US_RM_CHG1 from RM_USE where US_RM_CODE = @book_room and US_RM_USE = @book_use)
							Else
								set @room_charge = (select US_RM_CHG from RM_USE where US_RM_CODE = @book_room and US_RM_USE = @book_use)
		      			End
					Else
						set @room_charge = 0
		
					if (select  RM_MULTI from ROOMS where RM_ABBR = @book_room) = 1
						set @func_owner = @formatted_func_no
					else
						set @func_owner = ''

					insert into FUNC_FIL
					(
						F_REF, F_ROOM, F_RM_CHG, F_DAY, F_START, F_END, F_USE, F_STATUS,
						F_MBR_NO, F_PAX_GTD, F_PAX_ACT, F_PAX_MIN, F_OPID, F_OWNER,
						F_VATCODE, F_POSTED, F_SITDOWN, F_PKG, F_ACT, F_DATESTMP, F_CBACK, F_CREDIT,
						F_COMMENT, F_TICKET, F_FORECAST, F_INPROG, F_FINISHED, F_MATTER,
						F_SETUP, F_BDOWN, F_INTERN, F_MBR_NAME, F_LOCKED, F_SESSNO,
						F_CUT, F_OFFRM, F_SOLEUSE, F_REST, F_BOOKER, F_CANPOST,
						F_STARTDATETIME,F_ENDDATETIME, F_RMGIVEN
					)
					values
					(
						@formatted_func_no, @book_room, @room_charge, @book_day, @book_start, @book_end, @book_use, @book_status,
						@mbr_no, @book_max, @book_covers, @book_min, @booked_id, @func_owner,
						2, 0, '00:00', '', 0, getdate(), @book_cback, @book_credit,
						@book_purpose, 0, @book_forecast, 0,0, @book_matter,
						@func_setup, @func_bdown, @book_internal, @mbr_name, 0, @book_sessno,
						0, 0, 'Yes', 'No', @F_Booker, 'Yes',
						@f_StartDateTime, @f_EndDateTime, 'No'
					)
		
					-- Book Multi Rooms
					if @func_owner <> ''
					begin
		
						declare 
							multi_room_cursor 
						cursor for
							select 
								M_SECT 
							from 
								MULTIRMS, ROOMS
							where 
								M_ROOM = RM_ABBR AND M_ROOM = @book_room
		
						open multi_room_cursor
		
						fetch next from multi_room_cursor into @section_room
		
						while @@FETCH_STATUS = 0
						begin
							exec @func_num = cabs_get_next_num 1
							exec cabs_format_system_no 'F', @func_num, @formatted_func_no OUTPUT
		
							insert into FUNC_FIL			
							(
								F_REF, F_ROOM, F_RM_CHG, F_DAY, F_START, F_END, F_USE, F_STATUS,
								F_MBR_NO, F_PAX_GTD, F_PAX_ACT, F_PAX_MIN, F_OPID, F_OWNER,
								F_VATCODE, F_POSTED, F_SITDOWN, F_PKG, F_ACT, F_DATESTMP, F_CBACK, F_CREDIT,
								F_COMMENT, F_TICKET, F_FORECAST, F_INPROG, F_FINISHED, F_MATTER,
								F_SETUP, F_BDOWN, F_INTERN, F_MBR_NAME, F_LOCKED, F_SESSNO,
								F_CUT, F_OFFRM, F_SOLEUSE, F_REST, F_BOOKER, F_CANPOST,
								F_STARTDATETIME,F_ENDDATETIME, F_RMGIVEN
							)
							values
							(
								@formatted_func_no, @section_room, @room_charge, @book_day, @book_start, @book_end, @book_use, @book_status,
								@mbr_no, @book_max, @book_covers, @book_min, @booked_id, @func_owner,
								2, 0, '00:00', '', 0, getdate(), @book_cback, @book_credit,
								@book_purpose, 0, @book_forecast, 0,0, @book_matter,
								@func_setup, @func_bdown, @book_internal, @mbr_name, 0, @book_sessno,
								0, 0, 'Yes', 'No', 'Outlook', 'Yes',
								@f_StartDateTime, @f_EndDateTime, 'No'
							)

							fetch next from 
								multi_room_cursor 
							into 
								@section_room
		  				end -- while loop for multi rooms

						close multi_room_cursor
						deallocate multi_room_cursor
		
						set @formatted_func_no = @func_owner
		
					end -- Multi rooms
		
					/* Check for and assign automatic extras */
					declare 
						auto_extra_cursor 
					cursor for
						select 
							AX_CODE, AX_INCHRGE, AX_CHARGE, AX_FIXED, AX_REQD, AX_TEXT from AUTOEXTR
						where 
							AX_RMCODE = @book_room and AX_RMUSE = @book_use
		
					open auto_extra_cursor
		
					fetch next from 
						auto_extra_cursor 
					into  
						@auto_extra_code, @auto_extra_in_charge, @auto_extra_charge,
						@auto_extra_fixed, @auto_extra_reqd, @auto_extra_text
		
					while @@FETCH_STATUS = 0
					begin
						If @auto_extra_fixed <> 1 
							set @auto_extra_reqd = (@book_covers * @auto_extra_reqd)
		
						If (@auto_extra_text = '') or (@auto_extra_text is null)
							set @auto_extra_text = 'Extra assigned automatically'
		
						If @book_internal = 1
							set @auto_extra_use_charge = @auto_extra_in_charge
						else
							set @auto_extra_use_charge = @auto_extra_charge
		
						exec cabs_add_extra 
								'',
								@formatted_func_no,
								@book_start,
								@auto_extra_reqd, 
								@auto_extra_text, 
								@booked_id, 
								@auto_extra_code, 
								@book_end, 
								@auto_extra_use_charge,
								@book_cback, 
								@book_credit,
								'No',
								@f_StartDateTime,
								@f_EndDateTime
		
						fetch next from 
							auto_extra_cursor 
						into  
							@auto_extra_code, @auto_extra_in_charge, @auto_extra_charge,
							@auto_extra_fixed, @auto_extra_reqd, @auto_extra_text
	         		end  -- autoextras while loop

					close auto_extra_cursor
					deallocate auto_extra_cursor
				end -- end new booking
				else	
				begin
					declare
						cOldFuncValues
					cursor for
						select
							F_DAY,
							F_START,
							F_END,
							F_PAX_ACT,
							RM_LOC
						from
							FUNC_FIL, ROOMS
						where
							RM_ABBR = F_ROOM and
							F_REF = @func_ref
		
					open cOldFuncValues
		
					fetch next from 
						cOldFuncValues
					into
						@old_day,
						@old_start,
						@old_end,
						@old_covers,
						@old_loc

					close cOldFuncValues
					deallocate cOldFuncValues
		
					if @old_room <> @book_room and @was_multi = 1
			   			delete from FUNC_FIL where F_OWNER = @func_ref and F_OWNER <> F_REF

					if @is_multi = 1
						set @func_owner = @func_ref
					else
						set @func_owner = ''

					-- update booking
					update 
						FUNC_FIL
					set 
						F_ROOM = @book_room, F_DAY = @book_day,
						F_START = @book_start, F_END = @book_end,
						F_MBR_NO = @mbr_no, F_MBR_NAME = @mbr_name, 
						F_PAX_ACT = @book_covers, F_CBACK = @book_cback, F_CREDIT = @book_credit,
						F_USE = @book_use, F_COMMENT = @book_purpose,
						F_PAX_GTD = @book_max, F_PAX_MIN = @book_min, F_FORECAST = @book_forecast,
						F_STATUS = @book_status, F_INTERN = @book_internal,
						F_STARTDATETIME = @f_StartDateTime,
						F_ENDDATETIME = @f_EndDateTime,
						F_OWNER = @func_owner, F_OPID = @booked_id
					where
						F_REF = @func_ref
			
					if @is_multi = 1 and (select count(F_OWNER) from FUNC_FIL where F_OWNER = @func_ref) < 2
						begin
							-- create new multi rooms
							declare 
								multi_room_cursor 
							cursor for
								select 
									M_SECT 
								from 
									MULTIRMS, ROOMS
								where 
									M_ROOM = RM_ABBR AND M_ROOM = @book_room
					
							open multi_room_cursor
		
							fetch next from 
								multi_room_cursor 
							into 
								@section_room
		
							while @@FETCH_STATUS = 0
							begin
								exec @func_num = cabs_get_next_num 1
								exec cabs_format_system_no 'F', @func_num, @formatted_func_no OUTPUT
		
								insert into FUNC_FIL			
								(
									F_REF, F_ROOM, F_RM_CHG, F_DAY, F_START, F_END, F_USE, F_STATUS,
									F_MBR_NO, F_PAX_GTD, F_PAX_ACT, F_PAX_MIN, F_OPID, F_OWNER,
									F_VATCODE, F_POSTED, F_SITDOWN, F_PKG, F_ACT, F_DATESTMP, F_CBACK, F_CREDIT,
									F_COMMENT, F_TICKET, F_FORECAST, F_INPROG, F_FINISHED, F_MATTER,
									F_SETUP, F_BDOWN, F_INTERN, F_MBR_NAME, F_LOCKED, F_SESSNO,
									F_CUT, F_OFFRM, F_SOLEUSE, F_REST, F_BOOKER, F_CANPOST,
									F_STARTDATETIME,F_ENDDATETIME, F_RMGIVEN
								)
								values
								(
									@formatted_func_no, @section_room, @room_charge, @book_day, @book_start, @book_end, @book_use, @book_status,
									@mbr_no, @book_max, @book_covers, @book_min, @booked_id, @func_owner,
									2, 0, '00:00', '', 0, getdate(), @book_cback, @book_credit,
									@book_purpose, 0, @book_forecast, 0,0, '',
									@func_setup, @func_bdown, @book_internal, @mbr_name, 0, @book_sessno,
									0, 0, 'Yes', 'No', @f_booker, 'Yes',
									@f_StartDateTime, @f_EndDateTime, 'No'
								)
		
								fetch next from multi_room_cursor into @section_room
							end

							close multi_room_cursor
							deallocate multi_room_cursor
						end
					else
	 					-- update sections rooms booking
						update 
							FUNC_FIL
						set 
							F_DAY = @book_day,
							F_START = @book_start, F_END = @book_end,
							F_MBR_NO = @mbr_no, F_MBR_NAME = @mbr_name, 
							F_PAX_ACT = @book_covers, F_CBACK = @book_cback, F_CREDIT = @book_credit,
							F_USE = @book_use, F_COMMENT = @book_purpose,
							F_PAX_GTD = @book_max, F_PAX_MIN = @book_min, F_FORECAST = @book_forecast,
							F_STATUS = @book_status, F_INTERN = @book_internal,
							F_STARTDATETIME = @f_StartDateTime,
							F_ENDDATETIME = @f_EndDateTime, F_OPID = @booked_id
						where
							F_OWNER = @func_ref and F_OWNER <> F_REF
		
					if @book_status = 'CANCEL' 
						begin -- delete extras, update monitor and delete visitors
							update
								MONITOR
							set
								MON_DELETED = 1
							from	
								AI_FILE
							where
								AI_FREF = @func_ref and AI_PRIKEY = MON_PRIKEY
			
							delete from 
								AI_FILE
							where
								AI_FREF = @func_ref
			
							-- delete visitors
							delete from
								VISITORS
							where
								V_FUNCNO = @func_ref
		
							-- delete internal attendees
							delete from
								INTVIS
							where
								IV_FUNCREF = @func_ref
			
							if @book_use = 'CPARK'
								update VISITORS set V_CPARK_FREF = '' where V_CPARK_FREF = @func_Ref
					  	end
					else
						begin
							-- not cancelled, check extras

							set @new_loc = (select RM_LOC from ROOMS where RM_ABBR = @book_room)
							if 	@book_day <> @old_day or
								@old_start <> @book_start or
								@old_end <> @book_end or
								@old_covers <> @book_covers or
								@old_loc <> @new_loc
							begin
								exec cabsweb_update_extras	
												@func_ref,
												@old_day, @book_day, 
												@old_start, @book_start,
												@old_end, @book_end,
												@old_covers, @book_covers,
												@old_loc, @new_loc				
							end		
		
						
						end -- updating room info - not cancelled
				end  -- Updating existing booking
			end -- MBR No is null
		else
			set @av_ok = -2 -- Host not found
	end -- main room av ok
end -- multi room av clear

if @av_ok >= 0
	begin
		if @formatted_func_no is NULL -- ie it's an update to the booking
    		set @book_room_result = @func_ref
		else
			set @book_room_result = @formatted_func_no
	end
else
	begin -- the booking's failed
		set @book_room_result = ''
	end

return @av_ok

end