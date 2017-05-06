

if exists(select OBJECT_ID from sys.objects where name = 'usp_FI_Code_to_Tilda') begin
	DROP PROCEDURE usp_FI_Code_to_Tilda
end
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 21-Oct-2016
-- Description:	Return the first half of a code (up to the tilda)
-- =============================================
CREATE PROCEDURE usp_FI_Code_to_Tilda 
	-- Add the parameters for the stored procedure here
	@InputPar varchar(50)='',
	@InputPar1 varchar(50)='',
	@OutputVar varchar(50)='' output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @split int
	set @split = CHARINDEX('~',@InputPar,1)
    -- Insert statements for procedure here
	if ISNULL(@split,0) = 0 begin
		set @OutputVar = @InputPar
	end
	else begin
		SET @OutputVar= substring(@InputPar, 1,@split - 1)
	end
	
END
GO
