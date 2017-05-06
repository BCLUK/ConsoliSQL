
--==================================================================================

IF EXISTS(SELECT OBJECT_ID FROM SYS.OBJECTS WHERE Name = N'usp_getFIDim7') begin
	Drop Procedure usp_getFIDim7
END
Go
/****** Object:  StoredProcedure [dbo].[usp_getFIDim7]    Script Date: 20/09/2016 09:27:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- Description;  Takes 4 characters from astring starting at position 11
-- Purpose:		To take part of a cost code for a particular client (included in standard just so it doesnt get lost!)
-- Date:		Unknown
-- Author:		Peter Green
CREATE PROCEDURE [dbo].[usp_getFIDim7]
	
@InputPar varchar(50)='',
@InputPar1 varchar(50)='',
@OutputVar varchar(50)='' output

AS
BEGIN
	  --SELECT @inputPar1=P_NL_CODE FROM POST_DEF P INNER JOIN FOL_TRAN F ON F.F_POSTCODE=P.P_CODE WHERE F_TRANNO=@InputPar1
	  SET @OutputVar= substring(@InputPar, 11, 4)
	 -- SELECT @OutputVar
	   
END
------------------------------------------------------------------------

GO

