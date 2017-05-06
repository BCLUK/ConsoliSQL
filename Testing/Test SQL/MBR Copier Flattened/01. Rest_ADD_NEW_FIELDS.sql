IF (SELECT COUNT(*) FROM dbo.sysobjects where id = object_id(N'[GERestData_Full]')) = 1
BEGIN
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'RUN_ID'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GERestData_Full') = 0
	BEGIN
		ALTER TABLE GERestData_Full ADD RUN_ID INT
	END
END
GO

IF (SELECT COUNT(*) FROM dbo.sysobjects where id = object_id(N'[GERestData_Full]')) = 1
BEGIN
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'RUN_DATE'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GERestData_Full') = 0
	BEGIN
		ALTER TABLE GERestData_Full ADD RUN_DATE DATETIME
	END
END
GO

IF (SELECT COUNT(*) FROM dbo.sysobjects where id = object_id(N'[GERestData_Full]')) = 1
BEGIN
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'RUN_ID'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GERestData_Full') = 1
	BEGIN
		UPDATE GERestData_Full
		SET RUN_ID = 1
		WHERE COALESCE(RUN_ID, 0) = 0
	END
END
GO

IF (SELECT COUNT(*) FROM dbo.sysobjects where id = object_id(N'[GERestData_Full]')) = 1
BEGIN
	IF (SELECT count(*) FROM syscolumns, sysobjects where syscolumns.name = 'RUN_DATE'
		 and sysobjects.id = syscolumns.id
		 and sysobjects.name = 'GERestData_Full') = 1
	BEGIN
		UPDATE GERestData_Full
		SET RUN_DATE = '29-APR-2016'
		WHERE COALESCE(RUN_DATE, '') = ''
	END
END
GO