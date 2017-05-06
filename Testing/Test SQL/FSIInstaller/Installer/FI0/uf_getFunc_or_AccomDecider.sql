if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[uf_getFunc_or_AccomDecider]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[uf_getFunc_or_AccomDecider]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:           Peter Green   
-- Create date: 26th Sept 2012
-- Description:      Return the context - Conference, Accomodation or Extras based on FOL_TRAN
-- =============================================
CREATE FUNCTION [dbo].[uf_getFunc_or_AccomDecider] 
(
       -- Add the parameters for the function here
       @F_TranNo Varchar(10)
)
RETURNS Varchar(50)
AS
BEGIN
       -- Declare the return variable here
       DECLARE @ResultVar Varchar(50)

       -- Add the T-SQL statements to compute the return value here
       DECLARE @F_Owner Varchar(10)
       DECLARE @F_Source Varchar(10)
       DECLARE @F_ItemType Varchar(10)
       DECLARE @F_Package Varchar(10)

       Set @ResultVar = 'Conference'
       SET @F_Owner = (Select isnull(F_OWNER,' ') from FOL_TRAN where F_TRANNO = @F_TranNo)
       SET @F_Source = (Select isnull(F_Source,' ') from FOL_TRAN where F_TRANNO = @F_TranNo)
       Set @F_ItemType = (Select isnull(F_ItemType,' ') from FOL_TRAN where F_TRANNO = @F_TranNo)
       Set @F_Package = (Select isnull(F_PACKAGE,' ') from FOL_TRAN where F_TRANNO = @F_TranNo)
       if SUBSTRING(@F_Owner,1,1) = 'R'  OR SUBSTRING(@F_Owner,1,1) = 'B' begin
              If Substring(@F_ItemType,1,1) = '0' set @ResultVar = 'AccomExtras'
              else set @ResultVar = 'Accomodation'
       end
         --if SUBSTRING(@F_Source,1,1) = 'F' begin
       if SUBSTRING(@F_Owner,1,1) = 'F' begin
              if Substring(@F_Package,1,1) = 'P' set @ResultVar = 'ConfPackage'
              if Substring(@F_ItemType,1,1) = '0' set @ResultVar = 'ConfExtras'
       end
       if (SUBSTRING(@F_Owner,1,1) = 'M' or @F_Owner = ' ') begin
			if SUBSTRING(@F_Source,1,1) = 'R' set @ResultVar = 'Accomodation' -- this is a walk in (I think)
            else set @ResultVar = 'Manual Posting'
       end
              
       --SELECT @ResultVar

       -- Return the result of the function
       RETURN @ResultVar

END


GO
