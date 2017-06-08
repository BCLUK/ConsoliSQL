CREATE VIEW dbo.vw_MBRFileDoubleMetaphone WITH SCHEMABINDING AS
SELECT 
	MBR_SYSNO,
	MBR_CMPNAM,
	MBR_SALUT,
	MBR_ADDR1,
	MBR_ADDR2,
	MBR_INTERN,
	MBR_IMPKEY,
	MBR_STATUS,
	dbo.DoubleMetaphone( MBR_ADDR1 ) as FirstDoubleMetaphone,
	dbo.DoubleMetaphone( MBR_CMPNAM ) as LastDoubleMetaphone
FROM dbo.MBRFILE
WHERE
	MBR_INTERN = 1
	AND ISNULL( MBR_ADDR1, '' ) <> ''
	AND ISNULL( MBR_CMPNAM, '' ) <> ''

GO

CREATE UNIQUE CLUSTERED INDEX ix_MBRFileDoubleMetaphone ON dbo.vw_MBRFileDoubleMetaphone
(
	MBR_SYSNO,
	FirstDoubleMetaphone,
	LastDoubleMetaphone	
)

GO