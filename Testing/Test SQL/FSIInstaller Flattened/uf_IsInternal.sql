
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[uf_IsInternal]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[uf_IsInternal]
GO


-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter Green
-- Create date: 18 Oct 2012
-- Description:	From a Fol_tran Record number determines whether the booking is internal or external
-- =============================================
CREATE FUNCTION uf_IsInternal 
(
	-- Add the parameters for the function here
	@F_TranNo Varchar(15)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Internal int
	Declare @Owner Varchar(15)
	Declare @OwnerType Varchar(1)
	DECLARE @MBR Varchar(15)
	-- Add the T-SQL statements to compute the return value here

	Set @Owner= (Select F_Owner from Fol_Tran where  F_TRANNO = @F_TranNo)
	Set @OwnerType = Substring(@Owner,1,1)
	If @OwnerType = 'F' Begin
		SET @Internal = (Select F_Intern from Func_fil where F_REF = @Owner)
	End
	Else if @OwnerType = 'B' begin
		Set @MBR =  (Select F_SOURCE from Fol_Tran where  F_TRANNO = @F_TranNo)
		Set @Internal = (Select MBR_INTERN from MBRFILE where MBR_SYSNO = @MBR)	
	end
	Else if @OwnerType = 'M' begin
		set @MBR=@Owner
		Set @Internal = (Select MBR_INTERN from MBRFILE where MBR_SYSNO = @MBR)	
	end
	Else if @OwnerType = 'R' begin
		Set @MBR =  (Select F_SOURCE from Fol_Tran where  F_TRANNO = @F_TranNo)
		if SUBSTRING(@MBR,1,1) = 'M' begin
			Set @Internal = (Select MBR_INTERN from MBRFILE where MBR_SYSNO = @MBR)	
		end
		else begin
			Set @Internal = 0
		end
	end
	Else if @OwnerType = 'D' begin
		Set @MBR =  (Select F_SOURCE from Fol_Tran where  F_TRANNO = @F_TranNo)
		if SUBSTRING(@MBR,1,1) = 'M' begin
			Set @Internal = (Select MBR_INTERN from MBRFILE where MBR_SYSNO = @MBR)	
		end
		else begin
			Set @Internal = 0
		end
	end
	Else begin
		Set @MBR =  (Select F_SOURCE from Fol_Tran where  F_TRANNO = @F_TranNo)
		if SUBSTRING(@MBR,1,1) = 'M' begin
			Set @Internal = (Select MBR_INTERN from MBRFILE where MBR_SYSNO = @MBR)	
		end
		else begin
			Set @Internal = 0
		end
	end
	

	-- Return the result of the function
	RETURN isnull(@Internal,0)

END
GO

