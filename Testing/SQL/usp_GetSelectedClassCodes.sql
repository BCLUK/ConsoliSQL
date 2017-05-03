IF OBJECT_ID('[dbo].[usp_GetSelectedClassCodes]', 'P') IS NOT NULL
DROP PROCEDURE [dbo].[usp_GetSelectedClassCodes]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Edwards
-- Create date: 10/03/2017
-- Description:	Gets selected class codes from owner.
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetSelectedClassCodes]
	@Owner VARCHAR(7),
	@Table INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @TableId VARCHAR(2) = REPLACE(STR(@Table, 2), ' ', '0')
	DECLARE @Sql NVARCHAR(MAX) = '
		SELECT CT_DESC
		FROM AC' + @TableId + '
		INNER JOIN CT' + @TableId + '
		ON CT_CODE = AC_CODE
		WHERE AC_OWNER = @Owner
		ORDER BY CT_ORDER'

	EXEC sp_executesql @Sql, N'@Owner VARCHAR(7)', @Owner
END
GO