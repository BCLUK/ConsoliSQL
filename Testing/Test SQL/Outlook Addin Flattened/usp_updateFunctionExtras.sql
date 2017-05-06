SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Corey Bradford
-- Create date: 21/07/2016
-- Description:	Updates all of the extras for a function that has been moved
-- =============================================
CREATE PROCEDURE usp_updateFunctionExtras 
	-- Add the parameters for the stored procedure here
	@Impkey varchar( 31 ),
	@F_REF Varchar(10) = '',
	@hoursDiff int,
	@minsDiff int,
	@totalDiffinMins int,
	@covers decimal(10,2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @AIPrikey Varchar( 15 )

	declare @funcStartTime datetime
	declare @funcEndTime datetime

	set @funcStartTime = ( select F_STARTDATETIME from FUNC_FIL where F_REF = @F_REF );
	set @funcEndTime = ( select F_ENDDATETIME from FUNC_FIL where F_REF = @F_REF );

	declare @startdatetime datetime = dateadd( minute, @totalDiffinMins, @funcStartTime );
	declare @enddatetime datetime = dateadd( minute, @totalDiffinMins, @funcEndTime );

	declare @OPID varchar( 31 ) = ( select [dbo].[uf_getOPIDFromImpkey]( @Impkey, 'O' ) );

	declare aicur cursor fast_forward for select AI_PRIKEY from AI_FILE where AI_FREF = @F_REF
	open aicur 
	Fetch next from aicur into @AIPrikey
	While @@Fetch_status = 0 begin
		declare @extraTime datetime;		
		declare @endTime datetime;
		declare @notes varchar(255);
		declare @extraCode varchar;
		declare @charge decimal;
		declare @cback varchar( 50 );
		declare @credit varchar( 50 );
		declare @canpost varchar( 3 );
		declare @aires int;
		declare @oldcovers decimal;

		select @extraTime = AI_TIME,
				@endTime = AI_ENDTIME,
				@notes = cast(AI_TEXT as varchar(255)), 
				@extracode = AI_CODE, 
				@charge = AI_CHARGE, 
				@cback = AI_CHARGEBK,
				@credit = AI_CREDIT,
				@canpost = AI_CANPOST,
				@aires = AI_RES,
				@oldcovers = AI_COVERS,
				@startdatetime = AI_STARTDATETIME,
				@enddatetime = AI_ENDDATETIME
				from AI_FILE 
				where AI_PRIKEY = @AIPrikey;

		if( @aires = 1 )
			set @Covers = @oldcovers;

		set @extraTime = ( select [dbo].[uf_cabs_ModifyTime]( @extraTime, @hoursDiff, @minsDiff ) );
		set @endTime = ( select [dbo].[uf_cabs_ModifyTime]( @endTime, @hoursDiff, @minsDiff ) );

		exec cabs_add_extra @AIPrikey, @F_REF, @extraTime, @Covers, @notes, @OPID, @extracode, @endTime, @charge, @cback, @credit, @canPost, @startdatetime, @enddatetime
		
		Fetch next from aicur into @AIPrikey
	End
	close aicur
	Deallocate aicur
END