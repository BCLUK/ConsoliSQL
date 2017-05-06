
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_UpdateMBRDates]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_UpdateMBRDates]	
	PRINT 'usp_UpdateMBRDates: Dropped Procedure usp_UpdateMBRDates'
END
ELSE
BEGIN	
	PRINT 'usp_UpdateMBRDates: usp_UpdateMBRDates -  Does Not Already Exist !'
END

PRINT 'usp_UpdateMBRDates: Creating Procedure usp_UpdateMBRDates'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	08/02/2017
-- Description:	Updates the from and to dates in the MBRFILE based on the functions, restaurant and accomodation bookings
-- Module:		MBR Copier
-- Parameters:	@MBR_SYSNO
-- Returns:		INT
-- Switches:	None
-- Test:		Select an MBR and call it checking dates first
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		2.0
-- Date:		17/03/2017
-- ====================================================================================================================
-- Changes	(1.0): PLG: 08/02/2017: Original Version
--			(2.0): PLG: 17/03/2017:	moved isnull to inside min max
--			(3.0): PLG: 31/03/2017:	changed to ignore MBR_ENTRY in calculating from to
--									added look at extras for possible gloabal extras
--			(4.0): PLG: 05/04/2017: added packages to the updates
-- ====================================================================================================================
CREATE PROCEDURE usp_UpdateMBRDates 
	-- Add the parameters for the stored procedure here
	@MBR_SYSNO Varchar(10) = ''
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	DECLARE @MinDate datetime
	Declare @MaxDate datetime
	Declare @MBR_Default datetime
	-- Insert statements for procedure here
	--First initialise the record
	Update MBRFILE set MBR_FROM = dateadd(yy,10,isnull(MBR_ENTRY,getdate())), MBR_TO = dateadd(yy,-10,isnull(MBR_ENTRY,getdate())) where MBR_SYSNO = @MBR_SYSNO
	set @MBR_Default = isnull((Select MBR_ENTRY from MBRFILE where MBR_SYSNO = @MBR_SYSNO),dateadd(yy,-10,getdate()))
	-- now look at func_fil (this is rooms and restaurants)
	Select @MinDate = Min(isnull(F_startdatetime,getdate())), @MaxDate = Max(isnull(F_Enddatetime,@MBR_Default) ) from Func_Fil where F_MBR_NO = @MBR_SYSNO and F_STATUS <> 'CANCEL'
	Update MBRFILE set  MBR_FROM = case when (isnull(MBR_FROM,getdate()) > @MinDate) then @MinDate else MBR_FROM end, 
						MBR_TO = case when (MBR_TO < @MaxDate) then @MaxDate else MBR_TO end 
						where MBR_SYSNO = @MBR_SYSNO
	--print @MBR_SYSNO + '  now has range ' + cast(@MinDate as Varchar(20))+ '  to  ' + Cast(@MaxDate as Varchar(20))
	-- now look at accomodation
	Select @MinDate = Min(isnull(BL_date,getdate())), @MaxDate = Max(isnull(BL_TO,@MBR_Default) ) from Blocking where BL_MBR = @MBR_SYSNO
	Update MBRFILE set  MBR_FROM = case when (MBR_FROM > @MinDate) then @MinDate else MBR_FROM end, 
						MBR_TO = case when (MBR_TO < @MaxDate) then @MaxDate else MBR_TO end 
						where MBR_SYSNO = @MBR_SYSNO
	--print @MBR_SYSNO + '  now has range ' + cast(@MinDate as Varchar(20))+ '  to  ' + Cast(@MaxDate as Varchar(20))
	-- and look at enquiries
	Select @MinDate = Min(isnull(EA_date,getdate())), @MaxDate = Max(isnull(EA_DATE,@MBR_Default) ) from EnqAV where EA_OWNER = @MBR_SYSNO
	Update MBRFILE set  MBR_FROM = case when (MBR_FROM > @MinDate) then @MinDate else MBR_FROM end, 
						MBR_TO = case when (MBR_TO < @MaxDate) then @MaxDate else MBR_TO end 
						where MBR_SYSNO = @MBR_SYSNO
	--print @MBR_SYSNO + '  now has range ' + cast(@MinDate as Varchar(20))+ '  to  ' + Cast(@MaxDate as Varchar(20))
	-- now look at AI_FILE
	Select @MinDate = Min(isnull(AI_GEdate,getdate())), @MaxDate = Max(isnull(AI_GEDATE,@MBR_Default) ) from AI_File where AI_FREF = @MBR_SYSNO
	Update MBRFILE set  MBR_FROM = case when (MBR_FROM > @MinDate) then @MinDate else MBR_FROM end, 
						MBR_TO = case when (MBR_TO < @MaxDate) then @MaxDate else MBR_TO end 
						where MBR_SYSNO = @MBR_SYSNO

	-- '2017-04-05 17:14:14.073'look at packages
	Select @MinDate = Min(isnull(PH_FROM,getdate())), @MaxDate = Max(isnull(PH_TO,@MBR_Default) ) from PKGHEAD where PH_OWNER = @MBR_SYSNO
	Update MBRFILE set  MBR_FROM = case when (MBR_FROM > @MinDate) then @MinDate else MBR_FROM end, 
						MBR_TO = case when (MBR_TO < @MaxDate) then @MaxDate else MBR_TO end 
						where MBR_SYSNO = @MBR_SYSNO
		
	-- final check
	select @mindate = MBR_FROM, @MaxDate = MBR_TO from MBRFILE where MBR_SYSNO = @MBR_SYSNO
	if DATEDIFF(dd,@mindate,@Maxdate) < 0 begin
		update MBRFILE set MBR_TO = MBR_FROM  where MBR_SYSNO = @MBR_SYSNO
		--print @MBR_SYSNO + '  now has range ' + cast(@MinDate as Varchar(20))+ '  to  ' + Cast(@MinDate as Varchar(20))
	end
	select @mindate = MBR_FROM, @MaxDate = MBR_TO from MBRFILE where MBR_SYSNO = @MBR_SYSNO
	print @MBR_SYSNO + ' now has range   ' + cast(@MinDate as Varchar(20))+ '   to   ' + Cast(@MaxDate as Varchar(20))
	-- and last of all update FRANGE
	Update MBRFILE set MBR_FRANGE = dbo.fn_Format_CABS_Date(@MinDate) + ' - ' + dbo.fn_Format_CABS_Date(@MaxDate) where MBR_SYSNO = @MBR_SYSNO

END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_UpdateMBRDates]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'usp_UpdateMBRDates: usp_UpdateMBRDates Created Successfully'
END
ELSE
BEGIN
	PRINT 'usp_UpdateMBRDates: usp_UpdateMBRDates Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO