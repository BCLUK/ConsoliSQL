IF TYPE_ID('tvp_outlook_roomGroup') IS NOT NULL
DROP TYPE tvp_outlook_roomGroup
GO

CREATE TYPE tvp_outlook_roomGroup AS TABLE
(
	RG_GRPCODE VARCHAR(6) PRIMARY KEY
)
GO