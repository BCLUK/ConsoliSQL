declare 
	@RESULT NVARCHAR(MAX),
	@TYPE VARCHAR(1000),
	@SECTION VARCHAR(1000),
	@KEY VARCHAR(1000),
	@VALUE VARCHAR(1000)
	
declare 
	items_cursor
cursor FAST_FORWARD for

	SELECT [TYPE], [SECTION], [KEY], [VALUE]
	FROM xCABS_CONFIG_TABLE
	WHERE
		[TYPE] = 'S'
	AND
		[DELETED] = 0
	AND [SECTION] IN(
	--'AEFCHN',
	--'AEFCXL',
	--'AEFPRQ',
	--'AEFUIE',
	--'AEFUPE',
	--'AEFUPD'
	'AEFCON',
	'CABS_AUTO_EMAIL_FUNCS',
	'CABS_AUTO_EMAIL_FUNCS_Trigger',
	'DeptEmailAddresses'
	)	
	ORDER BY [SECTION], [KEY]

open items_cursor

fetch next from
	items_cursor
into
	@TYPE,
	@SECTION,
	@KEY,
	@VALUE



while @@fetch_status = 0
begin
	
	set @Result = ''
	set @Result = @Result + 'IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = ' + '''' + @SECTION + ''''+ ' AND [KEY] = ' + '''' + @KEY + '''' + ') = 0 ' + CHAR(10) + 'BEGIN ' + CHAR(10) +
	'INSERT INTO xCABS_CONFIG_TABLE' + CHAR(10) + '([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])' + CHAR(10) +
							'VALUES' + CHAR(10) + '(' + '''' + @TYPE + '''' + ', ' + '''''' + ', ' + ''''+ @SECTION + '''' + ', ' + '''' + @KEY + '''' + ', ' + '''' + @VALUE + '''' + ', ' + '''0''' + ', ' + '''cc''' + ', ' + 'GETUTCDATE())' + CHAR(10) + 'END' + CHAR(10) + 'GO' 
	
	PRINT @RESULT
	
	fetch next from
		items_cursor
	into
		@TYPE,
		@SECTION,
		@KEY,
		@VALUE
end

close items_cursor
deallocate items_cursor