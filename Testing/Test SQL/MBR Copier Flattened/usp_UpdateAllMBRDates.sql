
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '*****************************************************************************'

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_UpdateAllMBRDates]') 
					and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
	DROP PROCEDURE [dbo].[usp_UpdateAllMBRDates]	
	PRINT 'UpdateAllMBRDates: Dropped Procedure usp_UpdateAllMBRDates'
END
ELSE
BEGIN	
	PRINT 'UpdateAllMBRDates: usp_UpdateAllMBRDates -  Does Not Already Exist !'
END

PRINT 'UpdateAllMBRDates: Creating Procedure usp_UpdateAllMBRDates'
GO

-- ====================================================================================================================
-- Author:		Peter Green				
-- Create Date:	08/02/2017
-- Description:	Cycles through all MBRs and updates their dates
-- Module:		MBR Copier
-- Parameters:	None
-- Returns:		int
-- Switches:	None
-- Test:		Insert How to Test
-- Called By:	
-- Calls:		
-- ====================================================================================================================
-- Version:		1.0
-- Date:		08/02/2017
-- ====================================================================================================================
-- Changes (1.0): PLG: 08/02/2017: Original Version
-- ====================================================================================================================
CREATE PROCEDURE usp_UpdateAllMBRDates 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
	
	-- Insert statements for procedure here

	IF EXISTS(SELECT 0 FROM [sys].[columns] WHERE [object_id] = OBJECT_ID('[dbo].[MBRFILE]', 'U') AND [name] = 'MBR_FRANGE')
		AND (SELECT [max_length]
		FROM [sys].[columns]
		WHERE [object_id] = OBJECT_ID('[dbo].[MBRFILE]', 'U')
			AND [name] = 'MBR_FRANGE') <> 30
	ALTER TABLE [dbo].[MBRFILE]
	ALTER COLUMN [MBR_FRANGE] VARCHAR(30)

	declare @MBRNo Varchar(10)
	declare @rowcount int = 0
	declare mbrcur cursor fast_forward for select MBR_SYSNO from MBRFILE --where 
	open mbrcur
	fetch next from mbrcur into @MBRNo
	while @@FETCH_STATUS = 0 begin
		print ' Called ' + @MBrNo
		Exec usp_UpdateMBRDates @MBRNo 
		set @rowcount = @rowcount + 1
		fetch next from mbrcur into @MBRNo
	end
	close mbrcur
	deallocate mbrcur
	print 'Updated ' + cast(@rowcount as varchar(10)) + ' MBR records'
END
GO

IF EXISTS ( SELECT * FROM   sysobjects 
			WHERE  id = object_id(N'[dbo].[usp_UpdateAllMBRDates]') 
				   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN	
	PRINT 'UpdateAllMBRDates: usp_UpdateAllMBRDates Created Successfully'
END
ELSE
BEGIN
	PRINT 'UpdateAllMBRDates: usp_UpdateAllMBRDates Not Created Successfully !'	
END

PRINT '*****************************************************************************'
GO