-- *****************************************************************************
-- WHEN UPDATING THIS FILE DO NOT FORGET TO UPDATE THE VERSION NUMBER IN BOTH
-- THE FILE HEADER AND THE EXTENDED PROPERTIES SETION AT THE BOTTOM OF THIS FILE
-- *****************************************************************************

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT * FROM sys.objects
WHERE object_id = object_id(N'[dbo].[CABS_ADD_VIS]')
	and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE[dbo].[CABS_ADD_VIS]
	PRINT 'CABS_ADD_VIS: Dropped Procedure CABS_ADD_VIS'
END
ELSE
BEGIN
	PRINT 'CABS_ADD_VIS: CABS_ADD_VIS -  Does Not Already Exist !'
END
PRINT 'CABS_ADD_VIS: Creating Procedure CABS_ADD_VIS'
GO


-- ====================================================================================================================
-- Author:	Unknown
-- Create Date:	dd/mm/yyyy
-- Description:	
-- Product:		CABS
-- Module:		Core
-- Parameters:	
-- Returns:		
-- Switches:		
-- Test:		
-- Called By:		
-- Calls:		
-- ====================================================================================================================
-- Version:	7.0
-- Date:	dd/mm/yyyy
-- ====================================================================================================================
-- Changes(7.0): xxx: Original
-- ====================================================================================================================
CREATE PROCEDURE [dbo].[CABS_ADD_VIS]
( @func_ref varchar(7), @vis_exp varchar(5), @vis_title varchar(20), @vis_fname varchar(50), @vis_sname varchar(50),
				@vis_sysno varchar(10), @vis_date datetime, @vis_loc varchar(6), @vis_company varchar(50),
				@vis_telno varchar(20), @vis_faxno varchar(20) )
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.

	declare
		@vis_num varchar(10),
		@formatted_num varchar(20),
   		@cbcf_num int,

		@vis_host_name varchar(100),
		@vis_host_mbr varchar(7),
		@vis_room varchar(6),

		@room_loc varchar(6),

		@new_vis int,
		@vis_walkin int
		set @vis_walkin = 0

		if not @vis_sysno like 'V%'
			begin

			set @cbcf_num = (select CF_VISNO from CBCF)
			set @cbcf_num = @cbcf_num + 1

			update CBCF set CF_VISNO = @cbcf_num

			set @formatted_num = ('000000000' + ltrim(rtrim( convert(varchar(10), @cbcf_num ) )))
	     		set @vis_num = 'V' + ltrim(rtrim(right( @formatted_num, 9 )))

			set @new_vis = 1
			end
		else
			begin
			set @vis_num  = @vis_sysno
			set @new_vis  = 0
			end


		if @func_ref like 'M%' 
			begin
			set @vis_host_name = (select MBR_CMPNAM from MBRFILE where MBR_SYSNO = @func_ref)
			set @vis_host_mbr = @func_ref
			set @vis_room = ''
			set @room_loc = ''
			
			if @new_vis = 1
				set @vis_walkin = 1
			end	        
		else
			begin
			declare 
				func_dets_cursor
			cursor for
				select
					F_MBR_NAME, F_MBR_NO, F_DAY, F_ROOM 
				from
					FUNC_FIL 
		      		where 
					F_REF = @func_ref

			open func_dets_cursor

			fetch next from 
				func_dets_cursor
			into  
				@vis_host_name, @vis_host_mbr, @vis_date,  @vis_room 

			close func_dets_cursor
			deallocate func_dets_cursor

	   
			set @room_loc = (select RM_LOC from ROOMS where RM_ABBR = @vis_room)
			end

		if @new_vis = 1
						begin
			insert into VISITORS
				(V_SYSNO, V_HOSTNAME, V_DATE, V_EXPECTED, V_TITLE, V_FORENAME, V_SURNAME, V_HOSTMBR, V_ROOM, V_FUNCNO,
				V_TYPE,  V_WALKIN, V_BATCHED, V_LOC)
			values
				(@vis_num, @vis_host_name, @vis_date, @vis_exp, @vis_title, @vis_fname, @vis_sname, @vis_host_mbr, @vis_room, @func_ref,
				'NORM', @vis_walkin, 0, @room_loc)
						end
		else
						begin
			update 
				VISITORS
			set 
				V_HOSTNAME = @vis_host_name, 
				V_DATE = @vis_date, 
				V_EXPECTED = @vis_exp, 
				V_TITLE = @vis_title, 
				V_FORENAME = @vis_fname, 
				V_SURNAME = @vis_sname, 
				V_HOSTMBR = @vis_host_mbr, 
				V_BATCHED = 0,
				V_LOC = @room_loc
			where
				V_SYSNO = @vis_sysno
						end

	END

	SET QUOTED_IDENTIFIER OFF 

GO

IF EXISTS(SELECT * FROM sys.objects
	WHERE  object_id = object_id(N'[dbo].[CABS_ADD_VIS]')
		and OBJECTPROPERTY(object_id, N'IsProcedure') = 1 )
BEGIN
	PRINT 'CABS_ADD_VIS: CABS_ADD_VIS Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_ADD_VIS: CABS_ADD_VIS Not Created Successfully !'
END

PRINT '*****************************************************************************'
PRINT 'CABS_ADD_VIS: Creating Extended Properties'

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA'
		, @level0name = [dbo]
		, @level1type = N'PROCEDURE'
		, @level1name = [CABS_ADD_VIS]
		, @name = N'Product'
		, @value = N'CABS'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_ADD_VIS') AND[name] = 'Product')
BEGIN
	PRINT 'CABS_ADD_VIS: Product Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_ADD_VIS: Product Extended Property Not Created Successfully !'
END

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA'
		, @level0name = [dbo]
		, @level1type = N'PROCEDURE'
		, @level1name = [CABS_ADD_VIS]
		, @name = N'Module'
		, @value = N'Core'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_ADD_VIS') AND[name] = 'Module')
BEGIN
	PRINT 'CABS_ADD_VIS: Module Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_ADD_VIS: Module Extended Property Not Created Successfully !'
END

EXEC sys.sp_addextendedproperty @level0type = N'SCHEMA'
		, @level0name = [dbo]
		, @level1type = N'PROCEDURE'
		, @level1name = [CABS_ADD_VIS]
		, @name = N'Version'
		, @value = N'7.0'

IF EXISTS (SELECT NULL FROM sys.extended_properties where [major_id] = OBJECT_ID('CABS_ADD_VIS') AND[name] = 'Version')
BEGIN
	PRINT 'CABS_ADD_VIS: Version Extended Property Created Successfully'
END
ELSE
BEGIN
	PRINT 'CABS_ADD_VIS: Version Extended Property Not Created Successfully !'
END

PRINT '*****************************************************************************'
GO
