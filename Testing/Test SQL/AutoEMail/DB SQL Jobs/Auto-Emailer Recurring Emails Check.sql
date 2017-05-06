USE [msdb]
GO

-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 01/11/2016
-- Description:	This script is used to create a scheduled job to run stored procedure 
--				CABS_AEF_RESET_AEFL_SENT
--
-- =====================================================================================================
-- Version:		5
-- Date:		27/03/2017
-- =====================================================================================================
-- Changes:		PLG: xx/xx/20xx: Original Version
--
-- Changes:		TT:	01/11/2016: Added code to get DBName and DBLogin from temporary table
--  (2)							Deleted hard coded userid - not needed 
--								Changed the name of the scheduled job from [SHU] ... to [CABS] ...
--								Added header information
--
-- Changes:		TT:	08/11/2016: Added Diagnostic Code
--  (3)
--
-- Changes:		TT:	19/01/2017: Removed @DBName and @DBLogin settings - should be unset in preparation 
--  (4)							for delivery to client site

-- Changes:		TT:	27/03/2017: Changed the print statements to reflect the changed script name 
--  (5)							
-- =====================================================================================================

-- The top section of this script sets the variables  to be used throughout the script
-- Please enter the values here  for Database Name and the Login to be used for running the jobs
DECLARE @DBName VARCHAR(100)
DECLARE @DBLogin VARCHAR(100)

SET @DBName =  N'<<Put YOUR DB Name in Here>>'   --Value MUST be changed
SET @DBLogin = N'<<PUT THE LOGIN to run the job HERE>>'  --Value MUST be changed

CREATE TABLE ##vars (DBName Varchar(100), DBLogin Varchar(100))
INSERT INTO ##vars VALUES (@DBName, @DBLogin)
GO

-- Changed [SHU] to [CABS] to make it generic - TT - 01/11/2016
if exists (Select * from msdb.dbo.sysjobs where name = N'[CABS] Auto-Emailer Recurring Emails Check') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N'[CABS] Auto-Emailer Recurring Emails Check', @delete_unused_schedule=1
	-- Added Diagnostic Code - TT - 08/11/2016
	PRINT 'Auto-Emailer Recurring Emails Check: Deleted Job - [CABS] Auto-Emailer Recurring Emails Check'
end
ELSE
BEGIN
	PRINT 'Auto-Emailer Recurring Emails Check: [CABS] Auto-Emailer Recurring Emails Check Does Not Exist !'
END
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
	-- Added Diagnostic Code - TT - 08/11/2016
	PRINT 'Auto-Emailer Recurring Emails Check: Add Job Category'
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
ELSE
BEGIN
	PRINT 'Auto-Emailer Recurring Emails Check: Job Category Already Exists'
END

DECLARE @DBName VARCHAR(100)
DECLARE @DBLogin VARCHAR(100)
DECLARE @jobId BINARY(16)

-- Added code to get DBName and DBLogin from temporary table - TT - 01/11/2016
SELECT @DBName = DBName, @DBLogin = DBLogin FROM ##vars

-- Changed [SHU] to [CABS] to make it generic - TT - 01/11/2016
-- Added Diagnostic Code - TT - 08/11/2016
PRINT 'Auto-Emailer Recurring Emails Check: Add Job - [CABS] Auto-Emailer Recurring Emails Check'
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'[CABS] Auto-Emailer Recurring Emails Check', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@DBLogin, 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Added Diagnostic Code - TT - 08/11/2016
PRINT 'Auto-Emailer Recurring Emails Check: Add Job Step - Check Recurring Email'
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Recurring Email', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'CABS_AEF_RESET_AEFL_SENT', 
		@database_name=@DBName, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
-- Added Diagnostic Code - TT - 08/11/2016
PRINT 'Auto-Emailer Recurring Emails Check: Update Job'
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
-- Added Diagnostic Code - TT - 08/11/2016
PRINT 'Auto-Emailer Recurring Emails Check: Add Job Schedule'
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run SQL', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=24, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160616, 
		@active_end_date=99991231, 
		@active_start_time=100, 
		@active_end_time=235959 
-- Deleted hard coded userid - not needed - TT - 01/11/2016		 
-- @schedule_uid=N'8bf04924-edb3-4a61-903f-10a037e99324'

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
-- Added Diagnostic Code - TT - 08/11/2016
PRINT 'Auto-Emailer Recurring Emails Check: Add Job Server'
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

DROP TABLE ##vars
GO