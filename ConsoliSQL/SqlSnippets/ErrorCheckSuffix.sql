COMMIT
GO

IF @@ERROR <> 0
SET NOEXEC ON
GO

DECLARE @Success BIT = 1

SET NOEXEC OFF

IF @Success = 1
BEGIN
	PRINT 'ConsoliSQL - Successfully executed installation script!'
END
ELSE BEGIN
	IF @@TRANCOUNT > 0
	ROLLBACK

	PRINT 'ConsoliSQL - Failed to execute installation script...'
END
GO