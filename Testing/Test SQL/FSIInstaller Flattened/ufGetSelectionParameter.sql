if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ufGetSelectionParameter]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[ufGetSelectionParameter]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if exists (select OBJECT_ID from sys.objects where name = 'ufGetSelectionParameter') begin
	drop function ufGetSelectionParameter
end
GO
-- =============================================
-- Author:		Peter Green
-- Create date: Jan 2014
-- Description:	returns the selection parameter for a given selection field
-- Changes:		10/11/2016 added rooms
-- =============================================
CREATE FUNCTION [dbo].[ufGetSelectionParameter] 
(
	-- Add the parameters for the function here
	@SelectionField Varchar(15),
	@F_TranNo Varchar(10)
)
RETURNS Varchar(10)
AS
BEGIN
/****************************************************************************************************************************
CABS CONFIGURATION - GENERIC
****************************************************************************************************************************/
--OBJECT HEADER
	DECLARE @SP_TRG VARCHAR(100)
	SET @SP_TRG = 'ufGetSelectionParameter' --The Object Name
	
	-- Declare the return variable here
	DECLARE @REsultVar1 Varchar(10)
	DECLARE @ResultVar Varchar(10) = 'Field N/A'
	DECLARE @RM_ABBR Varchar(20)

	-- Add the T-SQL statements to compute the return value here
	if (@SelectionField = 'F_TRANNO') begin --1a
		set @ResultVar = @F_TranNo
	end -- 1a
	else begin --1b
		if (@SelectionField =  'MBR_SYSNO') begin --2a
			--we need to to find the MBR NO but it might not be the source
			set @ResultVar1 = (select F_SOURCE from FOL_TRAN where F_TRANNO = @F_TranNo)
			if Substring(@ResultVar1,1,1) <> 'M' begin -- 3a
				if Substring(@ResultVar1,1,1) = 'R' begin --4a
					--it is a room reservation
					set @ResultVar = (Select FOL_MBRNO from FOLIOS WHere FOL_MRN = @ResultVar)
				end --4a
				else begin --4b
					--I don't know what to do
					Set @ResultVar = 'M999999'
				end --4b
			end -- 3a
			else begin --3b
				set @ResultVar = @ResultVar1
			end --3b
		end --2a
		else begin --2b
		--if @SelectionField = 'AI_PRIKEY' 
			if @SelectionField =  'CL_SYSNO' begin --3c
				set @ResultVar1 = (select F_SOURCE from FOL_TRAN where F_TRANNO = @F_TranNo)
				if Substring(@ResultVar1,1,1) = 'M' begin -- 4c
					Set @ResultVar = (Select MBR_CLIENT from MBRFILE where MBR_SYSNO = @ResultVAr1)
				end --4c
				else begin --4d
					if Substring(@ResultVar1,1,1) = 'R' begin --5a
						--it is a room reservation
						set @ResultVar1 = (Select FOL_MBRNO from FOLIOS WHere FOL_MRN = @ResultVar)
						Set @ResultVar = isnull(
						(Select MBR_CLIENT from MBRFILE where MBR_SYSNO = @ResultVAr1),
						--(Select [VALUE] from xCABS_CONFIG_TABLE where Section = 'Finance' and [Key] = 'DefaultClientCode' and Deleted <> 1)
						(SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DefaultClientCode')
						)
					end --5a
					else begin --5b
						--Set @ResultVar = (Select [VALUE] from xCABS_CONFIG_TABLE where Section = 'Finance' and [Key] = 'DefaultClientCode' and Deleted <> 1)
						Set @ResultVar = (SELECT [VALUE] FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [TYPE] = 'S' AND SECTION = @SP_TRG AND [KEY] = 'DefaultClientCode')
					end -- 5b
				end -- 4d
			end	--3c 
	
			else begin -- 3d	
	
				if (@SelectionField =  'CT_SYSNO') begin -- 4e
					set @Resultvar1 = (SELECT F_SOURCE from FOL_TRAN where F_TRANNO = @F_TranNo)
					if (Substring(@ResultVar1,1,1) = 'M') begin -- 5b
						Set @ResultVar = (Select MBR_CONTNO From MBRFILE where MBR_SYSNO = @ResultVar1)
					end -- 5b
				end -- 4e
				else begin -- 4f
					if @SelectionField =  'P_CODE' begin -- 5c
						set @ResultVar = (Select F_POSTCODE from Fol_Tran where F_TRANNO = @F_TranNo)
					end --5c
					else begin -- 5d
						if @SelectionField = 'RLK_ID' begin -- 6a
							Set @REsultVar1 = (Select dbo.uf_getFunc_or_AccomDecider(@F_TranNo))
								If @REsultVar1 = 'Accomodation' begin --7a
									Set @ResultVar1 = (Select F_SOURCE from FOL_TRAN where F_TRANNO = @F_TranNo)   -- this is the folio
									Set @RM_ABBR = (Select FOL_ROOM from FOLIOS where FOL_MRN = @ResultVar1)  -- this is the room number
									Set @ResultVar1 = 'A'
								end --7a
								if @ResultVar1 = 'Conference' begin --7b
									Set @ResultVar1 = (Select F_OWNER from FOL_TRAN where F_TRANNO = @F_TranNo)   -- this is the func_fil record
									Set @RM_ABBR = (Select F_ROOM from FUNC_FIL where F_REF = @ResultVar1)  -- this is the room number
									Set @ResultVar1 = 'R'
								end --7b
								if @ResultVar1 = 'AccomExtras' begin --7c
									Set @ResultVar1 = (Select F_OWNER from FOL_TRAN where F_TRANNO = @F_TranNo)   -- this is the func_fil record
									Set @RM_ABBR = (Select FOL_ROOM from FOLIOS where FOL_MRN = @ResultVar1)  -- this is the room number
									Set @ResultVar1 = 'A'
								end  -- 7c
								If @ResultVar1 = 'AccomExtras' begin --7d
									Set @ResultVar1 = (Select F_SOURCE from FOL_TRAN where F_TRANNO = @F_TranNo)   -- this is the folio
									Set @RM_ABBR = (Select FOL_ROOM from FOLIOS where FOL_MRN = @ResultVar1)  -- this is the room number
									Set @ResultVar1 = 'A'
								end --7d
								If @ResultVar1 = 'Manual Posting' begin -- 7e  this shouldn't happen because we should have trapped for this
									-- No idea 
									set @ResultVar = 'XXXXX'
								end --7e
								else begin -- 7f
								--we need to find the appropriate link
									SET @ResultVar = (Select RLK_ID from RM_LINK where RLK_LINKTYPE = @ResultVar1 AND RLK_RMABBR = @RM_Abbr and RLK_TYPE = 'DEFLOC')
								end --7f
						end --6a
						else begin -- 6b
							if @SelectionField = 'RM_LOC' begin --7g
								set @REsultVar1 = (select F_OWNER from FOL_TRAN where F_TRANNO = @F_TranNo)  -- this is the f_ref
								if SUBSTRING(@Resultvar1,1,1) = 'F' begin		--  8a checks it is an F_REF
									set @REsultVar = (select dbo.uf_getFunctionLocation(@resultVar1))
								end --8a
							end --7g
							else begin --7h
								if @SelectionField = 'RM_ABBR' begin --8b
									set @REsultVar1 = (select F_OWNER from FOL_TRAN where F_TRANNO = @F_TranNo)  -- this is the f_ref
									if SUBSTRING(@Resultvar1,1,1) = 'F' begin		-- 9a  checks it is an F_REF
										set @REsultVar = (select F_ROOM from FUNC_FIL where F_REF = @REsultVar1)
									end -- 9a
								end --8b
							end --7h
						end --6b
					end --5d
				end -- 4f
			end --3d
		end --2b
	end	-- 1b			
	--SELECT @ResultVar

	-- Return the result of the function
	RETURN @ResultVar

END


