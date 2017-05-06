SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[cabsweb_add_vis_cpark]( @vis_prikey varchar(10),
										@vis_loc varchar(6),
										@vis_exptime varchar(5),
										@vis_endtime varchar(5),
										@vis_date datetime,
										@func_ref varchar(7) output,
										@vis_message varchar(255) output )
as
begin

declare
	@room varchar(6),
	@book_room_result varchar(7),
	@func_booker varchar(50),
	@imp_key varchar(50),
	@startdatetime datetime,
	@enddatetime datetime,
	@cpark_loc varchar(50)

set @room =	(select 
				min(RM_ABBR) 
			from 
				ROOMS, CPARK_LOCS
			where
				RM_LOC = CPL_CPARK
				and CPL_LOC = @vis_loc
				and not RM_ABBR in 
					(select 
						F_ROOM
					from
						FUNC_FIL
					where
						F_DAY = @vis_date
						and F_START < @vis_endtime
						and F_END > @vis_exptime
						and F_STATUS <> 'CANCEL'))
		
if @room is null
	begin
		set @func_ref = '' -- no rooms/spaces available

		-- SAK 22Jun2007 - Updated message to match PwC (ie) requirements
		--set @vis_message = 'Sorry - No carparking spaces are available at ' + convert(varchar(5), @vis_exptime, 108 ) + ' for ' + convert( varchar(10), @vis_date, 103)
		set @vis_message = 'Due to demand you need to contact the <br> Welcome desk on Ext 7666 to confirm a carparking space at ' + convert(varchar(5), @vis_exptime, 108 ) + ' on ' + convert( varchar(10), @vis_date, 103)
	end
else
	begin
		set @startdatetime = convert( datetime, convert( varchar(10), @vis_date, 103 ) + ' ' + convert( varchar(5), @vis_exptime, 108 ), 103 )
		set @enddatetime = convert( datetime, convert( varchar(10), @vis_date, 103 ) + ' ' + convert( varchar(5), @vis_endtime, 108 ), 103 )

		set @imp_key = (select MBR_IMPKEY from MBRFILE, VISITORS where V_HOSTMBR = MBR_SYSNO and V_SYSNO = @vis_prikey)
		set @func_booker = (select F_BOOKER from FUNC_FIL, VISITORS where F_REF = V_FUNCNO and V_SYSNO = @vis_prikey group by F_BOOKER)

		if @func_booker is null or @func_booker = ''
			set @func_booker = @imp_key

		exec cabs_book_room	'',
							@imp_key, 		/* Meeting Host */
							@vis_date,
							@vis_exptime,		/* 24Hr Clock */
							@vis_endtime,		/* 24Hr Clock */
							@room,
							'CONFRM',
							'CPARK',
							1,
							0,
							0,
							1,
							'',
							'',
							@func_booker,		/* Booker of the room, assistant etc. of host */
							@func_booker,		/* op id */
							'Car Parking',
							0,
							'',
							@startdatetime,
							@enddatetime,
							@book_room_result OUTPUT

		if @book_room_result is null
			begin
				set @func_ref = ''
				set @vis_message = 'Sorry - No carparking spaces are available at ' + convert(varchar(5), @vis_exptime, 108 ) + ' for ' + convert( varchar(10), @vis_date, 103)
			end
		else
			begin
				set @func_ref = @book_room_result -- carpark ref
				set @cpark_loc = (select ST_DESC from SYS_ABBR, ROOMS where RM_ABBR = @room and ST_CODE = RM_LOC)

				-- update visitor record
				update 
					VISITORS
				set
					V_CPARK_FREF = @func_ref
				where
					V_SYSNO = @vis_prikey

				set @vis_message = 'A carparking space has been booked in ' + @cpark_loc 
			end
	end
end