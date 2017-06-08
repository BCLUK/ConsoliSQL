CREATE FUNCTION PercentageMatch( @fullstring VARCHAR( 50 ), @searchterm VARCHAR( 50 ) )
RETURNS DECIMAL( 3, 2 )
AS
BEGIN
	IF ISNULL( @searchterm, '' ) = ''
		RETURN 0

	DECLARE 
		@fullstringlength INT,
		@searchtermlength INT,
		@fullindex INT = 1,
		@partindex INT = 1,
		@matchedchars INT = 0,
		@matchedpartchars INT = 0,
		@maxcharsinarow INT = 0,
		@inarowindex INT = 0

	SET @fullstringlength = LEN( @fullstring )
	SET @searchtermlength = LEN( @searchterm )

	-- Check how many search term letters are in the full string
	WHILE @partindex <= @searchtermlength
	BEGIN
		WHILE @fullindex <= @fullstringlength
		BEGIN
			IF( SUBSTRING( @fullstring, @fullindex, 1 ) = SUBSTRING( @searchterm, @partindex, 1) )
			BEGIN
				SET @matchedchars = @matchedchars + 1
				SET @fullindex = @fullstringlength
			END

			SET @fullindex = @fullindex + 1
		END
		SET @partindex = @partindex + 1
		SET @fullindex = 1
	END

	SET @inarowindex = @searchtermlength
	WHILE @inarowindex > 0
	BEGIN
		IF @fullstring LIKE '%' + SUBSTRING( @searchterm, 1, @inarowindex ) + '%'
		BEGIN
			SET @maxcharsinarow = @inarowindex
			SET @inarowindex = 0
		END
		SET @inarowindex = @inarowindex - 1
	END

	RETURN ( CAST( ( @matchedchars * 2 ) + @maxcharsinarow AS DECIMAL ) / ( @fullstringlength + @searchtermlength + @searchtermlength ) )
END