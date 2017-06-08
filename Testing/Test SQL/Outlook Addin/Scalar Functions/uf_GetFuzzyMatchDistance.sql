CREATE FUNCTION GetFuzzyMatchDistance
(
	@fullString VARCHAR( 50 ),
	@fullStringDblMet VARCHAR( 10 ),
	@searchTerm VARCHAR( 50 ),
	@searchTermMet VARCHAR( 5 )
)
RETURNS DECIMAL( 4, 2 )
AS
BEGIN
	DECLARE 
		@leftDMDiff DECIMAL( 4, 2 ),
		@rightDMDiff DECIMAL( 4, 2 ),
		@leven DECIMAL( 4, 2 ),
		@leftMet VARCHAR( 5 ),
		@rightMet VARCHAR( 5 )

	SET @leftMet = LTRIM( RTRIM( LEFT( @fullStringDblMet, 5 ) ) )
	SET @rightMet = LTRIM( RTRIM( RIGHT( @fullStringDblMet, 5 ) ) )

	SET @leftDMDiff = 1 - dbo.PercentageMatch( @searchTermMet, @leftMet )
	SET @rightDMDiff = 1 - dbo.PercentageMatch( @searchTermMet, @rightMet )

	SET @leven = dbo.LevenshteinDistance( @searchTermMet, @leftMet ) + dbo.LevenshteinDistance( @searchTermMet, @rightMet )
	SET @leven = CAST( @leven as DECIMAL ) / 2

	RETURN ( ( @leftDMDiff * @rightDMDiff ) * ( @leven * ( 1 - dbo.PercentageMatch( @fullstring, @searchTerm ) ) ) ) + ( 1 - dbo.PercentageMatch( @fullstring, @searchTerm ) )
END