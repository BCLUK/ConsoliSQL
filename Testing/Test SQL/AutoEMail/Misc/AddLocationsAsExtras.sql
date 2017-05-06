-- =====================================================================================================
-- Author:		Peter Green
-- Create date: xx/xx/xxxx
-- Description:	Adds each Location as an Extra. This enables location specific information to be 
--				configured such as an email address (which can be used for autoemails). This 
--				information can also be maintained by a client.
-- =====================================================================================================
-- Version:		1
-- Date:		01/12/2016
-- =====================================================================================================
-- Changes:		PLG: 24/09/2015: Original Version
--	(1)
-- =====================================================================================================

-- Add a GLOBAL config setting
EXEC xCABS_CONFIG_WriteString '','System','UseLocationExtendedData',1,'G'

-- Count how many locations are in POST_DEF and SYS_ABBR. If count is different ...
if (select Count(P_Code) from post_def where P_Code in (select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC')) <> 
	(select count(ST_CODE) FROM sys_ABBR where ST_TYPE = 'LOC' AND ST_CODE <> 'ALL') begin
	
	-- Check if Location Extra already exists in POST_DEF. If it does then rename it in tables POST_DEF, AI_FILE and FOL_TRAN
	if (select Count(P_Code) from post_def where P_Code in (select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC')) > 0 begin
		declare @DupCode Varchar(10)
		declare @CodeTest Varchar(6)
		declare @Counter int
		declare LocCur cursor fast_forward for select ST_CODE FROM sys_ABBR where ST_TYPE = 'LOC' and ST_CODE in (Select P_Code from Post_Def)
		open LocCur
		fetch next from LocCur into @DupCode
		while @@Fetch_status = 0 begin
			set @Counter = 1
			set @CodeTest = SUBSTRING(CHAR(64+@Counter) + @DUPCODE,1,6)
			while (select Count(P_Code) from POST_DEF where P_Code =@CodeTest) > 0 begin
				set @Counter = @Counter + 1
				set @CodeTest = SUBSTRING(CHAR(64+@Counter) + @CodeTest,2,5)
			end
			if (select Count(P_Code) from POST_DEF where P_Code =@CodeTest) = 0 begin
				update Post_def set P_Code = @CodeTest where P_CODE =@DupCode
				update AI_FILE set AI_COde = @CodeTest where AI_CODE =@DupCode
				update FOL_TRAN set F_POSTCODE= @CodeTest where F_POSTCODE =@DupCode
			end

			fetch next from LocCur into @DupCode
		end
		close LocCur
		deallocate Loccur
	end

	-- Insert new Location Extra with default values
	INSERT INTO [dbo].[POST_DEF]  ([P_CODE],[P_COSTCENT],[P_RPTCENT],[P_DESC],[P_ST_CHRGE],[P_NL_CODE]
			   ,[P_EVENT],[P_MAXPOOL],[P_IN_CHRGE],[P_CHARGEBK],[P_COST],[P_HOURLY],[P_OPGROUP]
			   ,[P_TIME],[P_ALTCODE],[P_LATEST_TIME],[P_EARLIEST_TIME],[P_ONLINE],[P_WEEKENDS],[P_EMAIL])
		 SELECT ST_CODE,'CCHIRE','','Additional Info - ' + ST_DESC,0.00, ''
				,1,1,0.00,0,0.00,0,'CCHIRE'
			   ,'00:00','','23:59','00:01',0,1,'helpdesk@bcluk.com' from SYS_ABBR where ST_TYPE = 'LOC' and ST_CODE <>'ALL'
end